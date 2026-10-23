import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/providers/together_provider.dart';
import 'couple_quiz_screen.dart';
import 'daily_question_detail_screen.dart';
import 'who_more_quiz_screen.dart';

class TogetherScreen extends StatelessWidget {
  const TogetherScreen({super.key});

  void _showAddWatchlistDialog(BuildContext context) {
    final titleController = TextEditingController();
    String type = 'movie';
    String platform = 'Netflix';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('İzleme Listesine Ekle'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Film / Dizi Adı'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: type,
                        decoration: const InputDecoration(labelText: 'Tür'),
                        items: const [
                          DropdownMenuItem(value: 'movie', child: Text('Film 🎬')),
                          DropdownMenuItem(value: 'series', child: Text('Dizi 📺')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => type = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: platform,
                        decoration: const InputDecoration(labelText: 'Platform'),
                        items: const [
                          DropdownMenuItem(value: 'Netflix', child: Text('Netflix')),
                          DropdownMenuItem(value: 'Prime Video', child: Text('Prime')),
                          DropdownMenuItem(value: 'BluTV', child: Text('BluTV')),
                          DropdownMenuItem(value: 'MUBI', child: Text('MUBI')),
                          DropdownMenuItem(value: 'Sinema', child: Text('Sinema')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => platform = val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty) {
                    final appState = Provider.of<AppStateProvider>(context, listen: false);
                    Provider.of<TogetherProvider>(context, listen: false).addWatchlistItem(
                      titleController.text.trim(),
                      type: type,
                      platform: platform,
                      addedBy: appState.currentUser.name,
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
    final togetherProvider = Provider.of<TogetherProvider>(context);
    final appState = Provider.of<AppStateProvider>(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final question = togetherProvider.todaysQuestion;
    final watchlist = togetherProvider.watchlist;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text('together_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Daily Question Hero Box
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DailyQuestionDetailScreen()),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(22),
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
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.text('daily_question_title'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            question.isRevealed ? 'Cevaplandı ✨' : 'Bekleniyor',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      question.getQuestion(appState.currentLanguage),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text(
                          'Detaylar ve Cevaplar',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section 1: Couple Games
            Text(
              l10n.text('section_games'),
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CoupleQuizScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBg : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.secondarySoft.withValues(alpha: isDark ? 0.2 : 0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.psychology_rounded, color: AppColors.secondary, size: 24),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.text('quiz_how_well'),
                            style: theme.textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '3 soru • Uyum skoru',
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WhoMoreQuizScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBg : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.people_outline_rounded, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.text('quiz_who_more'),
                            style: theme.textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Eğlenceli seçimler',
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Section 2: Shared Watchlist
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.text('section_watchlist'),
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                  tooltip: 'Film / Dizi Ekle',
                  onPressed: () => _showAddWatchlistDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...watchlist.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: IconButton(
                    icon: Icon(
                      item.isWatched ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded,
                      color: item.isWatched ? AppColors.accentTeal : AppColors.primary,
                      size: 26,
                    ),
                    onPressed: () => togetherProvider.toggleWatchlistItem(item.id),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: item.isWatched ? TextDecoration.lineThrough : null,
                      color: item.isWatched ? AppColors.textSecondary : null,
                    ),
                  ),
                  subtitle: Text(
                    '${item.platform} • Ekleyen: ${item.addedBy}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.textSecondary),
                    onPressed: () => togetherProvider.deleteWatchlistItem(item.id),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
