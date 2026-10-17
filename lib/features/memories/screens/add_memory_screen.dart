import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/memories_provider.dart';

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

  final List<String> _moodOptions = [
    'Romantik ❤️',
    'Eğlenceli 🎉',
    'Huzurlu 🕊️',
    'Özel Kutlama 🥂',
    'Macera 🌲',
    'Duygusal 🥺',
  ];

  final List<String> _quickLocations = [
    'Kadıköy',
    'Ortaköy',
    'Evimiz 🏡',
    'Sahil 🌊',
    'Havalimanı ✈️',
    'Kapadokya 🎈',
  ];

  final List<String> _samplePhotoPresets = [
    'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1522673607200-164d1b6ce486?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1518199266791-5375a83190b7?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _locationController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          for (final img in images) {
            _selectedImageUrls.add(img.path);
          }
        });
      }
    } catch (e) {
      // If native picker isn't available or running in simulator/web without permission, add sample photo
      _addSamplePhoto();
    }
  }

  void _addSamplePhoto() {
    setState(() {
      final nextIndex = _selectedImageUrls.length % _samplePhotoPresets.length;
      _selectedImageUrls.add(_samplePhotoPresets[nextIndex]);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fotoğraf eklendi! 📸'),
        duration: Duration(milliseconds: 1200),
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

  void _saveMemory() {
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen anınız için bir başlık girin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // If user didn't add any photo, add a default romantic photo
    if (_selectedImageUrls.isEmpty) {
      _selectedImageUrls.add(_samplePhotoPresets.first);
    }

    final memoriesProvider = Provider.of<MemoriesProvider>(context, listen: false);
    memoriesProvider.addMemory(
      title: title,
      note: note.isNotEmpty ? note : 'Birlikte geçirdiğimiz çok özel bir an...',
      date: _selectedDate,
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      mood: _selectedMood,
      imageUrls: _selectedImageUrls,
      tags: _tags.isNotEmpty ? _tags : ['Aşk'],
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Yeni anınız başarıyla deftere kaydedildi! ❤️'),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Anı Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              onPressed: _saveMemory,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Kaydet'),
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
                  'Fotoğraflar & Anı Kareleri',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${_selectedImageUrls.length} fotoğraf seçildi',
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
                          color: AppColors.primary.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 36),
                          SizedBox(height: 6),
                          Text(
                            'Fotoğraf Ekle',
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

                  // Pick Sample Photo Preset Button (for simulator & rapid testing)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: GestureDetector(
                      onTap: _addSamplePhoto,
                      child: Container(
                        width: 90,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? AppColors.darkDivider : AppColors.divider,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 26),
                            SizedBox(height: 4),
                            Text(
                              '+ Örnek Kare',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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
            Text('Anının Başlığı', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Örn: Boğaz Kenarında Akşam Yemeği',
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
                      Text('Tarih', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                                  DateFormat('d MMMM yyyy').format(_selectedDate),
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
                      Text('Konum / Yer', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          hintText: 'İstanbul / Londra',
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
              children: _quickLocations.map((loc) => ActionChip(
                label: Text(loc, style: const TextStyle(fontSize: 11)),
                onPressed: () {
                  setState(() => _locationController.text = loc);
                },
                backgroundColor: isDark ? AppColors.darkCardBg : AppColors.background,
              )).toList(),
            ),
            const SizedBox(height: 20),

            // Section 4: Mood of the Memory
            Text('Duygu & Anın Havası', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moodOptions.map((mood) {
                final isSelected = _selectedMood == mood;
                return ChoiceChip(
                  label: Text(mood),
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
            Text('Bu Anının Hikayesi', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Birlikte neler hissettiniz? Bu güne dair unutmamanız gereken küçük ayrıntılar...',
              ),
            ),
            const SizedBox(height: 20),

            // Section 6: Tags
            Text('Etiketler', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: 'Örn: Tatil, İlkGün, Sürpriz',
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
