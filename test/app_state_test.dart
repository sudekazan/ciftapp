import 'package:ciftapp/core/providers/app_state_provider.dart';
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

  test('unpairCouple clears partner info', () async {
    final state = AppStateProvider();
    await settle();

    await state.pairWithCode('CFT-ABC123', partnerName: 'Ayşe');
    expect(state.currentUser.isPaired, isTrue);
    expect(state.currentUser.partnerName, 'Ayşe');

    await state.unpairCouple();
    expect(state.currentUser.isPaired, isFalse);
    expect(state.currentUser.partnerId, isNull);
    expect(state.currentUser.partnerName, isNull);
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
