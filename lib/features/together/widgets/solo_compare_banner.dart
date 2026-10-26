import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/widgets/invite_partner_sheet.dart';

/// Replaces a quiz's score banner before pairing: answers are kept and
/// compared once the partner joins.
class SoloCompareBanner extends StatelessWidget {
  final Gradient gradient;
  final IconData icon;

  const SoloCompareBanner({super.key, required this.gradient, required this.icon});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
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
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.text('solo_quiz_banner'),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.3),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => InvitePartnerSheet.show(
                    context,
                    source: 'quiz',
                    message: l10n.text('solo_quiz_sheet'),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(l10n.text('invite_btn')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    // The theme's full-width minimum size would stretch the button.
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
