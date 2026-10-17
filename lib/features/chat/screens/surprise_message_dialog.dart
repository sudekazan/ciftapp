import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

class SurpriseMessageDialog extends StatefulWidget {
  final Function(String text, DateTime scheduledDate) onSchedule;

  const SurpriseMessageDialog({super.key, required this.onSchedule});

  @override
  State<SurpriseMessageDialog> createState() => _SurpriseMessageDialogState();
}

class _SurpriseMessageDialogState extends State<SurpriseMessageDialog> {
  final TextEditingController _textController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 6));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateFormatter = DateFormat('d MMMM yyyy');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.darkCardBg : Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.heartGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.text('surprise_message_title'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.text('surprise_message_desc'),
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Sürpriz aşk notunuzu yazın...',
                fillColor: isDark ? AppColors.darkSurface : AppColors.background,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.text('scheduled_for'),
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      dateFormatter.format(_selectedDate),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time_rounded, size: 16),
                    label: Text(
                      _selectedTime.format(context),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.text('cancel')),
        ),
        ElevatedButton(
          onPressed: () {
            final text = _textController.text.trim();
            if (text.isNotEmpty) {
              widget.onSchedule(text, _selectedDate);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(110, 44),
          ),
          child: const Text('Zamanla 🎁'),
        ),
      ],
    );
  }
}
