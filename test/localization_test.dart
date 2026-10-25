import 'dart:io';

import 'package:ciftapp/core/localization/app_localizations.dart';
import 'package:ciftapp/core/services/account_service.dart';
import 'package:ciftapp/core/services/couple_sync_service.dart';
import 'package:ciftapp/core/services/purchase_service.dart';
import 'package:flutter_test/flutter_test.dart';

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

  test('every key used in the code exists', () {
    final used = <String>{};
    final pattern = RegExp(r"""\.textf?\(\s*'([a-z0-9_]+)'""");
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      used.addAll(pattern.allMatches(file.readAsStringSync()).map((m) => m.group(1)!));
    }
    // Keys built at runtime from enum names.
    used
      ..addAll(PairingError.values.map((e) => 'pair_err_${e.name}'))
      ..addAll(PurchaseFailureReason.values.map((e) => 'purchase_err_${e.name}'))
      ..addAll(LinkResult.values.map((e) => 'account_link_${e.name}'));

    final missing = used.difference(AppLocalizations.supportedKeys);
    expect(missing, isEmpty, reason: 'Used but not defined: $missing');
  });
}
