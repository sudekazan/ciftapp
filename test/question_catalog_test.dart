import 'package:ciftapp/core/content/question_catalog.dart';
import 'package:ciftapp/core/providers/together_provider.dart';
import 'package:ciftapp/core/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_couple_data_store.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  test('catalog ids are unique and every pack has TR/EN content', () {
    final ids = <String>{
      ...QuestionCatalog.daily.map((q) => q['id']!),
      ...QuestionCatalog.quizPacks.expand((p) => p.items).map((q) => q.id),
      ...QuestionCatalog.whoMorePacks.expand((p) => p.items).map((q) => q.id),
    };
    final total = QuestionCatalog.daily.length +
        QuestionCatalog.quizPacks.expand((p) => p.items).length +
        QuestionCatalog.whoMorePacks.expand((p) => p.items).length;
    expect(ids.length, total);

    expect(QuestionCatalog.daily.length, greaterThanOrEqualTo(30));
    for (final q in QuestionCatalog.daily) {
      expect(q['tr'], isNotEmpty);
      expect(q['en'], isNotEmpty);
    }
    for (final q in QuestionCatalog.quizPacks.expand((p) => p.items)) {
      expect(q.optionsTr.length, q.optionsEn.length);
    }
    // One free starter pack and at least one premium pack per game.
    expect(QuestionCatalog.quizPacks.where((p) => !p.isPremium).map((p) => p.id), ['starter']);
    expect(QuestionCatalog.quizPacks.where((p) => p.isPremium), isNotEmpty);
    expect(QuestionCatalog.whoMorePacks.where((p) => !p.isPremium).map((p) => p.id), ['starter']);
    expect(QuestionCatalog.whoMorePacks.where((p) => p.isPremium), isNotEmpty);
  });

  test('a day that was answered keeps its question after the catalog grew', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final key = '${yesterday.year.toString().padLeft(4, '0')}-'
        '${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    SharedPreferences.setMockInitialValues({
      '${LocalStore.keyPrefix}together_state': '{"daily":{"dq_03@$key":"Gülüşün"},"quiz":{},"whoMore":{}}',
    });
    final provider = TogetherProvider(store: FakeCoupleDataStore(FakeCloud()));
    await settle();

    final archived = provider.archive(1).single;
    expect(archived.id, 'dq_03@$key');
    expect(archived.myAnswer, 'Gülüşün');
  });

  test('packs filter questions', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = TogetherProvider(store: FakeCoupleDataStore(FakeCloud()));
    await settle();
    expect(provider.quizIn('deep').map((q) => q.id), everyElement(startsWith('deep_')));
    expect(provider.whoMoreIn('romance').map((q) => q.id), everyElement(startsWith('rom_')));
  });
}
