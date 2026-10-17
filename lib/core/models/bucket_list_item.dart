class BucketListItem {
  final String id;
  final String title;
  final String category; // Seyahat ✈️, Romantik 🍷, Macera 🏕️, Gelecek & Ev 🏡, Deneyim 🎨
  final bool isCompleted;
  final DateTime? completedDate;
  final String? note;
  final String? targetDate;

  BucketListItem({
    required this.id,
    required this.title,
    required this.category,
    this.isCompleted = false,
    this.completedDate,
    this.note,
    this.targetDate,
  });

  BucketListItem copyWith({
    String? id,
    String? title,
    String? category,
    bool? isCompleted,
    DateTime? completedDate,
    String? note,
    String? targetDate,
  }) {
    return BucketListItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      note: note ?? this.note,
      targetDate: targetDate ?? this.targetDate,
    );
  }
}
