import 'package:ciftapp/core/providers/dreams_provider.dart';
import 'package:ciftapp/core/providers/memories_provider.dart';
import 'package:ciftapp/core/providers/plans_provider.dart';
import 'package:ciftapp/core/providers/together_provider.dart';
import 'package:ciftapp/core/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_couple_data_store.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 60));

void main() {
  late FakeCloud cloud;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cloud = FakeCloud();
  });

  test('a task added on one phone appears on the partner phone', () async {
    final mine = PlansProvider(store: FakeCoupleDataStore(cloud, uid: 'a'));
    final partner = PlansProvider(store: FakeCoupleDataStore(cloud, uid: 'b'));
    mine.bindCouple('cpl_1', 0);
    partner.bindCouple('cpl_1', 0);
    await settle();

    mine.addTask('Bilet al');
    mine.addShoppingItem('Süt', addedBy: 'Ben');
    await settle();

    expect(partner.tasks.map((t) => t.title), ['Bilet al']);
    expect(partner.shoppingList.map((s) => s.name), ['Süt']);

    partner.toggleTask(partner.tasks.first.id);
    await settle();
    expect(mine.tasks.first.isCompleted, isTrue);

    mine.deleteTask(mine.tasks.first.id);
    await settle();
    expect(partner.tasks, isEmpty);
  });

  test('task assignment is shown from each partner\'s point of view', () async {
    final mine = PlansProvider(store: FakeCoupleDataStore(cloud, uid: 'a'));
    final partner = PlansProvider(store: FakeCoupleDataStore(cloud, uid: 'b'));
    mine.bindCouple('cpl_1', 0);
    partner.bindCouple('cpl_1', 0);
    await settle();

    mine.addTask('Faturayı öde', assignedTo: 'me');
    mine.addTask('Market', assignedTo: 'both');
    await settle();

    final bill = partner.tasks.firstWhere((t) => t.title == 'Faturayı öde');
    expect(mine.assigneeOf(mine.tasks.first), 'me');
    expect(partner.assigneeOf(bill), 'partner');
    expect(partner.assigneeOf(partner.tasks.firstWhere((t) => t.title == 'Market')), 'both');
  });

  test('memories and love notes are shared, newest first', () async {
    final mine = MemoriesProvider(store: FakeCoupleDataStore(cloud, uid: 'a'));
    final partner = MemoriesProvider(store: FakeCoupleDataStore(cloud, uid: 'b'));
    mine.bindCouple('cpl_1', 0);
    partner.bindCouple('cpl_1', 0);
    await settle();

    mine.addMemory(title: 'İlk', note: '', date: DateTime(2024));
    await settle();
    mine.addMemory(title: 'İkinci', note: '', date: DateTime(2025));
    await settle();
    expect(partner.memories.map((m) => m.title), ['İkinci', 'İlk']);

    final myDreams = DreamsProvider(store: FakeCoupleDataStore(cloud, uid: 'a'));
    final partnerDreams = DreamsProvider(store: FakeCoupleDataStore(cloud, uid: 'b'));
    myDreams.bindCouple('cpl_1', 0);
    partnerDreams.bindCouple('cpl_1', 0);
    await settle();
    myDreams.addLoveNote(
      senderName: 'Ben',
      title: 'Kapsül',
      content: 'Seni seviyorum',
      colorHex: 0xFFFFE5EC,
      unlockDate: DateTime.now().add(const Duration(days: 3)),
    );
    await settle();

    final note = partnerDreams.loveNotes.single;
    expect(note.isLocked, isTrue, reason: 'time capsule reaches the partner still locked');
    expect(partnerDreams.isMyNote(note.id), isFalse);
    expect(myDreams.isMyNote(note.id), isTrue);
  });

  test('items created before pairing are uploaded to the couple space once', () async {
    SharedPreferences.setMockInitialValues({
      '${LocalStore.keyPrefix}plan_tasks': '[{"id":"t1","title":"Eski görev","isCompleted":false}]',
    });
    final provider = PlansProvider(store: FakeCoupleDataStore(cloud, uid: 'a'));
    provider.bindCouple('cpl_1', 0);
    await settle();

    expect(cloud.col('cpl_1', 'tasks').keys, ['t1']);
    expect(provider.tasks.single.title, 'Eski görev');

    // Deleted by the partner afterwards: must not be resurrected on restart.
    cloud.col('cpl_1', 'tasks').clear();
    cloud.emit('cpl_1', 'tasks');
    await settle();
    final restarted = PlansProvider(store: FakeCoupleDataStore(cloud, uid: 'a'));
    restarted.bindCouple('cpl_1', 0);
    await settle();
    expect(restarted.tasks, isEmpty);
    expect(cloud.col('cpl_1', 'tasks'), isEmpty);
  });

  test('leaving a couple drops the previous couple data instead of copying it', () async {
    final provider = PlansProvider(store: FakeCoupleDataStore(cloud, uid: 'a'));
    provider.bindCouple('cpl_old', 0);
    await settle();
    provider.addTask('Ortak görev');
    await settle();

    provider.bindCouple('cpl_new', 1); // dataGeneration changed
    await settle();

    expect(provider.tasks, isEmpty);
    expect(cloud.col('cpl_new', 'tasks'), isEmpty);
    expect(cloud.col('cpl_old', 'tasks'), hasLength(1), reason: 'partner keeps the shared data');
  });

  test('quiz and who-more answers are compared across partners', () async {
    final mine = TogetherProvider(store: FakeCoupleDataStore(cloud, uid: 'a'));
    final partner = TogetherProvider(store: FakeCoupleDataStore(cloud, uid: 'b'));
    mine.bindCouple('cpl_1', 0);
    partner.bindCouple('cpl_1', 0);
    await settle();

    final quizId = mine.coupleQuiz.first.id;
    mine.answerQuizQuestion(quizId, 2);
    partner.answerQuizQuestion(quizId, 2);
    await settle();
    expect(mine.quizMatchCount, 1);
    expect(partner.quizMatchCount, 1);
    expect(mine.coupleQuiz.first.partnerSelectedIndex, 2);

    // "Who wakes up later?" - both think it is "a".
    final whoId = mine.whoMoreList.first.id;
    mine.voteWhoMore(whoId, 'me');
    partner.voteWhoMore(whoId, 'partner');
    await settle();
    expect(mine.whoMoreAgreementCount, 1);
    expect(partner.whoMoreAgreementCount, 1);
    expect(mine.whoMoreList.first.partnerVote, 'me');
  });

  test('daily question answers reveal once both partners answered', () async {
    final mine = TogetherProvider(store: FakeCoupleDataStore(cloud, uid: 'a'));
    final partner = TogetherProvider(store: FakeCoupleDataStore(cloud, uid: 'b'));
    mine.bindCouple('cpl_1', 0);
    partner.bindCouple('cpl_1', 0);
    await settle();

    mine.submitMyAnswer('Gülüşün');
    await settle();
    expect(partner.todaysQuestion.isPartnerAnswered, isTrue);
    expect(partner.todaysQuestion.isRevealed, isFalse);

    partner.submitMyAnswer('Sesin');
    await settle();
    expect(mine.todaysQuestion.isRevealed, isTrue);
    expect(mine.todaysQuestion.partnerAnswer, 'Sesin');
  });

  test('watchlist from older versions is migrated', () async {
    SharedPreferences.setMockInitialValues({
      '${LocalStore.keyPrefix}together_state':
          '{"daily":{},"quiz":{},"whoMore":{},"watchlist":[{"id":"w1","title":"Dune","addedBy":"Ben"}]}',
    });
    final provider = TogetherProvider(store: FakeCoupleDataStore(cloud, uid: 'a'));
    await settle();
    expect(provider.watchlist.single.title, 'Dune');
  });
}
