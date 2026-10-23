import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../constants/revenuecat_constants.dart';

class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes RevenueCat SDK.
  /// If keys are not configured yet, it logs a warning without crashing.
  Future<void> init({String? appUserId}) async {
    if (_isInitialized) return;

    if (!RevenueCatConstants.isConfigured) {
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
      _isInitialized = true;
      debugPrint('PurchaseService: RevenueCat initialized successfully.');
    } catch (e) {
      debugPrint('PurchaseService: Failed to initialize RevenueCat: $e');
    }
  }

  /// Fetches current offerings from RevenueCat.
  Future<Offerings?> getOfferings() async {
    if (!_isInitialized) {
      await init();
      if (!_isInitialized) return null;
    }

    try {
      return await Purchases.getOfferings();
    } on PlatformException catch (e) {
      debugPrint('PurchaseService: getOfferings error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('PurchaseService: unexpected getOfferings error: $e');
      return null;
    }
  }

  /// Purchases a specific package.
  /// Returns `true` if the entitlement is active after purchase.
  Future<bool> purchasePackage(Package package) async {
    if (!_isInitialized) {
      await init();
      if (!_isInitialized) return false;
    }

    try {
      final result = await Purchases.purchasePackage(package);
      return result.customerInfo.entitlements.all[RevenueCatConstants.entitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('PurchaseService: User cancelled purchase.');
        return false;
      }
      debugPrint('PurchaseService: purchasePackage error: ${e.message} (code: $errorCode)');
      rethrow;
    } catch (e) {
      debugPrint('PurchaseService: unexpected purchasePackage error: $e');
      rethrow;
    }
  }

  /// Restores previous purchases.
  /// Returns `true` if the entitlement is active.
  Future<bool> restorePurchases() async {
    if (!_isInitialized) {
      await init();
      if (!_isInitialized) return false;
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[RevenueCatConstants.entitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      debugPrint('PurchaseService: restorePurchases error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('PurchaseService: unexpected restorePurchases error: $e');
      rethrow;
    }
  }

  /// Checks whether the user currently has an active entitlement.
  Future<bool> checkPremiumStatus() async {
    if (!_isInitialized) {
      await init();
      if (!_isInitialized) return false;
    }

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[RevenueCatConstants.entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('PurchaseService: checkPremiumStatus error: $e');
      return false;
    }
  }
}
