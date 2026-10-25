import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../premium/limits.dart';

/// A premium benefit shown on the paywall. Every entry must be a feature that
/// actually works in the app (App Store 2.3.1 / 3.1.2, Google Play policy).
class PremiumFeature {
  final IconData icon;
  final String title;
  final String description;

  const PremiumFeature(this.icon, this.title, this.description);

  static List<PremiumFeature> all(AppLocalizations l10n) => [
        PremiumFeature(
          Icons.photo_library_rounded,
          l10n.text('premium_feat_memories_title'),
          l10n.textf('premium_feat_memories_desc', {'m': Limits.premiumPhotosPerMemory}),
        ),
        PremiumFeature(
          Icons.favorite_rounded,
          l10n.text('premium_feat_love_title'),
          l10n.text('premium_feat_love_desc'),
        ),
        PremiumFeature(
          Icons.quiz_rounded,
          l10n.text('premium_feat_questions_title'),
          l10n.text('premium_feat_questions_desc'),
        ),
        PremiumFeature(
          Icons.people_alt_rounded,
          l10n.text('premium_feat_couple_title'),
          l10n.text('premium_feat_couple_desc'),
        ),
      ];
}
