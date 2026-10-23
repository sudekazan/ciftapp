import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/memory_item.dart';
import '../models/model_json.dart';
import '../services/local_store.dart';
import '../services/photo_storage.dart';

class MemoriesProvider extends ChangeNotifier {
  static const _memoriesKey = 'memories';
  static const _countdownsKey = 'countdowns';

  final List<MemoryItem> _memories = [];
  final List<CountdownEvent> _countdowns = [];
  bool _isLoaded = false;

  List<MemoryItem> get memories => List.unmodifiable(_memories);
  List<CountdownEvent> get countdowns => List.unmodifiable(_countdowns);
  bool get isLoaded => _isLoaded;

  MemoriesProvider() {
    _load();
  }

  Future<void> _load() async {
    final loaded = await LocalStore.loadList(_memoriesKey, MemoryItemJson.fromJson);
    final memories = <MemoryItem>[];
    for (final m in loaded) {
      final resolved = <String>[];
      for (final p in m.imageUrls) {
        resolved.add(await PhotoStorage.resolve(p));
      }
      memories.add(m.copyWith(imageUrls: resolved));
    }
    final countdowns = await LocalStore.loadList(_countdownsKey, CountdownEventJson.fromJson);
    _memories
      ..clear()
      ..addAll(memories);
    _countdowns
      ..clear()
      ..addAll(countdowns);
    _isLoaded = true;
    notifyListeners();

    // Asynchronously back up any local photos to Firebase Cloud Storage
    _syncLocalPhotosToCloud();
  }

  /// Silently uploads local photo files to Firebase Cloud Storage and updates paths to URLs
  Future<void> _syncLocalPhotosToCloud() async {
    if (Firebase.apps.isEmpty) return;
    try {
      bool changed = false;
      for (int i = 0; i < _memories.length; i++) {
        final memory = _memories[i];
        final updatedUrls = <String>[];
        bool memoryChanged = false;

        for (final url in memory.imageUrls) {
          if (!url.startsWith('http')) {
            final file = File(url);
            if (await file.exists()) {
              final cloudUrl = await PhotoStorage.uploadToCloud(file);
              if (cloudUrl != null) {
                updatedUrls.add(cloudUrl);
                memoryChanged = true;
                continue;
              }
            }
          }
          updatedUrls.add(url);
        }

        if (memoryChanged) {
          _memories[i] = memory.copyWith(imageUrls: updatedUrls);
          changed = true;
        }
      }

      if (changed) {
        notifyListeners();
        await _saveMemories();
        debugPrint('MemoriesProvider: Local photos synced to cloud successfully.');
      }
    } catch (e) {
      debugPrint('MemoriesProvider: Cloud photo sync error: $e');
    }
  }

  Future<void> _saveMemories() =>
      LocalStore.saveList(_memoriesKey, _memories, (m) => m.toJson());

  Future<void> _saveCountdowns() =>
      LocalStore.saveList(_countdownsKey, _countdowns, (c) => c.toJson());

  /// Clears all in-memory and persisted data (account deletion).
  Future<void> clearAll() async {
    await PhotoStorage.delete(_memories.expand((m) => m.imageUrls));
    _memories.clear();
    _countdowns.clear();
    await _saveMemories();
    await _saveCountdowns();
    notifyListeners();
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
    _memories.insert(
      0,
      MemoryItem(
        id: const Uuid().v4(),
        title: title,
        note: note,
        date: date,
        location: location,
        mood: mood,
        imageUrls: imageUrls,
        tags: tags,
      ),
    );
    notifyListeners();
    _saveMemories();
  }

  void deleteMemory(String id) {
    final index = _memories.indexWhere((m) => m.id == id);
    if (index != -1) {
      PhotoStorage.delete(_memories[index].imageUrls);
    }
    _memories.removeWhere((m) => m.id == id);
    notifyListeners();
    _saveMemories();
  }

  void toggleFavorite(String id) {
    final index = _memories.indexWhere((m) => m.id == id);
    if (index != -1) {
      final item = _memories[index];
      _memories[index] = item.copyWith(isFavorite: !item.isFavorite);
      notifyListeners();
      _saveMemories();
    }
  }

  void addCountdown({
    required String titleTr,
    required String titleEn,
    required DateTime targetDate,
    String icon = 'heart',
    bool isAnniversary = false,
  }) {
    _countdowns.add(CountdownEvent(
      id: const Uuid().v4(),
      titleTr: titleTr,
      titleEn: titleEn,
      targetDate: targetDate,
      icon: icon,
      isAnniversary: isAnniversary,
    ));
    notifyListeners();
    _saveCountdowns();
  }

  void deleteCountdown(String id) {
    _countdowns.removeWhere((c) => c.id == id);
    notifyListeners();
    _saveCountdowns();
  }
}
