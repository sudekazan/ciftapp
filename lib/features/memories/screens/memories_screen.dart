import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/content_labels.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/providers/memories_provider.dart';
import '../../../core/premium/limits.dart';
import '../../../core/premium/premium_gate.dart';
import 'add_memory_screen.dart';
import 'memory_detail_screen.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _onlyFavorites = false;

  AppLocalizations get _t => AppLocalizations.of(context);
  String get _lang => Localizations.localeOf(context).languageCode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddMemory() async {
    final count = Provider.of<MemoriesProvider>(context, listen: false).memories.length;
    final allowed = await PremiumGate.check(
      context,
      allowed: Limits.canAddMemory(count: count, premium: PremiumGate.isPremium(context)),
      source: PaywallSource.memoryLimit,
    );
    if (!allowed || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddMemoryScreen()),
    );
  }

  void _showAddCountdown() {
    final titleTrController = TextEditingController();
    DateTime targetDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            title: Text(_t.text('add_countdown')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleTrController,
                  decoration: InputDecoration(labelText: _t.text('countdown_title_label')),
                ),
                const SizedBox(height: 14),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: isDark ? AppColors.darkSurface : AppColors.background,
                  leading: const Icon(Icons.cake_rounded, color: AppColors.primary),
                  title: Text(DateFormat('d MMMM yyyy', _lang).format(targetDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: targetDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (picked != null) {
                      setModalState(() => targetDate = picked);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t.text('cancel'))),
              ElevatedButton(
                onPressed: () {
                  if (titleTrController.text.trim().isNotEmpty) {
                    Provider.of<MemoriesProvider>(context, listen: false).addCountdown(
                      titleTr: titleTrController.text.trim(),
                      titleEn: titleTrController.text.trim(),
                      targetDate: targetDate,
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
        title: Text(l10n.text('memories_title')),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(icon: const Icon(Icons.photo_library_rounded, size: 20), text: l10n.text('tab_memory_book')),
            Tab(icon: const Icon(Icons.timer_outlined, size: 20), text: l10n.text('tab_countdowns')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMemoryBookTab(theme, isDark, l10n),
          _buildCountdownsTab(theme, isDark, l10n),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Tabs live in one IndexedStack: each FAB needs its own hero tag.
        heroTag: 'memories_fab',
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddMemory();
          } else {
            _showAddCountdown();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(_t.text(_tabController.index == 0 ? 'add_memory_short' : 'add_countdown_short'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMemoryBookTab(ThemeData theme, bool isDark, AppLocalizations l10n) {
    final memoriesProvider = Provider.of<MemoriesProvider>(context);
    final allMemories = memoriesProvider.memories;
    final isPremium = Provider.of<AppStateProvider>(context).currentUser.isPremium;
    final l10n = AppLocalizations.of(context);

    final filteredMemories = allMemories.where((memory) {
      if (_onlyFavorites && !memory.isFavorite) return false;
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final inTitle = memory.title.toLowerCase().contains(query);
        final inNote = memory.note.toLowerCase().contains(query);
        final inLocation = memory.location?.toLowerCase().contains(query) ?? false;
        final inTags = memory.tags.any((t) => t.toLowerCase().contains(query));
        return inTitle || inNote || inLocation || inTags;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Free plan usage (premium: unlimited)
        if (!isPremium) ...[
          InkWell(
            onTap: () => PremiumGate.openPaywall(context, PaywallSource.memoryLimit),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.darkCardGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.accentGold, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.textf('memories_free_usage', {'n': allMemories.length, 'm': Limits.freeMemories}),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (allMemories.length / Limits.freeMemories).clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            color: AppColors.accentGold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.textf('memories_upgrade_hint', {'m': Limits.premiumPhotosPerMemory}),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Search and Favorites Filter Bar
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: _t.text('memories_search_hint'),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              avatar: Icon(
                _onlyFavorites ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 16,
                color: _onlyFavorites ? Colors.redAccent : AppColors.primary,
              ),
              label: Text(_t.text(_onlyFavorites ? 'favorites' : 'cat_all')),
              selected: _onlyFavorites,
              onSelected: (val) => setState(() => _onlyFavorites = val),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (filteredMemories.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                const SizedBox(height: 12),
                Text(
                  _t.text(_onlyFavorites ? 'memories_no_favorites' : 'memories_no_results'),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          )
        else
          ...filteredMemories.map((memory) {
            final dateStr = DateFormat('d MMMM yyyy', _lang).format(memory.date);
            final firstImage = memory.primaryImageUrl;
            final totalPhotos = memory.imageUrls.length;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => MemoryDetailScreen(memory: memory)),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (firstImage != null)
                      Stack(
                        children: [
                          Container(
                            height: 190,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: firstImage.startsWith('http')
                                    ? NetworkImage(firstImage) as ImageProvider
                                    : FileImage(File(firstImage)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Favorite Toggle Icon
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: () {
                                memoriesProvider.toggleFavorite(memory.id);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  memory.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: memory.isFavorite ? Colors.redAccent : Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          // Photo Count Badge
                          if (totalPhotos > 1)
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.photo_library_rounded, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      _t.textf('photo_count', {'n': totalPhotos}),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Mood Badge
                          if (memory.mood != null)
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  ContentLabels.mood(_t, memory.mood!),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ],
                            ),
                            if (memory.location != null)
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(memory.location!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          memory.title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          memory.note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Wrap(
                              spacing: 6,
                              children: memory.tags.map((tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('#$tag', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              )).toList(),
                            ),
                            Row(
                              children: [
                                Text(_t.text('view'), style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                SizedBox(width: 2),
                                Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 18),
                              ],
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildCountdownsTab(ThemeData theme, bool isDark, AppLocalizations l10n) {
    final memoriesProvider = Provider.of<MemoriesProvider>(context);
    final appState = Provider.of<AppStateProvider>(context);
    final countdowns = memoriesProvider.countdowns;
    final daysTogether = appState.currentUser.daysTogether;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Days Together Hero
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: AppColors.heartGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.white, size: 36),
              const SizedBox(height: 10),
              Text(
                _t.textf('days_together_count', {'n': daysTogether}),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _t.text('days_together_sub'),
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        ...countdowns.map((item) {
          final isPast = item.isPast;
          final days = item.remainingDays.abs();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: item.isAnniversary ? AppColors.primarySoft : AppColors.secondarySoft.withValues(alpha: isDark ? 0.2 : 0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        item.icon == 'plane'
                            ? Icons.flight_takeoff_rounded
                            : (item.icon == 'cake' ? Icons.cake_rounded : Icons.favorite_rounded),
                        color: item.isAnniversary ? AppColors.primary : AppColors.secondary,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.getTitle(appState.currentLanguage),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('d MMMM yyyy', _lang).format(item.targetDate),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPast
                          ? (isDark ? AppColors.darkSurface : AppColors.divider)
                          : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _t.textf(isPast ? 'days_passed' : 'days_left', {'n': days}),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPast ? AppColors.textSecondary : AppColors.primary,
                      ),
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
}
