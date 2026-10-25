import 'package:ciftapp/core/premium/limits.dart';
import 'package:ciftapp/core/providers/app_state_provider.dart';
import 'package:ciftapp/core/providers/dreams_provider.dart';
import 'package:ciftapp/core/providers/together_provider.dart';
import 'package:ciftapp/core/services/purchase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_couple_data_store.dart';
import 'fakes/fake_couple_sync.dart';
import 'fakes/fake_purchase_gateway.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('free plan limits, premium is unlimited', () {
    expect(Limits.canAddMemory(count: Limits.freeMemories - 1, premium: false), isTrue);
    expect(Limits.canAddMemory(count: Limits.freeMemories, premium: false), isFalse);
    expect(Limits.canAddMemory(count: 1000, premium: true), isTrue);

    expect(Limits.maxPhotosPerMemory(premium: false), Limits.freePhotosPerMemory);
    expect(Limits.maxPhotosPerMemory(premium: true), Limits.premiumPhotosPerMemory);

    expect(Limits.canSendPulse(sentToday: Limits.freeDailyPulses, premium: false), isFalse);
    expect(Limits.canSendPulse(sentToday: 99, premium: true), isTrue);

    expect(Limits.canCreateCapsule(createdThisMonth: 1, premium: false), isFalse);
    expect(Limits.questionArchiveDays(premium: true), greaterThan(Limits.questionArchiveDays(premium: false)));
  });

  test('daily pulses stop at the free limit and survive a restart', () async {
    AppStateProvider build() => AppStateProvider(
          sync: FakeCoupleSyncService(),
          data: FakeCoupleDataStore(FakeCloud()),
          purchases: FakePurchaseGateway(status: PremiumStatus.inactive),
        );
    final state = build();
    await settle();

    for (var i = 0; i < Limits.freeDailyPulses; i++) {
      expect(await state.triggerThinkingOfYou(), isTrue);
    }
    expect(state.canSendPulse, isFalse);
    expect(await state.triggerThinkingOfYou(), isFalse);

    final restarted = build();
    await settle();
    expect(restarted.pulsesSentToday, Limits.freeDailyPulses);
    expect(restarted.canSendPulse, isFalse);
  });

  test('premium users have no pulse limit', () async {
    final state = AppStateProvider(
      sync: FakeCoupleSyncService(),
      data: FakeCoupleDataStore(FakeCloud()),
      purchases: FakePurchaseGateway(status: const PremiumStatus(isActive: true)),
    );
    await settle();
    for (var i = 0; i < Limits.freeDailyPulses + 3; i++) {
      expect(await state.triggerThinkingOfYou(), isTrue);
    }
  });

  test('only my own time capsules of this month count toward the limit', () async {
    final cloud = FakeCloud();
    final mine = DreamsProvider(store: FakeCoupleDataStore(cloud, uid: 'a'));
    final partner = DreamsProvider(store: FakeCoupleDataStore(cloud, uid: 'b'));
    mine.bindCouple('cpl', 0);
    partner.bindCouple('cpl', 0);
    await settle();

    partner.addLoveNote(
      senderName: 'B',
      title: 't',
      content: 'c',
      colorHex: 0,
      unlockDate: DateTime.now().add(const Duration(days: 9)),
    );
    mine.addLoveNote(senderName: 'A', title: 'plain', content: 'c', colorHex: 0);
    await settle();
    expect(mine.capsulesCreatedThisMonth, 0);

    mine.addLoveNote(
      senderName: 'A',
      title: 't',
      content: 'c',
      colorHex: 0,
      unlockDate: DateTime.now().add(const Duration(days: 9)),
    );
    await settle();
    expect(mine.capsulesCreatedThisMonth, 1);
  });

  test('question archive only contains answered days within the window', () async {
    final provider = TogetherProvider(store: FakeCoupleDataStore(FakeCloud()));
    await settle();
    expect(provider.archive(7), isEmpty);
    provider.submitMyAnswer('bugün'); // today is not part of the archive
    expect(provider.archive(7), isEmpty);
  });
}
