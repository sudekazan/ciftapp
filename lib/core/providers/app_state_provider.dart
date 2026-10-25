import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/relationship_mode.dart';
import '../models/user_model.dart';
import '../services/couple_data_store.dart';
import '../services/couple_sync_service.dart';
import '../services/local_store.dart';
import '../services/notification_service.dart';
import '../services/photo_storage.dart';
import '../services/purchase_service.dart';
import '../services/time_zone_service.dart';

class AppStateProvider extends ChangeNotifier with WidgetsBindingObserver {
  final CoupleSyncService _sync;
  final CoupleDataStore _data;
  final PurchaseGateway _purchases;
  StreamSubscription<PremiumStatus>? _premiumSubscription;
  PremiumStatus? _subscription;
  bool _purchasesLoggedIn = false;
  late UserModel _currentUser;
  String _currentLanguage = 'tr';
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = true;
  bool _hasCompletedSetup = false;
  String? _coupleId;
  StreamSubscription? _coupleSubscription;
  bool _inviteEnsured = false;

  /// 'user1' or 'user2': which name field of the couple document is mine.
  String? _mySeat;

  UserModel get currentUser => _currentUser;
  String get currentLanguage => _currentLanguage;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get hasCompletedSetup => _hasCompletedSetup;
  String? get coupleId => _coupleId;

  /// The user's own store subscription (plan, renewal date, manage link).
  PremiumStatus? get subscription => _subscription;

  /// Incremented when the user leaves a couple or deletes the account, telling
  /// content providers to drop their cache instead of carrying it over.
  int _dataGeneration = 0;
  int get dataGeneration => _dataGeneration;

  // Partner time zone: published automatically by the partner's device as an
  // IANA name (DST-safe). The manual offset is only a fallback for partners on
  // older app versions.
  String? _partnerTimeZoneName;
  int? _partnerPublishedOffset;
  int? _partnerUtcOffsetMinutes;

  /// Partner's current UTC offset in minutes (this device's offset if unknown).
  int get partnerUtcOffsetMinutes {
    final name = _partnerTimeZoneName;
    final fromName = name == null ? null : TimeZoneService.offsetMinutesFor(name);
    return fromName ??
        _partnerPublishedOffset ??
        _partnerUtcOffsetMinutes ??
        DateTime.now().timeZoneOffset.inMinutes;
  }

  bool get hasPartnerTimeZone =>
      _partnerTimeZoneName != null || _partnerPublishedOffset != null || _partnerUtcOffsetMinutes != null;

  /// Whether the partner's zone comes from their device (no manual choice needed).
  bool get isPartnerTimeZoneAutomatic =>
      _partnerTimeZoneName != null || _partnerPublishedOffset != null;

  String? get partnerTimeZoneName => _partnerTimeZoneName;

  Future<void> setPartnerUtcOffset(int minutes) async {
    _partnerUtcOffsetMinutes = minutes;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ciftapp_partner_utc_offset_min', minutes);
  }

  /// Shares this device's time zone with the partner.
  void _publishMyTimeZone() {
    final coupleId = _coupleId;
    final uid = _sync.currentUid;
    if (coupleId == null || uid == null) return;
    unawaited(_sync.updateCouple(coupleId, {
      'tz.$uid': {
        'name': TimeZoneService.localName,
        'offsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
      },
    }));
  }

  /// Pushes shared couple settings to the partner.
  void _pushCoupleFields(Map<String, dynamic> fields) {
    final coupleId = _coupleId;
    if (coupleId != null) unawaited(_sync.updateCouple(coupleId, fields));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The zone may change while travelling; refresh it when the app returns.
    if (state == AppLifecycleState.resumed) _publishMyTimeZone();
  }

  AppStateProvider({CoupleSyncService? sync, CoupleDataStore? data, PurchaseGateway? purchases})
      : _sync = sync ?? FirestoreCoupleSyncService.instance,
        _data = data ?? FirestoreCoupleDataStore.instance,
        _purchases = purchases ?? PurchaseService.instance {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {
      // No binding (plain unit tests): lifecycle refresh is not needed.
    }
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
      _partnerTimeZoneName = prefs.getString('ciftapp_partner_tz_name');
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
        if (_coupleId == null) {
          unawaited(_createOwnSpace());
        } else {
          _startCoupleSync();
        }
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();

      if (_purchases.isConfigured) {
        // Renewals, expiry, refunds and purchases made outside the app.
        _premiumSubscription = _purchases.statusChanges.listen(_applyPremiumStatus);
        // On errors the result is null and the last known value is kept, so a
        // network problem never takes premium away from a paying user.
        _purchases.fetchStatus().then((status) {
          if (status != null) _applyPremiumStatus(status);
        });
      }
    }
  }

  /// Creates a fresh couple space for this user (setup without a code, after
  /// leaving a couple, or when an earlier attempt failed while offline).
  Future<void> _createOwnSpace() async {
    final id = await _sync.createCoupleSpace(
      inviteCode: _currentUser.inviteCode,
      userName: _currentUser.name,
      mode: _currentUser.mode.id,
      startDate: _currentUser.relationshipStartDate,
      fcmToken: NotificationService.instance.fcmToken,
    );
    if (id == null) return;
    _coupleId = id;
    _inviteEnsured = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ciftapp_couple_id', id);
    _startCoupleSync();
  }

  /// Starts real-time Firestore listener for live couple updates
  void _startCoupleSync() {
    if (_coupleId == null) return;
    _coupleSubscription?.cancel();

    _coupleSubscription = _sync.listenToCouple(
      coupleId: _coupleId!,
      onUpdate: _onCoupleUpdate,
    );

    NotificationService.instance.subscribeToCouple(_coupleId!);
    _publishMyTimeZone();

    final uid = _sync.currentUid;
    if (uid != null && !_purchasesLoggedIn && _purchases.isConfigured) {
      _purchasesLoggedIn = true;
      unawaited(_purchases.logIn(uid));
    }
  }

  Future<void> _onCoupleUpdate(Map<String, dynamic> data) async {
    final myUid = _sync.currentUid;
    if (myUid == null) return;
    final members = List<String>.from(data['memberIds'] as List? ?? const []);
    if (!members.contains(myUid)) return;

    _mySeat = data['user1Id'] == myUid ? 'user1' : 'user2';
    final partnerId = members.where((m) => m != myUid).firstOrNull;
    final partnerName = partnerId == null
        ? null
        : (data['user1Id'] == partnerId ? data['user1Name'] : data['user2Name']) as String?;
    final paired = partnerId != null;

    if (paired != _currentUser.isPaired ||
        partnerName != _currentUser.partnerName ||
        partnerId != _currentUser.partnerId) {
      _currentUser = paired
          ? _currentUser.copyWith(isPaired: true, partnerId: partnerId, partnerName: partnerName)
          : _currentUser.copyWith(isPaired: false, clearPartner: true);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ciftapp_is_paired', paired);
      if (partnerName != null) {
        await prefs.setString('ciftapp_partner_name', partnerName);
      } else {
        await prefs.remove('ciftapp_partner_name');
      }
    }

    await _applySharedSettings(data, partnerId);

    // Alone in this space (new user or partner left): keep the invite code
    // pointing here so a partner can join.
    if (!paired && !_inviteEnsured) {
      _inviteEnsured = true;
      unawaited(_sync.ensureInvite(
        inviteCode: _currentUser.inviteCode,
        coupleId: _coupleId!,
        ownerName: _currentUser.name,
      ));
    }

    // Live heartbeat / Thinking of You pulse
    final pulse = data['lastThinkingOfYou'];
    if (pulse is Map) await _handlePulse(Map<String, dynamic>.from(pulse), myUid);
  }

  /// Applies settings the partner may have changed: dates, mode, time zone.
  Future<void> _applySharedSettings(Map<String, dynamic> data, String? partnerId) async {
    final prefs = await SharedPreferences.getInstance();
    var user = _currentUser;

    final startDate = DateTime.tryParse(data['startDate'] as String? ?? '');
    if (startDate != null && startDate != user.relationshipStartDate) {
      user = user.copyWith(relationshipStartDate: startDate);
      await prefs.setString('ciftapp_start_date', startDate.toIso8601String());
    }

    final reunionDate = DateTime.tryParse(data['reunionDate'] as String? ?? '');
    final reunionLocation = data['reunionLocation'] as String?;
    if (reunionDate != null &&
        (reunionDate != user.nextReunionDate || reunionLocation != user.reunionLocation)) {
      user = user.copyWith(nextReunionDate: reunionDate, reunionLocation: reunionLocation);
      await prefs.setString('ciftapp_reunion_date', reunionDate.toIso8601String());
      await prefs.setString('ciftapp_reunion_loc', reunionLocation ?? '');
    }

    final modeId = data['mode'] as String?;
    if (modeId != null && modeId != user.mode.id) {
      user = user.copyWith(
        mode: modeId == RelationshipMode.coLiving.id
            ? RelationshipMode.coLiving
            : RelationshipMode.longDistance,
      );
      await prefs.setString('ciftapp_mode', modeId);
    }

    var tzChanged = false;
    final zones = data['tz'];
    final partnerZone = partnerId != null && zones is Map ? zones[partnerId] : null;
    if (partnerZone is Map) {
      final name = partnerZone['name'] as String?;
      final offset = (partnerZone['offsetMinutes'] as num?)?.toInt();
      if (name != _partnerTimeZoneName || offset != _partnerPublishedOffset) {
        _partnerTimeZoneName = name;
        _partnerPublishedOffset = offset;
        tzChanged = true;
        if (name != null) await prefs.setString('ciftapp_partner_tz_name', name);
      }
    }

    if (!identical(user, _currentUser) || tzChanged) {
      _currentUser = user;
      notifyListeners();
    }
  }

  static const _lastPulseSeenKey = 'ciftapp_last_pulse_seen';

  /// Shows a partner pulse once. The last seen pulse time is persisted so the
  /// first snapshot after a restart does not replay an old pulse.
  Future<void> _handlePulse(Map<String, dynamic> pulse, String myUid) async {
    final senderId = pulse['senderId'] as String?;
    final pulseTime = DateTime.tryParse(pulse['iso'] as String? ?? '');
    if (senderId == null || senderId == myUid || pulseTime == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lastSeen = DateTime.tryParse(prefs.getString(_lastPulseSeenKey) ?? '');
    if (lastSeen != null && !pulseTime.isAfter(lastSeen)) return;
    await prefs.setString(_lastPulseSeenKey, pulseTime.toIso8601String());

    // Fresh install / first sync: only surface pulses that are still recent.
    if (lastSeen == null && DateTime.now().difference(pulseTime) > const Duration(minutes: 5)) {
      return;
    }
    receivePartnerThinkingOfYou(at: pulseTime.toLocal());
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
      _coupleId = result.coupleId;
      resolvedPartnerName = result.partnerName;
    } else {
      // Offline: stays null and is retried on the next launch.
      _coupleId = await _sync.createCoupleSpace(
        inviteCode: _currentUser.inviteCode,
        userName: name,
        mode: mode.id,
        startDate: startDate ?? _currentUser.relationshipStartDate,
        fcmToken: NotificationService.instance.fcmToken,
      );
      _inviteEnsured = _coupleId != null;
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
  Future<PairingResult> _pairOrThrow(String code, String myName) async {
    try {
      return await _sync.pairWithInviteCode(
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
    _pushCoupleFields({'startDate': date.toIso8601String()});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ciftapp_start_date', date.toIso8601String());
  }

  Future<void> updateUserName(String name) async {
    _currentUser = _currentUser.copyWith(name: name);
    notifyListeners();
    if (_mySeat != null) _pushCoupleFields({'${_mySeat}Name': name});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ciftapp_user_name', name);
  }

  Future<void> updateReunion({required DateTime date, required String location}) async {
    _currentUser = _currentUser.copyWith(
      nextReunionDate: date,
      reunionLocation: location,
    );
    notifyListeners();
    _pushCoupleFields({'reunionDate': date.toIso8601String(), 'reunionLocation': location});
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
    _pushCoupleFields({'mode': mode.id});
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
      _sync.sendThinkingOfYouPulse(
        _coupleId!,
        _currentUser.name.isEmpty ? 'Ben' : _currentUser.name,
      );
    }
  }

  void receivePartnerThinkingOfYou({DateTime? at}) {
    HapticFeedback.mediumImpact();
    _currentUser = _currentUser.copyWith(
      lastThinkingOfYou: at ?? DateTime.now(),
      lastThinkingSender: _currentUser.partnerName ?? 'Partner',
    );
    notifyListeners();
  }

  /// Pairs with a partner's invite code. Throws [PairingException] on failure
  /// and leaves the current (unpaired) state untouched.
  Future<void> pairWithCode(String code) async {
    final result = await _pairOrThrow(code, _currentUser.name);
    _coupleSubscription?.cancel();
    if (_coupleId != null && _coupleId != result.coupleId) {
      NotificationService.instance.unsubscribeFromCouple(_coupleId!);
      // Content moves to the partner's space; the old solo space is purged
      // with the account later (its photo URLs are still referenced).
      await _rememberPreviousCouple(_coupleId!);
    }
    _coupleId = result.coupleId;
    final resolvedPartner = result.partnerName;

    _currentUser = _currentUser.copyWith(
      isPaired: true,
      partnerId: result.partnerId,
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

  /// Leaves the current couple. The partner keeps the shared space; this user
  /// starts over in a fresh, empty space with their own invite code.
  Future<void> unpairCouple() async {
    _coupleSubscription?.cancel();
    final oldCoupleId = _coupleId;
    if (oldCoupleId != null) {
      NotificationService.instance.unsubscribeFromCouple(oldCoupleId);
      await _sync.leaveCouple(oldCoupleId);
    }
    _coupleId = null;
    _inviteEnsured = false;
    _dataGeneration++;
    _partnerTimeZoneName = null;
    _partnerPublishedOffset = null;

    _currentUser = _currentUser.copyWith(
      isPaired: false,
      clearPartner: true,
    );
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ciftapp_is_paired', false);
    await prefs.remove('ciftapp_partner_name');
    await prefs.remove('ciftapp_couple_id');
    await prefs.remove('ciftapp_partner_tz_name');

    await _createOwnSpace();
  }

  static const _previousCouplesKey = 'ciftapp_previous_couples';

  Future<void> _rememberPreviousCouple(String coupleId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_previousCouplesKey) ?? [];
    if (!list.contains(coupleId)) {
      await prefs.setStringList(_previousCouplesKey, [...list, coupleId]);
    }
  }

  /// Deletes a couple space this user is the last member of.
  Future<void> _purgeCoupleSpace(String coupleId) async {
    try {
      await _data.deleteAll(coupleId);
      await PhotoStorage.deleteCoupleFolder(coupleId);
      await _sync.deleteCouple(coupleId);
    } catch (e) {
      debugPrint('Purge couple space $coupleId error: $e');
    }
  }

  Future<void> _applyPremiumStatus(PremiumStatus status) async {
    _subscription = status;
    final changed = status.isActive != _currentUser.isPremium;
    if (changed) _currentUser = _currentUser.copyWith(isPremium: status.isActive);
    notifyListeners();
    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ciftapp_is_premium', status.isActive);
    }
  }

  /// Called right after a successful purchase or restore.
  Future<void> upgradeToPremium() async {
    _currentUser = _currentUser.copyWith(isPremium: true);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ciftapp_is_premium', true);
  }

  /// Deletes the account and its cloud data (Apple 5.1.1(v), KVKK).
  ///
  /// - With a partner: this user leaves the couple and their answers are
  ///   removed; the partner keeps the shared memories.
  /// - Alone: the whole couple space (content, photos, document) is deleted.
  /// Finally the invite code, the Firebase Auth user and local data go.
  Future<void> deleteAccount() async {
    _coupleSubscription?.cancel();
    final prefs = await SharedPreferences.getInstance();
    final myUid = _sync.currentUid;
    final coupleId = _coupleId;

    if (coupleId != null) {
      NotificationService.instance.unsubscribeFromCouple(coupleId);
      if (await _sync.memberCount(coupleId) > 1) {
        if (myUid != null) {
          for (final collection in const ['answers', 'quiz', 'whoMore']) {
            try {
              await _data.deleteFieldEverywhere(coupleId, collection, myUid);
            } catch (e) {
              debugPrint('Delete answers error: $e');
            }
          }
        }
        await _sync.leaveCouple(coupleId);
      } else {
        await _purgeCoupleSpace(coupleId);
      }
    }
    for (final previous in prefs.getStringList(_previousCouplesKey) ?? const <String>[]) {
      if (previous != coupleId) await _purgeCoupleSpace(previous);
    }
    await _sync.deleteInvite(_currentUser.inviteCode);
    await _purchases.logOut();
    _purchasesLoggedIn = false;
    _subscription = null;
    await _sync.deleteCurrentUser();

    _coupleId = null;
    await LocalStore.clearAll();
    await prefs.clear();
    _dataGeneration++;
    _hasCompletedSetup = false;
    _inviteEnsured = false;
    _partnerUtcOffsetMinutes = null;
    _partnerTimeZoneName = null;
    _partnerPublishedOffset = null;
    _mySeat = null;
    _initDefaultUser();
    notifyListeners();
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _coupleSubscription?.cancel();
    _premiumSubscription?.cancel();
    super.dispose();
  }
}
