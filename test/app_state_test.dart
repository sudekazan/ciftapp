import 'package:ciftapp/core/models/relationship_mode.dart';
import 'package:ciftapp/core/providers/app_state_provider.dart';
import 'package:ciftapp/core/services/couple_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
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
}
