import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/premium/screens/paywall_screen.dart';
import '../../features/premium/screens/subscription_screen.dart';
import '../providers/app_state_provider.dart';
import '../services/analytics_service.dart';

/// Where a paywall was opened from; used for the contextual headline and
/// analytics.
enum PaywallSource {
  profile,
  onboarding,
  memoryLimit,
  photoLimit,
  pulseLimit,
  capsuleLimit,
  questionArchive,
  questionPack,
}

/// Central premium checks for feature limits.
class PremiumGate {
  PremiumGate._();

  static bool isPremium(BuildContext context) =>
      Provider.of<AppStateProvider>(context, listen: false).currentUser.isPremium;

  /// Returns `true` when the action may proceed. Otherwise opens the paywall
  /// with a message explaining which limit was reached, and returns whether
  /// the user became premium there.
  static Future<bool> check(
    BuildContext context, {
    required bool allowed,
    required PaywallSource source,
  }) async {
    if (allowed) return true;
    AnalyticsService.log('limit_reached', {'type': source.name});
    await openPaywall(context, source);
    return context.mounted && isPremium(context);
  }

  /// Opens the paywall, or the "My subscription" screen for premium users.
  static Future<void> openPaywall(BuildContext context, PaywallSource source) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => isPremium(context) ? const SubscriptionScreen() : PaywallScreen(source: source),
      ),
    );
  }
}
