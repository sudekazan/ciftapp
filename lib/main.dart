import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_localizations.dart';
import 'core/providers/app_state_provider.dart';
import 'core/providers/chat_provider.dart';
import 'core/providers/memories_provider.dart';
import 'core/providers/plans_provider.dart';
import 'core/providers/together_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/initial_setup_screen.dart';
import 'features/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => PlansProvider()),
        ChangeNotifierProvider(create: (_) => TogetherProvider()),
        ChangeNotifierProvider(create: (_) => MemoriesProvider()),
      ],
      child: const CiftApp(),
    ),
  );
}

class CiftApp extends StatelessWidget {
  const CiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return MaterialApp(
      title: 'ÇiftApp',
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
