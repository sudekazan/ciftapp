import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../constants/revenuecat_constants.dart';

enum PurchaseOutcome {
  success,
  cancelled,

  /// Payment awaits approval (e.g. Android cash / parental approval).
  pending,
}

/// Why a purchase or restore failed; the UI maps it to localized text.
enum PurchaseFailureReason { notConfigured, network, store, notAllowed, productUnavailable, unknown }

class PurchaseFailure implements Exception {
  final PurchaseFailureReason reason;
  const PurchaseFailure(this.reason);

  @override
  String toString() => 'PurchaseFailure($reason)';
}

/// The user's own subscription as reported by the store.
class PremiumStatus {
  final bool isActive;
  final DateTime? expiresAt;
  final bool willRenew;
  final bool isTrial;
  final String? productId;
  final String? managementUrl;

  const PremiumStatus({
    required this.isActive,
    this.expiresAt,
    this.willRenew = false,
    this.isTrial = false,
    this.productId,
    this.managementUrl,
  });

  static const inactive = PremiumStatus(isActive: false);

  factory PremiumStatus.fromCustomerInfo(CustomerInfo info) {
    final entitlement = info.entitlements.all[RevenueCatConstants.entitlementId];
    if (entitlement == null || !entitlement.isActive) {
      return PremiumStatus(isActive: false, managementUrl: info.managementURL);
    }
    return PremiumStatus(
      isActive: true,
      expiresAt: DateTime.tryParse(entitlement.expirationDate ?? ''),
      willRenew: entitlement.willRenew,
      isTrial: entitlement.periodType == PeriodType.trial,
      productId: entitlement.productIdentifier,
      managementUrl: info.managementURL,
    );
  }
}

/// Store purchases, abstracted so app state and paywall logic can be tested.
abstract class PurchaseGateway {
  bool get isConfigured;

  /// Emits whenever the subscription changes (renewal, expiry, refund,
  /// purchase made outside the app...).
  Stream<PremiumStatus> get statusChanges;

  /// Uses the Firebase uid as RevenueCat app user id so the backend webhook can
  /// grant premium to the whole couple.
  Future<void> logIn(String appUserId);

  Future<void> logOut();

  /// Current status, or `null` when it could not be determined (offline, SDK
  /// error). Callers must keep their last known value in that case.
  Future<PremiumStatus?> fetchStatus();

  Future<Offerings?> getOfferings();

  /// Throws [PurchaseFailure] on errors other than cancellation.
  Future<PurchaseOutcome> purchase(Package package);

  /// Returns whether premium is active after restoring. Throws [PurchaseFailure].
  Future<bool> restore();

  /// Length of the free trial this user can still get for [package], in days,
  /// or `null` when no trial applies (already used, or none configured).
  Future<int?> eligibleTrialDays(Package package);
}

class PurchaseService implements PurchaseGateway {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  final _statusController = StreamController<PremiumStatus>.broadcast();

  @override
  bool get isConfigured => RevenueCatConstants.isConfigured;

  @override
  Stream<PremiumStatus> get statusChanges => _statusController.stream;

  /// Initializes RevenueCat SDK.
  /// If keys are not configured yet, it logs a warning without crashing.
  Future<void> init({String? appUserId}) async {
    if (_isInitialized) return;

    if (!isConfigured) {
      debugPrint('PurchaseService: RevenueCat API keys are not configured yet.');
      return;
    }

    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      } else {
        await Purchases.setLogLevel(LogLevel.warn);
      }

      final config = PurchasesConfiguration(RevenueCatConstants.apiKey);
      if (appUserId != null && appUserId.isNotEmpty) {
        config.appUserID = appUserId;
      }
      await Purchases.configure(config);
      Purchases.addCustomerInfoUpdateListener(
        (info) => _statusController.add(PremiumStatus.fromCustomerInfo(info)),
      );
      _isInitialized = true;
      debugPrint('PurchaseService: RevenueCat initialized successfully.');
    } catch (e) {
      debugPrint('PurchaseService: Failed to initialize RevenueCat: $e');
    }
  }

  Future<bool> _ready() async {
    if (!_isInitialized) await init();
    return _isInitialized;
  }

  @override
  Future<void> logIn(String appUserId) async {
    if (!await _ready()) return;
    try {
      final result = await Purchases.logIn(appUserId);
      _statusController.add(PremiumStatus.fromCustomerInfo(result.customerInfo));
    } catch (e) {
      debugPrint('PurchaseService: logIn error: $e');
    }
  }

  @override
  Future<void> logOut() async {
    if (!_isInitialized) return;
    try {
      if (!await Purchases.isAnonymous) await Purchases.logOut();
    } catch (e) {
      debugPrint('PurchaseService: logOut error: $e');
    }
  }

  @override
  Future<PremiumStatus?> fetchStatus() async {
    if (!await _ready()) return null;
    try {
      return PremiumStatus.fromCustomerInfo(await Purchases.getCustomerInfo());
    } catch (e) {
      debugPrint('PurchaseService: fetchStatus error: $e');
      return null;
    }
  }

  @override
  Future<Offerings?> getOfferings() async {
    if (!await _ready()) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('PurchaseService: getOfferings error: $e');
      return null;
    }
  }

  static PurchaseFailureReason _reasonFor(PurchasesErrorCode code) => switch (code) {
        PurchasesErrorCode.networkError => PurchaseFailureReason.network,
        PurchasesErrorCode.storeProblemError => PurchaseFailureReason.store,
        PurchasesErrorCode.purchaseNotAllowedError ||
        PurchasesErrorCode.insufficientPermissionsError =>
          PurchaseFailureReason.notAllowed,
        PurchasesErrorCode.productNotAvailableForPurchaseError ||
        PurchasesErrorCode.purchaseInvalidError =>
          PurchaseFailureReason.productUnavailable,
        _ => PurchaseFailureReason.unknown,
      };

  @override
  Future<PurchaseOutcome> purchase(Package package) async {
    if (!await _ready()) throw const PurchaseFailure(PurchaseFailureReason.notConfigured);
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      final status = PremiumStatus.fromCustomerInfo(result.customerInfo);
      _statusController.add(status);
      return status.isActive ? PurchaseOutcome.success : PurchaseOutcome.pending;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      debugPrint('PurchaseService: purchase error: ${e.message} (code: $code)');
      if (code == PurchasesErrorCode.purchaseCancelledError) return PurchaseOutcome.cancelled;
      if (code == PurchasesErrorCode.paymentPendingError) return PurchaseOutcome.pending;
      throw PurchaseFailure(_reasonFor(code));
    }
  }

  @override
  Future<bool> restore() async {
    if (!await _ready()) throw const PurchaseFailure(PurchaseFailureReason.notConfigured);
    try {
      final status = PremiumStatus.fromCustomerInfo(await Purchases.restorePurchases());
      _statusController.add(status);
      return status.isActive;
    } on PlatformException catch (e) {
      debugPrint('PurchaseService: restore error: ${e.message}');
      throw PurchaseFailure(_reasonFor(PurchasesErrorHelper.getErrorCode(e)));
    }
  }

  static int? _days(PeriodUnit unit, int count) => switch (unit) {
        PeriodUnit.day => count,
        PeriodUnit.week => count * 7,
        PeriodUnit.month => count * 30,
        PeriodUnit.year => count * 365,
        PeriodUnit.unknown => null,
      };

  @override
  Future<int?> eligibleTrialDays(Package package) async {
    final product = package.storeProduct;
    try {
      if (Platform.isAndroid) {
        // Google Play only returns the free phase to users who can still use it.
        final period = product.defaultOption?.freePhase?.billingPeriod;
        return period == null ? null : _days(period.unit, period.value);
      }
      final intro = product.introductoryPrice;
      if (intro == null || intro.price > 0) return null;
      final eligibility = await Purchases.checkTrialOrIntroductoryPriceEligibility([product.identifier]);
      if (eligibility[product.identifier]?.status != IntroEligibilityStatus.introEligibilityStatusEligible) {
        return null;
      }
      return _days(intro.periodUnit, intro.periodNumberOfUnits * intro.cycles);
    } catch (e) {
      debugPrint('PurchaseService: trial eligibility error: $e');
      return null;
    }
  }
}
