import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/providers/memories_provider.dart';
import '../../premium/screens/paywall_screen.dart';
import 'add_memory_screen.dart';
import 'memory_detail_screen.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  void _showAddMemory() {
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
            title: const Text('Yeni Sayaç Ekle'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleTrController,
                  decoration: const InputDecoration(labelText: 'Özel Gün Başlığı (Örn: Doğum Günü)'),
                ),
                const SizedBox(height: 14),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: isDark ? AppColors.darkSurface : AppColors.background,
                  leading: const Icon(Icons.cake_rounded, color: AppColors.primary),
                  title: Text(DateFormat('d MMMM yyyy').format(targetDate)),
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
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
                child: const Text('Ekle'),
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
        label: Text(_tabController.index == 0 ? 'Anı Ekle' : 'Sayaç Ekle', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMemoryBookTab(ThemeData theme, bool isDark, AppLocalizations l10n) {
    final memoriesProvider = Provider.of<MemoriesProvider>(context);
    final memories = memoriesProvider.memories;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Annual Book Export Banner (Premium feature)
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            );
          },
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
                    color: AppColors.accentGold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: AppColors.accentGold, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Yıllık Anı Kitabı',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('PREMIUM', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tüm anılarınızı şık bir dijital kitaba veya PDF çıktısına dönüştürün.',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        ...memories.map((memory) {
          final dateStr = DateFormat('d MMMM yyyy').format(memory.date);
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
                        // Photo Count Badge
                        if (totalPhotos > 1)
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.photo_library_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$totalPhotos Fotoğraf',
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
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                memory.mood!,
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
                              children: const [
                                Text('İncele', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
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
                color: AppColors.primary.withOpacity(0.3),
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
                '$daysTogether Gündür',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Aynı sevgiyle, her geçen gün daha güçlü ❤️',
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
                      color: item.isAnniversary ? AppColors.primarySoft : AppColors.secondarySoft.withOpacity(isDark ? 0.2 : 0.8),
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
                          DateFormat('d MMMM yyyy').format(item.targetDate),
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
                      isPast ? '$days gün geçti' : '$days gün kaldı',
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
