import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared content stored under `couples/{coupleId}/{collection}/{docId}`.
abstract class CoupleDataStore {
  /// Every subcollection the app writes; used to wipe a couple space.
  static const collections = [
    'memories',
    'countdowns',
    'events',
    'tasks',
    'shopping',
    'bucket',
    'notes',
    'watchlist',
    'answers',
    'quiz',
    'whoMore',
  ];

  String? get currentUid;

  /// Streams every document of [collection]; each map contains its `id`.
  StreamSubscription<List<Map<String, dynamic>>>? listen(
    String coupleId,
    String collection,
    void Function(List<Map<String, dynamic>> docs) onData,
  );

  /// Replaces a document.
  Future<void> put(String coupleId, String collection, String id, Map<String, dynamic> data);

  /// Merges fields into a document (used for per-partner answers).
  Future<void> merge(String coupleId, String collection, String id, Map<String, dynamic> data);

  Future<void> remove(String coupleId, String collection, String id);

  /// Deletes every document of every known collection (account deletion).
  Future<void> deleteAll(String coupleId);

  /// Removes the [field] (a partner uid) from every document of [collection].
  Future<void> deleteFieldEverywhere(String coupleId, String collection, String field);
}

class FirestoreCoupleDataStore implements CoupleDataStore {
  FirestoreCoupleDataStore._();
  static final FirestoreCoupleDataStore instance = FirestoreCoupleDataStore._();

  bool get _online => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> _col(String coupleId, String collection) =>
      FirebaseFirestore.instance.collection('couples').doc(coupleId).collection(collection);

  @override
  String? get currentUid => _online ? FirebaseAuth.instance.currentUser?.uid : null;

  @override
  StreamSubscription<List<Map<String, dynamic>>>? listen(
    String coupleId,
    String collection,
    void Function(List<Map<String, dynamic>> docs) onData,
  ) {
    if (!_online) return null;
    return _col(coupleId, collection)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList())
        .listen(
          onData,
          onError: (e) => debugPrint('CoupleDataStore: $collection listen error: $e'),
        );
  }

  @override
  Future<void> put(String coupleId, String collection, String id, Map<String, dynamic> data) async {
    if (!_online) return;
    try {
      await _col(coupleId, collection).doc(id).set(data);
    } catch (e) {
      debugPrint('CoupleDataStore: put $collection/$id error: $e');
    }
  }

  @override
  Future<void> merge(String coupleId, String collection, String id, Map<String, dynamic> data) async {
    if (!_online) return;
    try {
      await _col(coupleId, collection).doc(id).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('CoupleDataStore: merge $collection/$id error: $e');
    }
  }

  @override
  Future<void> remove(String coupleId, String collection, String id) async {
    if (!_online) return;
    try {
      await _col(coupleId, collection).doc(id).delete();
    } catch (e) {
      debugPrint('CoupleDataStore: remove $collection/$id error: $e');
    }
  }

  @override
  Future<void> deleteAll(String coupleId) async {
    if (!_online) return;
    for (final collection in CoupleDataStore.collections) {
      final docs = await _col(coupleId, collection).get();
      // Batches are limited to 500 operations.
      for (var i = 0; i < docs.docs.length; i += 400) {
        final batch = FirebaseFirestore.instance.batch();
        for (final d in docs.docs.skip(i).take(400)) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    }
  }

  @override
  Future<void> deleteFieldEverywhere(String coupleId, String collection, String field) async {
    if (!_online) return;
    final docs = await _col(coupleId, collection).get();
    for (var i = 0; i < docs.docs.length; i += 400) {
      final batch = FirebaseFirestore.instance.batch();
      for (final d in docs.docs.skip(i).take(400)) {
        if (d.data().containsKey(field)) batch.update(d.reference, {field: FieldValue.delete()});
      }
      await batch.commit();
    }
  }
}
