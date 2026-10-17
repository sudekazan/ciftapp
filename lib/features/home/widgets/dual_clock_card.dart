import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';

class DualClockCard extends StatefulWidget {
  const DualClockCard({super.key});

  @override
  State<DualClockCard> createState() => _DualClockCardState();
}

class _DualClockCardState extends State<DualClockCard> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Local time (e.g. Istanbul)
    final myTime = _now;
    // Partner time (e.g. London, -2 or -3 hours difference)
    final partnerTime = _now.subtract(const Duration(hours: 2));

    final timeFormatter = DateFormat('HH:mm');

    final isPartnerDaytime = partnerTime.hour >= 7 && partnerTime.hour < 23;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'İki Şehir, Tek Kalp',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondarySoft.withOpacity(isDark ? 0.2 : 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '-2 Saat Farkı',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              // My Location & Time
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'İstanbul',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeFormatter.format(myTime),
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Senin Saatin',
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Partner Location & Time
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPartnerDaytime ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                            size: 14,
                            color: isPartnerDaytime ? AppColors.accentGold : AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Londra',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeFormatter.format(partnerTime),
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPartnerDaytime ? 'Gündüz Vakti ☀️' : 'Uyuyor Olabilir 🌙',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          color: isPartnerDaytime ? AppColors.accentGold : AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
