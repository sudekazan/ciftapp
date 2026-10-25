import 'app_localizations.dart';

/// Display labels for values that are stored in the couple's data as Turkish
/// ids (kept for existing data). Unknown values are shown as they are.
class ContentLabels {
  ContentLabels._();

  static const Map<String, String> moodKeys = {
    'Romantik ❤️': 'mood_romantic',
    'Eğlenceli 🎉': 'mood_fun',
    'Huzurlu 🕊️': 'mood_peaceful',
    'Özel Kutlama 🥂': 'mood_celebration',
    'Macera 🌲': 'mood_adventure',
    'Duygusal 🥺': 'mood_emotional',
  };

  static List<String> get moods => moodKeys.keys.toList();

  static String mood(AppLocalizations l10n, String mood) {
    final key = moodKeys[mood];
    return key == null ? mood : l10n.text(key);
  }
}
