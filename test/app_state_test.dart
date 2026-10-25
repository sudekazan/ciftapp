import 'package:ciftapp/core/models/relationship_mode.dart';
import 'package:ciftapp/core/providers/app_state_provider.dart';
import 'package:ciftapp/core/services/couple_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_couple_sync.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('invite code is unique per user and persisted', () async {
    final a = AppStateProvider();
    await settle();
    final code = a.currentUser.inviteCode;

    expect(code, matches(RegExp(r'^CFT-[A-HJ-NP-Z2-9]{6}$')));
    expect(code, isNot('CFT-7492'));

    final b = AppStateProvider();
    await settle();
    expect(b.currentUser.inviteCode, code, reason: 'code must survive restart');
  });

  test('failed pairing never marks the user as paired', () async {
    final state = AppStateProvider();
    await settle();

    // No backend in tests: the code cannot be verified.
    await expectLater(
      state.pairWithCode('CFT-ABC123'),
      throwsA(isA<PairingException>()),
    );
    expect(state.currentUser.isPaired, isFalse);
    expect(state.currentUser.partnerName, isNull);
  });

  test('failed pairing during setup does not complete setup', () async {
    final state = AppStateProvider();
    await settle();

    await expectLater(
      state.completeInitialSetup(
        name: 'Sude',
        mode: RelationshipMode.longDistance,
        partnerCode: 'CFT-ABC123',
      ),
      throwsA(isA<PairingException>()),
    );
    expect(state.hasCompletedSetup, isFalse);
    expect(state.currentUser.isPaired, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('ciftapp_setup_completed'), isNot(true));
    expect(prefs.getBool('ciftapp_is_paired'), isNot(true));
  });

  test('default user has no sample data', () async {
    final state = AppStateProvider();
    await settle();

    expect(state.currentUser.name, isEmpty);
    expect(state.currentUser.nextReunionDate, isNull);
    expect(state.currentUser.reunionLocation, isNull);
    expect(state.currentUser.isPaired, isFalse);
  });

  group('with a couple backend', () {
    late FakeCoupleSyncService backend;

    setUp(() {
      backend = FakeCoupleSyncService(uid: 'partner');
      // The partner already created a space with this invite code.
      backend.couples['cpl_p'] = {
        'user1Id': 'partner',
        'user1Name': 'Ayşe',
        'user2Id': null,
        'user2Name': null,
        'memberIds': ['partner'],
      };
      backend.invites['CFT-ABCDEF'] = {
        'coupleId': 'cpl_p',
        'ownerId': 'partner',
        'ownerName': 'Ayşe',
      };
      backend.uid = 'me';
    });

    test('pairing with a valid code pairs both sides', () async {
      final state = AppStateProvider(sync: backend);
      await settle();

      await state.pairWithCode('CFT-ABCDEF');
      await settle();

      expect(state.currentUser.isPaired, isTrue);
      expect(state.currentUser.partnerName, 'Ayşe');
      expect(state.coupleId, 'cpl_p');
      expect(backend.couples['cpl_p']!['memberIds'], ['partner', 'me']);
    });

    test('an invite code cannot be used twice', () async {
      final state = AppStateProvider(sync: backend);
      await settle();
      await state.pairWithCode('CFT-ABCDEF');

      backend.uid = 'stranger';
      SharedPreferences.setMockInitialValues({}); // a different phone
      final other = AppStateProvider(sync: backend);
      await settle();
      await expectLater(
        other.pairWithCode('CFT-ABCDEF'),
        throwsA(isA<PairingException>().having((e) => e.error, 'error', PairingError.alreadyUsed)),
      );
      expect(other.currentUser.isPaired, isFalse);
    });

    test('unpairCouple leaves the space and starts a fresh one', () async {
      final state = AppStateProvider(sync: backend);
      await settle();
      await state.pairWithCode('CFT-ABCDEF');
      await settle();

      await state.unpairCouple();
      await settle();

      expect(state.currentUser.isPaired, isFalse);
      expect(state.currentUser.partnerId, isNull);
      expect(state.currentUser.partnerName, isNull);
      expect(backend.couples['cpl_p']!['memberIds'], ['partner']);
      expect(state.coupleId, isNot('cpl_p'));
      expect(backend.invites[state.currentUser.inviteCode]!['coupleId'], state.coupleId);
    });

    test('partner leaving is reflected live', () async {
      final state = AppStateProvider(sync: backend);
      await settle();
      await state.pairWithCode('CFT-ABCDEF');
      await settle();

      backend.remoteUpdate('cpl_p', {
        'memberIds': ['me'],
        'user1Id': 'me',
        'user1Name': 'Ben',
        'user2Id': null,
        'user2Name': null,
      });
      await settle();

      expect(state.currentUser.isPaired, isFalse);
      // Invite code now points at the remaining space so a new partner can join.
      expect(backend.invites[state.currentUser.inviteCode]!['coupleId'], 'cpl_p');
    });
  
    Map<String, dynamic> pulse(String sender, DateTime at) => {
          'lastThinkingOfYou': {
            'senderId': sender,
            'senderName': 'Ben', // same name as the user on purpose
            'iso': at.toUtc().toIso8601String(),
          },
        };

    test('partner pulse is shown once and not replayed after restart', () async {
      final state = AppStateProvider(sync: backend);
      await settle();
      await state.updateUserName('Ben');
      await state.pairWithCode('CFT-ABCDEF');
      await settle();

      final sentAt = DateTime.now();
      backend.remoteUpdate('cpl_p', pulse('partner', sentAt));
      await settle();
      expect(state.currentUser.lastThinkingSender, 'Ayşe',
          reason: 'sender is identified by uid, not by name');

      // App restart: the same pulse arrives in the first snapshot again.
      final restarted = AppStateProvider(sync: backend);
      await settle();
      await settle();
      expect(restarted.currentUser.lastThinkingOfYou, isNull);
    });

    test('own pulse is not treated as a partner pulse', () async {
      final state = AppStateProvider(sync: backend);
      await settle();
      await state.pairWithCode('CFT-ABCDEF');
      await settle();

      backend.remoteUpdate('cpl_p', pulse('me', DateTime.now()));
      await settle();
      expect(state.currentUser.lastThinkingOfYou, isNull);
    });
  });
}
