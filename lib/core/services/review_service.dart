import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks for a store rating once, at a happy moment (after the 3rd memory).
/// The OS decides whether the prompt is actually shown.
class ReviewService {
  ReviewService._();

  static const memoriesBeforeReview = 3;
  static const _askedKey = 'ciftapp_review_requested';

  static Future<void> maybeRequestAfterMemory(int memoryCount) async {
    if (memoryCount < memoriesBeforeReview) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_askedKey) ?? false) return;
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      await prefs.setBool(_askedKey, true);
      await review.requestReview();
    } catch (e) {
      debugPrint('ReviewService: $e');
    }
  }
}
