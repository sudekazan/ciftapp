import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_links.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/subscription_plan.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/services/purchase_service.dart';

/// Shown to premium users instead of the paywall: plan, renewal date and a
/// link to manage or cancel the subscription in the store.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _restoring = false;

  static String get _storeSubscriptionsUrl => Platform.isIOS
      ? 'https://apps.apple.com/account/subscriptions'
      : 'https://play.google.com/store/account/subscriptions';

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    setState(() => _restoring = true);
    try {
      final restored = await PurchaseService.instance.restore();
      if (restored) await appState.upgradeToPremium();
      messenger.showSnackBar(SnackBar(content: Text(l10n.text(restored ? 'restore_success' : 'restore_none'))));
    } on PurchaseFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.text('purchase_err_${e.reason.name}'))));
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMMM yyyy', appState.currentLanguage);
    final subscription = appState.subscription;

    final String planName;
    final String? statusLine;
    if (appState.isPremiumFromPartner) {
      planName = l10n.textf('subscription_from_partner', {'name': appState.currentUser.partnerName ?? 'Partner'});
      final until = appState.couplePremiumUntil;
      statusLine = until == null ? null : l10n.textf('subscription_from_partner_until', {'date': dateFormat.format(until)});
    } else {
      final productId = subscription?.productId ?? '';
      planName = l10n.text(productId.contains('year')
          ? 'subscription_plan_yearly'
          : productId.contains('month')
              ? 'subscription_plan_monthly'
              : productId.contains('lifetime')
                  ? 'lifetime_plan'
                  : 'subscription_plan_unknown');
      final expires = subscription?.expiresAt;
      statusLine = expires == null
          ? null
          : l10n.textf(subscription!.willRenew ? 'subscription_renews_on' : 'subscription_ends_on',
              {'date': dateFormat.format(expires.toLocal())});
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('subscription_title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.purpleGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 36),
                const SizedBox(height: 12),
                Text(
                  planName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (subscription?.isTrial ?? false) ...[
                  const SizedBox(height: 6),
                  Text(l10n.text('subscription_trial'), style: const TextStyle(color: Colors.white)),
                ],
                if (statusLine != null) ...[
                  const SizedBox(height: 6),
                  Text(statusLine, style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: PremiumFeature.all(l10n)
                  .map((f) => ListTile(
                        leading: Icon(f.icon, color: AppColors.primary),
                        title: Text(f.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(f.description, style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          if (!appState.isPremiumFromPartner) ...[
            ElevatedButton.icon(
              onPressed: () => AppLinks.open(context, subscription?.managementUrl ?? _storeSubscriptionsUrl),
              icon: const Icon(Icons.manage_accounts_rounded),
              label: Text(l10n.text('subscription_manage')),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.text('subscription_manage_hint'),
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11.5),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: _restoring ? null : _restore,
            child: _restoring
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.text('restore_purchases')),
          ),
        ],
      ),
    );
  }
}
