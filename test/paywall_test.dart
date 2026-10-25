import 'package:ciftapp/core/localization/app_localizations.dart';
import 'package:ciftapp/core/premium/premium_gate.dart';
import 'package:ciftapp/core/providers/app_state_provider.dart';
import 'package:ciftapp/core/services/purchase_service.dart';
import 'package:ciftapp/features/premium/screens/paywall_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_couple_data_store.dart';
import 'fakes/fake_couple_sync.dart';
import 'fakes/fake_purchase_gateway.dart';

void main() {
  Future<void> pumpPaywall(WidgetTester tester, {PaywallSource source = PaywallSource.profile}) async {
    SharedPreferences.setMockInitialValues({});
    final purchases = FakePurchaseGateway(status: PremiumStatus.inactive); // no offerings
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppStateProvider(
          sync: FakeCoupleSyncService(),
          data: FakeCoupleDataStore(FakeCloud()),
          purchases: purchases,
        ),
        child: MaterialApp(
          locale: const Locale('tr'),
          supportedLocales: const [Locale('tr'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: PaywallScreen(source: source, purchases: purchases),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('no hard-coded prices or fake features are shown', (tester) async {
    await pumpPaywall(tester);

    expect(find.textContaining('₺'), findsNothing);
    expect(find.textContaining('PDF'), findsNothing);
    expect(find.textContaining('bütçe', findRichText: true), findsNothing);
    expect(find.textContaining('yüzlerce'), findsNothing);
    expect(find.textContaining('Ücretsiz Dene'), findsNothing, reason: 'trial only for eligible users');
    expect(find.textContaining('Planlar mağazadan yüklenemedi'), findsOneWidget);
    expect(find.text('Tekrar Dene'), findsOneWidget);
  });

  testWidgets('contextual paywall explains the reached limit', (tester) async {
    await pumpPaywall(tester, source: PaywallSource.memoryLimit);
    expect(find.textContaining('20 anı ekleyebilirsin'), findsOneWidget);
  });
}
