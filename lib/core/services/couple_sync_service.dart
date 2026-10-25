import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Why pairing with an invite code failed. The UI maps these to localized text.
enum PairingError { notFound, ownCode, alreadyUsed, unavailable }

class PairingException implements Exception {
  final PairingError error;
  const PairingException(this.error);

  @override
  String toString() => 'PairingException($error)';
}

class PairingResult {
  final String coupleId;
  final String? partnerId;
  final String? partnerName;

  const PairingResult({required this.coupleId, this.partnerId, this.partnerName});
}

/// Couple-level backend operations. Abstracted so the app state can be tested
/// without Firebase.
///
/// Firestore layout (see `firestore.rules`):
/// - `invites/{inviteCode}`: `{coupleId, ownerId, ownerName}`; lets a partner
///   find a couple space by code without listing every couple.
/// - `couples/{coupleId}`: random id, `memberIds` (1 or 2 uids), names, FCM
///   tokens and shared couple settings. Only members can read it.
/// - `couples/{coupleId}/{collection}/{docId}`: shared content.
abstract class CoupleSyncService {
  /// Firebase uid of the signed-in user, or `null` when offline.
  String? get currentUid;

  /// Creates a new couple space owned by the current user and points
  /// [inviteCode] at it. Returns the new couple id, or `null` when offline.
  Future<String?> createCoupleSpace({
    required String inviteCode,
    required String userName,
    required String mode,
    required DateTime startDate,
    String? fcmToken,
  });

  /// Makes sure [inviteCode] points to [coupleId] so a partner can join it.
  Future<void> ensureInvite({
    required String inviteCode,
    required String coupleId,
    required String ownerName,
  });

  /// Joins the couple space behind [inviteCode]. Throws [PairingException].
  Future<PairingResult> pairWithInviteCode({
    required String inviteCode,
    required String myName,
    String? fcmToken,
  });

  StreamSubscription<Map<String, dynamic>>? listenToCouple({
    required String coupleId,
    required void Function(Map<String, dynamic> data) onUpdate,
  });

  /// Merges shared couple settings (names, dates, mode, tokens...).
  Future<void> updateCouple(String coupleId, Map<String, dynamic> fields);

  Future<void> sendThinkingOfYouPulse(String coupleId, String senderName);

  /// Removes the current user from the couple; the partner keeps the space.
  Future<void> leaveCouple(String coupleId);

  /// Number of members of [coupleId] (0 if it does not exist or is unreadable).
  Future<int> memberCount(String coupleId);

  /// Deletes the couple document (allowed only for its last member).
  Future<void> deleteCouple(String coupleId);

  Future<void> deleteInvite(String inviteCode);

  /// Deletes the Firebase Auth user (account deletion).
  Future<void> deleteCurrentUser();

  /// After signing in on a new device: the couple space this user belongs to
  /// (a paired one first) with its data, or `null`.
  Future<({String coupleId, Map<String, dynamic> data})?> findMyCouple();

  /// The invite code this user owns, if any.
  Future<String?> findMyInviteCode();
}

/// Real-time couple synchronization backed by Cloud Firestore.
class FirestoreCoupleSyncService implements CoupleSyncService {
  FirestoreCoupleSyncService._();
  static final FirestoreCoupleSyncService instance = FirestoreCoupleSyncService._();

  bool get _online => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _couple(String coupleId) =>
      _db.collection('couples').doc(coupleId);

  @override
  String? get currentUid => _online ? FirebaseAuth.instance.currentUser?.uid : null;

  Future<String?> _ensureUid() async {
    if (!_online) return null;
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      debugPrint('CoupleSyncService: Auth note: $e');
      return null;
    }
  }

  @override
  Future<String?> createCoupleSpace({
    required String inviteCode,
    required String userName,
    required String mode,
    required DateTime startDate,
    String? fcmToken,
  }) async {
    final uid = await _ensureUid();
    if (uid == null) return null;
    try {
      final coupleId = 'cpl_${const Uuid().v4().replaceAll('-', '')}';
      await _couple(coupleId).set({
        'coupleId': coupleId,
        'inviteCode': inviteCode,
        'user1Id': uid,
        'user1Name': userName,
        'user2Id': null,
        'user2Name': null,
        'memberIds': [uid],
        'tokens': {if (fcmToken != null) uid: fcmToken},
        'mode': mode,
        'startDate': startDate.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await ensureInvite(inviteCode: inviteCode, coupleId: coupleId, ownerName: userName);
      debugPrint('CoupleSyncService: Created couple space $coupleId');
      return coupleId;
    } catch (e) {
      debugPrint('CoupleSyncService: createCoupleSpace error: $e');
      return null;
    }
  }

  @override
  Future<void> ensureInvite({
    required String inviteCode,
    required String coupleId,
    required String ownerName,
  }) async {
    final uid = await _ensureUid();
    if (uid == null) return;
    try {
      await _db.collection('invites').doc(inviteCode).set({
        'coupleId': coupleId,
        'ownerId': uid,
        'ownerName': ownerName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('CoupleSyncService: ensureInvite error: $e');
    }
  }

  @override
  Future<PairingResult> pairWithInviteCode({
    required String inviteCode,
    required String myName,
    String? fcmToken,
  }) async {
    final cleanCode = inviteCode.trim().toUpperCase();
    // Without a backend there is no way to verify the code: never fake a pairing.
    final uid = await _ensureUid();
    if (uid == null) throw const PairingException(PairingError.unavailable);

    final invite = await _db.collection('invites').doc(cleanCode).get();
    final inviteData = invite.data();
    if (!invite.exists || inviteData == null) {
      throw const PairingException(PairingError.notFound);
    }
    final ownerId = inviteData['ownerId'] as String?;
    final coupleId = inviteData['coupleId'] as String?;
    if (coupleId == null) throw const PairingException(PairingError.notFound);
    if (ownerId == uid) throw const PairingException(PairingError.ownCode);

    try {
      // Security rules only accept this write while the second seat is empty
      // and `joinCode` matches the invite, so no read access is needed first.
      await _couple(coupleId).update({
        'user2Id': uid,
        'user2Name': myName,
        'memberIds': [ownerId, uid],
        if (fcmToken != null) 'tokens.$uid': fcmToken,
        'joinCode': cleanCode,
        'pairedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('CoupleSyncService: join error: ${e.code}');
      if (e.code == 'permission-denied') {
        throw const PairingException(PairingError.alreadyUsed);
      }
      if (e.code == 'not-found') throw const PairingException(PairingError.notFound);
      throw const PairingException(PairingError.unavailable);
    }

    debugPrint('CoupleSyncService: Paired with couple $coupleId');
    return PairingResult(
      coupleId: coupleId,
      partnerId: ownerId,
      partnerName: inviteData['ownerName'] as String?,
    );
  }

  @override
  StreamSubscription<Map<String, dynamic>>? listenToCouple({
    required String coupleId,
    required void Function(Map<String, dynamic> data) onUpdate,
  }) {
    if (!_online) return null;
    return _couple(coupleId)
        .snapshots()
        .where((s) => s.exists && s.data() != null)
        .map((s) => s.data()!)
        .listen(
          onUpdate,
          onError: (err) => debugPrint('CoupleSyncService: Snapshot error on $coupleId: $err'),
        );
  }

  @override
  Future<void> updateCouple(String coupleId, Map<String, dynamic> fields) async {
    if (await _ensureUid() == null) return;
    try {
      await _couple(coupleId).update({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('CoupleSyncService: updateCouple error: $e');
    }
  }

  @override
  Future<void> sendThinkingOfYouPulse(String coupleId, String senderName) async {
    final uid = await _ensureUid();
    if (uid == null) return;
    await updateCouple(coupleId, {
      'lastThinkingOfYou': {
        'senderId': uid,
        'senderName': senderName,
        'timestamp': FieldValue.serverTimestamp(),
        'iso': DateTime.now().toUtc().toIso8601String(),
      },
    });
  }

  @override
  Future<void> leaveCouple(String coupleId) async {
    final uid = await _ensureUid();
    if (uid == null) return;
    try {
      final snapshot = await _couple(coupleId).get();
      final data = snapshot.data();
      if (data == null) return;
      final members = List<String>.from(data['memberIds'] as List? ?? const []);
      final remaining = members.where((m) => m != uid).toList();
      if (remaining.isEmpty) return; // Already alone in this space.

      final partnerId = remaining.first;
      final partnerName = data['user1Id'] == partnerId ? data['user1Name'] : data['user2Name'];
      await _couple(coupleId).update({
        'memberIds': [partnerId],
        'user1Id': partnerId,
        'user1Name': partnerName,
        'user2Id': null,
        'user2Name': null,
        'tokens.$uid': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('CoupleSyncService: leaveCouple error: $e');
    }
  }

  @override
  Future<int> memberCount(String coupleId) async {
    if (await _ensureUid() == null) return 0;
    try {
      final data = (await _couple(coupleId).get()).data();
      return (data?['memberIds'] as List?)?.length ?? 0;
    } catch (e) {
      debugPrint('CoupleSyncService: memberCount error: $e');
      return 0;
    }
  }

  @override
  Future<void> deleteCouple(String coupleId) async {
    if (await _ensureUid() == null) return;
    try {
      await _couple(coupleId).delete();
    } catch (e) {
      debugPrint('CoupleSyncService: deleteCouple error: $e');
    }
  }

  @override
  Future<void> deleteInvite(String inviteCode) async {
    if (await _ensureUid() == null) return;
    try {
      await _db.collection('invites').doc(inviteCode).delete();
    } catch (e) {
      debugPrint('CoupleSyncService: deleteInvite error: $e');
    }
  }

  @override
  Future<void> deleteCurrentUser() async {
    if (!_online) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      // e.g. requires-recent-login for linked accounts: at least sign out.
      debugPrint('CoupleSyncService: deleteCurrentUser error: ${e.code}');
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Future<({String coupleId, Map<String, dynamic> data})?> findMyCouple() async {
    final uid = await _ensureUid();
    if (uid == null) return null;
    try {
      // Allowed by the rules only because it is restricted to own memberships.
      final result = await _db.collection('couples').where('memberIds', arrayContains: uid).get();
      if (result.docs.isEmpty) return null;
      final docs = [...result.docs]
        ..sort((a, b) => ((b.data()['memberIds'] as List?)?.length ?? 0)
            .compareTo((a.data()['memberIds'] as List?)?.length ?? 0));
      return (coupleId: docs.first.id, data: docs.first.data());
    } catch (e) {
      debugPrint('CoupleSyncService: findMyCouple error: $e');
      return null;
    }
  }

  @override
  Future<String?> findMyInviteCode() async {
    final uid = await _ensureUid();
    if (uid == null) return null;
    try {
      final result = await _db.collection('invites').where('ownerId', isEqualTo: uid).limit(1).get();
      return result.docs.isEmpty ? null : result.docs.first.id;
    } catch (e) {
      debugPrint('CoupleSyncService: findMyInviteCode error: $e');
      return null;
    }
  }
}
