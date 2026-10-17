import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/memory_item.dart';

class MemoriesProvider extends ChangeNotifier {
  final List<MemoryItem> _memories = [];
  final List<CountdownEvent> _countdowns = [];

  List<MemoryItem> get memories => List.unmodifiable(_memories);
  List<CountdownEvent> get countdowns => List.unmodifiable(_countdowns);

  MemoriesProvider() {
    _loadSampleMemories();
  }

  void _loadSampleMemories() {
    final now = DateTime.now();

    _memories.addAll([
      MemoryItem(
        id: const Uuid().v4(),
        title: 'İlk Karşılaşmamız Kadıköy’de ✨',
        note: 'Yağmurlu bir sonbahar günüydü, kahvecide saatlerce konuşmuştuk. Zamanın nasıl geçtiğini hiç anlamamıştık.',
        date: now.subtract(const Duration(days: 342)),
        location: 'Kadıköy, Moda',
        mood: 'Romantik ❤️',
        imageUrls: [
          'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=800&q=80',
        ],
        tags: ['İlk Gün', 'İstanbul', 'Kahve'],
      ),
      MemoryItem(
        id: const Uuid().v4(),
        title: 'Boğaz Turu ve Gün Batımı 🌅',
        note: 'Rüzgar saçlarını uçururken bana sarıldığın o an dünyadaki en huzurlu andı.',
        date: now.subtract(const Duration(days: 210)),
        location: 'Ortaköy, İstanbul',
        mood: 'Huzurlu 🕊️',
        imageUrls: [
          'https://images.unsplash.com/photo-1522673607200-164d1b6ce486?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&w=800&q=80',
        ],
        tags: ['Gün Batımı', 'Boğaz', 'Aşk'],
      ),
      MemoryItem(
        id: const Uuid().v4(),
        title: 'Havaalanında Veda Ama Yeniden Başlangıç ✈️',
        note: 'Gözlerimiz dolsa da mesafeler kalpleri daha da yakınlaştırır demiştik. Bir sonraki kavuşma için gün sayıyoruz.',
        date: now.subtract(const Duration(days: 75)),
        location: 'İstanbul Havalimanı',
        mood: 'Duygusal 🥺',
        imageUrls: [
          'https://images.unsplash.com/photo-1518199266791-5375a83190b7?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?auto=format&fit=crop&w=800&q=80',
        ],
        tags: ['Uzak Mesafe', 'Sözümüz', 'Kavuşma'],
      ),
    ]);

    _countdowns.addAll([
      CountdownEvent(
        id: const Uuid().v4(),
        titleTr: 'Büyük Buluşma Günü ✈️',
        titleEn: 'Next Reunion Date ✈️',
        targetDate: now.add(const Duration(days: 14, hours: 8, minutes: 30)),
        icon: 'plane',
        isAnniversary: false,
      ),
      CountdownEvent(
        id: const Uuid().v4(),
        titleTr: '1. Yıl Dönümümüz 💍',
        titleEn: '1st Anniversary 💍',
        targetDate: now.add(const Duration(days: 23)),
        icon: 'heart',
        isAnniversary: true,
      ),
      CountdownEvent(
        id: const Uuid().v4(),
        titleTr: 'Yılbaşı Birlikte Tatili ❄️',
        titleEn: 'New Year Holiday ❄️',
        targetDate: now.add(const Duration(days: 75)),
        icon: 'cake',
        isAnniversary: false,
      ),
    ]);
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
  }

  void deleteMemory(String id) {
    _memories.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final index = _memories.indexWhere((m) => m.id == id);
    if (index != -1) {
      final item = _memories[index];
      _memories[index] = item.copyWith(isFavorite: !item.isFavorite);
      notifyListeners();
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
  }

  void deleteCountdown(String id) {
    _countdowns.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
