import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/relationship_mode.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  RelationshipMode _selectedMode = RelationshipMode.longDistance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final slides = [
      {
        'title': 'Sadece İkinize Özel Ortak Bir Evren',
        'desc': 'Sohbet, ortak takvim, anı defteri ve ilişki oyunları tek bir samimi alanda.',
        'icon': Icons.favorite_rounded,
        'gradient': AppColors.heartGradient,
      },
      {
        'title': 'İlişkinizin Durumuna Göre İki Farklı Mod',
        'desc': 'Uzak mesafede özlemi ve geri sayımı yönetin, aynı evde ise takvim ve alışverişi koordine edin.',
        'icon': Icons.swap_horiz_rounded,
        'gradient': AppColors.primaryGradient,
      },
      {
        'title': 'Güvenli, Şeffaf ve Tamamen Çift Odaklı',
        'desc': 'Tüm verileriniz şifrelenir ve sadece partnerinizle sizin aranızda kalır.',
        'icon': Icons.lock_outline_rounded,
        'gradient': AppColors.purpleGradient,
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                    );
                  },
                  child: Text(
                    'Atla',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: slides.length + 1, // +1 for mode selection step
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    if (index < slides.length) {
                      final slide = slides[index];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: slide['gradient'] as LinearGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              slide['icon'] as IconData,
                              size: 70,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            slide['title'] as String,
                            style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              slide['desc'] as String,
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.4),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Final Step: Choose Relationship Mode
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'İlişki Modunuzu Seçin',
                            style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bu seçim ana sayfanızı özelleştirir. Dilediğiniz an ayarlardan değiştirebilirsiniz.',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          _buildModeOption(
                            mode: RelationshipMode.longDistance,
                            title: 'Uzak Mesafe İlişkisi',
                            desc: 'İki saat dilimi, buluşma geri sayımı ve "Seni Düşünüyorum" dokunuşu öne çıkar.',
                            icon: Icons.flight_takeoff_rounded,
                            isSelected: _selectedMode == RelationshipMode.longDistance,
                            theme: theme,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildModeOption(
                            mode: RelationshipMode.coLiving,
                            title: 'Birlikte Yaşıyoruz / Evliyiz',
                            desc: 'Günün ortak planı, bekleyen ev işleri, ortak takvim ve alışveriş listesi öne çıkar.',
                            icon: Icons.home_rounded,
                            isSelected: _selectedMode == RelationshipMode.coLiving,
                            theme: theme,
                            isDark: isDark,
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),

              // Page Indicators & Next Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length + 1,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? AppColors.primary
                          : (isDark ? AppColors.darkDivider : AppColors.divider),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_currentPage < slides.length) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    final appState = Provider.of<AppStateProvider>(context, listen: false);
                    appState.setRelationshipMode(_selectedMode);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                    );
                  }
                },
                child: Text(_currentPage == slides.length ? 'ÇiftApp’e Başla' : 'Devam Et'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required RelationshipMode mode,
    required String title,
    required String desc,
    required IconData icon,
    required bool isSelected,
    required ThemeData theme,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryDark.withOpacity(0.3) : AppColors.primarySoft)
              : (isDark ? AppColors.darkCardBg : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkDivider : AppColors.divider),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurface : AppColors.divider),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected ? AppColors.primary : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
