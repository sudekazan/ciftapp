import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Free vs premium limits, managed in one place.
///
/// Defaults below are used offline; the values can be changed remotely with
/// Firebase Remote Config (same key names) to test limits without a release.
class Limits {
  Limits._();

  static int freeMemories = 20;
  static int freePhotosPerMemory = 3;
  static int premiumPhotosPerMemory = 20;
  static int freeDailyPulses = 5;
  static int freeCapsulesPerMonth = 1;
  static int freeQuestionArchiveDays = 7;
  static int premiumQuestionArchiveDays = 365;

  static Map<String, Object> get _defaults => {
        'free_memories': freeMemories,
        'free_photos_per_memory': freePhotosPerMemory,
        'premium_photos_per_memory': premiumPhotosPerMemory,
        'free_daily_pulses': freeDailyPulses,
        'free_capsules_per_month': freeCapsulesPerMonth,
        'free_question_archive_days': freeQuestionArchiveDays,
        'premium_question_archive_days': premiumQuestionArchiveDays,
      };

  static Future<void> loadRemote() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 8),
        minimumFetchInterval: kDebugMode ? const Duration(minutes: 5) : const Duration(hours: 6),
      ));
      await rc.setDefaults(_defaults);
      await rc.fetchAndActivate();
      int read(String key, int fallback) {
        final value = rc.getInt(key);
        return value > 0 ? value : fallback;
      }

      freeMemories = read('free_memories', freeMemories);
      freePhotosPerMemory = read('free_photos_per_memory', freePhotosPerMemory);
      premiumPhotosPerMemory = read('premium_photos_per_memory', premiumPhotosPerMemory);
      freeDailyPulses = read('free_daily_pulses', freeDailyPulses);
      freeCapsulesPerMonth = read('free_capsules_per_month', freeCapsulesPerMonth);
      freeQuestionArchiveDays = read('free_question_archive_days', freeQuestionArchiveDays);
      premiumQuestionArchiveDays = read('premium_question_archive_days', premiumQuestionArchiveDays);
    } catch (e) {
      debugPrint('Limits: Remote Config unavailable, using defaults: $e');
    }
  }

  static bool canAddMemory({required int count, required bool premium}) =>
      premium || count < freeMemories;

  static int maxPhotosPerMemory({required bool premium}) =>
      premium ? premiumPhotosPerMemory : freePhotosPerMemory;

  static bool canSendPulse({required int sentToday, required bool premium}) =>
      premium || sentToday < freeDailyPulses;

  static bool canCreateCapsule({required int createdThisMonth, required bool premium}) =>
      premium || createdThisMonth < freeCapsulesPerMonth;

  static int questionArchiveDays({required bool premium}) =>
      premium ? premiumQuestionArchiveDays : freeQuestionArchiveDays;
}
