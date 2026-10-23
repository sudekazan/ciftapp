import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/relationship_mode.dart';
import '../../../core/providers/app_state_provider.dart';

class ModeSwitchSheet extends StatelessWidget {
  const ModeSwitchSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentMode = appState.currentUser.mode;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.text('mode_switch_title'),
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.text('mode_switch_desc'),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          _buildModeTile(
            context: context,
            mode: RelationshipMode.longDistance,
            title: 'Uzak Mesafe Modu',
            desc: 'İki saat dilimi, buluşma geri sayımı ve "Seni Düşünüyorum" butonu öne çıkar.',
            icon: Icons.flight_takeoff_rounded,
            isSelected: currentMode == RelationshipMode.longDistance,
            theme: theme,
            isDark: isDark,
            onSelect: () {
              appState.setRelationshipMode(RelationshipMode.longDistance);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 14),

          _buildModeTile(
            context: context,
            mode: RelationshipMode.coLiving,
            title: 'Birlikte Yaşıyoruz Modu',
            desc: 'Bugünün planı, ortak ev görevleri ve alışveriş listesi öne çıkar.',
            icon: Icons.home_rounded,
            isSelected: currentMode == RelationshipMode.coLiving,
            theme: theme,
            isDark: isDark,
            onSelect: () {
              appState.setRelationshipMode(RelationshipMode.coLiving);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeTile({
    required BuildContext context,
    required RelationshipMode mode,
    required String title,
    required String desc,
    required IconData icon,
    required bool isSelected,
    required ThemeData theme,
    required bool isDark,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryDark.withValues(alpha: 0.3) : AppColors.primarySoft)
              : (isDark ? AppColors.darkSurface : AppColors.background),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkDivider : AppColors.divider),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCardBg : Colors.white),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected ? AppColors.primary : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
