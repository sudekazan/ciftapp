class LoveNoteItem {
  final String id;
  final String senderName;
  final String title;
  final String content;
  final int colorHex; // Pastel post-it colors (e.g. 0xFFFFE5EC, 0xFFFFF3CD, 0xFFE2F0CB, 0xFFE0E7FF)
  final DateTime createdAt;
  final DateTime? unlockDate; // If set, acts as a Time Capsule locked until this date
  final bool isOpened;

  LoveNoteItem({
    required this.id,
    required this.senderName,
    required this.title,
    required this.content,
    required this.colorHex,
    required this.createdAt,
    this.unlockDate,
    this.isOpened = false,
  });

  bool get isTimeCapsule => unlockDate != null;

  bool get isLocked {
    if (unlockDate == null) return false;
    return DateTime.now().isBefore(unlockDate!) && !isOpened;
  }

  Duration get remainingTime {
    if (unlockDate == null) return Duration.zero;
    final diff = unlockDate!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  LoveNoteItem copyWith({
    String? id,
    String? senderName,
    String? title,
    String? content,
    int? colorHex,
    DateTime? createdAt,
    DateTime? unlockDate,
    bool? isOpened,
  }) {
    return LoveNoteItem(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      title: title ?? this.title,
      content: content ?? this.content,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      unlockDate: unlockDate ?? this.unlockDate,
      isOpened: isOpened ?? this.isOpened,
    );
  }
}
