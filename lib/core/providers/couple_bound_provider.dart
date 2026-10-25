import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/couple_data_store.dart';
import '../services/synced_list.dart';

/// Connects a provider's [SyncedList]s to the current couple space.
///
/// [bindCouple] is called by a `ChangeNotifierProxyProvider` whenever
/// [AppStateProvider] changes. When the data generation changes (the user left
/// the couple or deleted the account) the local cache is wiped first so the
/// previous couple's content is not copied into the new space.
mixin CoupleBoundProvider on ChangeNotifier {
  CoupleDataStore get dataStore;

  /// Completes once the local cache has been loaded.
  Future<void> get ready;

  Iterable<SyncedList> get syncedLists;

  /// Called after the local cache was wiped because the couple changed.
  Future<void> onCoupleDataReset() async {}

  /// Called after the lists were bound to [coupleId].
  void onCoupleBound(String? coupleId) {}

  bool _bindRequested = false;
  String? _requestedCouple;
  int? _requestedGeneration;
  Future<void> _bindChain = Future.value();

  void bindCouple(String? coupleId, int generation) {
    if (_bindRequested && coupleId == _requestedCouple && generation == _requestedGeneration) {
      return;
    }
    final reset = _bindRequested && generation != _requestedGeneration;
    _bindRequested = true;
    _requestedCouple = coupleId;
    _requestedGeneration = generation;
    _bindChain = _bindChain.then((_) => _bind(coupleId, reset));
  }

  Future<void> _bind(String? coupleId, bool reset) async {
    await ready;
    if (reset) {
      for (final list in syncedLists) {
        list.bind(dataStore, null);
        await list.clearLocal();
      }
      await onCoupleDataReset();
      notifyListeners();
    }
    for (final list in syncedLists) {
      list.bind(dataStore, coupleId);
    }
    onCoupleBound(coupleId);
  }

  /// Waits until pending bind operations have finished (used by tests).
  @visibleForTesting
  Future<void> get bindingSettled => _bindChain;

  void disposeSyncedLists() {
    for (final list in syncedLists) {
      list.dispose();
    }
  }
}
