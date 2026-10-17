import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ciftapp/core/providers/app_state_provider.dart';
import 'package:ciftapp/core/providers/chat_provider.dart';
import 'package:ciftapp/core/providers/dreams_provider.dart';
import 'package:ciftapp/core/providers/memories_provider.dart';
import 'package:ciftapp/core/providers/plans_provider.dart';
import 'package:ciftapp/core/providers/together_provider.dart';
import 'package:ciftapp/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('CiftApp smoke test launches successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => DreamsProvider()),
          ChangeNotifierProvider(create: (_) => PlansProvider()),
          ChangeNotifierProvider(create: (_) => TogetherProvider()),
          ChangeNotifierProvider(create: (_) => MemoriesProvider()),
        ],
        child: const CiftApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify app name is rendered
    expect(find.textContaining('ÇiftApp'), findsWidgets);
  });

  testWidgets('InitialSetupScreen follows 3-step sequence: Name -> Start Date -> Pairing Space', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'ciftapp_setup_completed': false});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => DreamsProvider()),
          ChangeNotifierProvider(create: (_) => PlansProvider()),
          ChangeNotifierProvider(create: (_) => TogetherProvider()),
          ChangeNotifierProvider(create: (_) => MemoriesProvider()),
        ],
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

    // Tap "Bir Sonraki Adım: Çift Alanı"
    final nextBtnFinder = find.text('Bir Sonraki Adım: Çift Alanı');
    await tester.ensureVisible(nextBtnFinder);
    await tester.pumpAndSettle();
    await tester.tap(nextBtnFinder);
    await tester.pumpAndSettle();

    // Step 3: Verify Pairing space step is active
    expect(find.text('3. Çift Alanı'), findsOneWidget);
    expect(find.text('Çift Alanınızı Başlatalım ✨'), findsOneWidget);
  });
}
