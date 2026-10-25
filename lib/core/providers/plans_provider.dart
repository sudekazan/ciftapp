import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/model_json.dart';
import '../models/plan_item.dart';
import '../services/couple_data_store.dart';
import '../services/synced_list.dart';
import 'couple_bound_provider.dart';

class PlansProvider extends ChangeNotifier with CoupleBoundProvider {
  PlansProvider({CoupleDataStore? store})
      : dataStore = store ?? FirestoreCoupleDataStore.instance {
    _events = SyncedList(
      collection: 'events',
      localKey: 'plan_events',
      fromJson: CalendarEventJson.fromJson,
      toJson: (e) => e.toJson(),
      idOf: (e) => e.id,
      onChanged: notifyListeners,
    );
    _tasks = SyncedList(
      collection: 'tasks',
      localKey: 'plan_tasks',
      fromJson: TaskItemJson.fromJson,
      toJson: (t) => t.toJson(),
      idOf: (t) => t.id,
      onChanged: notifyListeners,
    );
    _shopping = SyncedList(
      collection: 'shopping',
      localKey: 'plan_shopping',
      fromJson: ShoppingItemJson.fromJson,
      toJson: (s) => s.toJson(),
      idOf: (s) => s.id,
      onChanged: notifyListeners,
    );
    ready = _load();
  }

  @override
  final CoupleDataStore dataStore;
  @override
  late final Future<void> ready;

  late final SyncedList<CalendarEvent> _events;
  late final SyncedList<TaskItem> _tasks;
  late final SyncedList<ShoppingItem> _shopping;
  bool _isLoaded = false;

  @override
  Iterable<SyncedList> get syncedLists => [_events, _tasks, _shopping];

  List<CalendarEvent> get events => _events.items;
  List<TaskItem> get tasks => _tasks.items;
  List<ShoppingItem> get shoppingList => _shopping.items;
  bool get isLoaded => _isLoaded;

  int get pendingTasksCount => tasks.where((t) => !t.isCompleted).length;

  /// Who [task] is assigned to from the current user's point of view
  /// ('me', 'partner' or 'both'). It is stored relative to its author, so it is
  /// flipped when the partner created the task.
  String assigneeOf(TaskItem task) {
    final assigned = task.assignedTo ?? 'both';
    final author = _tasks.authorOf(task.id);
    if (assigned == 'both' || author == null || author == dataStore.currentUid) return assigned;
    return assigned == 'me' ? 'partner' : 'me';
  }

  int get pendingShoppingCount => shoppingList.where((s) => !s.isBought).length;

  Future<void> _load() async {
    for (final list in syncedLists) {
      await list.loadLocal();
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Clears all in-memory and persisted data (account deletion).
  Future<void> clearAll() async {
    for (final list in syncedLists) {
      await list.clearLocal();
    }
    notifyListeners();
  }

  // Calendar
  void addEvent(String title, DateTime date, {String? description, String category = 'date'}) {
    _events.put(CalendarEvent(
      id: const Uuid().v4(),
      title: title,
      date: date,
      description: description,
      category: category,
    ));
  }

  void deleteEvent(String id) => _events.remove(id);

  // Tasks
  void addTask(String title, {String assignedTo = 'both', DateTime? dueDate}) {
    _tasks.put(TaskItem(
      id: const Uuid().v4(),
      title: title,
      assignedTo: assignedTo,
      dueDate: dueDate,
      isCompleted: false,
    ));
  }

  void toggleTask(String id) {
    final task = _tasks.byId(id);
    if (task != null) _tasks.put(task.copyWith(isCompleted: !task.isCompleted));
  }

  void deleteTask(String id) => _tasks.remove(id);

  // Shopping
  void addShoppingItem(String name, {String category = 'market', required String addedBy}) {
    _shopping.put(ShoppingItem(
      id: const Uuid().v4(),
      name: name,
      category: category,
      addedBy: addedBy,
      isBought: false,
    ));
  }

  void toggleShoppingItem(String id) {
    final item = _shopping.byId(id);
    if (item != null) _shopping.put(item.copyWith(isBought: !item.isBought));
  }

  void deleteShoppingItem(String id) => _shopping.remove(id);

  @override
  void dispose() {
    disposeSyncedLists();
    super.dispose();
  }
}
