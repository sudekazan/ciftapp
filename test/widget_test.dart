import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ciftapp/core/providers/app_state_provider.dart';
import 'package:ciftapp/features/auth/widgets/invite_partner_sheet.dart';
import 'package:ciftapp/features/premium/screens/paywall_screen.dart';
import 'package:ciftapp/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('CiftApp smoke test launches successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: appProviders(),
        child: const CiftApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify app name is rendered
    expect(find.textContaining('Yanyana'), findsWidgets);
  });

  testWidgets('InitialSetupScreen follows 4-step sequence: Name -> Start Date -> Mode -> Pairing Space', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'ciftapp_setup_completed': false});

    await tester.pumpWidget(
      MultiProvider(
        providers: appProviders(),
        child: const CiftApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Step 1: Verify Name input is present
    expect(find.text('1. Adınız'), findsOneWidget);
    expect(find.text('Seni nasıl çağıralım?'), findsOneWidget);

    // Enter name
    await tester.enterText(find.byType(TextField).first, 'Sude');
    await tester.pumpAndSettle();

    // Tap "Bir Sonraki Adım: Başlangıç Tarihimiz"
    await tester.tap(find.text('Bir Sonraki Adım: Başlangıç Tarihimiz'));
    await tester.pumpAndSettle();

    // Step 2: Verify Start Date step is active
    expect(find.text('2. Tarihimiz'), findsOneWidget);
    expect(find.text('Birlikte Olmaya Başladığımız Tarih 💍'), findsOneWidget);
    expect(find.textContaining('Gününüz'), findsWidgets);

    // Tap "Bir Sonraki Adım: İlişki Modumuz"
    final nextBtnStep2 = find.text('Bir Sonraki Adım: İlişki Modumuz');
    await tester.ensureVisible(nextBtnStep2);
    await tester.pumpAndSettle();
    await tester.tap(nextBtnStep2);
    await tester.pumpAndSettle();

    // Step 3: Verify Mode selection step is active
    expect(find.text('3. Modumuz'), findsOneWidget);
    expect(find.text('Nasıl Bir Birlikteliğiniz Var? 🌍'), findsOneWidget);
    expect(find.text('Uzak Mesafe İlişkisi Yaşıyoruz ✈️'), findsOneWidget);
    expect(find.text('Aynı Evde Birlikte Yaşıyoruz 🏡'), findsOneWidget);

    // Tap "Bir Sonraki Adım: Çift Alanı Kurulumu"
    final nextBtnStep3 = find.text('Bir Sonraki Adım: Çift Alanı Kurulumu');
    await tester.ensureVisible(nextBtnStep3);
    await tester.pumpAndSettle();
    await tester.tap(nextBtnStep3);
    await tester.pumpAndSettle();

    // Step 4: Verify Pairing space step is active
    expect(find.text('4. Çift Alanı'), findsOneWidget);
    expect(find.text('Çift Alanınızı Başlatalım ✨'), findsOneWidget);
  });

  // The home screen has live clocks, so pump fixed durations instead of settling.
  Future<void> pumpFor(WidgetTester tester, int ms) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('no paywall is pushed after setup while the user has no partner', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'ciftapp_setup_completed': true, 'ciftapp_user_name': 'Sude'});

    await tester.pumpWidget(MultiProvider(providers: appProviders(), child: const CiftApp()));
    await pumpFor(tester, 4000);

    expect(find.byType(PaywallScreen), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('ciftapp_paired_paywall_shown'), isNull);
  });

  testWidgets('a dismissible paywall is shown once after pairing', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'ciftapp_setup_completed': true,
      'ciftapp_user_name': 'Sude',
      'ciftapp_is_paired': true,
      'ciftapp_partner_name': 'Ali',
    });

    await tester.pumpWidget(MultiProvider(providers: appProviders(), child: const CiftApp()));
    await pumpFor(tester, 4000);

    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(find.text('Bağlandınız! 🎉 Tek üyelik ikinizi birden Premium yapar.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await pumpFor(tester, 1000);
    expect(find.byType(PaywallScreen), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('ciftapp_paired_paywall_shown'), isTrue);
  });

  testWidgets('users who saw the old post-setup paywall are not asked again', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'ciftapp_setup_completed': true,
      'ciftapp_user_name': 'Sude',
      'ciftapp_is_paired': true,
      'ciftapp_onboarding_paywall_shown': true,
    });

    await tester.pumpWidget(MultiProvider(providers: appProviders(), child: const CiftApp()));
    await pumpFor(tester, 4000);

    expect(find.byType(PaywallScreen), findsNothing);
  });

  testWidgets('without a partner the pulse invites instead of spending a free signal', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'ciftapp_setup_completed': true,
      'ciftapp_user_name': 'Sude',
      'ciftapp_mode': 'long_distance',
    });

    await tester.pumpWidget(MultiProvider(providers: appProviders(), child: const CiftApp()));
    await pumpFor(tester, 1000);

    final heart = find.byKey(const Key('pulse_heart'));
    await tester.ensureVisible(heart);
    await tester.tap(heart);
    await pumpFor(tester, 1000);

    expect(find.byType(InvitePartnerSheet), findsOneWidget);
    expect(find.text('Partnerine Gönder'), findsOneWidget);
    final appState = Provider.of<AppStateProvider>(tester.element(find.byType(InvitePartnerSheet)), listen: false);
    expect(appState.pulsesSentToday, 0);
  });
}
