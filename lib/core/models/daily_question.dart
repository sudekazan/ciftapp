class DailyQuestion {
  final String id;
  final String questionTr;
  final String questionEn;
  final DateTime date;
  final String? myAnswer;
  final String? partnerAnswer;
  final bool isMyAnswered;
  final bool isPartnerAnswered;

  DailyQuestion({
    required this.id,
    required this.questionTr,
    required this.questionEn,
    required this.date,
    this.myAnswer,
    this.partnerAnswer,
    this.isMyAnswered = false,
    this.isPartnerAnswered = false,
  });

  bool get isRevealed => isMyAnswered && isPartnerAnswered;

  String getQuestion(String lang) {
    return lang == 'en' ? questionEn : questionTr;
  }

  DailyQuestion copyWith({
    String? id,
    String? questionTr,
    String? questionEn,
    DateTime? date,
    String? myAnswer,
    String? partnerAnswer,
    bool? isMyAnswered,
    bool? isPartnerAnswered,
  }) {
    return DailyQuestion(
      id: id ?? this.id,
      questionTr: questionTr ?? this.questionTr,
      questionEn: questionEn ?? this.questionEn,
      date: date ?? this.date,
      myAnswer: myAnswer ?? this.myAnswer,
      partnerAnswer: partnerAnswer ?? this.partnerAnswer,
      isMyAnswered: isMyAnswered ?? this.isMyAnswered,
      isPartnerAnswered: isPartnerAnswered ?? this.isPartnerAnswered,
    );
  }
}

class WatchlistItem {
  final String id;
  final String title;
  final String type; // 'movie', 'series'
  final String platform; // 'Netflix', 'Cinema', 'Prime', 'Disney+'
  final bool isWatched;
  final double rating;
  final String addedBy;

  WatchlistItem({
    required this.id,
    required this.title,
    this.type = 'movie',
    this.platform = 'Netflix',
    this.isWatched = false,
    this.rating = 0.0,
    required this.addedBy,
  });

  WatchlistItem copyWith({
    String? id,
    String? title,
    String? type,
    String? platform,
    bool? isWatched,
    double? rating,
    String? addedBy,
  }) {
    return WatchlistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      platform: platform ?? this.platform,
      isWatched: isWatched ?? this.isWatched,
      rating: rating ?? this.rating,
      addedBy: addedBy ?? this.addedBy,
    );
  }
}

class QuizQuestion {
  final String id;
  final String questionTr;
  final String questionEn;
  final List<String> optionsTr;
  final List<String> optionsEn;
  final int? mySelectedIndex;
  final int? partnerSelectedIndex;

  QuizQuestion({
    required this.id,
    required this.questionTr,
    required this.questionEn,
    required this.optionsTr,
    required this.optionsEn,
    this.mySelectedIndex,
    this.partnerSelectedIndex,
  });

  bool get isBothAnswered => mySelectedIndex != null && partnerSelectedIndex != null;
  bool get isMatch => isBothAnswered && mySelectedIndex == partnerSelectedIndex;

  QuizQuestion copyWith({
    String? id,
    String? questionTr,
    String? questionEn,
    List<String>? optionsTr,
    List<String>? optionsEn,
    int? mySelectedIndex,
    int? partnerSelectedIndex,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      questionTr: questionTr ?? this.questionTr,
      questionEn: questionEn ?? this.questionEn,
      optionsTr: optionsTr ?? this.optionsTr,
      optionsEn: optionsEn ?? this.optionsEn,
      mySelectedIndex: mySelectedIndex ?? this.mySelectedIndex,
      partnerSelectedIndex: partnerSelectedIndex ?? this.partnerSelectedIndex,
    );
  }
}

class WhoMoreQuestion {
  final String id;
  final String questionTr;
  final String questionEn;
  final String? myVote; // 'me' or 'partner'
  final String? partnerVote; // 'me' or 'partner'

  WhoMoreQuestion({
    required this.id,
    required this.questionTr,
    required this.questionEn,
    this.myVote,
    this.partnerVote,
  });

  bool get isBothVoted => myVote != null && partnerVote != null;
  bool get isAgreed => isBothVoted && myVote == partnerVote;

  String getQuestion(String lang) => lang == 'en' ? questionEn : questionTr;

  WhoMoreQuestion copyWith({
    String? id,
    String? questionTr,
    String? questionEn,
    String? myVote,
    String? partnerVote,
  }) {
    return WhoMoreQuestion(
      id: id ?? this.id,
      questionTr: questionTr ?? this.questionTr,
      questionEn: questionEn ?? this.questionEn,
      myVote: myVote ?? this.myVote,
      partnerVote: partnerVote ?? this.partnerVote,
    );
  }
}
