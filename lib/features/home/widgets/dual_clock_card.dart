import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_state_provider.dart';

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

  static String _formatOffset(int minutes) {
    final sign = minutes < 0 ? '-' : '+';
    final abs = minutes.abs();
    final h = abs ~/ 60;
    final m = abs % 60;
    return 'UTC$sign$h${m == 0 ? '' : ':${m.toString().padLeft(2, '0')}'}';
  }

  void _pickPartnerOffset(BuildContext context, AppStateProvider appState) {
    // UTC-12:00 ... UTC+14:00 in 30-minute steps.
    final offsets = List.generate(53, (i) => -720 + i * 30);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context).text('clock_pick_partner_zone'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            SizedBox(
              height: 320,
              child: ListView(
                children: offsets
                    .map((o) => ListTile(
                          title: Text(_formatOffset(o)),
                          trailing: o == appState.partnerUtcOffsetMinutes
                              ? const Icon(Icons.check_rounded, color: AppColors.primary)
                              : null,
                          onTap: () {
                            appState.setPartnerUtcOffset(o);
                            Navigator.pop(ctx);
                          },
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appState = context.watch<AppStateProvider>();
    final l10n = AppLocalizations.of(context);

    final myTime = _now;
    final myOffset = _now.timeZoneOffset.inMinutes;
    final partnerOffset = appState.partnerUtcOffsetMinutes;
    final diffMinutes = partnerOffset - myOffset;
    final partnerTime = _now.toUtc().add(Duration(minutes: partnerOffset));
    final partnerLabel = appState.currentUser.partnerName ?? l10n.text('partner');

    final diffHours = diffMinutes / 60;
    final diffText = diffMinutes == 0
        ? l10n.text('clock_same_time')
        : l10n.textf('clock_diff', {
            'h': '${diffMinutes > 0 ? '+' : ''}${diffHours == diffHours.roundToDouble() ? diffHours.toInt() : diffHours}',
          });

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
                    l10n.text('clock_title'),
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
                  color: AppColors.secondarySoft.withValues(alpha: isDark ? 0.2 : 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  diffText,
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
                            l10n.text('you'),
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
                        l10n.text('my_time'),
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Partner Location & Time
              Expanded(
                child: GestureDetector(
                // Picked automatically from the partner's phone when available.
                onTap: appState.isPartnerTimeZoneAutomatic ? null : () => _pickPartnerOffset(context, appState),
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
                          Expanded(
                            child: Text(
                              partnerLabel,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (!appState.isPartnerTimeZoneAutomatic)
                            Icon(Icons.edit_rounded, size: 12, color: AppColors.textSecondary),
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
                        appState.hasPartnerTimeZone
                            ? l10n.text(isPartnerDaytime ? 'clock_partner_day' : 'clock_partner_night')
                            : l10n.text('clock_pick_zone'),
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
