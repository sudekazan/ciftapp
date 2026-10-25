import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/providers/plans_provider.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  AppLocalizations get _t => AppLocalizations.of(context);
  String get _lang => Localizations.localeOf(context).languageCode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddModal() {
    final currentTab = _tabController.index;
    if (currentTab == 0) {
      _showAddEventDialog();
    } else if (currentTab == 1) {
      _showAddTaskDialog();
    } else {
      _showAddShoppingDialog();
    }
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            title: Text(_t.text('add_event')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: _t.text('event_title_label')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(labelText: _t.text('event_desc_label')),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: isDark ? AppColors.darkSurface : AppColors.background,
                    leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                    title: Text(DateFormat('d MMMM yyyy', _lang).format(selectedDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t.text('cancel'))),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty) {
                    Provider.of<PlansProvider>(context, listen: false).addEvent(
                      titleController.text.trim(),
                      selectedDate,
                      description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: Text(_t.text('save')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    String assignedTo = 'both';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(_t.text('add_task')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: _t.text('task_title_label')),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: assignedTo,
                  decoration: InputDecoration(labelText: _t.text('task_assign_label')),
                  items: [
                    DropdownMenuItem(value: 'both', child: Text(_t.text('task_assign_both'))),
                    DropdownMenuItem(value: 'me', child: Text(_t.text('task_assign_me'))),
                    DropdownMenuItem(value: 'partner', child: Text(_t.text('task_assign_partner'))),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => assignedTo = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t.text('cancel'))),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty) {
                    Provider.of<PlansProvider>(context, listen: false).addTask(
                      titleController.text.trim(),
                      assignedTo: assignedTo,
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: Text(_t.text('add')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddShoppingDialog() {
    final nameController = TextEditingController();
    String category = 'market';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(_t.text('add_shopping_item')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: _t.text('shopping_name_label')),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: InputDecoration(labelText: _t.text('shopping_category_label')),
                  items: [
                    DropdownMenuItem(value: 'market', child: Text(_t.text('shopping_cat_market'))),
                    DropdownMenuItem(value: 'home', child: Text(_t.text('shopping_cat_home'))),
                    DropdownMenuItem(value: 'other', child: Text(_t.text('shopping_cat_other'))),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => category = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t.text('cancel'))),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    final appState = Provider.of<AppStateProvider>(context, listen: false);
                    Provider.of<PlansProvider>(context, listen: false).addShoppingItem(
                      nameController.text.trim(),
                      category: category,
                      addedBy: appState.currentUser.name,
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: Text(_t.text('add')),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text('plans_title')),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(icon: const Icon(Icons.calendar_month_rounded, size: 20), text: l10n.text('tab_calendar')),
            Tab(icon: const Icon(Icons.checklist_rounded, size: 20), text: l10n.text('tab_tasks')),
            Tab(icon: const Icon(Icons.shopping_bag_outlined, size: 20), text: l10n.text('tab_shopping')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(theme, isDark),
          _buildTasksTab(theme, isDark),
          _buildShoppingTab(theme, isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddModal,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(_t.text('add_new'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarTab(ThemeData theme, bool isDark) {
    final plansProvider = Provider.of<PlansProvider>(context);
    final events = plansProvider.events;

    if (events.isEmpty) {
      return _buildEmptyState(theme, Icons.event_note_rounded, _t.text('events_empty'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final dateStr = DateFormat('d MMMM yyyy, EEEE', _lang).format(event.date);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${event.date.day}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        DateFormat('MMM', _lang).format(event.date),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (event.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 20),
                  onPressed: () => plansProvider.deleteEvent(event.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTasksTab(ThemeData theme, bool isDark) {
    final plansProvider = Provider.of<PlansProvider>(context);
    final tasks = plansProvider.tasks;

    if (tasks.isEmpty) {
      return _buildEmptyState(theme, Icons.checklist_rounded, _t.text('tasks_empty'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];

        return Card(
          child: ListTile(
            leading: IconButton(
              icon: Icon(
                task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: task.isCompleted ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
              onPressed: () => plansProvider.toggleTask(task.id),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? AppColors.textSecondary : null,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _t.text(switch (plansProvider.assigneeOf(task)) {
                'me' => 'task_assigned_me',
                'partner' => 'task_assigned_partner',
                _ => 'task_assigned_both',
              }),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.textSecondary),
              onPressed: () => plansProvider.deleteTask(task.id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShoppingTab(ThemeData theme, bool isDark) {
    final plansProvider = Provider.of<PlansProvider>(context);
    final items = plansProvider.shoppingList;

    if (items.isEmpty) {
      return _buildEmptyState(theme, Icons.shopping_bag_outlined, _t.text('shopping_empty'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          child: ListTile(
            leading: IconButton(
              icon: Icon(
                item.isBought ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: item.isBought ? AppColors.accentTeal : AppColors.textSecondary,
                size: 24,
              ),
              onPressed: () => plansProvider.toggleShoppingItem(item.id),
            ),
            title: Text(
              item.name,
              style: TextStyle(
                decoration: item.isBought ? TextDecoration.lineThrough : null,
                color: item.isBought ? AppColors.textSecondary : null,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _t.textf('shopping_added_by', {
                'name': item.addedBy,
                'category': _t.text(switch (item.category) {
                  'market' => 'shopping_cat_market',
                  'home' => 'shopping_cat_home',
                  _ => 'shopping_cat_other',
                }),
              }),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.textSecondary),
              onPressed: () => plansProvider.deleteShoppingItem(item.id),
            ),
          ),
        );
      },
    );
  }
}
