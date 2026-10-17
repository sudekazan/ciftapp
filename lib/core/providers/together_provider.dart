import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_question.dart';

class TogetherProvider extends ChangeNotifier {
  late DailyQuestion _todaysQuestion;
  final List<DailyQuestion> _pastQuestions = [];
  final List<WatchlistItem> _watchlist = [];
  final List<QuizQuestion> _coupleQuiz = [];
  final List<WhoMoreQuestion> _whoMoreList = [];

  DailyQuestion get todaysQuestion => _todaysQuestion;
  List<DailyQuestion> get pastQuestions => List.unmodifiable(_pastQuestions);
  List<WatchlistItem> get watchlist => List.unmodifiable(_watchlist);
  List<QuizQuestion> get coupleQuiz => List.unmodifiable(_coupleQuiz);
  List<WhoMoreQuestion> get whoMoreList => List.unmodifiable(_whoMoreList);

  int get quizMatchCount => _coupleQuiz.where((q) => q.isMatch).length;
  int get whoMoreAgreementCount => _whoMoreList.where((q) => q.isAgreed).length;

  TogetherProvider() {
    _loadSampleContent();
  }

  void _loadSampleContent() {
    final now = DateTime.now();

    _todaysQuestion = DailyQuestion(
      id: const Uuid().v4(),
      questionTr: 'İlk tanıştığımız gün benim hakkımda ilk düşündüğün şey neydi?',
      questionEn: 'What was your very first thought about me when we first met?',
      date: now,
      myAnswer: 'Gülümsemenin çok samimi ve sıcak olduğunu düşünmüştüm.',
      partnerAnswer: 'Gözlerinin parıltısı ve esprilerin beni hemen etkilemişti!',
      isMyAnswered: true,
      isPartnerAnswered: true,
    );

    _pastQuestions.addAll([
      DailyQuestion(
        id: const Uuid().v4(),
        questionTr: 'Birlikte geçirdiğimiz en unutulmaz an hangisiydi?',
        questionEn: 'What is the most memorable moment we have shared together?',
        date: now.subtract(const Duration(days: 1)),
        myAnswer: 'Yağmur altında sırılsıklam olup güldüğümüz o gece.',
        partnerAnswer: 'Sahilde sabaha kadar oturup gelecek planları yaptığımız gün.',
        isMyAnswered: true,
        isPartnerAnswered: true,
      ),
      DailyQuestion(
        id: const Uuid().v4(),
        questionTr: 'Benim en sevdiğin küçük alışkanlığım nedir?',
        questionEn: 'What is your favorite little habit of mine?',
        date: now.subtract(const Duration(days: 2)),
        myAnswer: 'Kahve yaparken şarkı mırıldanman.',
        partnerAnswer: 'Heyecanlandığında ellerinle anlattığın anlar.',
        isMyAnswered: true,
        isPartnerAnswered: true,
      ),
    ]);

    _watchlist.addAll([
      WatchlistItem(
        id: const Uuid().v4(),
        title: 'Normal People',
        type: 'series',
        platform: 'BluTV / Hulu',
        isWatched: true,
        rating: 4.8,
        addedBy: 'Sude',
      ),
      WatchlistItem(
        id: const Uuid().v4(),
        title: 'Past Lives',
        type: 'movie',
        platform: 'MUBI',
        isWatched: true,
        rating: 5.0,
        addedBy: 'Can',
      ),
      WatchlistItem(
        id: const Uuid().v4(),
        title: 'About Time',
        type: 'movie',
        platform: 'Netflix',
        isWatched: false,
        rating: 0.0,
        addedBy: 'Sude',
      ),
      WatchlistItem(
        id: const Uuid().v4(),
        title: 'Modern Love',
        type: 'series',
        platform: 'Prime Video',
        isWatched: false,
        rating: 0.0,
        addedBy: 'Can',
      ),
    ]);

    _coupleQuiz.addAll([
      QuizQuestion(
        id: const Uuid().v4(),
        questionTr: 'Benim en sevdiğim kahve türü hangisi?',
        questionEn: 'What is my favorite coffee drink?',
        optionsTr: ['Latte', 'Americano', 'Filtre Kahve', 'Cappuccino'],
        optionsEn: ['Latte', 'Americano', 'Filter Coffee', 'Cappuccino'],
        mySelectedIndex: 2,
        partnerSelectedIndex: 2,
      ),
      QuizQuestion(
        id: const Uuid().v4(),
        questionTr: 'Stresli olduğumda beni en çok ne rahatlatır?',
        questionEn: 'What relaxes me the most when stressed?',
        optionsTr: ['Müzik dinlemek', 'Sana sarılmak', 'Yürüyüşe çıkmak', 'Tatlı yemek'],
        optionsEn: ['Listening to music', 'Hugging you', 'Going for a walk', 'Eating sweets'],
        mySelectedIndex: 1,
        partnerSelectedIndex: 1,
      ),
      QuizQuestion(
        id: const Uuid().v4(),
        questionTr: 'Birlikte gitmek istediğimiz ilk yurt dışı tatili neresi?',
        questionEn: 'Where is our dream first trip together?',
        optionsTr: ['İtalya', 'Japonya', 'İzlanda', 'İspanya'],
        optionsEn: ['Italy', 'Japan', 'Iceland', 'Spain'],
        mySelectedIndex: 0,
        partnerSelectedIndex: 0,
      ),
    ]);

    _whoMoreList.addAll([
      WhoMoreQuestion(
        id: const Uuid().v4(),
        questionTr: 'Hangimiz sabahları daha zor uyanır?',
        questionEn: 'Who is harder to wake up in the morning?',
        myVote: 'me',
        partnerVote: 'me',
      ),
      WhoMoreQuestion(
        id: const Uuid().v4(),
        questionTr: 'Hangimiz sürpriz yapmayı daha çok sever?',
        questionEn: 'Who loves preparing surprises more?',
        myVote: 'partner',
        partnerVote: 'partner',
      ),
      WhoMoreQuestion(
        id: const Uuid().v4(),
        questionTr: 'Hangimiz daha kıskançtır?',
        questionEn: 'Who gets jealous more easily?',
        myVote: 'me',
        partnerVote: 'partner',
      ),
      WhoMoreQuestion(
        id: const Uuid().v4(),
        questionTr: 'Hangimiz tartışmalarda ilk adımı atıp özür diler?',
        questionEn: 'Who takes the first step and apologizes first?',
        myVote: 'partner',
        partnerVote: 'partner',
      ),
      WhoMoreQuestion(
        id: const Uuid().v4(),
        questionTr: 'Hangimiz kaybolduğunda yol sormaktan daha çok çekinir?',
        questionEn: 'Who is more hesitant to ask for directions when lost?',
        myVote: null,
        partnerVote: 'partner',
      ),
      WhoMoreQuestion(
        id: const Uuid().v4(),
        questionTr: 'Hangimiz plan yapmadan spontane yaşamayı daha çok sever?',
        questionEn: 'Who is more spontaneous and hates rigid plans?',
        myVote: null,
        partnerVote: 'me',
      ),
    ]);
  }

  void submitMyAnswer(String answer) {
    _todaysQuestion = _todaysQuestion.copyWith(
      myAnswer: answer,
      isMyAnswered: true,
    );
    notifyListeners();
  }

  void toggleWatchlistItem(String id) {
    final index = _watchlist.indexWhere((w) => w.id == id);
    if (index != -1) {
      _watchlist[index] = _watchlist[index].copyWith(isWatched: !_watchlist[index].isWatched);
      notifyListeners();
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
  }

  void deleteWatchlistItem(String id) {
    _watchlist.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  void answerQuizQuestion(String questionId, int selectedIndex) {
    final index = _coupleQuiz.indexWhere((q) => q.id == questionId);
    if (index != -1) {
      _coupleQuiz[index] = _coupleQuiz[index].copyWith(mySelectedIndex: selectedIndex);
      notifyListeners();
    }
  }

  void voteWhoMore(String questionId, String vote) {
    final index = _whoMoreList.indexWhere((q) => q.id == questionId);
    if (index != -1) {
      _whoMoreList[index] = _whoMoreList[index].copyWith(myVote: vote);
      notifyListeners();
    }
  }
}
