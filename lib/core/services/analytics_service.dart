import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Product analytics. Event names are what the revenue funnel is built on:
/// setup_completed → pairing_success → paywall_shown(source) → trial_started /
/// purchase, plus limit_reached and daily_question_answered.
class AnalyticsService {
  AnalyticsService._();

  static Future<void> log(String event, [Map<String, Object>? params]) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: event, parameters: params);
    } catch (e) {
      debugPrint('Analytics: $event not logged: $e');
    }
  }

  static Future<void> setUserId(String? uid) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseAnalytics.instance.setUserId(id: uid);
    } catch (_) {}
  }
}
