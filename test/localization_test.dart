import 'package:flutter_test/flutter_test.dart';
import 'package:ciftapp/core/localization/app_localizations.dart';

void main() {
  test('TR and EN localizations have parity and no missing keys', () {
    final trKeys = AppLocalizations.keysFor('tr');
    final enKeys = AppLocalizations.keysFor('en');

    expect(trKeys, isNotEmpty);
    expect(enKeys, isNotEmpty);

    final missingInEn = trKeys.difference(enKeys);
    final missingInTr = enKeys.difference(trKeys);

    expect(missingInEn, isEmpty, reason: 'Keys in TR but missing in EN: $missingInEn');
    expect(missingInTr, isEmpty, reason: 'Keys in EN but missing in TR: $missingInTr');
  });
}
