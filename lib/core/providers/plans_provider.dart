import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/plan_item.dart';

class PlansProvider extends ChangeNotifier {
  final List<CalendarEvent> _events = [];
  final List<TaskItem> _tasks = [];
  final List<ShoppingItem> _shoppingList = [];

  List<CalendarEvent> get events => List.unmodifiable(_events);
  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  List<ShoppingItem> get shoppingList => List.unmodifiable(_shoppingList);

  int get pendingTasksCount => _tasks.where((t) => !t.isCompleted).length;
  int get pendingShoppingCount => _shoppingList.where((s) => !s.isBought).length;

  PlansProvider() {
    _loadSampleData();
  }

  void _loadSampleData() {
    final now = DateTime.now();

    _events.addAll([
      CalendarEvent(
        id: const Uuid().v4(),
        title: 'Havaalanı Karşılama ✈️',
        description: 'Buluşma günü! Terminal 2 saat 14:30',
        date: now.add(const Duration(days: 14)),
        category: 'travel',
      ),
      CalendarEvent(
        id: const Uuid().v4(),
        title: 'Online Film Randevusu 🍿',
        description: 'La La Land izliyoruz',
        date: now.add(const Duration(days: 2, hours: 20)),
        category: 'date',
      ),
      CalendarEvent(
        id: const Uuid().v4(),
        title: '1. Yıl Dönümümüz 💍',
        description: 'Birlikte 365 gün tamamlanıyor!',
        date: now.add(const Duration(days: 23)),
        category: 'anniversary',
      ),
    ]);

    _tasks.addAll([
      TaskItem(
        id: const Uuid().v4(),
        title: 'Buluşma için biletleri kontrol et',
        isCompleted: false,
        assignedTo: 'me',
        dueDate: now.add(const Duration(days: 3)),
      ),
      TaskItem(
        id: const Uuid().v4(),
        title: 'Fotoğraf albümü için kareleri seç',
        isCompleted: false,
        assignedTo: 'partner',
        dueDate: now.add(const Duration(days: 5)),
      ),
      TaskItem(
        id: const Uuid().v4(),
        title: 'Rezervasyon yaptır (İtalyan restoranı)',
        isCompleted: true,
        assignedTo: 'both',
      ),
    ]);

    _shoppingList.addAll([
      ShoppingItem(
        id: const Uuid().v4(),
        name: 'Lavanta Kokulu Mum',
        isBought: false,
        category: 'home',
        addedBy: 'Sude',
      ),
      ShoppingItem(
        id: const Uuid().v4(),
        name: 'Kahve Çekirdeği (Filtre)',
        isBought: false,
        category: 'market',
        addedBy: 'Can',
      ),
      ShoppingItem(
        id: const Uuid().v4(),
        name: 'Ortak polar battaniye',
        isBought: true,
        category: 'home',
        addedBy: 'Sude',
      ),
    ]);
  }

  // Calendar
  void addEvent(String title, DateTime date, {String? description, String category = 'date'}) {
    _events.add(CalendarEvent(
      id: const Uuid().v4(),
      title: title,
      date: date,
      description: description,
      category: category,
    ));
    notifyListeners();
  }

  void deleteEvent(String id) {
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // Tasks
  void addTask(String title, {String assignedTo = 'both', DateTime? dueDate}) {
    _tasks.add(TaskItem(
      id: const Uuid().v4(),
      title: title,
      assignedTo: assignedTo,
      dueDate: dueDate,
      isCompleted: false,
    ));
    notifyListeners();
  }

  void toggleTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(isCompleted: !_tasks[index].isCompleted);
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // Shopping
  void addShoppingItem(String name, {String category = 'market', required String addedBy}) {
    _shoppingList.add(ShoppingItem(
      id: const Uuid().v4(),
      name: name,
      category: category,
      addedBy: addedBy,
      isBought: false,
    ));
    notifyListeners();
  }

  void toggleShoppingItem(String id) {
    final index = _shoppingList.indexWhere((s) => s.id == id);
    if (index != -1) {
      _shoppingList[index] = _shoppingList[index].copyWith(isBought: !_shoppingList[index].isBought);
      notifyListeners();
    }
  }

  void deleteShoppingItem(String id) {
    _shoppingList.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
