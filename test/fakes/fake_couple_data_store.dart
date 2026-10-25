import 'dart:async';

import 'package:ciftapp/core/services/couple_data_store.dart';

/// Shared in-memory "Firestore" for couple subcollections.
class FakeCloud {
  /// path "coupleId/collection" -> docId -> data
  final Map<String, Map<String, Map<String, dynamic>>> data = {};
  final Map<String, StreamController<List<Map<String, dynamic>>>> _controllers = {};

  Map<String, Map<String, dynamic>> col(String coupleId, String collection) =>
      data.putIfAbsent('$coupleId/$collection', () => {});

  StreamController<List<Map<String, dynamic>>> _controller(String path) =>
      _controllers.putIfAbsent(path, () => StreamController.broadcast());

  List<Map<String, dynamic>> _snapshot(String coupleId, String collection) => col(coupleId, collection)
      .entries
      .map((e) => {...e.value, 'id': e.key})
      .toList();

  void emit(String coupleId, String collection) {
    _controller('$coupleId/$collection').add(_snapshot(coupleId, collection));
  }
}

/// One device's view of [FakeCloud], signed in as [uid].
class FakeCoupleDataStore implements CoupleDataStore {
  FakeCoupleDataStore(this.cloud, {this.uid = 'me'});

  final FakeCloud cloud;
  final String? uid;

  @override
  String? get currentUid => uid;

  @override
  StreamSubscription<List<Map<String, dynamic>>>? listen(
    String coupleId,
    String collection,
    void Function(List<Map<String, dynamic>> docs) onData,
  ) {
    final sub = cloud._controller('$coupleId/$collection').stream.listen(onData);
    scheduleMicrotask(() => onData(cloud._snapshot(coupleId, collection)));
    return sub;
  }

  @override
  Future<void> put(String coupleId, String collection, String id, Map<String, dynamic> data) async {
    cloud.col(coupleId, collection)[id] = Map.of(data);
    cloud.emit(coupleId, collection);
  }

  @override
  Future<void> merge(String coupleId, String collection, String id, Map<String, dynamic> data) async {
    cloud.col(coupleId, collection).putIfAbsent(id, () => {}).addAll(data);
    cloud.emit(coupleId, collection);
  }

  @override
  Future<void> remove(String coupleId, String collection, String id) async {
    cloud.col(coupleId, collection).remove(id);
    cloud.emit(coupleId, collection);
  }

  @override
  Future<void> deleteAll(String coupleId) async {
    for (final c in CoupleDataStore.collections) {
      cloud.col(coupleId, c).clear();
      cloud.emit(coupleId, c);
    }
  }
}
