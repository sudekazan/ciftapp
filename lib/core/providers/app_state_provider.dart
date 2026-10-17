import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/relationship_mode.dart';
import '../models/user_model.dart';

class AppStateProvider extends ChangeNotifier {
  late UserModel _currentUser;
  String _currentLanguage = 'tr';
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = true;
  bool _hasCompletedSetup = false;

  UserModel get currentUser => _currentUser;
  String get currentLanguage => _currentLanguage;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get hasCompletedSetup => _hasCompletedSetup;

  AppStateProvider() {
    _initDefaultUser();
    _loadFromPreferences();
  }

  void _initDefaultUser() {
    _currentUser = UserModel(
      id: const Uuid().v4(),
      name: 'Sude',
      partnerId: null,
      partnerName: null,
      inviteCode: 'CFT-7492',
      isPaired: false,
      relationshipStartDate: DateTime.now().subtract(const Duration(days: 342)),
      mode: RelationshipMode.longDistance,
      isPremium: false,
      myTimeZone: 'Europe/Istanbul',
      partnerTimeZone: 'Europe/London',
      nextReunionDate: DateTime.now().add(const Duration(days: 14, hours: 8)),
      reunionLocation: 'Londra & İstanbul Buluşması ✈️',
      lastThinkingOfYou: null,
      lastThinkingSender: null,
    );
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('ciftapp_language') ?? 'tr';
      final isDark = prefs.getBool('ciftapp_dark_mode') ?? false;
      final modeId = prefs.getString('ciftapp_mode') ?? 'long_distance';
      final isPaired = prefs.getBool('ciftapp_is_paired') ?? false;
      final partnerName = prefs.getString('ciftapp_partner_name');
      final userName = prefs.getString('ciftapp_user_name');
      final isPrem = prefs.getBool('ciftapp_is_premium') ?? false;
      _hasCompletedSetup = prefs.getBool('ciftapp_setup_completed') ?? false;

      final startDateStr = prefs.getString('ciftapp_start_date');
      DateTime? startDate;
      if (startDateStr != null) {
        startDate = DateTime.tryParse(startDateStr);
      }

      final reunionDateStr = prefs.getString('ciftapp_reunion_date');
      final reunionLoc = prefs.getString('ciftapp_reunion_loc');
      DateTime? reunionDate;
      if (reunionDateStr != null) {
        reunionDate = DateTime.tryParse(reunionDateStr);
      }

      _currentLanguage = lang;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

      _currentUser = _currentUser.copyWith(
        name: userName ?? _currentUser.name,
        mode: modeId == 'co_living'
            ? RelationshipMode.coLiving
            : RelationshipMode.longDistance,
        isPaired: isPaired,
        partnerName: partnerName,
        isPremium: isPrem,
        relationshipStartDate: startDate ?? _currentUser.relationshipStartDate,
        nextReunionDate: reunionDate ?? _currentUser.nextReunionDate,
        reunionLocation: reunionLoc ?? _currentUser.reunionLocation,
      );
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeInitialSetup({
    required String name,
    required RelationshipMode mode,
    String? partnerCode,
    String? partnerName,
    DateTime? startDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final isPairingWithCode = partnerCode != null && partnerCode.trim().isNotEmpty;

    _currentUser = _currentUser.copyWith(
      name: name,
      mode: mode,
      isPaired: isPairingWithCode,
      partnerId: isPairingWithCode ? 'partner_${partnerCode.toLowerCase().trim()}' : null,
      partnerName: isPairingWithCode ? (partnerName ?? 'Partnerim') : null,
      relationshipStartDate: startDate ?? _currentUser.relationshipStartDate,
    );

    _hasCompletedSetup = true;
    notifyListeners();

    await prefs.setBool('ciftapp_setup_completed', true);
    await prefs.setString('ciftapp_user_name', name);
    await prefs.setString('ciftapp_mode', mode.id);
    if (startDate != null) {
      await prefs.setString('ciftapp_start_date', startDate.toIso8601String());
    }
    if (isPairingWithCode) {
      await prefs.setBool('ciftapp_is_paired', true);
      await prefs.setString('ciftapp_partner_name', partnerName ?? 'Partnerim');
    }
  }

  Future<void> updateRelationshipStartDate(DateTime date) async {
    _currentUser = _currentUser.copyWith(relationshipStartDate: date);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ciftapp_start_date', date.toIso8601String());
  }

  Future<void> updateUserName(String name) async {
    _currentUser = _currentUser.copyWith(name: name);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ciftapp_user_name', name);
  }

  Future<void> updateReunion({required DateTime date, required String location}) async {
    _currentUser = _currentUser.copyWith(
      nextReunionDate: date,
      reunionLocation: location,
    );
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ciftapp_reunion_date', date.toIso8601String());
    await prefs.setString('ciftapp_reunion_loc', location);
  }

  Future<void> setLanguage(String langCode) async {
    _currentLanguage = langCode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ciftapp_language', langCode);
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ciftapp_dark_mode', _themeMode == ThemeMode.dark);
  }

  Future<void> setRelationshipMode(RelationshipMode mode) async {
    _currentUser = _currentUser.copyWith(mode: mode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ciftapp_mode', mode.id);
  }

  Future<void> triggerThinkingOfYou() async {
    HapticFeedback.heavyImpact();

    _currentUser = _currentUser.copyWith(
      lastThinkingOfYou: DateTime.now(),
      lastThinkingSender: _currentUser.name,
    );
    notifyListeners();
  }

  void receivePartnerThinkingOfYou() {
    HapticFeedback.mediumImpact();
    _currentUser = _currentUser.copyWith(
      lastThinkingOfYou: DateTime.now(),
      lastThinkingSender: _currentUser.partnerName ?? 'Partner',
    );
    notifyListeners();
  }

  Future<void> pairWithCode(String code, {String? partnerName}) async {
    _currentUser = _currentUser.copyWith(
      isPaired: true,
      partnerId: 'partner_${code.toLowerCase()}',
      partnerName: partnerName ?? 'Can',
    );
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ciftapp_is_paired', true);
    await prefs.setString('ciftapp_partner_name', partnerName ?? 'Can');
  }

  Future<void> activateDemoPairing() async {
    await pairWithCode('CFT-DEMO', partnerName: 'Can ❤️');
  }

  Future<void> unpairCouple() async {
    _currentUser = _currentUser.copyWith(
      isPaired: false,
      partnerId: null,
      partnerName: null,
    );
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ciftapp_is_paired', false);
    await prefs.remove('ciftapp_partner_name');
  }

  Future<void> upgradeToPremium() async {
    _currentUser = _currentUser.copyWith(isPremium: true);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ciftapp_is_premium', true);
  }

  Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _hasCompletedSetup = false;
    _initDefaultUser();
    notifyListeners();
  }
}
