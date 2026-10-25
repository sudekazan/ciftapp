import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/content_labels.dart';
import '../../../core/premium/limits.dart';
import '../../../core/premium/premium_gate.dart';
import '../../../core/providers/memories_provider.dart';
import '../../../core/services/photo_storage.dart';
import '../../../core/services/review_service.dart';

class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({super.key});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedMood = 'Romantik ❤️';
  final List<String> _selectedImageUrls = [];
  final List<String> _tags = [];

  final ImagePicker _picker = ImagePicker();
  static const double _maxPhotoSide = 2048;
  static const int _photoQuality = 80;
  bool _isSaving = false;

  final List<String> _moodOptions = ContentLabels.moods;

  static const _quickLocationKeys = ['loc_home', 'loc_cafe', 'loc_beach', 'loc_park', 'loc_restaurant', 'loc_airport'];

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _locationController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImagesFromGallery() async {
    final isPremium = PremiumGate.isPremium(context);
    final maxPhotos = Limits.maxPhotosPerMemory(premium: isPremium);
    final remaining = maxPhotos - _selectedImageUrls.length;
    if (remaining <= 0) {
      if (isPremium) {
        _showPhotoLimit(maxPhotos);
      } else {
        await PremiumGate.openPaywall(context, PaywallSource.photoLimit);
      }
      return;
    }
    try {
      // Downscaled and compressed: full-resolution photos are slow to sync and
      // costly to store, and 2048px is plenty for a phone screen.
      final List<XFile> images = remaining == 1
          ? [
              if (await _picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: _maxPhotoSide,
                maxHeight: _maxPhotoSide,
                imageQuality: _photoQuality,
              )
                  case final image?)
                image,
            ]
          : await _picker.pickMultiImage(
              limit: remaining,
              maxWidth: _maxPhotoSide,
              maxHeight: _maxPhotoSide,
              imageQuality: _photoQuality,
            );
      if (images.isNotEmpty) {
        setState(() {
          for (final img in images.take(remaining)) {
            _selectedImageUrls.add(img.path);
          }
        });
        if (images.length > remaining) _showPhotoLimit(maxPhotos);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t.text('photos_access_denied')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showPhotoLimit(int maxPhotos) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t.textf('photo_limit_reached', {'n': maxPhotos})),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  void _addTag() {
    final text = _tagController.text.trim();
    if (text.isNotEmpty) {
      final clean = text.replaceAll('#', '');
      if (!_tags.contains(clean)) {
        setState(() => _tags.add(clean));
      }
      _tagController.clear();
    }
  }

  Future<void> _saveMemory() async {
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t.text('memory_title_required')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final memoriesProvider = Provider.of<MemoriesProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final persistedPaths = <String>[];
      for (final path in _selectedImageUrls) {
        persistedPaths.add(path.startsWith('http')
            ? path
            : await PhotoStorage.persist(path, coupleId: memoriesProvider.coupleId));
      }

      memoriesProvider.addMemory(
        title: title,
        note: note,
        date: _selectedDate,
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        mood: _selectedMood,
        imageUrls: persistedPaths,
        tags: List<String>.from(_tags),
      );
      ReviewService.maybeRequestAfterMemory(memoriesProvider.memories.length);

      if (!mounted) return;
      navigator.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(_t.text('memory_saved'))),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(_t.text('memory_save_failed')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t.text('add_memory'), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveMemory,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_t.text(_isSaving ? 'uploading' : 'save')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(90, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Photos & Media Gallery Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _t.text('memory_photos_title'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  _t.textf('memory_photos_selected', {'n': _selectedImageUrls.length}),
                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Horizontal Photo List
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Add Photo Button
                  GestureDetector(
                    onTap: _pickImagesFromGallery,
                    child: Container(
                      width: 110,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBg : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 36),
                          SizedBox(height: 6),
                          Text(
                            _t.text('memory_photo'),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Display Picked Photos
                  ..._selectedImageUrls.asMap().entries.map((entry) {
                    final index = entry.key;
                    final url = entry.value;

                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(left: 10),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                image: url.startsWith('http')
                                    ? NetworkImage(url) as ImageProvider
                                    : FileImage(File(url)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Remove button
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedImageUrls.removeAt(index));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                          // Index badge
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Title
            Text(_t.text('memory_title_label'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: _t.text('memory_title_hint'),
                prefixIcon: Icon(Icons.title_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: Date & Location
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_t.text('date_label'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormat('d MMMM yyyy', Localizations.localeOf(context).languageCode).format(_selectedDate),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_t.text('memory_location_label'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          hintText: _t.text('memory_location_hint'),
                          prefixIcon: Icon(Icons.location_on_rounded, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quick location suggestions
            Wrap(
              spacing: 6,
              children: _quickLocationKeys.map((key) => _t.text(key)).map((loc) => ActionChip(
                label: Text(loc, style: const TextStyle(fontSize: 11)),
                onPressed: () {
                  setState(() => _locationController.text = loc);
                },
                backgroundColor: isDark ? AppColors.darkCardBg : AppColors.background,
              )).toList(),
            ),
            const SizedBox(height: 20),

            // Section 4: Mood of the Memory
            Text(_t.text('memory_mood_label'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moodOptions.map((mood) {
                final isSelected = _selectedMood == mood;
                return ChoiceChip(
                  label: Text(ContentLabels.mood(_t, mood)),
                  selected: isSelected,
                  selectedColor: AppColors.primarySoft,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryDark : null,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedMood = mood);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Section 5: Note / Story
            Text(_t.text('memory_story_label'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: _t.text('memory_note'),
              ),
            ),
            const SizedBox(height: 20),

            // Section 6: Tags
            Text(_t.text('memory_tags_label'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: _t.text('memory_tags_hint'),
                      prefixIcon: Icon(Icons.tag_rounded, color: AppColors.secondary),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add_circle_rounded, color: AppColors.secondary, size: 32),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _tags.map((tag) => Chip(
                  label: Text('#$tag', style: const TextStyle(fontSize: 11)),
                  onDeleted: () => setState(() => _tags.remove(tag)),
                  deleteIconColor: AppColors.textSecondary,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
