import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_links.dart';
import '../../../core/localization/app_localizations.dart';

class PrivacyPolicySheet extends StatelessWidget {
  const PrivacyPolicySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

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
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.security_rounded, color: AppColors.primary, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.text('privacy_sheet_title'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                l10n.text('privacy_sheet_body'),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => AppLinks.open(context, AppLinks.privacyPolicy),
                child: Text(l10n.text('privacy_full')),
              ),
              TextButton(
                onPressed: () => AppLinks.open(context, AppLinks.termsOfUse),
                child: Text(l10n.text('terms_of_use')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.text('got_it')),
          ),
        ],
      ),
    );
  }
}
