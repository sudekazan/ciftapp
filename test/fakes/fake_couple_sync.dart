import 'dart:async';

import 'package:ciftapp/core/services/couple_sync_service.dart';

/// In-memory [CoupleSyncService] that mimics the Firestore rules closely
/// enough to test pairing flows without Firebase.
class FakeCoupleSyncService implements CoupleSyncService {
  FakeCoupleSyncService({this.uid = 'me'});

  @override
  String? get currentUid => uid;
  String uid;

  final Map<String, Map<String, dynamic>> couples = {};
  final Map<String, Map<String, dynamic>> invites = {};
  final Map<String, StreamController<Map<String, dynamic>>> _controllers = {};
  int _seq = 0;

  StreamController<Map<String, dynamic>> _controller(String id) =>
      _controllers.putIfAbsent(id, () => StreamController.broadcast());

  void _emit(String coupleId) {
    final data = couples[coupleId];
    if (data != null) _controller(coupleId).add(Map.of(data));
  }

  /// Simulates a remote change made by the partner's device.
  void remoteUpdate(String coupleId, Map<String, dynamic> fields) {
    couples[coupleId]!.addAll(fields);
    _emit(coupleId);
  }

  @override
  Future<String?> createCoupleSpace({
    required String inviteCode,
    required String userName,
    required String mode,
    required DateTime startDate,
    String? fcmToken,
  }) async {
    final id = 'cpl_${++_seq}';
    couples[id] = {
      'user1Id': uid,
      'user1Name': userName,
      'user2Id': null,
      'user2Name': null,
      'memberIds': [uid],
      'mode': mode,
    };
    invites[inviteCode] = {'coupleId': id, 'ownerId': uid, 'ownerName': userName};
    return id;
  }

  @override
  Future<void> ensureInvite({
    required String inviteCode,
    required String coupleId,
    required String ownerName,
  }) async {
    invites[inviteCode] = {'coupleId': coupleId, 'ownerId': uid, 'ownerName': ownerName};
  }

  @override
  Future<PairingResult> pairWithInviteCode({
    required String inviteCode,
    required String myName,
    String? fcmToken,
  }) async {
    final invite = invites[inviteCode];
    if (invite == null) throw const PairingException(PairingError.notFound);
    if (invite['ownerId'] == uid) throw const PairingException(PairingError.ownCode);
    final coupleId = invite['coupleId'] as String;
    final couple = couples[coupleId]!;
    if (couple['user2Id'] != null) throw const PairingException(PairingError.alreadyUsed);
    couple
      ..['user2Id'] = uid
      ..['user2Name'] = myName
      ..['memberIds'] = [couple['user1Id'], uid];
    _emit(coupleId);
    return PairingResult(
      coupleId: coupleId,
      partnerId: invite['ownerId'] as String?,
      partnerName: invite['ownerName'] as String?,
    );
  }

  @override
  StreamSubscription<Map<String, dynamic>>? listenToCouple({
    required String coupleId,
    required void Function(Map<String, dynamic> data) onUpdate,
  }) {
    final sub = _controller(coupleId).stream.listen(onUpdate);
    scheduleMicrotask(() => _emit(coupleId));
    return sub;
  }

  @override
  Future<void> updateCouple(String coupleId, Map<String, dynamic> fields) async {
    couples[coupleId]?.addAll(fields);
    _emit(coupleId);
  }

  final List<String> pulses = [];

  @override
  Future<void> sendThinkingOfYouPulse(String coupleId, String senderName) async {
    pulses.add(coupleId);
  }

  @override
  Future<void> leaveCouple(String coupleId) async {
    final couple = couples[coupleId];
    if (couple == null) return;
    final remaining = List<String>.from(couple['memberIds'] as List).where((m) => m != uid).toList();
    if (remaining.isEmpty) return;
    final partner = remaining.first;
    final partnerName = couple['user1Id'] == partner ? couple['user1Name'] : couple['user2Name'];
    couple
      ..['memberIds'] = [partner]
      ..['user1Id'] = partner
      ..['user1Name'] = partnerName
      ..['user2Id'] = null
      ..['user2Name'] = null;
    _emit(coupleId);
  }
}
