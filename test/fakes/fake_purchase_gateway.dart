import 'dart:async';

import 'package:ciftapp/core/services/purchase_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class FakePurchaseGateway implements PurchaseGateway {
  FakePurchaseGateway({this.status});

  /// What [fetchStatus] returns; `null` simulates an SDK/network error.
  PremiumStatus? status;
  final controller = StreamController<PremiumStatus>.broadcast();
  final List<String> logIns = [];
  int logOuts = 0;

  @override
  bool get isConfigured => true;

  @override
  Stream<PremiumStatus> get statusChanges => controller.stream;

  @override
  Future<void> logIn(String appUserId) async => logIns.add(appUserId);

  @override
  Future<void> logOut() async => logOuts++;

  @override
  Future<PremiumStatus?> fetchStatus() async => status;

  @override
  Future<Offerings?> getOfferings() async => null;

  @override
  Future<PurchaseOutcome> purchase(Package package) async => PurchaseOutcome.success;

  @override
  Future<bool> restore() async => status?.isActive ?? false;

  @override
  Future<int?> eligibleTrialDays(Package package) async => null;
}
