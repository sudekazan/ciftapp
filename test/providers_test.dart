import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ciftapp/core/providers/dreams_provider.dart';
import 'package:ciftapp/core/providers/plans_provider.dart';
import 'package:ciftapp/core/providers/together_provider.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 60));

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TogetherProvider', () {
    test('submits daily answer and persists', () async {
      final p1 = TogetherProvider();
      await settle();

      expect(p1.todaysQuestion.isMyAnswered, isFalse);
      p1.submitMyAnswer('Gülümsemen');
      expect(p1.todaysQuestion.isMyAnswered, isTrue);
      expect(p1.todaysQuestion.myAnswer, 'Gülümsemen');

      // Re-create provider to test persistence
      final p2 = TogetherProvider();
      await settle();
      expect(p2.todaysQuestion.isMyAnswered, isTrue);
      expect(p2.todaysQuestion.myAnswer, 'Gülümsemen');
    });

    test('adds and toggles watchlist item', () async {
      final p = TogetherProvider();
      await settle();

      expect(p.watchlist, isEmpty);
      p.addWatchlistItem('Interstellar', type: 'movie', platform: 'Netflix', addedBy: 'Test');
      expect(p.watchlist.length, 1);
      expect(p.watchlist.first.title, 'Interstellar');
      expect(p.watchlist.first.isWatched, isFalse);

      p.toggleWatchlistItem(p.watchlist.first.id);
      expect(p.watchlist.first.isWatched, isTrue);

      p.deleteWatchlistItem(p.watchlist.first.id);
      expect(p.watchlist, isEmpty);
    });

    test('answers couple quiz and votes on who more', () async {
      final p = TogetherProvider();
      await settle();

      expect(p.coupleQuiz, isNotEmpty);
      final firstQuiz = p.coupleQuiz.first;
      expect(firstQuiz.mySelectedIndex, isNull);

      p.answerQuizQuestion(firstQuiz.id, 2);
      expect(p.coupleQuiz.first.mySelectedIndex, 2);

      expect(p.whoMoreList, isNotEmpty);
      final firstWho = p.whoMoreList.first;
      p.voteWhoMore(firstWho.id, 'me');
      expect(p.whoMoreList.first.myVote, 'me');
    });

    test('clearAll wipes together data', () async {
      final p = TogetherProvider();
      await settle();

      p.submitMyAnswer('Bir anı');
      p.addWatchlistItem('Dizi', addedBy: 'Test');
      await p.clearAll();

      expect(p.todaysQuestion.isMyAnswered, isFalse);
      expect(p.watchlist, isEmpty);
    });
  });

  group('DreamsProvider', () {
    test('adds bucket item and toggles completion', () async {
      final p = DreamsProvider();
      await settle();

      expect(p.bucketList, isEmpty);
      p.addBucketItem(
        title: 'Kapadokya Balon Turu',
        category: 'travel',
        targetDate: '2027',
      );
      expect(p.bucketList.length, 1);
      expect(p.completedCount, 0);

      p.toggleBucketItem(p.bucketList.first.id);
      expect(p.completedCount, 1);
      expect(p.progressPercentage, 1.0);
    });

    test('adds love note and locks until unlock date', () async {
      final p = DreamsProvider();
      await settle();

      final futureDate = DateTime.now().add(const Duration(days: 30));
      p.addLoveNote(
        senderName: 'Ben',
        title: 'Geleceğe Not',
        content: 'Seni seviyorum',
        colorHex: 0xFFFFE5EC,
        unlockDate: futureDate,
      );

      expect(p.loveNotes.length, 1);
      expect(p.loveNotes.first.isLocked, isTrue);
    });
  });

  group('PlansProvider', () {
    test('adds task and toggles completion', () async {
      final p = PlansProvider();
      await settle();

      p.addTask('Pasaportları yenile', assignedTo: 'me');
      expect(p.tasks.length, 1);
      expect(p.tasks.where((t) => !t.isCompleted).length, 1);

      p.toggleTask(p.tasks.first.id);
      expect(p.tasks.where((t) => !t.isCompleted).length, 0);
    });

    test('adds shopping item and toggles bought', () async {
      final p = PlansProvider();
      await settle();

      p.addShoppingItem('Kahve çekirdeği', category: 'Mutfak', addedBy: 'Ben');
      expect(p.shoppingList.length, 1);
      expect(p.shoppingList.where((s) => !s.isBought).length, 1);

      p.toggleShoppingItem(p.shoppingList.first.id);
      expect(p.shoppingList.where((s) => !s.isBought).length, 0);
    });
  });
}
