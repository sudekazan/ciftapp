import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/providers/together_provider.dart';

class CoupleQuizScreen extends StatelessWidget {
  const CoupleQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final togetherProvider = Provider.of<TogetherProvider>(context);
    final appState = Provider.of<AppStateProvider>(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final quizList = togetherProvider.coupleQuiz;
    final matchCount = togetherProvider.quizMatchCount;
    final partnerName = appState.currentUser.partnerName ?? 'Can';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text('quiz_how_well')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.purpleGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uyum Skoru: %${((matchCount / quizList.length) * 100).round()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$matchCount / ${quizList.length} soruda aynı cevabı verdiniz! 🎉',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ...quizList.asMap().entries.map((entry) {
              final index = entry.key;
              final q = entry.value;
              final questionText = appState.currentLanguage == 'en' ? q.questionEn : q.questionTr;
              final options = appState.currentLanguage == 'en' ? q.optionsEn : q.optionsTr;

              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Soru ${index + 1}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          if (q.isMatch)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentTeal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.favorite_rounded, color: AppColors.accentTeal, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Eşleşti!',
                                    style: TextStyle(color: AppColors.accentTeal, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        questionText,
                        style: theme.textTheme.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),

                      // Options
                      ...options.asMap().entries.map((opt) {
                        final optIndex = opt.key;
                        final optText = opt.value;
                        final isMyChoice = q.mySelectedIndex == optIndex;
                        final isPartnerChoice = q.partnerSelectedIndex == optIndex;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isMyChoice
                                ? (isDark ? AppColors.primaryDark.withValues(alpha: 0.4) : AppColors.primarySoft)
                                : (isDark ? AppColors.darkSurface : AppColors.background),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isMyChoice ? AppColors.primary : Colors.transparent,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            onTap: () {
                              togetherProvider.answerQuizQuestion(q.id, optIndex);
                            },
                            title: Text(
                              optText,
                              style: TextStyle(
                                fontWeight: isMyChoice ? FontWeight.bold : FontWeight.normal,
                                color: isMyChoice ? AppColors.primary : null,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isMyChoice)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Sen', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                if (isPartnerChoice) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(partnerName, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
