import 'package:ciftapp/core/providers/dreams_provider.dart';
import 'package:ciftapp/core/providers/memories_provider.dart';
import 'package:ciftapp/core/providers/plans_provider.dart';
import 'package:ciftapp/core/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('providers start empty (no sample data)', () async {
    final memories = MemoriesProvider();
    final dreams = DreamsProvider();
    final plans = PlansProvider();
    await settle();

    expect(memories.memories, isEmpty);
    expect(memories.countdowns, isEmpty);
    expect(dreams.bucketList, isEmpty);
    expect(dreams.loveNotes, isEmpty);
    expect(plans.events, isEmpty);
    expect(plans.tasks, isEmpty);
    expect(plans.shoppingList, isEmpty);
  });

  test('memories persist across provider instances', () async {
    final first = MemoriesProvider();
    await settle();
    first.addMemory(
      title: 'İlk buluşma',
      note: 'Kahve',
      date: DateTime(2024, 5, 1),
      location: 'Kadıköy',
      tags: ['kahve'],
    );
    first.addCountdown(
      titleTr: 'Tatil',
      titleEn: 'Holiday',
      targetDate: DateTime(2030, 1, 1),
    );
    await settle();

    final second = MemoriesProvider();
    await settle();

    expect(second.memories, hasLength(1));
    expect(second.memories.first.title, 'İlk buluşma');
    expect(second.memories.first.location, 'Kadıköy');
    expect(second.memories.first.tags, ['kahve']);
    expect(second.countdowns, hasLength(1));
    expect(second.countdowns.first.titleEn, 'Holiday');
  });

  test('dreams persist, including toggled state and love notes', () async {
    final first = DreamsProvider();
    await settle();
    first.addBucketItem(title: 'Paraşüt', category: 'Macera');
    first.toggleBucketItem(first.bucketList.first.id);
    first.addLoveNote(
      senderName: 'Ben',
      title: 'Not',
      content: 'Seni seviyorum',
      colorHex: 0xFFFFE5EC,
      unlockDate: DateTime(2035, 1, 1),
    );
    await settle();

    final second = DreamsProvider();
    await settle();

    expect(second.bucketList, hasLength(1));
    expect(second.bucketList.first.isCompleted, isTrue);
    expect(second.loveNotes, hasLength(1));
    expect(second.loveNotes.first.unlockDate, DateTime(2035, 1, 1));
  });

  test('plans persist and clearAll wipes stored data', () async {
    final first = PlansProvider();
    await settle();
    first.addEvent('Film', DateTime(2030, 3, 3), category: 'date');
    first.addTask('Bilet al', assignedTo: 'me');
    first.addShoppingItem('Süt', addedBy: 'Ben');
    await settle();

    final second = PlansProvider();
    await settle();
    expect(second.events, hasLength(1));
    expect(second.tasks, hasLength(1));
    expect(second.shoppingList, hasLength(1));

    await second.clearAll();
    final third = PlansProvider();
    await settle();
    expect(third.events, isEmpty);
    expect(third.tasks, isEmpty);
    expect(third.shoppingList, isEmpty);
  });

  test('LocalStore skips corrupted entries instead of crashing', () async {
    SharedPreferences.setMockInitialValues({
      '${LocalStore.keyPrefix}test': '[{"id":"ok"},{"broken":true},42]',
    });

    final items = await LocalStore.loadList<String>(
      'test',
      (json) => json['id'] as String,
    );

    expect(items, ['ok']);
  });

  test('LocalStore returns empty list for invalid JSON', () async {
    SharedPreferences.setMockInitialValues({
      '${LocalStore.keyPrefix}bad': 'not json at all',
    });

    final items = await LocalStore.loadList<String>('bad', (j) => j['id'] as String);
    expect(items, isEmpty);
  });
}
