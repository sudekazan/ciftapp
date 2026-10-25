import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'couple_data_store.dart';
import 'local_store.dart';

/// A list of items shared by both partners.
///
/// Items are cached in [LocalStore] (instant, offline start) and mirrored to
/// `couples/{coupleId}/{collection}`. Once bound to a couple space, remote
/// snapshots are the source of truth. The first time a list meets a couple
/// space, items that only exist locally (added before pairing or before the
/// cloud sync existed) are uploaded so nothing is lost.
class SyncedList<T> {
  SyncedList({
    required this.collection,
    required this.fromJson,
    required this.toJson,
    required this.idOf,
    required this.onChanged,
    this.newestFirst = false,
    String? localKey,
  }) : localKey = localKey ?? collection;

  /// Firestore subcollection name.
  final String collection;

  /// [LocalStore] key of the offline cache.
  final String localKey;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;
  final String Function(T item) idOf;
  final VoidCallback onChanged;
  final bool newestFirst;

  static const orderField = '_order';
  static const authorField = 'authorId';

  final Map<String, Map<String, dynamic>> _docs = {};
  List<T> _items = const [];

  CoupleDataStore? _store;
  String? _coupleId;
  StreamSubscription? _sub;

  List<T> get items => _items;
  String? get coupleId => _coupleId;

  /// Uid of the partner who created [id], when known.
  String? authorOf(String id) => _docs[id]?[authorField] as String?;

  String get _markerKey => 'ciftapp_sync_${collection}_couple';

  Future<void> loadLocal() async {
    final raw = await LocalStore.loadList(localKey, (j) => j);
    final base = DateTime.now().millisecondsSinceEpoch;
    _docs.clear();
    for (var i = 0; i < raw.length; i++) {
      final json = raw[i];
      final id = json['id'];
      if (id is! String) continue;
      // Legacy caches have no order field: keep their stored order.
      json[orderField] ??= newestFirst ? base - i : base - raw.length + i;
      _docs[id] = json;
    }
    _rebuild();
  }

  /// Starts mirroring [coupleId]. Passing the current id again is a no-op.
  void bind(CoupleDataStore store, String? coupleId) {
    if (identical(store, _store) && coupleId == _coupleId) return;
    _sub?.cancel();
    _sub = null;
    _store = store;
    _coupleId = coupleId;
    if (coupleId == null) return;
    _sub = store.listen(coupleId, collection, (docs) => _onRemote(coupleId, docs));
  }

  Future<void> _onRemote(String coupleId, List<Map<String, dynamic>> remote) async {
    if (coupleId != _coupleId) return;
    final docs = {for (final d in remote) d['id'] as String: Map<String, dynamic>.from(d)};

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_markerKey) != coupleId) {
      for (final entry in _docs.entries) {
        if (!docs.containsKey(entry.key)) {
          docs[entry.key] = entry.value;
          unawaited(_store?.put(coupleId, collection, entry.key, entry.value));
        }
      }
      await prefs.setString(_markerKey, coupleId);
    }
    if (coupleId != _coupleId) return;

    _docs
      ..clear()
      ..addAll(docs);
    _rebuild();
    onChanged();
    await _saveLocal();
  }

  void _rebuild() {
    final entries = _docs.values.toList()
      ..sort((a, b) {
        final c = ((a[orderField] as num?) ?? 0).compareTo((b[orderField] as num?) ?? 0);
        return newestFirst ? -c : c;
      });
    final list = <T>[];
    for (final json in entries) {
      try {
        list.add(fromJson(json));
      } catch (e) {
        debugPrint('SyncedList($collection): skipped invalid item: $e');
      }
    }
    _items = List.unmodifiable(list);
  }

  Future<void> _saveLocal() => LocalStore.saveList(localKey, _docs.values.toList(), (j) => j);

  T? byId(String id) {
    for (final item in _items) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  /// Adds or replaces [item] locally and in the couple space.
  void put(T item) {
    final id = idOf(item);
    final previous = _docs[id];
    final json = toJson(item);
    json[orderField] = previous?[orderField] ?? DateTime.now().millisecondsSinceEpoch;
    final author = previous?[authorField] ?? (previous == null ? _store?.currentUid : null);
    if (author != null) json[authorField] = author;

    _docs[id] = json;
    _rebuild();
    onChanged();
    unawaited(_saveLocal());
    final coupleId = _coupleId;
    if (coupleId != null) unawaited(_store?.put(coupleId, collection, id, json));
  }

  void remove(String id) {
    if (_docs.remove(id) == null) return;
    _rebuild();
    onChanged();
    unawaited(_saveLocal());
    final coupleId = _coupleId;
    if (coupleId != null) unawaited(_store?.remove(coupleId, collection, id));
  }

  /// Forgets the local cache (account deletion or leaving a couple).
  Future<void> clearLocal() async {
    _docs.clear();
    _rebuild();
    await _saveLocal();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_markerKey);
  }

  void dispose() {
    _sub?.cancel();
  }
}
