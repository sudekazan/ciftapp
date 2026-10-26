import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_links.dart';
import '../localization/app_localizations.dart';
import 'analytics_service.dart';

/// Sends the invite code through the system share sheet. Every invite button
/// goes through here, so `invite_shared(source)` covers the whole pairing
/// funnel: setup_completed → invite_shared → pairing_success.
class InviteService {
  InviteService._();

  static Future<void> share(BuildContext context, String code, {required String source}) async {
    final l10n = AppLocalizations.of(context);
    // iPad shows the share sheet as a popover and needs an anchor.
    final box = context.findRenderObject() as RenderBox?;
    final result = await SharePlus.instance.share(ShareParams(
      text: l10n.textf('invite_share_text', {'code': code, 'link': AppLinks.inviteUrl(code)}),
      subject: l10n.text('invite_share_subject'),
      sharePositionOrigin: box == null || !box.hasSize ? null : box.localToGlobal(Offset.zero) & box.size,
    ));
    // Android cannot tell whether a target was picked ("unavailable"), so
    // everything except an explicit dismissal counts as shared.
    if (result.status != ShareResultStatus.dismissed) {
      await AnalyticsService.log('invite_shared', {'source': source});
    }
  }
}
