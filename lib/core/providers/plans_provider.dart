import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/model_json.dart';
import '../models/plan_item.dart';
import '../services/local_store.dart';

class PlansProvider extends ChangeNotifier {
  static const _eventsKey = 'plan_events';
  static const _tasksKey = 'plan_tasks';
  static const _shoppingKey = 'plan_shopping';

  final List<CalendarEvent> _events = [];
  final List<TaskItem> _tasks = [];
  final List<ShoppingItem> _shoppingList = [];
  bool _isLoaded = false;

  List<CalendarEvent> get events => List.unmodifiable(_events);
  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  List<ShoppingItem> get shoppingList => List.unmodifiable(_shoppingList);
  bool get isLoaded => _isLoaded;

  int get pendingTasksCount => _tasks.where((t) => !t.isCompleted).length;
  int get pendingShoppingCount => _shoppingList.where((s) => !s.isBought).length;

  PlansProvider() {
    _load();
  }

  Future<void> _load() async {
    final events = await LocalStore.loadList(_eventsKey, CalendarEventJson.fromJson);
    final tasks = await LocalStore.loadList(_tasksKey, TaskItemJson.fromJson);
    final shopping = await LocalStore.loadList(_shoppingKey, ShoppingItemJson.fromJson);
    _events
      ..clear()
      ..addAll(events);
    _tasks
      ..clear()
      ..addAll(tasks);
    _shoppingList
      ..clear()
      ..addAll(shopping);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveEvents() =>
      LocalStore.saveList(_eventsKey, _events, (e) => e.toJson());

  Future<void> _saveTasks() =>
      LocalStore.saveList(_tasksKey, _tasks, (t) => t.toJson());

  Future<void> _saveShopping() =>
      LocalStore.saveList(_shoppingKey, _shoppingList, (s) => s.toJson());

  /// Clears all in-memory and persisted data (account deletion).
  Future<void> clearAll() async {
    _events.clear();
    _tasks.clear();
    _shoppingList.clear();
    await _saveEvents();
    await _saveTasks();
    await _saveShopping();
    notifyListeners();
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
    _saveEvents();
  }

  void deleteEvent(String id) {
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
    _saveEvents();
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
    _saveTasks();
  }

  void toggleTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(isCompleted: !_tasks[index].isCompleted);
      notifyListeners();
      _saveTasks();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    _saveTasks();
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
    _saveShopping();
  }

  void toggleShoppingItem(String id) {
    final index = _shoppingList.indexWhere((s) => s.id == id);
    if (index != -1) {
      _shoppingList[index] = _shoppingList[index].copyWith(isBought: !_shoppingList[index].isBought);
      notifyListeners();
      _saveShopping();
    }
  }

  void deleteShoppingItem(String id) {
    _shoppingList.removeWhere((s) => s.id == id);
    notifyListeners();
    _saveShopping();
  }
}
