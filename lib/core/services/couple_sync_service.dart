import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/model_json.dart';
import '../models/plan_item.dart';

/// Why pairing with an invite code failed. The UI maps these to localized text.
enum PairingError { notFound, ownCode, alreadyUsed, unavailable }

class PairingException implements Exception {
  final PairingError error;
  const PairingException(this.error);

  @override
  String toString() => 'PairingException($error)';
}

abstract class ICoupleSyncService {
  Future<void> sendThinkingOfYouPulse(String coupleId, String senderName);
  Future<void> syncTask(String coupleId, TaskItem task);
  Future<void> syncDailyQuestionAnswer(String coupleId, String questionId, String answer, String userId);
}

/// Real-time couple synchronization service using Firebase Cloud Firestore.
/// Synchronizes pairing status, heartbeat pulses, tasks, and daily questions between two phones.
class FirestoreCoupleSyncService implements ICoupleSyncService {
  FirestoreCoupleSyncService._();
  static final FirestoreCoupleSyncService instance = FirestoreCoupleSyncService._();

  Future<String> _ensureUid() async {
    if (Firebase.apps.isEmpty) return 'offline_user';
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      return FirebaseAuth.instance.currentUser?.uid ?? 'anon_user';
    } catch (e) {
      debugPrint('CoupleSyncService: Auth note: $e');
      return 'anon_user';
    }
  }

  /// Registers user's couple space with their inviteCode in Firestore
  Future<String> registerMyCoupleSpace({
    required String inviteCode,
    required String userName,
    required String mode,
    required DateTime startDate,
    String? fcmToken,
  }) async {
    if (Firebase.apps.isEmpty) return 'cpl_$inviteCode';
    try {
      final uid = await _ensureUid();
      final coupleId = 'cpl_$inviteCode';
      final docRef = FirebaseFirestore.instance.collection('couples').doc(coupleId);

      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        await docRef.set({
          'coupleId': coupleId,
          'inviteCode': inviteCode,
          'user1Id': uid,
          'user1Name': userName,
          'user1Token': fcmToken,
          'user2Id': null,
          'user2Name': null,
          'user2Token': null,
          'mode': mode,
          'startDate': startDate.toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final data = snapshot.data();
        final updates = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (data?['user1Id'] == uid) {
          updates['user1Name'] = userName;
          if (fcmToken != null) updates['user1Token'] = fcmToken;
        } else if (data?['user2Id'] == uid) {
          updates['user2Name'] = userName;
          if (fcmToken != null) updates['user2Token'] = fcmToken;
        }
        await docRef.update(updates);
      }
      debugPrint('CoupleSyncService: Registered couple space: $coupleId');
      return coupleId;
    } catch (e) {
      debugPrint('CoupleSyncService: Register error: $e');
      return 'cpl_$inviteCode';
    }
  }

  /// Pairs current user with the partner's inviteCode on Firestore
  Future<Map<String, dynamic>> pairWithInviteCode({
    required String inviteCode,
    required String myName,
    String? fcmToken,
  }) async {
    final cleanCode = inviteCode.trim().toUpperCase();
    // Without a backend there is no way to verify the code: never fake a pairing.
    if (Firebase.apps.isEmpty) throw const PairingException(PairingError.unavailable);

    final uid = await _ensureUid();
    final firestore = FirebaseFirestore.instance;

    // 1. Direct document lookup
    final coupleId = 'cpl_$cleanCode';
    var docRef = firestore.collection('couples').doc(coupleId);
    var snapshot = await docRef.get();

    // 2. Query fallback
    if (!snapshot.exists) {
      final query = await firestore
          .collection('couples')
          .where('inviteCode', isEqualTo: cleanCode)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        snapshot = query.docs.first;
        docRef = snapshot.reference;
      } else {
        throw const PairingException(PairingError.notFound);
      }
    }

    final data = snapshot.data() ?? {};
    final user1Id = data['user1Id'];
    final user2Id = data['user2Id'];
    final user1Name = data['user1Name'] ?? 'Partner';

    if (user1Id == uid) {
      throw const PairingException(PairingError.ownCode);
    }

    if (user2Id != null && user2Id != uid) {
      throw const PairingException(PairingError.alreadyUsed);
    }

    // Link current user as user2
    await docRef.update({
      'user2Id': uid,
      'user2Name': myName,
      if (fcmToken != null) 'user2Token': fcmToken,
      'pairedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('CoupleSyncService: Paired with couple ${docRef.id} (Partner: $user1Name)');

    return {
      'coupleId': docRef.id,
      'partnerId': user1Id,
      'partnerName': user1Name,
      'mode': data['mode'] ?? 'long_distance',
      'startDate': data['startDate'],
    };
  }

  /// Real-time listener for couple updates (heartbeats, pairing, mode changes)
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? listenToCouple({
    required String coupleId,
    required void Function(Map<String, dynamic> data) onUpdate,
    void Function(Object error)? onError,
  }) {
    if (Firebase.apps.isEmpty) return null;
    try {
      return FirebaseFirestore.instance
          .collection('couples')
          .doc(coupleId)
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            onUpdate(snapshot.data()!);
          }
        },
        onError: (err) {
          debugPrint('CoupleSyncService: Snapshot error on $coupleId: $err');
          onError?.call(err);
        },
      );
    } catch (e) {
      debugPrint('CoupleSyncService: Listen error: $e');
      return null;
    }
  }

  /// Sends a "Thinking of You" love heartbeat pulse to partner
  @override
  Future<void> sendThinkingOfYouPulse(String coupleId, String senderName) async {
    if (Firebase.apps.isEmpty) return;
    try {
      final uid = await _ensureUid();
      await FirebaseFirestore.instance.collection('couples').doc(coupleId).update({
        'lastThinkingOfYou': {
          'senderId': uid,
          'senderName': senderName,
          'timestamp': FieldValue.serverTimestamp(),
          'iso': DateTime.now().toIso8601String(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('CoupleSyncService: Pulse sent for $coupleId');
    } catch (e) {
      debugPrint('CoupleSyncService: sendThinkingOfYouPulse error: $e');
    }
  }

  /// Syncs shared task item
  @override
  Future<void> syncTask(String coupleId, TaskItem task) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(coupleId)
          .collection('tasks')
          .doc(task.id)
          .set(task.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CoupleSyncService: syncTask error: $e');
    }
  }

  /// Syncs answer to daily question
  @override
  Future<void> syncDailyQuestionAnswer(
    String coupleId,
    String questionId,
    String answer,
    String userId,
  ) async {
    if (Firebase.apps.isEmpty) return;
    try {
      final uid = await _ensureUid();
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(coupleId)
          .collection('daily_answers')
          .doc(questionId)
          .set({
        uid: answer,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('CoupleSyncService: syncDailyQuestionAnswer error: $e');
    }
  }

  /// Unpairs the couple space
  Future<void> unpair(String coupleId) async {
    if (Firebase.apps.isEmpty) return;
    try {
      final uid = await _ensureUid();
      final docRef = FirebaseFirestore.instance.collection('couples').doc(coupleId);
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data?['user2Id'] == uid) {
          await docRef.update({
            'user2Id': null,
            'user2Name': null,
            'user2Token': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('CoupleSyncService: unpair error: $e');
    }
  }
}

/// Backwards compatibility alias for mock usage
class MockCoupleSyncService extends FirestoreCoupleSyncService {
  MockCoupleSyncService() : super._();
}
