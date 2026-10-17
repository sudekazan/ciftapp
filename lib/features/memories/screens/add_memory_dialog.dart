import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

class AddMemoryDialog extends StatefulWidget {
  final Function({
    required String title,
    required String note,
    required DateTime date,
    String? location,
    String? imageUrl,
    List<String> tags,
  }) onSave;

  const AddMemoryDialog({super.key, required this.onSave});

  @override
  State<AddMemoryDialog> createState() => _AddMemoryDialogState();
}

class _AddMemoryDialogState extends State<AddMemoryDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Yeni Anı Ekle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Anı Başlığı (Örn: Boğaz Gezisi)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Konum / Yer'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Anının Hikayesi...'),
            ),
            const SizedBox(height: 14),
            ListTile(
              dense: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: isDark ? AppColors.darkSurface : AppColors.background,
              leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
              title: Text(DateFormat('d MMMM yyyy').format(_selectedDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2010),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.text('cancel'))),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isNotEmpty) {
              widget.onSave(
                title: _titleController.text.trim(),
                note: _noteController.text.trim(),
                location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
                date: _selectedDate,
                imageUrl: 'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?auto=format&fit=crop&w=800&q=80',
                tags: ['Özel Anı'],
              );
              Navigator.pop(context);
            }
          },
          child: Text(l10n.text('save')),
        ),
      ],
    );
  }
}
