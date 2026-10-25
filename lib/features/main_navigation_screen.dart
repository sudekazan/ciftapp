import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../core/providers/app_state_provider.dart';
import '../core/services/notification_service.dart';
import 'dreams/screens/dreams_screen.dart';
import 'home/screens/home_screen.dart';
import 'memories/screens/memories_screen.dart';
import 'plans/screens/plans_screen.dart';
import 'together/screens/together_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  bool _notificationPromptChecked = false;

  static const _notifPromptKey = 'ciftapp_notif_prompted';

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ask for notifications once the user is paired: by then they understand
    // why (partner pulses, answers, memories).
    final isPaired = context.watch<AppStateProvider>().currentUser.isPaired;
    if (isPaired && !_notificationPromptChecked) {
      _notificationPromptChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAskForNotifications());
    }
  }

  Future<void> _maybeAskForNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_notifPromptKey) ?? false) return;
    if (await NotificationService.instance.hasAskedPermission()) return;
    await prefs.setBool(_notifPromptKey, true);
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final allow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 36),
        title: Text(l10n.text('notif_prompt_title'), textAlign: TextAlign.center),
        content: Text(l10n.text('notif_prompt_body'), textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.text('notif_prompt_later')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.text('notif_prompt_allow')),
          ),
        ],
      ),
    );
    if (allow == true) await NotificationService.instance.requestPermission();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pages = [
      HomeScreen(onTabChangeRequested: _onTabTapped),
      const DreamsScreen(),
      const PlansScreen(),
      const TogetherScreen(),
      const MemoriesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
              width: 1,
            ),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, l10n.text('nav_home')),
                _buildNavItem(1, Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, l10n.text('nav_dreams')),
                _buildNavItem(2, Icons.calendar_today_rounded, Icons.calendar_today_outlined, l10n.text('nav_plans')),
                _buildNavItem(3, Icons.favorite_rounded, Icons.favorite_border_rounded, l10n.text('nav_together')),
                _buildNavItem(4, Icons.photo_library_rounded, Icons.photo_library_outlined, l10n.text('nav_memories')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryDark.withValues(alpha: 0.3) : AppColors.primarySoft)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
