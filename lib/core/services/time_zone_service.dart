import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// IANA time zone support so the partner's clock stays correct across
/// daylight-saving changes (a fixed UTC offset would drift twice a year).
class TimeZoneService {
  TimeZoneService._();

  static bool _initialized = false;
  static String? _localName;

  /// IANA name of this device's zone, e.g. `Europe/Istanbul`.
  static String? get localName => _localName;

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      _initialized = true;
      _localName = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (e) {
      debugPrint('TimeZoneService: init error: $e');
    }
  }

  /// Current UTC offset of the IANA zone [name], or `null` if unknown.
  static int? offsetMinutesFor(String name, [DateTime? at]) {
    if (!_initialized) return null;
    try {
      final location = tz.getLocation(name);
      return tz.TZDateTime.from(at ?? DateTime.now(), location).timeZoneOffset.inMinutes;
    } catch (_) {
      return null;
    }
  }
}
