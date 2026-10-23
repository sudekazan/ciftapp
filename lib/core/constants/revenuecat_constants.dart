import 'dart:io';
import 'package:flutter/foundation.dart';

/// Configuration constants for RevenueCat in Yanyana.
///
/// To connect your RevenueCat project:
/// 1. Create a project in https://app.revenuecat.com
/// 2. Add Android app with package name `com.sudekazan.yanyana`
/// 3. Add iOS app with bundle ID `com.sudekazan.yanyana`
/// 4. Paste Public API keys below:
class RevenueCatConstants {
  RevenueCatConstants._();

  /// Public Google API key from RevenueCat
  static const String googleApiKey = 'goog_hKqRbkoTWXstQXNsDWSFRRcoUTU';

  /// Public Apple API key from RevenueCat
  static const String appleApiKey = 'appl_yDRwaLROQVRsbFZFNhqGdaqYobe';

  /// Entitlement ID attached to your monthly & annual products in RevenueCat
  static const String entitlementId = 'premium';

  static String get apiKey {
    if (kIsWeb) return '';
    return Platform.isAndroid ? googleApiKey : appleApiKey;
  }

  static bool get isConfigured =>
      apiKey.isNotEmpty && !apiKey.contains('YOUR_REVENUECAT');
}
