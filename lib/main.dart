import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'core/localization/app_localizations.dart';
import 'core/premium/limits.dart';
import 'core/providers/app_state_provider.dart';
import 'core/providers/couple_bound_provider.dart';
import 'core/providers/dreams_provider.dart';
import 'core/providers/memories_provider.dart';
import 'core/providers/plans_provider.dart';
import 'core/providers/together_provider.dart';
import 'core/services/couple_data_store.dart';
import 'core/services/notification_service.dart';
import 'core/services/purchase_service.dart';
import 'core/services/time_zone_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/initial_setup_screen.dart';
import 'features/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The layout is designed for portrait only.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase SDK
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully.');

    // Ensure anonymous auth for Cloud Storage & Firestore access
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
        debugPrint('Firebase Auth: Signed in anonymously (${FirebaseAuth.instance.currentUser?.uid})');
      }
    } catch (authError) {
      debugPrint('Firebase Auth anonymous sign-in error: $authError');
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  await TimeZoneService.init();
  // Free/premium limits can be tuned remotely; defaults apply until fetched.
  unawaited(Limits.loadRemote());

  // Initialize Notification Service (FCM & Alerts)
  await NotificationService.instance.init();

  // Initialize RevenueCat SDK (non-blocking if not configured). The Firebase uid
  // is the RevenueCat app user id so premium can be shared with the partner.
  await PurchaseService.instance.init(
    appUserId: Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid,
  );

  runApp(
    MultiProvider(
      providers: appProviders(),
      child: const CiftApp(),
    ),
  );
}

/// App-wide providers. Content providers follow the current couple space so
/// both partners see the same memories, plans, dreams and answers.
List<SingleChildWidget> appProviders({
  AppStateProvider Function()? appState,
  CoupleDataStore? store,
}) {
  ChangeNotifierProxyProvider<AppStateProvider, T> bound<T extends CoupleBoundProvider>(
    T Function() create,
  ) {
    return ChangeNotifierProxyProvider<AppStateProvider, T>(
      create: (_) => create(),
      update: (_, app, provider) => provider!..bindCouple(app.coupleId, app.dataGeneration),
    );
  }

  return [
    ChangeNotifierProvider(create: (_) => appState?.call() ?? AppStateProvider()),
    bound(() => DreamsProvider(store: store)),
    bound(() => PlansProvider(store: store)),
    bound(() => TogetherProvider(store: store)),
    bound(() => MemoriesProvider(store: store)),
  ];
}

class CiftApp extends StatelessWidget {
  const CiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return MaterialApp(
      title: 'Yanyana',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.themeMode,
      locale: Locale(appState.currentLanguage),
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Status bar icons follow the resolved theme (light icons on dark theme).
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
          child: child!,
        );
      },
      home: appState.isLoading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : (appState.hasCompletedSetup
              ? const MainNavigationScreen()
              : const InitialSetupScreen()),
    );
  }
}
