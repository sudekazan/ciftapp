import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_links.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/subscription_plan.dart';
import '../../../core/premium/limits.dart';
import '../../../core/premium/plan_pricing.dart';
import '../../../core/premium/premium_gate.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/purchase_service.dart';

enum _OfferingsState { loading, loaded, failed }

class PaywallScreen extends StatefulWidget {
  final PaywallSource source;
  final PurchaseGateway? purchases;

  const PaywallScreen({super.key, this.source = PaywallSource.profile, this.purchases});

  /// Explains which limit opened the paywall, or `null` for a plain paywall.
  static String? reasonText(AppLocalizations l10n, PaywallSource source) {
    return switch (source) {
      PaywallSource.memoryLimit => l10n.textf('paywall_reason_memoryLimit', {'n': Limits.freeMemories}),
      PaywallSource.photoLimit => l10n.textf('paywall_reason_photoLimit',
          {'n': Limits.freePhotosPerMemory, 'm': Limits.premiumPhotosPerMemory}),
      PaywallSource.pulseLimit => l10n.textf('paywall_reason_pulseLimit', {'n': Limits.freeDailyPulses}),
      PaywallSource.capsuleLimit => l10n.textf('paywall_reason_capsuleLimit', {'n': Limits.freeCapsulesPerMonth}),
      PaywallSource.questionArchive =>
        l10n.textf('paywall_reason_questionArchive', {'n': Limits.freeQuestionArchiveDays}),
      PaywallSource.questionPack => l10n.text('paywall_reason_questionPack'),
      PaywallSource.profile || PaywallSource.onboarding => null,
    };
  }

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late final PurchaseGateway _purchases = widget.purchases ?? PurchaseService.instance;

  bool _yearlySelected = true; // Yearly is the main product.
  bool _isLoading = false;
  _OfferingsState _offeringsState = _OfferingsState.loading;
  Package? _monthlyPackage;
  Package? _yearlyPackage;
  final Map<String, int?> _trialDays = {};

  Package? get _selectedPackage => _yearlySelected ? _yearlyPackage : _monthlyPackage;

  @override
  void initState() {
    super.initState();
    AnalyticsService.log('paywall_shown', {'source': widget.source.name});
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() => _offeringsState = _OfferingsState.loading);
    final current = _purchases.isConfigured ? (await _purchases.getOfferings())?.current : null;
    final monthly = current?.monthly;
    final yearly = current?.annual;
    // Trial text depends on whether this user can still get the trial.
    for (final package in [monthly, yearly].whereType<Package>()) {
      _trialDays[package.identifier] = await _purchases.eligibleTrialDays(package);
    }
    if (!mounted) return;
    setState(() {
      _monthlyPackage = monthly;
      _yearlyPackage = yearly;
      _offeringsState =
          monthly == null && yearly == null ? _OfferingsState.failed : _OfferingsState.loaded;
      if (yearly == null) _yearlySelected = false;
    });
  }

  void _showMessage(String text, {Color color = Colors.redAccent}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  Future<void> _handlePurchase() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    final selectedPackage = _selectedPackage;
    if (selectedPackage == null) {
      _showMessage(l10n.text('offerings_unavailable'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final outcome = await _purchases.purchase(selectedPackage);
      if (!mounted) return;

      switch (outcome) {
        case PurchaseOutcome.success:
          final trialDays = _trialDays[selectedPackage.identifier];
          AnalyticsService.log(trialDays != null ? 'trial_started' : 'purchase', {
            'product': selectedPackage.storeProduct.identifier,
            'source': widget.source.name,
          });
          await appState.upgradeToPremium();
          if (!mounted) return;
          Navigator.of(context).pop();
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.text('premium_activated'))),
                ],
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        case PurchaseOutcome.pending:
          _showMessage(l10n.text('purchase_pending'), color: AppColors.secondary);
        case PurchaseOutcome.cancelled:
          break;
      }
    } on PurchaseFailure catch (e) {
      if (mounted) _showMessage(l10n.text('purchase_err_${e.reason.name}'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    final nav = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    setState(() => _isLoading = true);

    try {
      final isRestored = await _purchases.restore();
      if (!mounted) return;

      if (isRestored) {
        await appState.upgradeToPremium();
        _showMessage(l10n.text('restore_success'), color: AppColors.primary);
        nav.pop();
      } else {
        _showMessage(l10n.text('restore_none'), color: Colors.grey);
      }
    } on PurchaseFailure catch (e) {
      if (mounted) _showMessage(l10n.text('purchase_err_${e.reason.name}'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final selected = _selectedPackage;
    final trialDays = selected == null ? null : _trialDays[selected.identifier];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFFBFBFE),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleRestore,
            child: Text(
              l10n.text('restore_purchases'),
              style: TextStyle(color: secondaryText, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          children: [
            // Header
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.heartGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.text('premium_title'),
              style: theme.textTheme.displayLarge?.copyWith(fontSize: 26, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.text('premium_subtitle'),
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (PaywallScreen.reasonText(l10n, widget.source) case final reason?) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_open_rounded, color: AppColors.accentGold, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(reason, style: const TextStyle(fontSize: 12.5, height: 1.35))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Feature list: only features that really work in the app.
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
              ),
              child: Column(
                children: PremiumFeature.all(l10n).map((f) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(f.icon, color: AppColors.primary, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              Text(f.description, style: TextStyle(color: secondaryText, fontSize: 11.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            ..._buildPlans(l10n, appState.currentLanguage, isDark, secondaryText),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: _isLoading || selected == null ? null : _handlePurchase,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(trialDays != null
                      ? l10n.textf('start_trial_btn', {'n': trialDays})
                      : l10n.text('subscribe_btn')),
            ),
            const SizedBox(height: 12),

            // Transparent trial disclosure, only for users who can still get it
            // (Apple & Google Play policy requirement).
            if (trialDays != null && selected != null) ...[
              Text(
                l10n.textf('trial_info', {
                  'n': trialDays,
                  'price': '${selected.storeProduct.priceString} / '
                      '${l10n.text(_yearlySelected ? 'per_year' : 'per_month')}',
                }),
                style: TextStyle(fontSize: 11, color: secondaryText, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
            ],
            Text(
              l10n.text('auto_renew_info'),
              style: TextStyle(fontSize: 10.5, color: secondaryText, height: 1.4),
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  key: const Key('paywall_privacy_link'),
                  onPressed: () => AppLinks.open(context, AppLinks.privacyPolicy),
                  child: Text(l10n.text('privacy_policy'), style: const TextStyle(fontSize: 12)),
                ),
                const Text('•'),
                TextButton(
                  key: const Key('paywall_terms_link'),
                  onPressed: () => AppLinks.open(context, AppLinks.termsOfUse),
                  child: Text(l10n.text('terms_of_use'), style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlans(AppLocalizations l10n, String lang, bool isDark, Color secondaryText) {
    switch (_offeringsState) {
      case _OfferingsState.loading:
        return [
          const SizedBox(height: 12),
          const CircularProgressIndicator(),
          const SizedBox(height: 10),
          Text(l10n.text('offerings_loading'), style: TextStyle(color: secondaryText, fontSize: 12)),
        ];
      case _OfferingsState.failed:
        return [
          Text(
            l10n.text('offerings_unavailable'),
            style: TextStyle(color: secondaryText, fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
          TextButton.icon(
            onPressed: _loadOfferings,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.text('retry')),
          ),
        ];
      case _OfferingsState.loaded:
        final monthly = _monthlyPackage;
        final yearly = _yearlyPackage;
        final savings = monthly != null && yearly != null
            ? PlanPricing.savingsPercent(
                monthlyPrice: monthly.storeProduct.price,
                yearlyPrice: yearly.storeProduct.price,
              )
            : null;
        return [
          if (yearly != null)
            _planTile(
              isSelected: _yearlySelected,
              onTap: () => setState(() => _yearlySelected = true),
              title: l10n.text('yearly_plan'),
              badge: savings == null ? null : l10n.textf('plan_savings_badge', {'p': savings}),
              detail: () {
                final perMonth = PlanPricing.monthlyEquivalent(
                  yearlyPrice: yearly.storeProduct.price,
                  currencyCode: yearly.storeProduct.currencyCode,
                  locale: lang,
                );
                return savings == null
                    ? l10n.textf('plan_yearly_detail', {'price': perMonth})
                    : l10n.textf('plan_yearly_detail_savings', {'price': perMonth, 'p': savings});
              }(),
              price: '${yearly.storeProduct.priceString} / ${l10n.text('per_year')}',
              isDark: isDark,
              secondaryText: secondaryText,
            ),
          if (monthly != null)
            _planTile(
              isSelected: !_yearlySelected,
              onTap: () => setState(() => _yearlySelected = false),
              title: l10n.text('monthly_plan'),
              detail: l10n.text('plan_renews_monthly'),
              price: '${monthly.storeProduct.priceString} / ${l10n.text('per_month')}',
              isDark: isDark,
              secondaryText: secondaryText,
            ),
        ];
    }
  }

  Widget _planTile({
    required bool isSelected,
    required VoidCallback onTap,
    required String title,
    required String detail,
    required String price,
    required bool isDark,
    required Color secondaryText,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryDark.withValues(alpha: 0.3) : AppColors.primarySoft)
              : (isDark ? AppColors.darkCardBg : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkDivider : AppColors.divider),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isSelected ? AppColors.primary : null,
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(detail, style: TextStyle(fontSize: 11, color: secondaryText)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(price, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
