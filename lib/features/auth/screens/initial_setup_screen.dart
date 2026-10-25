import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_links.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/relationship_mode.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/services/account_service.dart';
import '../../../core/services/couple_sync_service.dart';
import '../../profile/widgets/account_backup_card.dart';
import '../../main_navigation_screen.dart';

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  int _currentStep = 0; // 0: Name, 1: Date, 2: Mode, 3: Pairing Choice

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _partnerCodeController = TextEditingController();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  RelationshipMode _selectedMode = RelationshipMode.longDistance;

  // Selected path: 'have_code' or 'create_new'
  String _pathChoice = 'create_new';
  bool _isLoading = false;
  bool _consentAccepted = false;

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void dispose() {
    _nameController.dispose();
    _partnerCodeController.dispose();
    super.dispose();
  }

  void _goToStep2Date() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t.text('setup_enter_name_snack')),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }
    setState(() => _currentStep = 1);
  }

  void _goToStep3Mode() {
    setState(() => _currentStep = 2);
  }

  void _goToStep4Pairing() {
    setState(() => _currentStep = 3);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _finishSetup() async {
    if (!_consentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t.text('setup_consent_snack')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final name = _nameController.text.trim().isEmpty ? _t.text('default_my_name') : _nameController.text.trim();
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    setState(() => _isLoading = true);

    String? partnerCode;

    if (_pathChoice == 'have_code') {
      final error = appState.validatePartnerCode(_partnerCodeController.text);
      if (error != null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t.text(error)), backgroundColor: Colors.redAccent),
        );
        return;
      }
      partnerCode = _partnerCodeController.text.trim().toUpperCase();
    }

    try {
      await appState.completeInitialSetup(
        name: name,
        mode: _selectedMode,
        partnerCode: partnerCode,
        startDate: _startDate,
      );
    } on PairingException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).text('pair_err_${e.error.name}')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  /// New phone: sign in with the linked Apple/Google account and reconnect to
  /// the existing couple space instead of starting over.
  Future<void> _showSignInSheet() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final provider = await showModalBottomSheet<AccountProvider>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_t.text('account_signin_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(_t.text('account_signin_desc'), style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              AccountProviderButtons(
                providers: AccountService.instance.availableProviders,
                onPressed: (p) => Navigator.pop(ctx, p),
              ),
            ],
          ),
        ),
      ),
    );
    if (provider == null || !mounted) return;

    setState(() => _isLoading = true);
    final uid = await AccountService.instance.signIn(provider);
    final restored = uid != null && await appState.restoreFromAccount();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (restored) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (uid != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t.text('account_signin_no_space'))));
    }
  }

  void _shareInviteCode(String code) {
    final l10n = AppLocalizations.of(context);
    SharePlus.instance.share(ShareParams(
      text: l10n.textf('invite_share_text', {'code': code, 'link': AppLinks.inviteUrl(code)}),
      subject: l10n.text('invite_share_subject'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 4-Step Progress Header with Clear Labels
            _buildStepIndicator(isDark, appState),

            // Step Content
            Expanded(
              child: _buildCurrentStep(theme, isDark, appState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark, AppStateProvider appState) {
    final steps = [
      {'label': _t.text('setup_step1_label'), 'icon': Icons.person_rounded},
      {'label': _t.text('setup_step2_label'), 'icon': Icons.calendar_month_rounded},
      {'label': _t.text('setup_step3_label'), 'icon': Icons.public_rounded},
      {'label': _t.text('setup_step4_label'), 'icon': Icons.favorite_rounded},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.favorite_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 6),
                  Text('Yanyana', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  final nextLang = appState.currentLanguage == 'tr' ? 'en' : 'tr';
                  appState.setLanguage(nextLang);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        appState.currentLanguage.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(steps.length, (index) {
              final isCompleted = _currentStep > index;
              final isCurrent = _currentStep == index;
              final color = isCurrent || isCompleted
                  ? AppColors.primary
                  : (isDark ? AppColors.darkDivider : AppColors.divider);

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted
                                      ? AppColors.primary
                                      : (isCurrent ? AppColors.primary : Colors.transparent),
                                  border: Border.all(
                                    color: color,
                                    width: 1.6,
                                  ),
                                ),
                                child: Center(
                                  child: isCompleted
                                      ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                                      : Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isCurrent
                                                ? Colors.white
                                                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  steps[index]['label'] as String,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                    color: isCurrent
                                        ? AppColors.primary
                                        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: isCompleted || isCurrent
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkDivider : AppColors.divider),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index < steps.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 13,
                          color: isDark ? AppColors.darkDivider : AppColors.divider,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(ThemeData theme, bool isDark, AppStateProvider appState) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Name(theme, isDark);
      case 1:
        return _buildStep2Date(theme, isDark);
      case 2:
        return _buildStep3Mode(theme, isDark);
      case 3:
      default:
        return _buildStep4PairingChoice(theme, isDark, appState);
    }
  }

  // ==========================================
  // ADIM 1: Sadece Kullanıcının Adını Alma
  // ==========================================
  Widget _buildStep1Name(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              gradient: AppColors.heartGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 20),
          Text(
            _t.text('setup_welcome_title'),
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            _t.text('setup_welcome_sub'),
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 36),

          // Name Input Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _t.text('setup_name_question'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _t.text('setup_name_help'),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameController,
                  autofocus: false,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _goToStep2Date(),
                  decoration: InputDecoration(
                    hintText: _t.text('setup_name_hint'),
                    prefixIcon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                    suffixIcon: _nameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _nameController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Next Button to Step 2
          ElevatedButton(
            onPressed: _goToStep2Date,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_t.text('setup_next_date')),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
          if (AccountService.instance.availableProviders.isNotEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _showSignInSheet,
                child: Text(_t.text('account_have_account')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // ADIM 2: Birlikte Olmaya Başladığımız Tarih
  // ==========================================
  Widget _buildStep2Date(ThemeData theme, bool isDark) {
    final daysTogether = DateTime.now().difference(_startDate).inDays;
    final years = daysTogether ~/ 365;
    final remainingDays = daysTogether % 365;
    final months = remainingDays ~/ 30;

    final String durationText;
    if (years > 0 && months > 0) {
      durationText = _t.textf('setup_duration_years_months', {'y': years, 'm': months});
    } else if (years > 0) {
      durationText = _t.textf('setup_duration_years', {'y': years});
    } else if (months > 0) {
      durationText = _t.textf('setup_duration_months', {'m': months});
    } else {
      durationText = _t.textf('setup_duration_days', {'d': daysTogether});
    }
    final lang = Localizations.localeOf(context).languageCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _currentStep = 0),
                tooltip: _t.text('setup_back'),
              ),
              const SizedBox(width: 4),
              Text(
                _t.text('setup_step2_header'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _t.text('setup_date_title'),
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            _t.text('setup_date_sub'),
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13.5),
          ),
          const SizedBox(height: 24),

          // Date Selector Interactive Card
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: AppColors.heartGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t.text('profile_start_date'),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('d MMMM yyyy', lang).format(_startDate),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                            Text(
                              DateFormat('EEEE', lang).format(_startDate),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_calendar_rounded, color: AppColors.primary, size: 16),
                            const SizedBox(width: 4),
                            Text(_t.text('change'), style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Preset Chips for Date Picking
          Text(
            _t.text('setup_quick_picks'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickDateChip(_t.text('setup_quick_today'), DateTime.now()),
                _buildQuickDateChip(_t.text('setup_quick_1m'), DateTime.now().subtract(const Duration(days: 30))),
                _buildQuickDateChip(_t.text('setup_quick_6m'), DateTime.now().subtract(const Duration(days: 180))),
                _buildQuickDateChip(_t.text('setup_quick_1y'), DateTime.now().subtract(const Duration(days: 365))),
                _buildQuickDateChip(_t.text('setup_quick_2y'), DateTime.now().subtract(const Duration(days: 730))),
                ActionChip(
                  avatar: const Icon(Icons.date_range_rounded, size: 16, color: AppColors.primary),
                  label: Text(_t.text('setup_quick_calendar')),
                  onPressed: _pickDate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Days Together Live Preview Badge & Romance Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppColors.darkCardGradient
                  : const LinearGradient(
                      colors: [Color(0xFFFFF0F2), Color(0xFFFFE6EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t.textf('setup_today_day_n', {'n': daysTogether}),
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            durationText,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : AppColors.primaryDark.withValues(alpha: 0.8),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _t.text('setup_date_hint'),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Next Button to Step 3 (Mode)
          ElevatedButton(
            onPressed: _goToStep3Mode,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_t.text('setup_next_mode')),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ADIM 3: İlişki Modunu Belirleme (Uzak Mesafe mi, Aynı Ev mi?)
  // ==========================================
  Widget _buildStep3Mode(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _currentStep = 1),
                tooltip: _t.text('setup_back'),
              ),
              const SizedBox(width: 4),
              Text(
                _t.text('setup_step3_header'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _t.text('setup_mode_title'),
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            _t.text('setup_mode_sub'),
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13.5),
          ),
          const SizedBox(height: 24),

          // Mod 1: Uzak Mesafe Kartı
          _buildModeSelectionCard(
            mode: RelationshipMode.longDistance,
            title: _t.text('setup_ld_title'),
            badge: _t.text('setup_ld_badge'),
            desc: _t.text('setup_ld_desc'),
            features: [
              _t.text('setup_ld_feat1'),
              _t.text('setup_ld_feat2'),
              _t.text('setup_ld_feat3'),
            ],
            icon: Icons.flight_takeoff_rounded,
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Mod 2: Aynı Evde Yaşıyoruz Kartı
          _buildModeSelectionCard(
            mode: RelationshipMode.coLiving,
            title: _t.text('setup_cl_title'),
            badge: _t.text('setup_cl_badge'),
            desc: _t.text('setup_cl_desc'),
            features: [
              _t.text('setup_cl_feat1'),
              _t.text('setup_cl_feat2'),
              _t.text('setup_cl_feat3'),
            ],
            icon: Icons.home_rounded,
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(height: 36),

          // Next Button to Step 4 (Pairing)
          ElevatedButton(
            onPressed: _goToStep4Pairing,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_t.text('setup_next_pairing')),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelectionCard({
    required RelationshipMode mode,
    required String title,
    required String badge,
    required String desc,
    required List<String> features,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryDark.withValues(alpha: 0.25) : Colors.white)
              : (isDark ? AppColors.darkCardBg : AppColors.background),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkDivider : AppColors.divider),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurface : AppColors.primarySoft),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isSelected ? AppColors.primary : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              desc,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            ...features.map((feat) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      feat,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateChip(String label, DateTime targetDate) {
    final isSelected = _startDate.year == targetDate.year &&
        _startDate.month == targetDate.month &&
        _startDate.day == targetDate.day;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primarySoft,
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primaryDark : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        onSelected: (_) {
          setState(() => _startDate = targetDate);
        },
      ),
    );
  }

  // ==========================================
  // ADIM 4: Çift Alanı Kurulumu (Partner Eşleşmesi)
  // ==========================================
  Widget _buildStep4PairingChoice(ThemeData theme, bool isDark, AppStateProvider appState) {
    final modeName = _t.text(_selectedMode == RelationshipMode.longDistance ? 'setup_mode_name_ld' : 'setup_mode_name_cl');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _currentStep = 2),
                tooltip: _t.text('setup_back'),
              ),
              const SizedBox(width: 4),
              Text(
                _t.text('setup_step4_header'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _t.text('setup_pair_title'),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 23),
          ),
          const SizedBox(height: 6),
          Text(
            _t.textf('setup_pair_sub', {'mode': modeName}),
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Option A: Have Partner's Code
          _buildChoiceCard(
            id: 'have_code',
            title: _t.text('setup_have_code_title'),
            subtitle: _t.text('setup_have_code_sub'),
            isSelected: _pathChoice == 'have_code',
            theme: theme,
            isDark: isDark,
            child: _pathChoice == 'have_code'
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _partnerCodeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: _t.text('setup_code_hint'),
                            prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // Option B: Create New Space
          _buildChoiceCard(
            id: 'create_new',
            title: _t.text('setup_create_title'),
            subtitle: _t.text('setup_create_sub'),
            isSelected: _pathChoice == 'create_new',
            theme: theme,
            isDark: isDark,
            child: _pathChoice == 'create_new'
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_t.text('setup_your_code'), style: const TextStyle(fontSize: 11, color: AppColors.primaryDark)),
                                  Text(
                                    appState.currentUser.inviteCode,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _shareInviteCode(appState.currentUser.inviteCode),
                                icon: const Icon(Icons.share_rounded, size: 14),
                                label: Text(_t.text('share'), style: const TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  side: const BorderSide(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 20),

          // KVKK / GDPR & Age 17+ consent
          InkWell(
            onTap: () => setState(() => _consentAccepted = !_consentAccepted),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _consentAccepted,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) => setState(() => _consentAccepted = val ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _t.text('consent_prefix'),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => AppLinks.open(context, AppLinks.privacyPolicy),
                          child: Text(
                            _t.text('consent_privacy'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          _t.text('consent_and'),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => AppLinks.open(context, AppLinks.termsOfUse),
                          child: Text(
                            _t.text('consent_terms'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          _t.text('consent_suffix'),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _isLoading ? null : _finishSetup,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(_t.text('setup_start_btn')),
          ),
          const SizedBox(height: 12),

          Center(
            child: TextButton(
              onPressed: () {
                setState(() => _pathChoice = 'create_new');
                _finishSetup();
              },
              child: Text(
                _t.text('setup_explore_alone'),
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard({
    required String id,
    required String title,
    required String subtitle,
    required bool isSelected,
    required ThemeData theme,
    required bool isDark,
    Widget? child,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _pathChoice = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryDark.withValues(alpha: 0.2) : Colors.white)
              : (isDark ? AppColors.darkCardBg : AppColors.background),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkDivider : AppColors.divider),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected && !isDark)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
            ),
            if (child != null) child,
          ],
        ),
      ),
    );
  }
}
