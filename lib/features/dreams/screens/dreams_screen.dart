import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/love_note_item.dart';
import '../../../core/premium/limits.dart';
import '../../../core/premium/premium_gate.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/providers/dreams_provider.dart';

class DreamsScreen extends StatefulWidget {
  const DreamsScreen({super.key});

  @override
  State<DreamsScreen> createState() => _DreamsScreenState();
}

class _DreamsScreenState extends State<DreamsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = _allCategory;

  // Category values are stored with the item (Turkish ids, kept for existing
  // data); only their display text is localized.
  static const _allCategory = 'Tümü';
  static const Map<String, String> _categoryKeys = {
    'Tümü': 'cat_all',
    'Seyahat ✈️': 'cat_travel',
    'Romantik 🍷': 'cat_romantic',
    'Macera 🏕️': 'cat_adventure',
    'Gelecek & Ev 🏡': 'cat_future_home',
    'Deneyim 🎨': 'cat_experience',
  };
  final List<String> _categories = _categoryKeys.keys.toList();

  AppLocalizations get _t => AppLocalizations.of(context);
  String get _lang => Localizations.localeOf(context).languageCode;

  String _categoryLabel(String category) {
    final key = _categoryKeys[category];
    return key == null ? category : _t.text(key);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddBucketDialog() {
    final titleController = TextEditingController();
    final targetDateController = TextEditingController();
    String category = 'Seyahat ✈️';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(_t.text('dreams_add_dream'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: _t.text('dream_title_label'),
                      hintText: _t.text('dream_title_hint'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_t.text('dream_category_label'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _categories.where((c) => c != _allCategory).map((cat) {
                      final isSel = category == cat;
                      return ChoiceChip(
                        label: Text(_categoryLabel(cat), style: const TextStyle(fontSize: 11.5)),
                        selected: isSel,
                        onSelected: (_) => setModalState(() => category = cat),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: targetDateController,
                    decoration: InputDecoration(
                      labelText: _t.text('dream_target_label'),
                      hintText: _t.text('dream_target_hint'),
                      prefixIcon: const Icon(Icons.event_outlined, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t.text('cancel'))),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isNotEmpty) {
                    Provider.of<DreamsProvider>(context, listen: false).addBucketItem(
                      title: title,
                      category: category,
                      targetDate: targetDateController.text.trim().isEmpty ? null : targetDateController.text.trim(),
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: Text(_t.text('dream_add_btn')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddLoveNoteDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    int selectedColor = 0xFFFFE5EC;
    DateTime? scheduledUnlockDate;
    bool isCapsule = false;

    final colors = [
      0xFFFFE5EC, // Romantic pink
      0xFFFFF3CD, // Pastel yellow
      0xFFE0E7FF, // Time capsule indigo
      0xFFE2F0CB, // Fresh mint
      0xFFFCE7F3, // Soft rose
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Row(
              children: [
                Icon(isCapsule ? Icons.lock_clock_rounded : Icons.edit_note_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(_t.text(isCapsule ? 'note_capsule_title' : 'note_plain_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: _t.text('note_title_label'),
                      hintText: _t.text('note_title_hint'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: _t.text('note_content_label'),
                      hintText: _t.text('note_content_hint'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_t.text('note_color_label'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: colors.map((col) {
                      final isSel = selectedColor == col;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColor = col),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(col),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                              width: isSel ? 2.5 : 1,
                            ),
                          ),
                          child: isSel ? const Icon(Icons.check, size: 16, color: AppColors.primary) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_t.text('note_capsule_switch'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      [
                        _t.text('note_capsule_switch_sub'),
                        if (!appState.currentUser.isPremium)
                          AppLocalizations.of(context).textf('capsule_free_note', {'n': Limits.freeCapsulesPerMonth}),
                      ].join('\n'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: isCapsule,
                    onChanged: (val) {
                      setModalState(() {
                        isCapsule = val;
                        if (isCapsule && scheduledUnlockDate == null) {
                          scheduledUnlockDate = DateTime.now().add(const Duration(days: 14));
                        }
                      });
                    },
                  ),
                  if (isCapsule) ...[
                    const SizedBox(height: 6),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                      leading: const Icon(Icons.event_available_rounded, color: AppColors.primary),
                      title: Text(
                        scheduledUnlockDate != null
                            ? DateFormat('d MMMM yyyy', _lang).format(scheduledUnlockDate!)
                            : _t.text('note_pick_unlock_date'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.edit_calendar_rounded, size: 18),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: scheduledUnlockDate ?? DateTime.now().add(const Duration(days: 14)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          setModalState(() => scheduledUnlockDate = picked);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t.text('cancel'))),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final content = contentController.text.trim();
                  if (title.isNotEmpty && content.isNotEmpty) {
                    final dreams = Provider.of<DreamsProvider>(context, listen: false);
                    if (isCapsule) {
                      final allowed = await PremiumGate.check(
                        context,
                        allowed: Limits.canCreateCapsule(
                          createdThisMonth: dreams.capsulesCreatedThisMonth,
                          premium: PremiumGate.isPremium(context),
                        ),
                        source: PaywallSource.capsuleLimit,
                      );
                      if (!allowed || !ctx.mounted) return;
                    }
                    dreams.addLoveNote(
                      senderName: appState.currentUser.name,
                      title: title,
                      content: content,
                      colorHex: selectedColor,
                      unlockDate: isCapsule ? scheduledUnlockDate : null,
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: Text(_t.text('note_save_btn')),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(l10n.text('nav_dreams'), style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: [
            Tab(icon: const Icon(Icons.stars_rounded, size: 20), text: l10n.text('dreams_tab_bucket')),
            Tab(icon: const Icon(Icons.mark_email_read_rounded, size: 20), text: l10n.text('dreams_tab_capsule')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBucketListTab(theme, isDark),
          _buildLoveNotesTab(theme, isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddBucketDialog();
          } else {
            _showAddLoveNoteDialog();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          _tabController.index == 0 ? l10n.text('dreams_add_dream') : l10n.text('dreams_add_note'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: HAYAL LİSTESİ (BUCKET LIST)
  // ==========================================
  Widget _buildBucketListTab(ThemeData theme, bool isDark) {
    final dreamsProvider = Provider.of<DreamsProvider>(context);
    final items = dreamsProvider.bucketList;

    final filteredItems = _selectedCategory == _allCategory
        ? items
        : items.where((it) => it.category == _selectedCategory).toList();

    final completedCount = dreamsProvider.completedCount;
    final totalCount = items.length;
    final percentage = dreamsProvider.progressPercentage;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Progress Hero Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkCardGradient : AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(_t.text('dreams_progress_title'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _t.textf('dreams_progress_count', {'done': completedCount, 'total': totalCount}),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                percentage == 1.0
                    ? _t.text('dreams_progress_all_done')
                    : _t.text('dreams_progress_keep_going'),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) {
              final isSel = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(_categoryLabel(cat)),
                  selected: isSel,
                  selectedColor: AppColors.primarySoft,
                  labelStyle: TextStyle(
                    color: isSel ? AppColors.primaryDark : null,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Bucket Items List
        if (filteredItems.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Icon(Icons.star_outline_rounded, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 10),
                Text(_t.text('dreams_empty_category'), style: theme.textTheme.bodyMedium),
              ],
            ),
          )
        else
          ...filteredItems.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: GestureDetector(
                  onTap: () => dreamsProvider.toggleBucketItem(item.id),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: item.isCompleted ? AppColors.accentTeal : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: item.isCompleted ? AppColors.accentTeal : AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: item.isCompleted
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                        : null,
                  ),
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                    color: item.isCompleted ? AppColors.textSecondary : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _categoryLabel(item.category),
                            style: const TextStyle(fontSize: 10.5, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (item.targetDate != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '🎯 ${item.targetDate!}',
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                    if (item.isCompleted && item.completedDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _t.textf('dream_completed_on', {'date': DateFormat('d MMMM yyyy', _lang).format(item.completedDate!)}),
                        style: const TextStyle(fontSize: 11, color: AppColors.accentTeal, fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (item.note != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '“${item.note!}”',
                        style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: isDark ? Colors.white70 : AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (val) {
                    if (val == 'delete') {
                      dreamsProvider.deleteBucketItem(item.id);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'delete', child: Text(_t.text('dream_delete'), style: const TextStyle(color: Colors.redAccent))),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ==========================================
  // TAB 2: AŞK NOTLARI & ZAMAN KAPSÜLÜ
  // ==========================================
  Widget _buildLoveNotesTab(ThemeData theme, bool isDark) {
    final dreamsProvider = Provider.of<DreamsProvider>(context);
    final notes = dreamsProvider.loveNotes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Intro Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: AppColors.heartGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t.text('notes_intro_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      _t.text('notes_intro_sub'),
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Notes Cards
        if (notes.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Icon(Icons.mail_outline_rounded, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 10),
                Text(_t.text('dreams_empty_capsule'), style: theme.textTheme.bodyMedium),
              ],
            ),
          )
        else
          ...notes.map((note) {
            final isLocked = note.isLocked;

            return GestureDetector(
              onTap: () {
                if (isLocked) {
                  _showLockedCapsuleDialog(note);
                } else {
                  _showReadNoteDialog(note);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : Color(note.colorHex),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isLocked ? AppColors.secondary : Colors.black.withValues(alpha: 0.06),
                    width: isLocked ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isLocked ? Icons.lock_clock_rounded : Icons.favorite_rounded,
                              size: 16,
                              color: isLocked ? AppColors.secondary : AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _t.textf('note_from', {'name': note.senderName}),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (isLocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_rounded, size: 12, color: AppColors.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  _t.text('note_locked_badge'),
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            DateFormat('d MMM yyyy', _lang).format(note.createdAt),
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      note.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (isLocked)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, color: AppColors.secondary, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _t.textf('note_locked_until', {'date': DateFormat('d MMMM yyyy', _lang).format(note.unlockDate!)}),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        note.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showLockedCapsuleDialog(LoveNoteItem note) {
    final dreamsProvider = Provider.of<DreamsProvider>(context, listen: false);
    final remaining = note.remainingTime;
    // Only the author may peek; the capsule stays locked for the partner.
    final isAuthor = dreamsProvider.isMyNote(note.id);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_clock_rounded, color: AppColors.secondary, size: 40),
            ),
            const SizedBox(height: 16),
            Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              _t.textf(isAuthor ? 'capsule_dialog_author' : 'capsule_dialog_recipient', {
                'name': note.senderName,
                'date': DateFormat('d MMMM yyyy', _lang).format(note.unlockDate!),
              }),
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _t.textf('capsule_days_left', {'n': remaining.inDays}),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t.text('close'))),
          if (isAuthor)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showReadNoteDialog(note);
              },
              child: Text(_t.text('capsule_preview'), style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  void _showReadNoteDialog(LoveNoteItem note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_t.textf('note_written_by', {'name': note.senderName}), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                  Text(DateFormat('d MMMM yyyy', _lang).format(note.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              const Divider(height: 20),
              Text(
                note.content,
                style: const TextStyle(fontSize: 14.5, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: Text(_t.text('close'))),
        ],
      ),
    );
  }
}
