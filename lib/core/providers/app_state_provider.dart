import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../constants/revenuecat_constants.dart';
import '../models/relationship_mode.dart';
import '../models/user_model.dart';
import '../services/couple_sync_service.dart';
import '../services/notification_service.dart';
import '../services/purchase_service.dart';

class AppStateProvider extends ChangeNotifier {
  late UserModel _currentUser;
  String _currentLanguage = 'tr';
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = true;
  bool _hasCompletedSetup = false;
  String? _coupleId;
  StreamSubscription? _coupleSubscription;

  UserModel get currentUser => _currentUser;
  String get currentLanguage => _currentLanguage;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get hasCompletedSetup => _hasCompletedSetup;
  String? get coupleId => _coupleId;

  /// Partner's UTC offset in minutes. `null` = same as this device.
  int? _partnerUtcOffsetMinutes;
  int get partnerUtcOffsetMinutes =>
      _partnerUtcOffsetMinutes ?? DateTime.now().timeZoneOffset.inMinutes;
  bool get hasPartnerTimeZone => _partnerUtcOffsetMinutes != null;

  Future<void> setPartnerUtcOffset(int minutes) async {
    _partnerUtcOffsetMinutes = minutes;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ciftapp_partner_utc_offset_min', minutes);
  }

  AppStateProvider() {
    _initDefaultUser();
    _loadFromPreferences();
  }

  /// Generates a random invite code such as `CFT-K7M2QX`.
  /// Ambiguous characters (0/O, 1/I) are excluded.
  static String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    final suffix = List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
    return 'CFT-$suffix';
  }

  static final RegExp _inviteCodePattern = RegExp(r'^CFT-[A-HJ-NP-Z2-9]{6}$');

  /// Returns an error message (TR) or `null` if [raw] is a valid partner code.
  String? validatePartnerCode(String raw) {
    final code = raw.trim().toUpperCase();
    if (code.isEmpty) return 'Lütfen partnerinizin kodunu girin.';
    if (!_inviteCodePattern.hasMatch(code)) {
      return 'Geçersiz kod. Kod CFT-XXXXXX biçiminde olmalı.';
    }
    if (code == _currentUser.inviteCode) {
      return 'Kendi davet kodunu giremezsin. Partnerinin kodunu gir.';
    }
    return null;
  }

  void _initDefaultUser() {
    _currentUser = UserModel(
      id: const Uuid().v4(),
      name: '',
      partnerId: null,
      partnerName: null,
      inviteCode: _generateInviteCode(),
      isPaired: false,
      relationshipStartDate: DateTime.now(),
      mode: RelationshipMode.longDistance,
      isPremium: false,
      myTimeZone: 'Europe/Istanbul',
      partnerTimeZone: 'Europe/London',
      nextReunionDate: null,
      reunionLocation: null,
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
      _partnerUtcOffsetMinutes = prefs.getInt('ciftapp_partner_utc_offset_min');
      _coupleId = prefs.getString('ciftapp_couple_id');

      var inviteCode = prefs.getString('ciftapp_invite_code');
      if (inviteCode == null || inviteCode.isEmpty) {
        inviteCode = _currentUser.inviteCode;
        await prefs.setString('ciftapp_invite_code', inviteCode);
      }

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
        inviteCode: inviteCode,
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

      // Initialize live Firestore sync if setup is finished
      if (_hasCompletedSetup) {
        _coupleId ??= 'cpl_$inviteCode';
        _startCoupleSync();
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();

      if (RevenueCatConstants.isConfigured) {
        PurchaseService.instance.checkPremiumStatus().then((hasPrem) async {
          if (hasPrem != _currentUser.isPremium) {
            _currentUser = _currentUser.copyWith(isPremium: hasPrem);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('ciftapp_is_premium', hasPrem);
            notifyListeners();
          }
        });
      }
    }
  }

  /// Starts real-time Firestore listener for live couple updates
  void _startCoupleSync() {
    if (_coupleId == null) return;
    _coupleSubscription?.cancel();

    _coupleSubscription = FirestoreCoupleSyncService.instance.listenToCouple(
      coupleId: _coupleId!,
      onUpdate: (data) async {
        bool changed = false;
        final user2Name = data['user2Name'] as String?;

        // Partner paired dynamically while app is open
        if (user2Name != null && !_currentUser.isPaired) {
          _currentUser = _currentUser.copyWith(
            isPaired: true,
            partnerName: user2Name,
          );
          changed = true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('ciftapp_is_paired', true);
          await prefs.setString('ciftapp_partner_name', user2Name);
        }

        // Live heartbeat / Thinking of You pulse
        final pulse = data['lastThinkingOfYou'];
        if (pulse is Map<String, dynamic>) {
          final senderName = pulse['senderName'] as String? ?? 'Partner';
          final pulseTimeStr = pulse['iso'] as String?;
          final pulseTime = pulseTimeStr != null ? DateTime.tryParse(pulseTimeStr) : null;

          if (senderName != _currentUser.name && pulseTime != null) {
            if (_currentUser.lastThinkingOfYou == null ||
                pulseTime.isAfter(_currentUser.lastThinkingOfYou!)) {
              receivePartnerThinkingOfYou();
            }
          }
        }

        if (changed) {
          notifyListeners();
        }
      },
    );

    NotificationService.instance.subscribeToCouple(_coupleId!);
  }

  /// Finishes onboarding. When [partnerCode] is given the pairing must succeed:
  /// on failure a [PairingException] is thrown and nothing is persisted, so the
  /// user can fix the code and try again.
  Future<void> completeInitialSetup({
    required String name,
    required RelationshipMode mode,
    String? partnerCode,
    DateTime? startDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isPairingWithCode = partnerCode != null && partnerCode.trim().isNotEmpty;
    String? resolvedPartnerName;

    if (isPairingWithCode) {
      final result = await _pairOrThrow(partnerCode, name);
      _coupleId = result['coupleId'] as String?;
      resolvedPartnerName = result['partnerName'] as String?;
    } else {
      try {
        _coupleId = await FirestoreCoupleSyncService.instance.registerMyCoupleSpace(
          inviteCode: _currentUser.inviteCode,
          userName: name,
          mode: mode.id,
          startDate: startDate ?? _currentUser.relationshipStartDate,
          fcmToken: NotificationService.instance.fcmToken,
        );
      } catch (e) {
        debugPrint('Setup register space error: $e');
        _coupleId = 'cpl_${_currentUser.inviteCode}';
      }
    }

    _currentUser = _currentUser.copyWith(
      name: name,
      mode: mode,
      isPaired: isPairingWithCode,
      partnerName: resolvedPartnerName,
      relationshipStartDate: startDate ?? _currentUser.relationshipStartDate,
    );

    _hasCompletedSetup = true;
    notifyListeners();

    await prefs.setBool('ciftapp_setup_completed', true);
    await prefs.setString('ciftapp_user_name', name);
    await prefs.setString('ciftapp_mode', mode.id);
    if (_coupleId != null) {
      await prefs.setString('ciftapp_couple_id', _coupleId!);
    }
    if (startDate != null) {
      await prefs.setString('ciftapp_start_date', startDate.toIso8601String());
    }
    if (isPairingWithCode) {
      await prefs.setBool('ciftapp_is_paired', true);
      if (resolvedPartnerName != null) {
        await prefs.setString('ciftapp_partner_name', resolvedPartnerName);
      }
    }

    _startCoupleSync();
  }

  /// Pairs via the backend; any failure surfaces as a [PairingException].
  Future<Map<String, dynamic>> _pairOrThrow(String code, String myName) async {
    try {
      return await FirestoreCoupleSyncService.instance.pairWithInviteCode(
        inviteCode: code,
        myName: myName.isEmpty ? 'Ben' : myName,
        fcmToken: NotificationService.instance.fcmToken,
      );
    } on PairingException {
      rethrow;
    } catch (e) {
      debugPrint('Pairing error: $e');
      throw const PairingException(PairingError.unavailable);
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

    if (_coupleId != null) {
      FirestoreCoupleSyncService.instance.sendThinkingOfYouPulse(
        _coupleId!,
        _currentUser.name.isEmpty ? 'Ben' : _currentUser.name,
      );
    }
  }

  void receivePartnerThinkingOfYou() {
    HapticFeedback.mediumImpact();
    _currentUser = _currentUser.copyWith(
      lastThinkingOfYou: DateTime.now(),
      lastThinkingSender: _currentUser.partnerName ?? 'Partner',
    );
    notifyListeners();
  }

  /// Pairs with a partner's invite code. Throws [PairingException] on failure
  /// and leaves the current (unpaired) state untouched.
  Future<void> pairWithCode(String code) async {
    final result = await _pairOrThrow(code, _currentUser.name);
    _coupleId = result['coupleId'] as String?;
    final resolvedPartner = result['partnerName'] as String?;

    _currentUser = _currentUser.copyWith(
      isPaired: true,
      partnerId: result['partnerId'] as String?,
      partnerName: resolvedPartner,
    );
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ciftapp_is_paired', true);
    if (resolvedPartner != null) {
      await prefs.setString('ciftapp_partner_name', resolvedPartner);
    }
    if (_coupleId != null) {
      await prefs.setString('ciftapp_couple_id', _coupleId!);
    }

    _startCoupleSync();
  }

  Future<void> unpairCouple() async {
    _coupleSubscription?.cancel();
    if (_coupleId != null) {
      FirestoreCoupleSyncService.instance.unpair(_coupleId!);
      NotificationService.instance.unsubscribeFromCouple(_coupleId!);
    }

    _currentUser = _currentUser.copyWith(
      isPaired: false,
      clearPartner: true,
    );
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ciftapp_is_paired', false);
    await prefs.remove('ciftapp_partner_name');
    await prefs.remove('ciftapp_couple_id');
  }

  Future<void> upgradeToPremium() async {
    _currentUser = _currentUser.copyWith(isPremium: true);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ciftapp_is_premium', true);
  }

  Future<void> deleteAccount() async {
    _coupleSubscription?.cancel();
    if (_coupleId != null) {
      FirestoreCoupleSyncService.instance.unpair(_coupleId!);
      NotificationService.instance.unsubscribeFromCouple(_coupleId!);
      _coupleId = null;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _hasCompletedSetup = false;
    _partnerUtcOffsetMinutes = null;
    _initDefaultUser();
    notifyListeners();
  }

  @override
  void dispose() {
    _coupleSubscription?.cancel();
    super.dispose();
  }
}
