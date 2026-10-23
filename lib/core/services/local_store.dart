import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small JSON-list persistence helper on top of SharedPreferences.
///
/// Corrupted entries are skipped instead of crashing the app.
class LocalStore {
  LocalStore._();

  static const String keyPrefix = 'ciftapp_data_';

  static Future<List<T>> loadList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$keyPrefix$key');
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final result = <T>[];
      for (final entry in decoded) {
        try {
          result.add(fromJson(Map<String, dynamic>.from(entry as Map)));
        } catch (e) {
          debugPrint('LocalStore: skipped corrupted item in "$key": $e');
        }
      }
      return result;
    } catch (e) {
      debugPrint('LocalStore: failed to load "$key": $e');
      return [];
    }
  }

  static Future<void> saveList<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T item) toJson,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$keyPrefix$key',
        jsonEncode(items.map(toJson).toList()),
      );
    } catch (e) {
      debugPrint('LocalStore: failed to save "$key": $e');
    }
  }

  /// Removes every persisted data list (used when deleting the account).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((k) => k.startsWith(keyPrefix)).toList()) {
      await prefs.remove(key);
    }
  }
}
