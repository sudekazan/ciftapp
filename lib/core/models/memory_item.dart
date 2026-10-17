class MemoryItem {
  final String id;
  final String title;
  final String note;
  final DateTime date;
  final List<String> imageUrls;
  final String? location;
  final String? mood; // Romantik, Eğlenceli, Kutlama, Macera, Huzur
  final List<String> tags;

  MemoryItem({
    required this.id,
    required this.title,
    required this.note,
    required this.date,
    List<String>? imageUrls,
    String? imageUrl,
    this.location,
    this.mood,
    this.tags = const [],
  }) : imageUrls = imageUrls ?? (imageUrl != null ? [imageUrl] : []);

  String? get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;
  String? get imageUrl => primaryImageUrl;

  MemoryItem copyWith({
    String? id,
    String? title,
    String? note,
    DateTime? date,
    List<String>? imageUrls,
    String? location,
    String? mood,
    List<String>? tags,
  }) {
    return MemoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      date: date ?? this.date,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
    );
  }
}

class CountdownEvent {
  final String id;
  final String titleTr;
  final String titleEn;
  final DateTime targetDate;
  final String icon; // heart, plane, ring, home, cake
  final bool isAnniversary;

  CountdownEvent({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.targetDate,
    this.icon = 'heart',
    this.isAnniversary = false,
  });

  Duration get remainingDuration => targetDate.difference(DateTime.now());
  bool get isPast => DateTime.now().isAfter(targetDate);

  int get remainingDays => remainingDuration.inDays;
  int get remainingHours => remainingDuration.inHours % 24;
  int get remainingMinutes => remainingDuration.inMinutes % 60;

  String getTitle(String lang) => lang == 'en' ? titleEn : titleTr;
}
