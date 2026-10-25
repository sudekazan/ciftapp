import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/relationship_mode.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../profile/screens/mode_switch_sheet.dart';
import '../../profile/screens/profile_settings_screen.dart';
import '../widgets/coliving_summary_card.dart';
import '../widgets/countdown_hero_card.dart';
import '../widgets/daily_question_preview_card.dart';
import '../widgets/distance_header_card.dart';
import '../widgets/dual_clock_card.dart';
import '../widgets/thinking_of_you_button.dart';

class HomeScreen extends StatelessWidget {
  final Function(int)? onTabChangeRequested;

  const HomeScreen({super.key, this.onTabChangeRequested});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final user = appState.currentUser;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                gradient: AppColors.heartGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.text('app_name'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          // Mode switch button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                user.mode == RelationshipMode.longDistance
                    ? Icons.flight_takeoff_rounded
                    : Icons.home_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            tooltip: l10n.text('mode_switch_title'),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ModeSwitchSheet(),
              );
            },
          ),
          // Profile & Settings
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.divider,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
            ),
            tooltip: l10n.text('profile_title'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Distance & Couple Header
              const DistanceHeaderCard(),
              const SizedBox(height: 16),

              // 2. Mode-Dependent Section
              if (user.mode == RelationshipMode.longDistance) ...[
                // Long Distance Mode: Thinking of you button
                const ThinkingOfYouButton(),
                const SizedBox(height: 16),

                // Reunion Countdown Hero
                CountdownHeroCard(
                  onOpenPlans: () => onTabChangeRequested?.call(2), // Plans tab
                ),
                const SizedBox(height: 16),

                // Dual Clock Card
                const DualClockCard(),
                const SizedBox(height: 16),
              ] else ...[
                // Co-Living Mode: Shared tasks and shopping
                ColivingSummaryCard(
                  onOpenPlans: () => onTabChangeRequested?.call(2),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Daily Question Preview (Common to both modes)
              DailyQuestionPreviewCard(
                onOpenTogether: () => onTabChangeRequested?.call(3), // Together tab
              ),
            ],
          ),
        ),
      ),
    );
  }
}
