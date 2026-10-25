import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_links.dart';
import '../../../core/constants/revenuecat_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/subscription_plan.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/services/purchase_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlanIndex = 1; // Default to Yearly (Best Value)
  bool _isLoading = false;
  Package? _monthlyPackage;
  Package? _yearlyPackage;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    if (!RevenueCatConstants.isConfigured) return;
    try {
      final offerings = await PurchaseService.instance.getOfferings();
      if (offerings != null && offerings.current != null) {
        if (!mounted) return;
        setState(() {
          _monthlyPackage = offerings.current!.monthly;
          _yearlyPackage = offerings.current!.annual;
        });
      }
    } catch (e) {
      debugPrint('PaywallScreen: error loading offerings: $e');
    }
  }

  final List<SubscriptionPlan> _plans = const [
    SubscriptionPlan(
      id: 'yanyana_monthly',
      titleTr: 'Aylık Üyelik',
      titleEn: 'Monthly Plan',
      priceTr: '₺79,99 / Ay',
      priceEn: '\$4.99 / Month',
      periodTr: 'Her ay yenilenir',
      periodEn: 'Renews monthly',
      trialDays: 7,
      isFeatured: false,
    ),
    SubscriptionPlan(
      id: 'yanyana_yearly',
      titleTr: 'Yıllık Üyelik (En Popüler)',
      titleEn: 'Annual Plan (Best Value)',
      priceTr: '₺599,99 / Yıl',
      priceEn: '\$39.99 / Year',
      periodTr: 'Aylık sadece ₺49,99\'a gelir (%38 Tasarruf)',
      periodEn: 'Only \$3.33 / month (Save 38%)',
      badgeTr: '%38 İNDİRİMLİ',
      badgeEn: 'SAVE 38%',
      trialDays: 7,
      isFeatured: true,
    ),
  ];

  void _showMessage(String text, {Color color = Colors.redAccent}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  Future<void> _handlePurchase() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    if (!RevenueCatConstants.isConfigured) {
      _showMessage(l10n.text('purchase_err_notConfigured'), color: Colors.orange);
      return;
    }

    final selectedPackage = _selectedPlanIndex == 1 ? _yearlyPackage : _monthlyPackage;
    if (selectedPackage == null) {
      _showMessage(l10n.text('offerings_unavailable'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final outcome = await PurchaseService.instance.purchase(selectedPackage);
      if (!mounted) return;

      switch (outcome) {
        case PurchaseOutcome.success:
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

    if (!RevenueCatConstants.isConfigured) {
      _showMessage(l10n.text('purchase_err_notConfigured'), color: Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isRestored = await PurchaseService.instance.restore();
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
    final lang = appState.currentLanguage;

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
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontSize: 12,
              ),
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
            const SizedBox(height: 24),

            // Feature List Cards
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
              ),
              child: Column(
                children: PremiumFeatures.features.map((f) {
                  final title = lang == 'en' ? f['title_en']! : f['title_tr']!;
                  final desc = lang == 'en' ? f['desc_en']! : f['desc_tr']!;

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
                          child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              Text(
                                desc,
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
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

            // Plan Selector (Monthly vs Yearly)
            ..._plans.asMap().entries.map((entry) {
              final idx = entry.key;
              final plan = entry.value;
              final isSelected = _selectedPlanIndex == idx;

              return GestureDetector(
                onTap: () => setState(() => _selectedPlanIndex = idx),
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
                            Row(
                              children: [
                                Text(
                                  plan.getTitle(lang),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isSelected ? AppColors.primary : null,
                                  ),
                                ),
                                if (plan.getBadge(lang) != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentGold,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      plan.getBadge(lang)!,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              plan.getPeriod(lang),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Builder(builder: (_) {
                        String displayPrice = plan.getPrice(lang);
                        if (idx == 0 && _monthlyPackage != null) {
                          displayPrice = '${_monthlyPackage!.storeProduct.priceString} / ${lang == 'en' ? 'Month' : 'Ay'}';
                        } else if (idx == 1 && _yearlyPackage != null) {
                          displayPrice = '${_yearlyPackage!.storeProduct.priceString} / ${lang == 'en' ? 'Year' : 'Yıl'}';
                        }
                        return Text(
                          displayPrice,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 18),

            // Start Trial Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handlePurchase,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(l10n.text('start_trial_btn')),
            ),
            const SizedBox(height: 12),

            // Transparent Trial Disclosure (Apple & Google Play Policy requirement)
            Text(
              l10n.text('trial_info'),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.text('auto_renew_info'),
              style: TextStyle(
                fontSize: 10.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                height: 1.4,
              ),
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
}
