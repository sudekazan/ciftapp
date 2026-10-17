import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_state_provider.dart';

class ThinkingOfYouButton extends StatefulWidget {
  const ThinkingOfYouButton({super.key});

  @override
  State<ThinkingOfYouButton> createState() => _ThinkingOfYouButtonState();
}

class _ThinkingOfYouButtonState extends State<ThinkingOfYouButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _recentlyTapped = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.15), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapHeart() {
    _animController.forward(from: 0.0);
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    appState.triggerThinkingOfYou();

    setState(() => _recentlyTapped = true);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _recentlyTapped = false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Partnerine sevgi dokunuşun iletildi! ❤️'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
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
    final user = appState.currentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.text('thinking_of_you'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.text('thinking_of_you_sub'),
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
              // Simulate partner button for easy demonstration
              IconButton(
                icon: const Icon(Icons.touch_app_rounded, color: AppColors.secondary, size: 20),
                tooltip: 'Partner Dokunuşu Simüle Et',
                onPressed: () {
                  appState.receivePartnerThinkingOfYou();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.partnerName ?? "Partnerin"} az önce seni düşündü! ❤️'),
                      backgroundColor: AppColors.secondary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Glowing Pulsating Heart
          GestureDetector(
            onTap: _onTapHeart,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.heartGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(_recentlyTapped ? 0.6 : 0.35),
                      blurRadius: _recentlyTapped ? 30 : 20,
                      spreadRadius: _recentlyTapped ? 6 : 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status indicator
          if (user.lastThinkingOfYou != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    user.lastThinkingSender == user.name
                        ? 'Sevgini gönderdin (Az önce)'
                        : '${user.partnerName ?? "Partnerin"} seni düşündü! ❤️',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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
