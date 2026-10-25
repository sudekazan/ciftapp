import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/relationship_mode.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/providers/dreams_provider.dart';
import '../../../core/providers/memories_provider.dart';
import '../../../core/providers/plans_provider.dart';
import '../../../core/providers/together_provider.dart';
import '../../auth/screens/pairing_screen.dart';
import '../../premium/screens/paywall_screen.dart';
import 'mode_switch_sheet.dart';
import 'privacy_policy_sheet.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adını Güncelle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Adınız veya Takma Adınız',
            prefixIcon: Icon(Icons.person_rounded, color: AppColors.primary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                appState.updateUserName(newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showChangeStartDatePicker(BuildContext context, DateTime currentDate) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      await appState.updateRelationshipStartDate(picked);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Birliktelik başlangıç tarihiniz güncellendi! ❤️'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    var isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.text('delete_account')),
          content: isDeleting
              ? const SizedBox(height: 64, child: Center(child: CircularProgressIndicator()))
              : Text(l10n.text('delete_account_warning')),
          actions: isDeleting
              ? null
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.text('cancel')),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () async {
                      setDialogState(() => isDeleting = true);
                      final nav = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      final memories = Provider.of<MemoriesProvider>(context, listen: false);
                      final dreams = Provider.of<DreamsProvider>(context, listen: false);
                      final plans = Provider.of<PlansProvider>(context, listen: false);
                      final together = Provider.of<TogetherProvider>(context, listen: false);
                      await appState.deleteAccount();
                      await memories.clearAll();
                      await together.clearAll();
                      await dreams.clearAll();
                      await plans.clearAll();
                      if (ctx.mounted) Navigator.pop(ctx);
                      nav.popUntil((route) => route.isFirst);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.text('delete_account_done')),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    },
                    child: Text(l10n.text('delete_permanently')),
                  ),
                ],
        ),
      ),
    );
  }

  void _showUnpairDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    var isWorking = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.text('unpair_title')),
          content: isWorking
              ? const SizedBox(height: 64, child: Center(child: CircularProgressIndicator()))
              : Text(l10n.text('unpair_warning')),
          actions: isWorking
              ? null
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.text('cancel')),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () async {
                      setDialogState(() => isWorking = true);
                      final messenger = ScaffoldMessenger.of(context);
                      await appState.unpairCouple();
                      if (ctx.mounted) Navigator.pop(ctx);
                      messenger.showSnackBar(SnackBar(content: Text(l10n.text('unpair_done'))));
                    },
                    child: Text(l10n.text('unpair_btn')),
                  ),
                ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final user = appState.currentUser;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text('profile_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Profile Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      gradient: AppColors.heartGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0] : 'S',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _showEditNameDialog(context, user.name),
                              child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.isPaired
                              ? '${l10n.text('connected_with')} ${user.partnerName ?? "Partner"}'
                              : l10n.text('unpaired_warning'),
                          style: TextStyle(
                            color: user.isPaired ? AppColors.accentTeal : AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () => _showChangeStartDatePicker(context, user.relationshipStartDate),
                          child: Row(
                            children: [
                              Text(
                                '${user.daysTogether} ${l10n.text('profile_days_together_suffix')}',
                                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit_calendar_rounded, size: 13, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Premium Banner
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: user.isPremium ? AppColors.purpleGradient : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.isPremium ? l10n.text('profile_premium_active') : l10n.text('profile_upgrade_premium'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.isPremium
                              ? l10n.text('feature_single_payment')
                              : l10n.text('premium_subtitle'),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section 1: Partner & Mode & Dates
          _buildSectionHeader(theme, l10n.text('profile_section_relationship')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                  title: Text(l10n.text('profile_start_date')),
                  subtitle: Text(
                    '${DateFormat('d MMMM yyyy').format(user.relationshipStartDate)} (${user.daysTogether} ${l10n.text('days_together')})',
                  ),
                  trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                  onTap: () => _showChangeStartDatePicker(context, user.relationshipStartDate),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.favorite_outline_rounded, color: AppColors.primary),
                  title: Text(l10n.text('partner_pairing')),
                  subtitle: Text(user.isPaired ? '${l10n.text('your_invite_code')}: ${user.inviteCode}' : l10n.text('unpaired_warning')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PairingScreen(isModal: true)),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    user.mode == RelationshipMode.longDistance ? Icons.flight_takeoff_rounded : Icons.home_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(l10n.text('change_mode')),
                  subtitle: Text(user.mode.getTitle(appState.currentLanguage)),
                  trailing: const Icon(Icons.swap_horiz_rounded),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const ModeSwitchSheet(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Preferences
          _buildSectionHeader(theme, l10n.text('profile_section_preferences')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppColors.secondary),
                  title: Text(l10n.text('language')),
                  subtitle: Text(appState.currentLanguage == 'tr' ? 'Türkçe 🇹🇷' : 'English 🇬🇧'),
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'tr', label: Text('TR')),
                      ButtonSegment(value: 'en', label: Text('EN')),
                    ],
                    selected: {appState.currentLanguage},
                    onSelectionChanged: (val) {
                      appState.setLanguage(val.first);
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(
                    appState.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppColors.secondary,
                  ),
                  title: Text(l10n.text('profile_dark_mode')),
                  value: appState.isDarkMode,
                  onChanged: (_) => appState.toggleTheme(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 3: Privacy & Legal
          _buildSectionHeader(theme, l10n.text('profile_section_legal')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.textSecondary),
                  title: Text(l10n.text('privacy_policy')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const SizedBox(height: 500, child: PrivacyPolicySheet()),
                    );
                  },
                ),
                if (user.isPaired) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.heart_broken_outlined, color: Colors.redAccent),
                    title: Text(l10n.text('unpair_title'), style: const TextStyle(color: Colors.redAccent)),
                    onTap: () => _showUnpairDialog(context),
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: Text(l10n.text('delete_account'), style: const TextStyle(color: Colors.redAccent)),
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Center(
            child: Text(
              'Yanyana v1.0.0 • Sevgiyle Hazırlandı ❤️',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }
}
