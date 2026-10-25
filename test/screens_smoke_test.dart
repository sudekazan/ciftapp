import 'package:ciftapp/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens every tab in both languages and both relationship modes; layout
/// errors (unbounded constraints, hero clashes...) fail the test.
/// Narrow-screen text overflow is not checked here: the test font renders
/// every glyph as a full square, so widths are not representative.
void main() {
  for (final lang in ['tr', 'en']) {
    for (final mode in ['long_distance', 'co_living']) {
      testWidgets('all tabs render ($lang, $mode)', (tester) async {
        SharedPreferences.setMockInitialValues({
          'ciftapp_setup_completed': true,
          'ciftapp_user_name': 'Sude',
          'ciftapp_language': lang,
          'ciftapp_mode': mode,
          'ciftapp_onboarding_paywall_shown': true,
        });
        Future<void> pumpFor(int ms) async {
          for (var i = 0; i < ms ~/ 100; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        await tester.pumpWidget(MultiProvider(providers: appProviders(), child: const CiftApp()));
        await pumpFor(800);

        final labels = lang == 'tr'
            ? ['Hayallerimiz', 'Planlar', 'Birlikte', 'Anılar', 'Ana Sayfa']
            : ['Bucket List', 'Plans', 'Together', 'Memories', 'Home'];
        for (final label in labels) {
          await tester.tap(find.text(label).last);
          await pumpFor(600);
        }
      });
    }
  }
}
