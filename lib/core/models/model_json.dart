import '../models/bucket_list_item.dart';
import '../models/love_note_item.dart';
import '../models/memory_item.dart';
import '../models/plan_item.dart';

/// JSON (de)serialization for persisted models.
/// Kept separate from the models so their definitions stay untouched.

DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v as String);

extension MemoryItemJson on MemoryItem {
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'date': date.toIso8601String(),
        'imageUrls': imageUrls,
        'location': location,
        'mood': mood,
        'tags': tags,
        'isFavorite': isFavorite,
      };

  static MemoryItem fromJson(Map<String, dynamic> j) => MemoryItem(
        id: j['id'] as String,
        title: j['title'] as String,
        note: (j['note'] as String?) ?? '',
        date: DateTime.parse(j['date'] as String),
        imageUrls: List<String>.from(j['imageUrls'] as List? ?? const []),
        location: j['location'] as String?,
        mood: j['mood'] as String?,
        tags: List<String>.from(j['tags'] as List? ?? const []),
        isFavorite: (j['isFavorite'] as bool?) ?? false,
      );
}

extension CountdownEventJson on CountdownEvent {
  Map<String, dynamic> toJson() => {
        'id': id,
        'titleTr': titleTr,
        'titleEn': titleEn,
        'targetDate': targetDate.toIso8601String(),
        'icon': icon,
        'isAnniversary': isAnniversary,
      };

  static CountdownEvent fromJson(Map<String, dynamic> j) => CountdownEvent(
        id: j['id'] as String,
        titleTr: j['titleTr'] as String,
        titleEn: j['titleEn'] as String,
        targetDate: DateTime.parse(j['targetDate'] as String),
        icon: (j['icon'] as String?) ?? 'heart',
        isAnniversary: (j['isAnniversary'] as bool?) ?? false,
      );
}

extension BucketListItemJson on BucketListItem {
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'isCompleted': isCompleted,
        'completedDate': completedDate?.toIso8601String(),
        'note': note,
        'targetDate': targetDate,
      };

  static BucketListItem fromJson(Map<String, dynamic> j) => BucketListItem(
        id: j['id'] as String,
        title: j['title'] as String,
        category: j['category'] as String,
        isCompleted: (j['isCompleted'] as bool?) ?? false,
        completedDate: _dt(j['completedDate']),
        note: j['note'] as String?,
        targetDate: j['targetDate'] as String?,
      );
}

extension LoveNoteItemJson on LoveNoteItem {
  Map<String, dynamic> toJson() => {
        'id': id,
        'senderName': senderName,
        'title': title,
        'content': content,
        'colorHex': colorHex,
        'createdAt': createdAt.toIso8601String(),
        'unlockDate': unlockDate?.toIso8601String(),
        'isOpened': isOpened,
      };

  static LoveNoteItem fromJson(Map<String, dynamic> j) => LoveNoteItem(
        id: j['id'] as String,
        senderName: j['senderName'] as String,
        title: j['title'] as String,
        content: j['content'] as String,
        colorHex: j['colorHex'] as int,
        createdAt: DateTime.parse(j['createdAt'] as String),
        unlockDate: _dt(j['unlockDate']),
        isOpened: (j['isOpened'] as bool?) ?? false,
      );
}

extension CalendarEventJson on CalendarEvent {
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'category': category,
        'isAllDay': isAllDay,
      };

  static CalendarEvent fromJson(Map<String, dynamic> j) => CalendarEvent(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        date: DateTime.parse(j['date'] as String),
        category: (j['category'] as String?) ?? 'date',
        isAllDay: (j['isAllDay'] as bool?) ?? false,
      );
}

extension TaskItemJson on TaskItem {
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'assignedTo': assignedTo,
        'dueDate': dueDate?.toIso8601String(),
      };

  static TaskItem fromJson(Map<String, dynamic> j) => TaskItem(
        id: j['id'] as String,
        title: j['title'] as String,
        isCompleted: (j['isCompleted'] as bool?) ?? false,
        assignedTo: (j['assignedTo'] as String?) ?? 'both',
        dueDate: _dt(j['dueDate']),
      );
}

extension ShoppingItemJson on ShoppingItem {
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isBought': isBought,
        'category': category,
        'addedBy': addedBy,
      };

  static ShoppingItem fromJson(Map<String, dynamic> j) => ShoppingItem(
        id: j['id'] as String,
        name: j['name'] as String,
        isBought: (j['isBought'] as bool?) ?? false,
        category: (j['category'] as String?) ?? 'market',
        addedBy: (j['addedBy'] as String?) ?? '',
      );
}
