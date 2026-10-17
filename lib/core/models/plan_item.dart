class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final String category; // 'date', 'travel', 'anniversary', 'reminder'
  final bool isAllDay;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.category = 'date',
    this.isAllDay = false,
  });

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? category,
    bool? isAllDay,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      category: category ?? this.category,
      isAllDay: isAllDay ?? this.isAllDay,
    );
  }
}

class TaskItem {
  final String id;
  final String title;
  final bool isCompleted;
  final String? assignedTo; // 'me', 'partner', 'both'
  final DateTime? dueDate;

  TaskItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.assignedTo = 'both',
    this.dueDate,
  });

  TaskItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    String? assignedTo,
    DateTime? dueDate,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

class ShoppingItem {
  final String id;
  final String name;
  final bool isBought;
  final String category; // 'market', 'home', 'other'
  final String addedBy;

  ShoppingItem({
    required this.id,
    required this.name,
    this.isBought = false,
    this.category = 'market',
    required this.addedBy,
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    bool? isBought,
    String? category,
    String? addedBy,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isBought: isBought ?? this.isBought,
      category: category ?? this.category,
      addedBy: addedBy ?? this.addedBy,
    );
  }
}
