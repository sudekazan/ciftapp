import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/providers/together_provider.dart';

class DailyQuestionPreviewCard extends StatelessWidget {
  final VoidCallback onOpenTogether;
  const DailyQuestionPreviewCard({super.key, required this.onOpenTogether});

  @override
  Widget build(BuildContext context) {
    final togetherProvider = Provider.of<TogetherProvider>(context);
    final appState = Provider.of<AppStateProvider>(context);
    final question = togetherProvider.todaysQuestion;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.text('daily_question_title'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: question.isRevealed
                      ? AppColors.accentTeal.withValues(alpha: 0.12)
                      : AppColors.accentGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      question.isRevealed ? Icons.lock_open_rounded : Icons.lock_rounded,
                      size: 13,
                      color: question.isRevealed ? AppColors.accentTeal : AppColors.accentGold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      question.isRevealed ? 'Cevaplar Açık' : 'Kilitli',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: question.isRevealed ? AppColors.accentTeal : AppColors.accentGold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            question.getQuestion(appState.currentLanguage),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          if (question.isRevealed)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'İkiniz de cevapladınız! Cevapları okumak için dokunun.',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ],
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: onOpenTogether,
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: Text(l10n.text('answer_btn')),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
            ),
        ],
      ),
    );
  }
}
