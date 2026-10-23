import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_question.dart';
import '../services/local_store.dart';

/// Question catalog + the current user's own answers.
///
/// Partner answers are only filled in once a real sync backend exists;
/// no fake partner data is generated.
class TogetherProvider extends ChangeNotifier {
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

  late DailyQuestion _todaysQuestion;
  final List<DailyQuestion> _pastQuestions = [];
  final List<WatchlistItem> _watchlist = [];
  final List<QuizQuestion> _coupleQuiz = [];
  final List<WhoMoreQuestion> _whoMoreList = [];

  // Persisted user state
  final Map<String, String> _dailyAnswers = {}; // "dq_id@yyyy-mm-dd" -> answer
  final Map<String, int> _quizAnswers = {};
  final Map<String, String> _whoMoreVotes = {};
  bool _isLoaded = false;

  DailyQuestion get todaysQuestion => _todaysQuestion;
  List<DailyQuestion> get pastQuestions => List.unmodifiable(_pastQuestions);
  List<WatchlistItem> get watchlist => List.unmodifiable(_watchlist);
  List<QuizQuestion> get coupleQuiz => List.unmodifiable(_coupleQuiz);
  List<WhoMoreQuestion> get whoMoreList => List.unmodifiable(_whoMoreList);
  bool get isLoaded => _isLoaded;

  int get quizMatchCount => _coupleQuiz.where((q) => q.isMatch).length;
  int get whoMoreAgreementCount => _whoMoreList.where((q) => q.isAgreed).length;

  TogetherProvider() {
    _rebuild();
    _load();
  }

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DailyQuestion _questionFor(DateTime day) {
    final dayIndex = DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final q = _dailyCatalog[dayIndex % _dailyCatalog.length];
    final key = '${q['id']}@${_dayKey(day)}';
    final answer = _dailyAnswers[key];
    return DailyQuestion(
      id: key,
      questionTr: q['tr']!,
      questionEn: q['en']!,
      date: day,
      myAnswer: answer,
      isMyAnswered: answer != null,
    );
  }

  void _rebuild() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _todaysQuestion = _questionFor(today);

    _pastQuestions
      ..clear()
      ..addAll(List.generate(2, (i) => _questionFor(today.subtract(Duration(days: i + 1))))
          .where((q) => q.isMyAnswered));

    _coupleQuiz
      ..clear()
      ..addAll(_quizCatalog.map((q) => QuizQuestion(
            id: q.id,
            questionTr: q.questionTr,
            questionEn: q.questionEn,
            optionsTr: q.optionsTr,
            optionsEn: q.optionsEn,
            mySelectedIndex: _quizAnswers[q.id],
          )));

    _whoMoreList
      ..clear()
      ..addAll(_whoMoreCatalog.map((q) => WhoMoreQuestion(
            id: q.id,
            questionTr: q.questionTr,
            questionEn: q.questionEn,
            myVote: _whoMoreVotes[q.id],
          )));
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_stateKey);
      if (raw != null && raw.isNotEmpty) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _dailyAnswers.addAll(Map<String, String>.from(json['daily'] as Map? ?? {}));
        _quizAnswers.addAll(Map<String, int>.from(json['quiz'] as Map? ?? {}));
        _whoMoreVotes.addAll(Map<String, String>.from(json['whoMore'] as Map? ?? {}));
        for (final w in (json['watchlist'] as List? ?? [])) {
          final m = Map<String, dynamic>.from(w as Map);
          _watchlist.add(WatchlistItem(
            id: m['id'] as String,
            title: m['title'] as String,
            type: m['type'] as String? ?? 'movie',
            platform: m['platform'] as String? ?? 'Netflix',
            isWatched: m['isWatched'] as bool? ?? false,
            rating: (m['rating'] as num?)?.toDouble() ?? 0.0,
            addedBy: m['addedBy'] as String? ?? '',
          ));
        }
      }
    } catch (e) {
      debugPrint('TogetherProvider: failed to load state: $e');
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
          'watchlist': _watchlist
              .map((w) => {
                    'id': w.id,
                    'title': w.title,
                    'type': w.type,
                    'platform': w.platform,
                    'isWatched': w.isWatched,
                    'rating': w.rating,
                    'addedBy': w.addedBy,
                  })
              .toList(),
        }),
      );
    } catch (e) {
      debugPrint('TogetherProvider: failed to save state: $e');
    }
  }

  /// Clears all in-memory and persisted data (account deletion).
  Future<void> clearAll() async {
    _dailyAnswers.clear();
    _quizAnswers.clear();
    _whoMoreVotes.clear();
    _watchlist.clear();
    _rebuild();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stateKey);
    notifyListeners();
  }

  void submitMyAnswer(String answer) {
    _dailyAnswers[_todaysQuestion.id] = answer;
    _todaysQuestion = _todaysQuestion.copyWith(myAnswer: answer, isMyAnswered: true);
    notifyListeners();
    _save();
  }

  void toggleWatchlistItem(String id) {
    final index = _watchlist.indexWhere((w) => w.id == id);
    if (index != -1) {
      _watchlist[index] = _watchlist[index].copyWith(isWatched: !_watchlist[index].isWatched);
      notifyListeners();
      _save();
    }
  }

  void addWatchlistItem(String title, {String type = 'movie', String platform = 'Netflix', required String addedBy}) {
    _watchlist.add(WatchlistItem(
      id: const Uuid().v4(),
      title: title,
      type: type,
      platform: platform,
      addedBy: addedBy,
    ));
    notifyListeners();
    _save();
  }

  void deleteWatchlistItem(String id) {
    _watchlist.removeWhere((w) => w.id == id);
    notifyListeners();
    _save();
  }

  void answerQuizQuestion(String questionId, int selectedIndex) {
    final index = _coupleQuiz.indexWhere((q) => q.id == questionId);
    if (index != -1) {
      _quizAnswers[questionId] = selectedIndex;
      _coupleQuiz[index] = _coupleQuiz[index].copyWith(mySelectedIndex: selectedIndex);
      notifyListeners();
      _save();
    }
  }

  void voteWhoMore(String questionId, String vote) {
    final index = _whoMoreList.indexWhere((q) => q.id == questionId);
    if (index != -1) {
      _whoMoreVotes[questionId] = vote;
      _whoMoreList[index] = _whoMoreList[index].copyWith(myVote: vote);
      notifyListeners();
      _save();
    }
  }
}
