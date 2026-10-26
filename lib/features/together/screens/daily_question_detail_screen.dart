import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/premium/limits.dart';
import '../../../core/premium/premium_gate.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/providers/together_provider.dart';
import '../../auth/widgets/invite_partner_sheet.dart';

class DailyQuestionDetailScreen extends StatefulWidget {
  const DailyQuestionDetailScreen({super.key});

  @override
  State<DailyQuestionDetailScreen> createState() => _DailyQuestionDetailScreenState();
}

class _DailyQuestionDetailScreenState extends State<DailyQuestionDetailScreen> {
  final TextEditingController _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _submitAnswer() {
    final text = _answerController.text.trim();
    if (text.isEmpty) return;

    final togetherProvider = Provider.of<TogetherProvider>(context, listen: false);
    togetherProvider.submitMyAnswer(text);

    _answerController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).text('dq_answer_saved')),
        backgroundColor: AppColors.primary,
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
    final partnerName = appState.currentUser.partnerName ?? l10n.text('partner');

    final isPremium = appState.currentUser.isPremium;
    final archive = togetherProvider.archive(Limits.questionArchiveDays(premium: isPremium));
    final hasLockedArchive = !isPremium &&
        togetherProvider.archive(Limits.premiumQuestionArchiveDays).length > archive.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text('daily_question_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question Hero Banner
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.darkCardGradient : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DateFormat('d MMMM yyyy, EEEE', appState.currentLanguage).format(question.date),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    question.getQuestion(appState.currentLanguage),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // User Answer Section
            Text(
              l10n.text('your_answer'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (question.isMyAnswered && question.myAnswer != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.myAnswer!,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  TextField(
                    controller: _answerController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: l10n.text('write_your_answer'),
                      fillColor: isDark ? AppColors.darkSurface : AppColors.background,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _submitAnswer,
                    child: Text(l10n.text('save')),
                  ),
                ],
              ),

            const SizedBox(height: 28),

            // Partner's Answer Section
            Text(
              l10n.textf('dq_partner_answer_title', {'name': partnerName}),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (!appState.currentUser.isPaired)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.favorite_border_rounded, color: AppColors.primary, size: 32),
                    const SizedBox(height: 10),
                    Text(
                      l10n.text('solo_dq_locked'),
                      style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => InvitePartnerSheet.show(
                        context,
                        source: 'daily_question',
                        message: l10n.text('solo_dq_sheet'),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: Text(l10n.text('invite_btn')),
                    ),
                  ],
                ),
              )
            else if (!question.isMyAnswered)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.divider.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_rounded, color: AppColors.textSecondary, size: 32),
                    const SizedBox(height: 10),
                    Text(
                      l10n.text('dq_partner_locked'),
                      style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.text('daily_question_locked'),
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.favorite_rounded, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.partnerAnswer ?? l10n.text('dq_partner_not_answered'),
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 36),

            // Past Questions Archive
            Text(
              l10n.text('dq_archive_title'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...archive.map(
              (pq) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    pq.getQuestion(appState.currentLanguage),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    DateFormat('d MMMM yyyy', appState.currentLanguage).format(pq.date),
                    style: const TextStyle(fontSize: 11),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          Text('${l10n.text('you')}: ${pq.myAnswer ?? "-"}', style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('$partnerName: ${pq.partnerAnswer ?? "-"}', style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (hasLockedArchive)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lock_rounded, color: AppColors.accentGold),
                  title: Text(
                    l10n.textf('archive_locked', {'n': Limits.freeQuestionArchiveDays}),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.workspace_premium_rounded, color: AppColors.accentGold),
                  onTap: () => PremiumGate.openPaywall(context, PaywallSource.questionArchive),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
