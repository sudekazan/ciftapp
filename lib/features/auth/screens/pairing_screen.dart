import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_state_provider.dart';

class PairingScreen extends StatefulWidget {
  final bool isModal;
  const PairingScreen({super.key, this.isModal = false});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isConnecting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _copyMyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Davet kodunuz kopyalandı!'),
          ],
        ),
        backgroundColor: AppColors.accentTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareCode(String code) {
    Share.share(
      'ÇiftApp\'te seninle özel alanımızı oluşturalım! Davet kodum: $code\nUygulamayı indir ve kodumu girerek eşleşelim ❤️',
      subject: 'ÇiftApp Partner Daveti',
    );
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Lütfen partnerinizin kodunu girin.');
      return;
    }

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    await appState.pairWithCode(code);

    setState(() => _isConnecting = false);

    if (widget.isModal) {
      nav.pop();
    }

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Partnerinizle başarıyla eşleştiniz! ❤️'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text('partner_pairing')),
        leading: widget.isModal
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: AppColors.heartGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Partnerinizle Eşleşin',
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'İki telefonu birbirine bağlayarak sohbet, anılar, takvim ve günün sorusunu ortak alanınızda paylaşın.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Card 1: My Invite Code
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    l10n.text('your_invite_code'),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryLight.withOpacity(0.5)),
                    ),
                    child: Text(
                      appState.currentUser.inviteCode,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                        letterSpacing: 4,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyMyCode(appState.currentUser.inviteCode),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: Text(l10n.text('copy_code')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _shareCode(appState.currentUser.inviteCode),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: Text(l10n.text('share_code')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: isDark ? AppColors.darkDivider : AppColors.divider)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('VEYA', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: Divider(color: isDark ? AppColors.darkDivider : AppColors.divider)),
              ],
            ),
            const SizedBox(height: 24),

            // Card 2: Enter Partner's Code
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.text('enter_partner_code'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Örn: CFT-9821',
                      prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppColors.primary),
                      errorText: _errorMessage,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isConnecting ? null : _submitCode,
                    child: _isConnecting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l10n.text('connect_button')),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Demo Mode helper for testing
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondarySoft.withOpacity(isDark ? 0.2 : 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondaryLight.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Geliştirme & Test Eşleşmesi',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            color: isDark ? Colors.white : AppColors.secondary,
                          ),
                        ),
                        Text(
                          'İkinci bir cihaza ihtiyaç duymadan simüle edilmiş partnerle ("Can ❤️") hemen test edin.',
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      await appState.activateDemoPairing();
                      if (widget.isModal) {
                        nav.pop();
                      }
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Test partneri Can ❤️ ile eşleşildi!'),
                          backgroundColor: AppColors.secondary,
                        ),
                      );
                    },
                    child: const Text('Bağla', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
