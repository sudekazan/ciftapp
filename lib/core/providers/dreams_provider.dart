import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/bucket_list_item.dart';
import '../models/love_note_item.dart';

class DreamsProvider extends ChangeNotifier {
  final List<BucketListItem> _bucketList = [];
  final List<LoveNoteItem> _loveNotes = [];

  List<BucketListItem> get bucketList => List.unmodifiable(_bucketList);
  List<LoveNoteItem> get loveNotes => List.unmodifiable(_loveNotes);

  int get completedCount => _bucketList.where((item) => item.isCompleted).length;
  double get progressPercentage => _bucketList.isEmpty ? 0 : completedCount / _bucketList.length;

  DreamsProvider() {
    _loadSampleData();
  }

  void _loadSampleData() {
    final now = DateTime.now();

    _bucketList.addAll([
      BucketListItem(
        id: const Uuid().v4(),
        title: 'Kapadokya’da gün doğumunda sıcak hava balonuna binmek 🎈',
        category: 'Seyahat ✈️',
        isCompleted: true,
        completedDate: now.subtract(const Duration(days: 120)),
        note: 'Gökyüzündeki o sessizlik ve gözlerindeki ışıltı hayatımın en güzel anıydı.',
      ),
      BucketListItem(
        id: const Uuid().v4(),
        title: 'Birlikte İtalya’da sokak arasında pizza ve dondurma yemek 🍕',
        category: 'Seyahat ✈️',
        isCompleted: false,
        targetDate: '2027 Yazı',
      ),
      BucketListItem(
        id: const Uuid().v4(),
        title: 'Yağmur altında sırılsıklam olup dans etmek 🌧️',
        category: 'Romantik 🍷',
        isCompleted: true,
        completedDate: now.subtract(const Duration(days: 45)),
        note: 'Gülmekten karnımız ağrımıştı, unutulmaz bir gündü.',
      ),
      BucketListItem(
        id: const Uuid().v4(),
        title: 'Deniz kenarında kamp kurup sabaha kadar yıldızları izlemek 🌌',
        category: 'Macera 🏕️',
        isCompleted: false,
      ),
      BucketListItem(
        id: const Uuid().v4(),
        title: 'Kendi ellerimizle pasta yapıp birbirimizin yüzüne krema sürmek 🎂',
        category: 'Deneyim 🎨',
        isCompleted: false,
      ),
      BucketListItem(
        id: const Uuid().v4(),
        title: 'Birlikte sıcacık kahvemizi içebileceğimiz kendi yuvamızı kurmak 🏡',
        category: 'Gelecek & Ev 🏡',
        isCompleted: false,
      ),
      BucketListItem(
        id: const Uuid().v4(),
        title: 'Kuzey Işıklarını (Aurora) el ele izlemek ❄️',
        category: 'Seyahat ✈️',
        isCompleted: false,
      ),
    ]);

    _loveNotes.addAll([
      LoveNoteItem(
        id: const Uuid().v4(),
        senderName: 'Can ❤️',
        title: 'Günün En Güzel Anı ☕',
        content: 'Sabah uyanıp senin mesajını gördüğüm her gün dünyanın en şanslı insanı olduğumu hatırlıyorum. Seni çok seviyorum.',
        colorHex: 0xFFFFE5EC, // Romantic pink
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      LoveNoteItem(
        id: const Uuid().v4(),
        senderName: 'Can ❤️',
        title: '1. Yıl Dönümümüzde Açılacak Mektup 💌',
        content: 'Bu mektubu sana ilişkimizin 6. ayında yazdım. Zaman ne kadar hızlı geçse de sana olan aşkım her geçen gün katlanarak büyüdü. İyi ki varsın her şeyim!',
        colorHex: 0xFFE0E7FF, // Time capsule indigo
        createdAt: now.subtract(const Duration(days: 90)),
        unlockDate: now.add(const Duration(days: 23)), // Time locked capsule!
      ),
      LoveNoteItem(
        id: const Uuid().v4(),
        senderName: 'Sude 🌸',
        title: 'Küçük Bir Hatırlatma ✨',
        content: 'Günün nasıl geçerse geçsin, akşam sesini duyduğumda bütün yorgunluğum geçiyor. Kendini çok yorma sevgilim.',
        colorHex: 0xFFFFF3CD, // Pastel gold/yellow
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ]);
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
    }
  }

  void deleteBucketItem(String id) {
    _bucketList.removeWhere((item) => item.id == id);
    notifyListeners();
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
  }

  void unlockLoveNote(String id) {
    final index = _loveNotes.indexWhere((item) => item.id == id);
    if (index != -1) {
      _loveNotes[index] = _loveNotes[index].copyWith(isOpened: true);
      notifyListeners();
    }
  }

  void deleteLoveNote(String id) {
    _loveNotes.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
