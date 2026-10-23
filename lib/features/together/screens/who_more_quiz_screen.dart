import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/providers/together_provider.dart';

class WhoMoreQuizScreen extends StatelessWidget {
  const WhoMoreQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final togetherProvider = Provider.of<TogetherProvider>(context);
    final appState = Provider.of<AppStateProvider>(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final list = togetherProvider.whoMoreList;
    final agreedCount = togetherProvider.whoMoreAgreementCount;
    final totalVoted = list.where((q) => q.isBothVoted).length;

    final myName = appState.currentUser.name;
    final partnerName = appState.currentUser.partnerName ?? 'Can';

    final percent = totalVoted > 0 ? ((agreedCount / totalVoted) * 100).round() : 100;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text('quiz_who_more')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score Banner
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ortak Görüş: %$percent',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalVoted sorudan $agreedCount tanesinde aynı cevabı verdiniz! 🎉',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            ...list.asMap().entries.map((entry) {
              final index = entry.key;
              final q = entry.value;
              final questionText = appState.currentLanguage == 'en' ? q.questionEn : q.questionTr;

              final isVoted = q.myVote != null;
              final isAgreed = q.isAgreed;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SORU ${index + 1}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                          if (isVoted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isAgreed
                                    ? AppColors.accentTeal.withValues(alpha: 0.15)
                                    : AppColors.accentGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAgreed ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                    size: 13,
                                    color: isAgreed ? AppColors.accentTeal : AppColors.accentGold,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAgreed ? 'Aynı Fikirdeyiz! 🎉' : 'Farklı Düşünce 😄',
                                    style: TextStyle(
                                      color: isAgreed ? AppColors.accentTeal : AppColors.accentGold,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(
                        questionText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Vote Buttons: [Me] or [Partner]
                      Row(
                        children: [
                          Expanded(
                            child: _buildVoteButton(
                              context: context,
                              theme: theme,
                              isDark: isDark,
                              label: '$myName (Ben)',
                              voteKey: 'me',
                              isSelected: q.myVote == 'me',
                              isPartnerChoice: q.partnerVote == 'me',
                              onTap: () => togetherProvider.voteWhoMore(q.id, 'me'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildVoteButton(
                              context: context,
                              theme: theme,
                              isDark: isDark,
                              label: partnerName,
                              voteKey: 'partner',
                              isSelected: q.myVote == 'partner',
                              isPartnerChoice: q.partnerVote == 'partner',
                              onTap: () => togetherProvider.voteWhoMore(q.id, 'partner'),
                            ),
                          ),
                        ],
                      ),

                      if (isVoted && q.partnerVote != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '$partnerName tercihi: ${q.partnerVote == "me" ? myName : partnerName}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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
  }

  Widget _buildVoteButton({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required String label,
    required String voteKey,
    required bool isSelected,
    required bool isPartnerChoice,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryDark.withValues(alpha: 0.4) : AppColors.primarySoft)
              : (isDark ? AppColors.darkSurface : AppColors.background),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkDivider : AppColors.divider),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              voteKey == 'me' ? Icons.person_rounded : Icons.favorite_rounded,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.primary : null,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
