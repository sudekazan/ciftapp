import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/services/invite_service.dart';
import '../screens/pairing_screen.dart';

/// Shown when an unpaired user taps a feature that needs a partner (pulse,
/// clock, answers). Explains why and offers the invite code right there.
class InvitePartnerSheet extends StatelessWidget {
  /// Analytics source of the `invite_shared` event, e.g. `pulse`.
  final String source;

  /// Feature-specific explanation; a generic one is used when null.
  final String? message;

  const InvitePartnerSheet({super.key, required this.source, this.message});

  static Future<void> show(BuildContext context, {required String source, String? message}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => InvitePartnerSheet(source: source, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final code = Provider.of<AppStateProvider>(context).currentUser.inviteCode;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(gradient: AppColors.heartGradient, shape: BoxShape.circle),
                child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.text('invite_sheet_title'),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 19),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message ?? l10n.text('invite_sheet_body'),
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.vpn_key_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.text('setup_your_code'), style: const TextStyle(fontSize: 11, color: AppColors.primaryDark)),
                        Text(
                          code,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.text('copy'),
                    icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.text('setup_copied_snack'))),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Builder(
              builder: (buttonContext) => ElevatedButton.icon(
                onPressed: () => InviteService.share(buttonContext, code, source: source),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(l10n.text('invite_partner_btn')),
              ),
            ),
            TextButton(
              onPressed: () {
                final nav = Navigator.of(context);
                nav.pop();
                nav.push(MaterialPageRoute(builder: (_) => const PairingScreen(isModal: true)));
              },
              child: Text(l10n.text('setup_have_code_title')),
            ),
          ],
        ),
      ),
    );
  }
}
