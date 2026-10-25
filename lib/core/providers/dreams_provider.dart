import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/bucket_list_item.dart';
import '../models/love_note_item.dart';
import '../models/model_json.dart';
import '../services/couple_data_store.dart';
import '../services/synced_list.dart';
import 'couple_bound_provider.dart';

class DreamsProvider extends ChangeNotifier with CoupleBoundProvider {
  DreamsProvider({CoupleDataStore? store})
      : dataStore = store ?? FirestoreCoupleDataStore.instance {
    _bucket = SyncedList(
      collection: 'bucket',
      localKey: 'bucket_list',
      fromJson: BucketListItemJson.fromJson,
      toJson: (b) => b.toJson(),
      idOf: (b) => b.id,
      onChanged: notifyListeners,
      newestFirst: true,
    );
    _notes = SyncedList(
      collection: 'notes',
      localKey: 'love_notes',
      fromJson: LoveNoteItemJson.fromJson,
      toJson: (n) => n.toJson(),
      idOf: (n) => n.id,
      onChanged: notifyListeners,
      newestFirst: true,
    );
    ready = _load();
  }

  @override
  final CoupleDataStore dataStore;
  @override
  late final Future<void> ready;

  late final SyncedList<BucketListItem> _bucket;
  late final SyncedList<LoveNoteItem> _notes;
  bool _isLoaded = false;

  @override
  Iterable<SyncedList> get syncedLists => [_bucket, _notes];

  List<BucketListItem> get bucketList => _bucket.items;
  List<LoveNoteItem> get loveNotes => _notes.items;
  bool get isLoaded => _isLoaded;

  int get completedCount => bucketList.where((item) => item.isCompleted).length;
  double get progressPercentage => bucketList.isEmpty ? 0 : completedCount / bucketList.length;

  /// Whether the current user wrote note [id] (unknown authors count as mine).
  bool isMyNote(String id) {
    final author = _notes.authorOf(id);
    return author == null || author == dataStore.currentUid;
  }

  /// Time capsules this user created in the current month (free plan limit).
  int get capsulesCreatedThisMonth {
    final now = DateTime.now();
    return loveNotes
        .where((n) =>
            n.isTimeCapsule &&
            isMyNote(n.id) &&
            n.createdAt.year == now.year &&
            n.createdAt.month == now.month)
        .length;
  }

  Future<void> _load() async {
    for (final list in syncedLists) {
      await list.loadLocal();
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Clears all in-memory and persisted data (account deletion).
  Future<void> clearAll() async {
    for (final list in syncedLists) {
      await list.clearLocal();
    }
    notifyListeners();
  }

  void addBucketItem({
    required String title,
    required String category,
    String? targetDate,
    String? note,
  }) {
    _bucket.put(BucketListItem(
      id: const Uuid().v4(),
      title: title,
      category: category,
      targetDate: targetDate,
      note: note,
    ));
  }

  void toggleBucketItem(String id) {
    final current = _bucket.byId(id);
    if (current == null) return;
    // copyWith cannot clear completedDate, so rebuild the item.
    _bucket.put(BucketListItem(
      id: current.id,
      title: current.title,
      category: current.category,
      isCompleted: !current.isCompleted,
      completedDate: !current.isCompleted ? DateTime.now() : null,
      note: current.note,
      targetDate: current.targetDate,
    ));
  }

  void deleteBucketItem(String id) => _bucket.remove(id);

  void addLoveNote({
    required String senderName,
    required String title,
    required String content,
    required int colorHex,
    DateTime? unlockDate,
  }) {
    _notes.put(LoveNoteItem(
      id: const Uuid().v4(),
      senderName: senderName,
      title: title,
      content: content,
      colorHex: colorHex,
      createdAt: DateTime.now(),
      unlockDate: unlockDate,
    ));
  }

  void unlockLoveNote(String id) {
    final note = _notes.byId(id);
    if (note != null) _notes.put(note.copyWith(isOpened: true));
  }

  void deleteLoveNote(String id) => _notes.remove(id);

  @override
  void dispose() {
    disposeSyncedLists();
    super.dispose();
  }
}
