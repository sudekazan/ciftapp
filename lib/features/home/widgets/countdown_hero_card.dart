import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/app_state_provider.dart';

class CountdownHeroCard extends StatefulWidget {
  final VoidCallback? onOpenPlans;
  const CountdownHeroCard({super.key, this.onOpenPlans});

  @override
  State<CountdownHeroCard> createState() => _CountdownHeroCardState();
}

class _CountdownHeroCardState extends State<CountdownHeroCard> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _showEditReunionDialog(BuildContext context, UserModel user) {
    DateTime selectedDate = user.nextReunionDate ?? DateTime.now().add(const Duration(days: 14));
    final locController = TextEditingController(text: user.reunionLocation ?? 'İstanbul & Londra Buluşması ✈️');
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.flight_takeoff_rounded, color: AppColors.primary, size: 22),
                SizedBox(width: 8),
                Text('Buluşmayı Güncelle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: locController,
                  decoration: const InputDecoration(
                    labelText: 'Buluşma Yeri / Planı',
                    prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Buluşma Tarihi & Saati:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ListTile(
                  tileColor: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  leading: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                  title: Text(
                    DateFormat('d MMMM yyyy, HH:mm').format(selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  trailing: const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.primary),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (pickedDate != null && context.mounted) {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (pickedTime != null) {
                        setModalState(() {
                          selectedDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
              ElevatedButton(
                onPressed: () async {
                  await appState.updateReunion(
                    date: selectedDate,
                    location: locController.text.trim().isEmpty ? 'Buluşma Planı ✈️' : locController.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final user = appState.currentUser;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final targetDate = user.nextReunionDate ?? DateTime.now().add(const Duration(days: 14));
    final diff = targetDate.difference(DateTime.now());

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flight_land_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.text('next_reunion'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.reunionLocation ?? 'Buluşma Planı',
                                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _showEditReunionDialog(context, user),
                                child: const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_calendar_rounded, size: 20, color: AppColors.primary),
                tooltip: 'Buluşma Tarihini Değiştir',
                onPressed: () => _showEditReunionDialog(context, user),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Countdown Units
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildUnitBox(theme, isDark, '$days', 'GÜN'),
              _buildColon(theme),
              _buildUnitBox(theme, isDark, hours.toString().padLeft(2, '0'), 'SAAT'),
              _buildColon(theme),
              _buildUnitBox(theme, isDark, minutes.toString().padLeft(2, '0'), 'DAKİKA'),
              _buildColon(theme),
              _buildUnitBox(theme, isDark, seconds.toString().padLeft(2, '0'), 'SANİYE'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitBox(ThemeData theme, bool isDark, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColon(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: TextStyle(
          color: AppColors.primary.withOpacity(0.6),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
