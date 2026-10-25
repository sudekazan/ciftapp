import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_question.dart';
import '../models/model_json.dart';
import '../services/couple_data_store.dart';
import '../services/local_store.dart';
import '../services/synced_list.dart';
import 'couple_bound_provider.dart';

/// Question catalog, the current user's answers and the partner's answers.
///
/// Answers live in `answers`, `quiz` and `whoMore` documents of the couple
/// space, one field per partner uid, so each side sees the other's answer.
class TogetherProvider extends ChangeNotifier with CoupleBoundProvider {
  static const _stateKey = '${LocalStore.keyPrefix}together_state';

  static const List<Map<String, String>> _dailyCatalog = [
    {'id': 'dq_01', 'tr': 'İlk tanıştığımız gün benim hakkımda ilk düşündüğün şey neydi?', 'en': 'What was your very first thought about me when we first met?'},
    {'id': 'dq_02', 'tr': 'Birlikte geçirdiğimiz en unutulmaz an hangisiydi?', 'en': 'What is the most memorable moment we have shared together?'},
    {'id': 'dq_03', 'tr': 'Benim en sevdiğin küçük alışkanlığım nedir?', 'en': 'What is your favorite little habit of mine?'},
    {'id': 'dq_04', 'tr': 'Bir gün tüm gün birlikte olsak ne yapmak isterdin?', 'en': 'If we had a whole free day together, what would you do?'},
    {'id': 'dq_05', 'tr': 'Bana en son ne zaman gurur duydun?', 'en': 'When was the last time you felt proud of me?'},
    {'id': 'dq_06', 'tr': 'Birlikte öğrenmek istediğin bir şey var mı?', 'en': 'Is there something you would like us to learn together?'},
    {'id': 'dq_07', 'tr': 'Seni en çok ne mutlu ediyor, bunu daha sık nasıl yapabilirim?', 'en': 'What makes you happiest, and how can I do it more often?'},
  ];

  final List<QuizQuestion> _quizCatalog = [
    QuizQuestion(
      id: 'quiz_01',
      questionTr: 'Benim en sevdiğim kahve türü hangisi?',
      questionEn: 'What is my favorite coffee drink?',
      optionsTr: ['Latte', 'Americano', 'Filtre Kahve', 'Cappuccino'],
      optionsEn: ['Latte', 'Americano', 'Filter Coffee', 'Cappuccino'],
    ),
    QuizQuestion(
      id: 'quiz_02',
      questionTr: 'Stresli olduğumda beni en çok ne rahatlatır?',
      questionEn: 'What relaxes me the most when stressed?',
      optionsTr: ['Müzik dinlemek', 'Sana sarılmak', 'Yürüyüşe çıkmak', 'Tatlı yemek'],
      optionsEn: ['Listening to music', 'Hugging you', 'Going for a walk', 'Eating sweets'],
    ),
    QuizQuestion(
      id: 'quiz_03',
      questionTr: 'Birlikte gitmek istediğimiz ilk yurt dışı tatili neresi?',
      questionEn: 'Where is our dream first trip together?',
      optionsTr: ['İtalya', 'Japonya', 'İzlanda', 'İspanya'],
      optionsEn: ['Italy', 'Japan', 'Iceland', 'Spain'],
    ),
  ];

  final List<WhoMoreQuestion> _whoMoreCatalog = [
    WhoMoreQuestion(id: 'who_01', questionTr: 'Hangimiz sabahları daha zor uyanır?', questionEn: 'Who is harder to wake up in the morning?'),
    WhoMoreQuestion(id: 'who_02', questionTr: 'Hangimiz sürpriz yapmayı daha çok sever?', questionEn: 'Who loves preparing surprises more?'),
    WhoMoreQuestion(id: 'who_03', questionTr: 'Hangimiz daha kıskançtır?', questionEn: 'Who gets jealous more easily?'),
    WhoMoreQuestion(id: 'who_04', questionTr: 'Hangimiz tartışmalarda ilk adımı atıp özür diler?', questionEn: 'Who takes the first step and apologizes first?'),
    WhoMoreQuestion(id: 'who_05', questionTr: 'Hangimiz kaybolduğunda yol sormaktan daha çok çekinir?', questionEn: 'Who is more hesitant to ask for directions when lost?'),
    WhoMoreQuestion(id: 'who_06', questionTr: 'Hangimiz plan yapmadan spontane yaşamayı daha çok sever?', questionEn: 'Who is more spontaneous and hates rigid plans?'),
  ];

  TogetherProvider({CoupleDataStore? store})
      : dataStore = store ?? FirestoreCoupleDataStore.instance {
    _watchlist = SyncedList(
      collection: 'watchlist',
      fromJson: WatchlistItemJson.fromJson,
      toJson: (w) => w.toJson(),
      idOf: (w) => w.id,
      onChanged: notifyListeners,
    );
    _rebuild();
    ready = _load();
  }

  @override
  final CoupleDataStore dataStore;
  @override
  late final Future<void> ready;

  late final SyncedList<WatchlistItem> _watchlist;

  late DailyQuestion _todaysQuestion;
  final List<QuizQuestion> _coupleQuiz = [];
  final List<WhoMoreQuestion> _whoMoreList = [];

  // The current user's answers (persisted locally and mirrored remotely).
  final Map<String, String> _dailyAnswers = {}; // "dq_id@yyyy-mm-dd" -> answer
  final Map<String, int> _quizAnswers = {};
  final Map<String, String> _whoMoreVotes = {}; // 'me' | 'partner' from my point of view

  // Partner answers from the couple space.
  final Map<String, String> _partnerDaily = {};
  final Map<String, int> _partnerQuiz = {};
  final Map<String, String> _partnerWhoMore = {}; // from the partner's point of view

  final List<StreamSubscription> _answerSubs = [];
  bool _isLoaded = false;

  @override
  Iterable<SyncedList> get syncedLists => [_watchlist];

  DailyQuestion get todaysQuestion => _todaysQuestion;

  /// Answered questions of the last [days] days, newest first (today excluded).
  List<DailyQuestion> archive(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      for (var i = 1; i <= days; i++) _questionFor(today.subtract(Duration(days: i))),
    ].where((q) => q.isMyAnswered || q.isPartnerAnswered).toList();
  }
  List<WatchlistItem> get watchlist => _watchlist.items;
  List<QuizQuestion> get coupleQuiz => List.unmodifiable(_coupleQuiz);
  List<WhoMoreQuestion> get whoMoreList => List.unmodifiable(_whoMoreList);
  bool get isLoaded => _isLoaded;

  int get quizMatchCount => _coupleQuiz.where((q) => q.isMatch).length;
  int get whoMoreAgreementCount => _whoMoreList.where((q) => q.isAgreed).length;

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DailyQuestion _questionFor(DateTime day) {
    final dayIndex = DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final q = _dailyCatalog[dayIndex % _dailyCatalog.length];
    final key = '${q['id']}@${_dayKey(day)}';
    final answer = _dailyAnswers[key];
    final partnerAnswer = _partnerDaily[key];
    return DailyQuestion(
      id: key,
      questionTr: q['tr']!,
      questionEn: q['en']!,
      date: day,
      myAnswer: answer,
      isMyAnswered: answer != null,
      partnerAnswer: partnerAnswer,
      isPartnerAnswered: partnerAnswer != null,
    );
  }

  /// The partner's vote converted to my point of view.
  static String? _flipVote(String? vote) => switch (vote) {
        'me' => 'partner',
        'partner' => 'me',
        _ => null,
      };

  void _rebuild() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _todaysQuestion = _questionFor(today);

    _coupleQuiz
      ..clear()
      ..addAll(_quizCatalog.map((q) => QuizQuestion(
            id: q.id,
            questionTr: q.questionTr,
            questionEn: q.questionEn,
            optionsTr: q.optionsTr,
            optionsEn: q.optionsEn,
            mySelectedIndex: _quizAnswers[q.id],
            partnerSelectedIndex: _partnerQuiz[q.id],
          )));

    _whoMoreList
      ..clear()
      ..addAll(_whoMoreCatalog.map((q) => WhoMoreQuestion(
            id: q.id,
            questionTr: q.questionTr,
            questionEn: q.questionEn,
            myVote: _whoMoreVotes[q.id],
            partnerVote: _flipVote(_partnerWhoMore[q.id]),
          )));
  }

  Future<void> _load() async {
    final legacyWatchlist = <Map<String, dynamic>>[];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_stateKey);
      if (raw != null && raw.isNotEmpty) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _dailyAnswers.addAll(Map<String, String>.from(json['daily'] as Map? ?? {}));
        _quizAnswers.addAll(Map<String, int>.from(json['quiz'] as Map? ?? {}));
        _whoMoreVotes.addAll(Map<String, String>.from(json['whoMore'] as Map? ?? {}));
        for (final w in (json['watchlist'] as List? ?? [])) {
          legacyWatchlist.add(Map<String, dynamic>.from(w as Map));
        }
      }
    } catch (e) {
      debugPrint('TogetherProvider: failed to load state: $e');
    }
    await _watchlist.loadLocal();
    // Older versions stored the watchlist inside the state blob.
    if (legacyWatchlist.isNotEmpty && _watchlist.items.isEmpty) {
      for (final w in legacyWatchlist) {
        try {
          _watchlist.put(WatchlistItemJson.fromJson(w));
        } catch (e) {
          debugPrint('TogetherProvider: skipped legacy watchlist item: $e');
        }
      }
      await _save();
    }
    _rebuild();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _stateKey,
        jsonEncode({
          'daily': _dailyAnswers,
          'quiz': _quizAnswers,
          'whoMore': _whoMoreVotes,
        }),
      );
    } catch (e) {
      debugPrint('TogetherProvider: failed to save state: $e');
    }
  }

  // --- Couple space sync of answers ---

  static const _metaFields = {'id', 'updatedAt', SyncedList.orderField, SyncedList.authorField};

  @override
  void onCoupleBound(String? coupleId) {
    for (final sub in _answerSubs) {
      sub.cancel();
    }
    _answerSubs.clear();
    _partnerDaily.clear();
    _partnerQuiz.clear();
    _partnerWhoMore.clear();
    _rebuild();
    notifyListeners();
    if (coupleId == null) return;

    void listen<T>(String collection, Map<String, T> mine, Map<String, T> partner) {
      final sub = dataStore.listen(coupleId, collection, (docs) {
        _onAnswers(coupleId, collection, docs, mine, partner);
      });
      if (sub != null) _answerSubs.add(sub);
    }

    listen<String>('answers', _dailyAnswers, _partnerDaily);
    listen<int>('quiz', _quizAnswers, _partnerQuiz);
    listen<String>('whoMore', _whoMoreVotes, _partnerWhoMore);
  }

  Future<void> _onAnswers<T>(
    String coupleId,
    String collection,
    List<Map<String, dynamic>> docs,
    Map<String, T> mine,
    Map<String, T> partner,
  ) async {
    final myUid = dataStore.currentUid;
    if (myUid == null) return;
    final remoteMine = <String, T>{};
    partner.clear();
    for (final doc in docs) {
      final id = doc['id'] as String;
      for (final entry in doc.entries) {
        if (_metaFields.contains(entry.key) || entry.value is! T) continue;
        if (entry.key == myUid) {
          remoteMine[id] = entry.value as T;
        } else {
          partner[id] = entry.value as T;
        }
      }
    }

    // First contact with this couple space: upload answers given offline or
    // before pairing. Answers already in the cloud (e.g. reinstall) are adopted.
    final prefs = await SharedPreferences.getInstance();
    final marker = 'ciftapp_sync_${collection}_couple';
    if (prefs.getString(marker) != coupleId) {
      for (final entry in mine.entries) {
        if (!remoteMine.containsKey(entry.key)) {
          unawaited(dataStore.merge(coupleId, collection, entry.key, {myUid: entry.value}));
        }
      }
      await prefs.setString(marker, coupleId);
    }
    var adopted = false;
    for (final entry in remoteMine.entries) {
      if (mine[entry.key] != entry.value) {
        mine[entry.key] = entry.value;
        adopted = true;
      }
    }
    if (adopted) await _save();

    _rebuild();
    notifyListeners();
  }

  void _pushAnswer(String collection, String id, Object value) {
    final coupleId = _watchlist.coupleId;
    final uid = dataStore.currentUid;
    if (coupleId == null || uid == null) return;
    unawaited(dataStore.merge(coupleId, collection, id, {uid: value}));
  }

  @override
  Future<void> onCoupleDataReset() async {
    await _clearAnswers();
  }

  Future<void> _clearAnswers() async {
    _dailyAnswers.clear();
    _quizAnswers.clear();
    _whoMoreVotes.clear();
    _partnerDaily.clear();
    _partnerQuiz.clear();
    _partnerWhoMore.clear();
    _rebuild();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stateKey);
    for (final c in ['answers', 'quiz', 'whoMore']) {
      await prefs.remove('ciftapp_sync_${c}_couple');
    }
  }

  /// Clears all in-memory and persisted data (account deletion).
  Future<void> clearAll() async {
    await _clearAnswers();
    await _watchlist.clearLocal();
    notifyListeners();
  }

  void submitMyAnswer(String answer) {
    _dailyAnswers[_todaysQuestion.id] = answer;
    _todaysQuestion = _todaysQuestion.copyWith(myAnswer: answer, isMyAnswered: true);
    notifyListeners();
    _save();
    _pushAnswer('answers', _todaysQuestion.id, answer);
  }

  void toggleWatchlistItem(String id) {
    final item = _watchlist.byId(id);
    if (item != null) _watchlist.put(item.copyWith(isWatched: !item.isWatched));
  }

  void addWatchlistItem(String title, {String type = 'movie', String platform = 'Netflix', required String addedBy}) {
    _watchlist.put(WatchlistItem(
      id: const Uuid().v4(),
      title: title,
      type: type,
      platform: platform,
      addedBy: addedBy,
    ));
  }

  void deleteWatchlistItem(String id) => _watchlist.remove(id);

  void answerQuizQuestion(String questionId, int selectedIndex) {
    final index = _coupleQuiz.indexWhere((q) => q.id == questionId);
    if (index != -1) {
      _quizAnswers[questionId] = selectedIndex;
      _coupleQuiz[index] = _coupleQuiz[index].copyWith(mySelectedIndex: selectedIndex);
      notifyListeners();
      _save();
      _pushAnswer('quiz', questionId, selectedIndex);
    }
  }

  void voteWhoMore(String questionId, String vote) {
    final index = _whoMoreList.indexWhere((q) => q.id == questionId);
    if (index != -1) {
      _whoMoreVotes[questionId] = vote;
      _whoMoreList[index] = _whoMoreList[index].copyWith(myVote: vote);
      notifyListeners();
      _save();
      _pushAnswer('whoMore', questionId, vote);
    }
  }

  @override
  void dispose() {
    for (final sub in _answerSubs) {
      sub.cancel();
    }
    disposeSyncedLists();
    super.dispose();
  }
}
