import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/account_service.dart';

/// Apple / Google buttons for the providers configured on this platform.
class AccountProviderButtons extends StatelessWidget {
  final List<AccountProvider> providers;
  final bool busy;
  final ValueChanged<AccountProvider> onPressed;

  const AccountProviderButtons({
    super.key,
    required this.providers,
    required this.onPressed,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final provider in providers) ...[
          OutlinedButton.icon(
            onPressed: busy ? null : () => onPressed(provider),
            icon: Icon(provider == AccountProvider.apple ? Icons.apple_rounded : Icons.g_mobiledata_rounded, size: 24),
            label: Text(l10n.text(provider == AccountProvider.apple ? 'account_with_apple' : 'account_with_google')),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Profile card that links the anonymous account to Apple / Google so data
/// survives a phone change. Hidden when no provider is configured.
class AccountBackupCard extends StatefulWidget {
  const AccountBackupCard({super.key});

  @override
  State<AccountBackupCard> createState() => _AccountBackupCardState();
}

class _AccountBackupCardState extends State<AccountBackupCard> {
  bool _busy = false;

  Future<void> _link(AccountProvider provider) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final result = await AccountService.instance.link(provider);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result != LinkResult.cancelled) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.text('account_link_${result.name}'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = AccountService.instance;
    final available = accounts.availableProviders;
    final linked = accounts.linkedProviders;
    if (available.isEmpty && linked.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(linked.isEmpty ? Icons.cloud_off_rounded : Icons.verified_user_rounded,
                    color: linked.isEmpty ? AppColors.accentGold : AppColors.accentTeal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.text(linked.isEmpty ? 'account_backup_title' : 'account_backup_done'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              linked.isEmpty
                  ? l10n.text('account_backup_desc')
                  : l10n.textf('account_backup_linked', {
                      'provider': linked.map((p) => p == AccountProvider.apple ? 'Apple' : 'Google').join(', '),
                    }),
              style: const TextStyle(fontSize: 12.5),
            ),
            if (linked.isEmpty) ...[
              const SizedBox(height: 12),
              AccountProviderButtons(providers: available, busy: _busy, onPressed: _link),
            ],
          ],
        ),
      ),
    );
  }
}
