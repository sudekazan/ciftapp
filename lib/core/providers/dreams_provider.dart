import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/bucket_list_item.dart';
import '../models/love_note_item.dart';
import '../models/model_json.dart';
import '../services/local_store.dart';

class DreamsProvider extends ChangeNotifier {
  static const _bucketKey = 'bucket_list';
  static const _notesKey = 'love_notes';

  final List<BucketListItem> _bucketList = [];
  final List<LoveNoteItem> _loveNotes = [];
  bool _isLoaded = false;

  List<BucketListItem> get bucketList => List.unmodifiable(_bucketList);
  List<LoveNoteItem> get loveNotes => List.unmodifiable(_loveNotes);
  bool get isLoaded => _isLoaded;

  int get completedCount => _bucketList.where((item) => item.isCompleted).length;
  double get progressPercentage => _bucketList.isEmpty ? 0 : completedCount / _bucketList.length;

  DreamsProvider() {
    _load();
  }

  Future<void> _load() async {
    final bucket = await LocalStore.loadList(_bucketKey, BucketListItemJson.fromJson);
    final notes = await LocalStore.loadList(_notesKey, LoveNoteItemJson.fromJson);
    _bucketList
      ..clear()
      ..addAll(bucket);
    _loveNotes
      ..clear()
      ..addAll(notes);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveBucket() =>
      LocalStore.saveList(_bucketKey, _bucketList, (b) => b.toJson());

  Future<void> _saveNotes() =>
      LocalStore.saveList(_notesKey, _loveNotes, (n) => n.toJson());

  /// Clears all in-memory and persisted data (account deletion).
  Future<void> clearAll() async {
    _bucketList.clear();
    _loveNotes.clear();
    await _saveBucket();
    await _saveNotes();
    notifyListeners();
  }

  void addBucketItem({
    required String title,
    required String category,
    String? targetDate,
    String? note,
  }) {
    _bucketList.insert(
      0,
      BucketListItem(
        id: const Uuid().v4(),
        title: title,
        category: category,
        targetDate: targetDate,
        note: note,
      ),
    );
    notifyListeners();
    _saveBucket();
  }

  void toggleBucketItem(String id) {
    final index = _bucketList.indexWhere((item) => item.id == id);
    if (index != -1) {
      final current = _bucketList[index];
      _bucketList[index] = current.copyWith(
        isCompleted: !current.isCompleted,
        completedDate: !current.isCompleted ? DateTime.now() : null,
      );
      notifyListeners();
      _saveBucket();
    }
  }

  void deleteBucketItem(String id) {
    _bucketList.removeWhere((item) => item.id == id);
    notifyListeners();
    _saveBucket();
  }

  void addLoveNote({
    required String senderName,
    required String title,
    required String content,
    required int colorHex,
    DateTime? unlockDate,
  }) {
    _loveNotes.insert(
      0,
      LoveNoteItem(
        id: const Uuid().v4(),
        senderName: senderName,
        title: title,
        content: content,
        colorHex: colorHex,
        createdAt: DateTime.now(),
        unlockDate: unlockDate,
      ),
    );
    notifyListeners();
    _saveNotes();
  }

  void unlockLoveNote(String id) {
    final index = _loveNotes.indexWhere((item) => item.id == id);
    if (index != -1) {
      _loveNotes[index] = _loveNotes[index].copyWith(isOpened: true);
      notifyListeners();
      _saveNotes();
    }
  }

  void deleteLoveNote(String id) {
    _loveNotes.removeWhere((item) => item.id == id);
    notifyListeners();
    _saveNotes();
  }
}
