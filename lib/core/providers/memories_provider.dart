import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/memory_item.dart';
import '../models/model_json.dart';
import '../services/couple_data_store.dart';
import '../services/photo_storage.dart';
import '../services/synced_list.dart';
import 'couple_bound_provider.dart';

class MemoriesProvider extends ChangeNotifier with CoupleBoundProvider {
  MemoriesProvider({CoupleDataStore? store})
      : dataStore = store ?? FirestoreCoupleDataStore.instance {
    _memories = SyncedList(
      collection: 'memories',
      fromJson: MemoryItemJson.fromJson,
      toJson: (m) => m.toJson(),
      idOf: (m) => m.id,
      onChanged: _rebuildResolved,
      newestFirst: true,
    );
    _countdowns = SyncedList(
      collection: 'countdowns',
      fromJson: CountdownEventJson.fromJson,
      toJson: (c) => c.toJson(),
      idOf: (c) => c.id,
      onChanged: notifyListeners,
    );
    ready = _load();
  }

  @override
  final CoupleDataStore dataStore;
  @override
  late final Future<void> ready;

  late final SyncedList<MemoryItem> _memories;
  late final SyncedList<CountdownEvent> _countdowns;
  List<MemoryItem> _resolvedMemories = const [];
  bool _isLoaded = false;

  @override
  Iterable<SyncedList> get syncedLists => [_memories, _countdowns];

  List<MemoryItem> get memories => _resolvedMemories;
  List<CountdownEvent> get countdowns => _countdowns.items;
  bool get isLoaded => _isLoaded;

  /// Couple space new photos should be uploaded to.
  String? get coupleId => _memories.coupleId;

  Future<void> _load() async {
    await PhotoStorage.initLocalDir();
    for (final list in syncedLists) {
      await list.loadLocal();
    }
    _isLoaded = true;
    _rebuildResolved();
  }

  /// Local photo paths are re-mapped to the current app container
  /// (it can change between iOS app updates).
  void _rebuildResolved() {
    _resolvedMemories = List.unmodifiable(_memories.items.map(
      (m) => m.copyWith(imageUrls: m.imageUrls.map(PhotoStorage.resolveSync).toList()),
    ));
    notifyListeners();
  }

  @override
  void onCoupleBound(String? coupleId) {
    if (coupleId != null) _syncLocalPhotosToCloud(coupleId);
  }

  /// Uploads photos that only exist on this device so the partner can see them.
  Future<void> _syncLocalPhotosToCloud(String coupleId) async {
    if (Firebase.apps.isEmpty) return;
    try {
      for (final memory in _memories.items) {
        if (memory.imageUrls.every((u) => u.startsWith('http'))) continue;
        final updatedUrls = <String>[];
        var changed = false;
        for (final url in memory.imageUrls) {
          if (!url.startsWith('http')) {
            final file = File(PhotoStorage.resolveSync(url));
            if (await file.exists()) {
              final cloudUrl = await PhotoStorage.uploadToCloud(file, coupleId);
              if (cloudUrl != null) {
                updatedUrls.add(cloudUrl);
                changed = true;
                continue;
              }
            }
          }
          updatedUrls.add(url);
        }
        if (changed && _memories.coupleId == coupleId) {
          final latest = _memories.byId(memory.id);
          if (latest != null) _memories.put(latest.copyWith(imageUrls: updatedUrls));
        }
      }
    } catch (e) {
      debugPrint('MemoriesProvider: Cloud photo sync error: $e');
    }
  }

  /// Clears all in-memory and persisted data (account deletion).
  Future<void> clearAll() async {
    await PhotoStorage.delete(_memories.items.expand((m) => m.imageUrls));
    for (final list in syncedLists) {
      await list.clearLocal();
    }
    _rebuildResolved();
  }

  void addMemory({
    required String title,
    required String note,
    required DateTime date,
    String? location,
    String? mood,
    List<String> imageUrls = const [],
    List<String> tags = const [],
  }) {
    _memories.put(MemoryItem(
      id: const Uuid().v4(),
      title: title,
      note: note,
      date: date,
      location: location,
      mood: mood,
      imageUrls: imageUrls,
      tags: tags,
    ));
  }

  void deleteMemory(String id) {
    final memory = _memories.byId(id);
    if (memory != null) PhotoStorage.delete(memory.imageUrls);
    _memories.remove(id);
  }

  void toggleFavorite(String id) {
    final item = _memories.byId(id);
    if (item != null) _memories.put(item.copyWith(isFavorite: !item.isFavorite));
  }

  void addCountdown({
    required String titleTr,
    required String titleEn,
    required DateTime targetDate,
    String icon = 'heart',
    bool isAnniversary = false,
  }) {
    _countdowns.put(CountdownEvent(
      id: const Uuid().v4(),
      titleTr: titleTr,
      titleEn: titleEn,
      targetDate: targetDate,
      icon: icon,
      isAnniversary: isAnniversary,
    ));
  }

  void deleteCountdown(String id) => _countdowns.remove(id);

  @override
  void dispose() {
    disposeSyncedLists();
    super.dispose();
  }
}
