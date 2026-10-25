import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/content/question_catalog.dart';
import '../../../core/premium/premium_gate.dart';

/// Chips to switch between question packs; locked premium packs open the paywall.
class PackSelector extends StatelessWidget {
  final List<QuestionPack> packs;
  final String selectedId;
  final String lang;
  final bool isPremium;
  final ValueChanged<String> onSelected;

  const PackSelector({
    super.key,
    required this.packs,
    required this.selectedId,
    required this.lang,
    required this.isPremium,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: packs.map((pack) {
        final locked = pack.isPremium && !isPremium;
        return ChoiceChip(
          avatar: locked
              ? const Icon(Icons.lock_rounded, size: 16, color: AppColors.accentGold)
              : (pack.isPremium ? const Icon(Icons.workspace_premium_rounded, size: 16, color: AppColors.accentGold) : null),
          label: Text(pack.getTitle(lang)),
          selected: pack.id == selectedId,
          onSelected: (_) {
            if (locked) {
              PremiumGate.openPaywall(context, PaywallSource.questionPack);
            } else {
              onSelected(pack.id);
            }
          },
        );
      }).toList(),
    );
  }
}
