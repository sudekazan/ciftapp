import 'package:ciftapp/core/providers/app_state_provider.dart';
import 'package:ciftapp/core/services/purchase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_couple_data_store.dart';
import 'fakes/fake_couple_sync.dart';
import 'fakes/fake_purchase_gateway.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppStateProvider build(FakePurchaseGateway purchases, {FakeCoupleSyncService? sync}) =>
      AppStateProvider(
        sync: sync ?? FakeCoupleSyncService(),
        data: FakeCoupleDataStore(FakeCloud()),
        purchases: purchases,
      );

  test('a store error does not take premium away from a paying user', () async {
    SharedPreferences.setMockInitialValues({'ciftapp_is_premium': true});
    final state = build(FakePurchaseGateway(status: null)); // SDK error
    await settle();

    expect(state.currentUser.isPremium, isTrue);
  });

  test('an expired subscription is reflected', () async {
    SharedPreferences.setMockInitialValues({'ciftapp_is_premium': true});
    final state = build(FakePurchaseGateway(status: PremiumStatus.inactive));
    await settle();

    expect(state.currentUser.isPremium, isFalse);
  });

  test('subscription changes while the app is open are applied', () async {
    SharedPreferences.setMockInitialValues({});
    final purchases = FakePurchaseGateway(status: PremiumStatus.inactive);
    final state = build(purchases);
    await settle();
    expect(state.currentUser.isPremium, isFalse);

    final expiry = DateTime(2030, 1, 1);
    purchases.controller.add(PremiumStatus(isActive: true, expiresAt: expiry, willRenew: true));
    await settle();
    expect(state.currentUser.isPremium, isTrue);
    expect(state.subscription?.expiresAt, expiry);

    purchases.controller.add(PremiumStatus.inactive); // refund / expiry
    await settle();
    expect(state.currentUser.isPremium, isFalse);
  });

  test('RevenueCat uses the Firebase uid and is logged out on account deletion', () async {
    SharedPreferences.setMockInitialValues({});
    final purchases = FakePurchaseGateway(status: PremiumStatus.inactive);
    final sync = FakeCoupleSyncService(uid: 'uid_123');
    final state = build(purchases, sync: sync);
    await settle();
    await state.completeInitialSetup(name: 'Ben', mode: state.currentUser.mode);
    await settle();

    expect(purchases.logIns, ['uid_123']);

    await state.deleteAccount();
    expect(purchases.logOuts, 1);
  });
}
