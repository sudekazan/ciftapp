import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public URLs required by App Store / Google Play listings.
/// Hosted from the repo's /docs folder via GitHub Pages.
class AppLinks {
  AppLinks._();

  static const String privacyPolicy = 'https://sudekazan.github.io/ciftapp/privacy.html';
  static const String termsOfUse = 'https://sudekazan.github.io/ciftapp/terms.html';
  static const String supportEmail = 'destek@yanyana.app';

  /// Invite page with the code and store buttons (docs/davet.html).
  static String inviteUrl(String code) => 'https://sudekazan.github.io/ciftapp/davet.html?kod=$code';

  static Future<void> open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(url)));
    }
  }
}
