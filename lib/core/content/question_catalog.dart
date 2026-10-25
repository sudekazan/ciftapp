import '../models/daily_question.dart';

/// A group of questions; premium packs are unlocked by the subscription.
class QuestionPack<T> {
  final String id;
  final String titleTr;
  final String titleEn;
  final bool isPremium;
  final List<T> items;

  const QuestionPack({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.items,
    this.isPremium = false,
  });

  String getTitle(String lang) => lang == 'en' ? titleEn : titleTr;
}

/// All built-in question content (TR/EN).
class QuestionCatalog {
  QuestionCatalog._();

  /// Rotates daily. Ids are stable: answers are stored per id and date.
  static const List<Map<String, String>> daily = [
    {'id': 'dq_01', 'tr': 'İlk tanıştığımız gün benim hakkımda ilk düşündüğün şey neydi?', 'en': 'What was your very first thought about me when we first met?'},
    {'id': 'dq_02', 'tr': 'Birlikte geçirdiğimiz en unutulmaz an hangisiydi?', 'en': 'What is the most memorable moment we have shared together?'},
    {'id': 'dq_03', 'tr': 'Benim en sevdiğin küçük alışkanlığım nedir?', 'en': 'What is your favorite little habit of mine?'},
    {'id': 'dq_04', 'tr': 'Bir gün tüm gün birlikte olsak ne yapmak isterdin?', 'en': 'If we had a whole free day together, what would you do?'},
    {'id': 'dq_05', 'tr': 'Bana en son ne zaman gurur duydun?', 'en': 'When was the last time you felt proud of me?'},
    {'id': 'dq_06', 'tr': 'Birlikte öğrenmek istediğin bir şey var mı?', 'en': 'Is there something you would like us to learn together?'},
    {'id': 'dq_07', 'tr': 'Seni en çok ne mutlu ediyor, bunu daha sık nasıl yapabilirim?', 'en': 'What makes you happiest, and how can I do it more often?'},
    {'id': 'dq_08', 'tr': 'Seni en çok güldüren anımız hangisi?', 'en': 'Which of our moments makes you laugh the most?'},
    {'id': 'dq_09', 'tr': 'Bana söylemek isteyip de henüz söylemediğin bir şey var mı?', 'en': "Is there something you've wanted to tell me but haven't yet?"},
    {'id': 'dq_10', 'tr': 'Birlikte yaşamak istediğin bir sonraki macera ne?', 'en': 'What adventure would you like us to have next?'},
    {'id': 'dq_11', 'tr': 'Bizi en iyi anlatan şarkı hangisi?', 'en': 'Which song describes us best?'},
    {'id': 'dq_12', 'tr': 'Benimle ilgili seni ilk etkileyen şey neydi?', 'en': 'What first attracted you to me?'},
    {'id': 'dq_13', 'tr': 'Bu hafta seni en mutlu eden küçük şey neydi?', 'en': 'What small thing made you happiest this week?'},
    {'id': 'dq_14', 'tr': 'Birlikte yaşlandığımızı hayal ettiğinde ne görüyorsun?', 'en': 'When you imagine us growing old together, what do you see?'},
    {'id': 'dq_15', 'tr': 'Hangi konuda sana daha çok destek olmamı istersin?', 'en': 'Where would you like more support from me?'},
    {'id': 'dq_16', 'tr': 'En sevdiğin fotoğrafımız hangisi ve neden?', 'en': 'Which photo of us is your favorite, and why?'},
    {'id': 'dq_17', 'tr': 'Mükemmel bir buluşma gününü anlatır mısın?', 'en': 'Can you describe a perfect date day?'},
    {'id': 'dq_18', 'tr': 'Benden öğrendiğin bir şey var mı?', 'en': "Is there something you've learned from me?"},
    {'id': 'dq_19', 'tr': 'İlişkimizde en çok gurur duyduğun şey ne?', 'en': 'What are you most proud of in our relationship?'},
    {'id': 'dq_20', 'tr': 'Kötü bir gününde sana nasıl iyi gelebilirim?', 'en': 'How can I comfort you on a bad day?'},
    {'id': 'dq_21', 'tr': 'Birlikte başlatmak istediğin bir gelenek var mı?', 'en': "Is there a tradition you'd like us to start?"},
    {'id': 'dq_22', 'tr': 'Beni üç kelimeyle anlatır mısın?', 'en': 'Can you describe me in three words?'},
    {'id': 'dq_23', 'tr': 'Birlikte izlemek istediğin bir film veya dizi hangisi?', 'en': "Which movie or show would you like us to watch together?"},
    {'id': 'dq_24', 'tr': 'Çocukluğundan bana anlatmadığın bir anıyı paylaşır mısın?', 'en': "Can you share a childhood memory you haven't told me?"},
    {'id': 'dq_25', 'tr': 'Sana sevildiğini en çok ne hissettirir?', 'en': 'What makes you feel most loved?'},
    {'id': 'dq_26', 'tr': 'Bir yıl sonra bu zamanlar ne yapıyor olmak isterdik?', 'en': 'What would we like to be doing a year from now?'},
    {'id': 'dq_27', 'tr': 'Hangi huyumu hiç değiştirmememi istersin?', 'en': 'Which trait of mine would you never want me to change?'},
    {'id': 'dq_28', 'tr': 'Birlikte gittiğimiz en güzel yer neresiydi?', 'en': "What is the most beautiful place we've been together?"},
    {'id': 'dq_29', 'tr': 'Hayatında şu an en çok neye minnettarsın?', 'en': 'What are you most grateful for in your life right now?'},
    {'id': 'dq_30', 'tr': 'Bugün bana söylemek istediğin tatlı bir şey var mı?', 'en': 'Is there something sweet you would like to tell me today?'},
  ];

  static QuizQuestion _quiz(String id, String tr, String en, List<String> optionsTr, List<String> optionsEn) =>
      QuizQuestion(id: id, questionTr: tr, questionEn: en, optionsTr: optionsTr, optionsEn: optionsEn);

  static final List<QuestionPack<QuizQuestion>> quizPacks = [
    QuestionPack(
      id: 'starter',
      titleTr: 'Başlangıç',
      titleEn: 'Starter',
      items: [
        _quiz('quiz_01', 'Benim en sevdiğim kahve türü hangisi?', 'What is my favorite coffee drink?',
            ['Latte', 'Americano', 'Filtre Kahve', 'Cappuccino'], ['Latte', 'Americano', 'Filter Coffee', 'Cappuccino']),
        _quiz('quiz_02', 'Stresli olduğumda beni en çok ne rahatlatır?', 'What relaxes me the most when stressed?',
            ['Müzik dinlemek', 'Sana sarılmak', 'Yürüyüşe çıkmak', 'Tatlı yemek'],
            ['Listening to music', 'Hugging you', 'Going for a walk', 'Eating sweets']),
        _quiz('quiz_03', 'Birlikte gitmek istediğimiz ilk yurt dışı tatili neresi?', 'Where is our dream first trip together?',
            ['İtalya', 'Japonya', 'İzlanda', 'İspanya'], ['Italy', 'Japan', 'Iceland', 'Spain']),
        _quiz('quiz_04', 'Birlikte en çok hangi aktiviteden keyif alıyoruz?', 'Which activity do we enjoy most together?',
            ['Film/dizi izlemek', 'Yemek yapmak', 'Gezmek', 'Oyun oynamak'],
            ['Watching movies/shows', 'Cooking', 'Traveling', 'Playing games']),
        _quiz('quiz_05', 'İdeal hafta sonumuz nasıl geçer?', 'What does our ideal weekend look like?',
            ['Evde dinlenerek', 'Şehirde gezerek', 'Doğada', 'Arkadaşlarla'],
            ['Relaxing at home', 'Exploring the city', 'In nature', 'With friends']),
      ],
    ),
    QuestionPack(
      id: 'deep',
      titleTr: 'Derinleşme',
      titleEn: 'Deeper',
      isPremium: true,
      items: [
        _quiz('deep_01', 'Tartıştığımızda en çok neye ihtiyaç duyuyoruz?', 'What do we need most when we argue?',
            ['Biraz yalnız kalmaya', 'Hemen konuşmaya', 'Sarılmaya', 'Biraz mizaha'],
            ['Some time alone', 'Talking it out right away', 'A hug', 'A bit of humor']),
        _quiz('deep_02', 'Sevgiyi en çok nasıl gösteriyoruz?', 'How do we show love the most?',
            ['Sözlerle', 'Dokunarak', 'Birlikte vakit geçirerek', 'Küçük sürprizlerle'],
            ['With words', 'Through touch', 'Spending time together', 'With little surprises']),
        _quiz('deep_03', 'İlişkimizin en güçlü yanı ne?', 'What is the strongest part of our relationship?',
            ['Güven', 'Mizah', 'İletişim', 'Tutku'], ['Trust', 'Humor', 'Communication', 'Passion']),
        _quiz('deep_04', 'Zor bir günün sonunda en iyi gelen şey ne?', 'What helps most at the end of a hard day?',
            ['Uzun bir sohbet', 'Sessizce yan yana olmak', 'Sevdiğimiz bir yemek', 'Bir film'],
            ['A long talk', 'Quietly being together', 'Our favorite food', 'A movie']),
        _quiz('deep_05', 'Birlikte en çok neyi geliştirmek istiyoruz?', 'What do we most want to improve together?',
            ['Daha çok vakit geçirmek', 'Daha açık iletişim', 'Ortak hedefler', 'Daha çok macera'],
            ['More time together', 'More open communication', 'Shared goals', 'More adventure']),
        _quiz('deep_06', 'Birbirimizi en çok ne zaman özlüyoruz?', 'When do we miss each other the most?',
            ['Sabah uyanınca', 'Akşam yemeğinde', 'Güzel bir şey olunca', 'Gece uyumadan önce'],
            ['When waking up', 'At dinner', 'When something good happens', 'Before falling asleep']),
      ],
    ),
    QuestionPack(
      id: 'future',
      titleTr: 'Geleceğimiz',
      titleEn: 'Our Future',
      isPremium: true,
      items: [
        _quiz('fut_01', 'Beş yıl sonra nerede yaşıyoruz?', 'Where do we live five years from now?',
            ['Büyük bir şehirde', 'Sahil kasabasında', 'Yurt dışında', 'Doğanın içinde'],
            ['In a big city', 'In a seaside town', 'Abroad', 'Close to nature']),
        _quiz('fut_02', 'Hayalimizdeki ev hangisi?', 'Which one is our dream home?',
            ['Şehir merkezinde daire', 'Bahçeli müstakil ev', 'Deniz manzaralı bir yer', 'Küçük bir dağ evi'],
            ['A downtown apartment', 'A house with a garden', 'A place with a sea view', 'A small cabin']),
        _quiz('fut_03', 'Birlikte ilk büyük hedefimiz ne olmalı?', 'What should our first big goal be?',
            ['Ortak bir ev', 'Büyük bir seyahat', 'Birikim yapmak', 'Bir evcil hayvan'],
            ['A home together', 'A big trip', 'Saving money', 'A pet']),
        _quiz('fut_04', 'Yıl dönümümüzü nasıl kutlamak isteriz?', 'How would we like to celebrate our anniversary?',
            ['Romantik bir akşam yemeği', 'Sürpriz bir seyahat', 'Evde baş başa', 'Arkadaşlarla parti'],
            ['A romantic dinner', 'A surprise trip', 'Just us at home', 'A party with friends']),
        _quiz('fut_05', 'Emekliliğimizi nasıl hayal ediyoruz?', 'How do we imagine our retirement?',
            ['Dünyayı gezerek', 'Bahçeyle uğraşarak', 'Torunlarla', 'Yeni hobilerle'],
            ['Traveling the world', 'Gardening', 'With grandchildren', 'With new hobbies']),
        _quiz('fut_06', 'Birlikte öğrenmek istediğimiz şey ne?', 'What would we like to learn together?',
            ['Yeni bir dil', 'Dans', 'Bir enstrüman', 'Yemek sanatı'],
            ['A new language', 'Dancing', 'An instrument', 'Cooking']),
      ],
    ),
  ];

  static WhoMoreQuestion _who(String id, String tr, String en) =>
      WhoMoreQuestion(id: id, questionTr: tr, questionEn: en);

  static final List<QuestionPack<WhoMoreQuestion>> whoMorePacks = [
    QuestionPack(
      id: 'starter',
      titleTr: 'Başlangıç',
      titleEn: 'Starter',
      items: [
        _who('who_01', 'Hangimiz sabahları daha zor uyanır?', 'Who is harder to wake up in the morning?'),
        _who('who_02', 'Hangimiz sürpriz yapmayı daha çok sever?', 'Who loves preparing surprises more?'),
        _who('who_03', 'Hangimiz daha kıskançtır?', 'Who gets jealous more easily?'),
        _who('who_04', 'Hangimiz tartışmalarda ilk adımı atıp özür diler?', 'Who takes the first step and apologizes first?'),
        _who('who_05', 'Hangimiz kaybolduğunda yol sormaktan daha çok çekinir?', 'Who is more hesitant to ask for directions when lost?'),
        _who('who_06', 'Hangimiz plan yapmadan spontane yaşamayı daha çok sever?', 'Who is more spontaneous and hates rigid plans?'),
      ],
    ),
    QuestionPack(
      id: 'fun',
      titleTr: 'Eğlenceli',
      titleEn: 'Fun',
      isPremium: true,
      items: [
        _who('fun_01', 'Hangimiz daha çok atıştırmalık saklar?', 'Who hides more snacks?'),
        _who('fun_02', 'Hangimiz filmlerin sonunu tahmin etmeye çalışır?', 'Who keeps guessing how movies end?'),
        _who('fun_03', 'Hangimiz daha çok selfie çeker?', 'Who takes more selfies?'),
        _who('fun_04', 'Hangimiz yol tarifinde daha iyidir?', 'Who is better with directions?'),
        _who('fun_05', 'Hangimiz daha uzun duş alır?', 'Who takes longer showers?'),
        _who('fun_06', 'Hangimiz dizilerde daha çok spoiler verir?', 'Who gives away more spoilers?'),
      ],
    ),
    QuestionPack(
      id: 'romance',
      titleTr: 'Romantik',
      titleEn: 'Romance',
      isPremium: true,
      items: [
        _who('rom_01', 'Hangimiz önce "seni seviyorum" dedi?', 'Who said "I love you" first?'),
        _who('rom_02', 'Hangimiz daha romantiktir?', 'Who is more romantic?'),
        _who('rom_03', 'Hangimiz özel günleri daha iyi hatırlar?', 'Who remembers special dates better?'),
        _who('rom_04', 'Hangimiz daha çok sarılmak ister?', 'Who wants more cuddles?'),
        _who('rom_05', 'Hangimiz daha çok aşk mesajı yazar?', 'Who writes more love messages?'),
        _who('rom_06', 'Hangimiz ilk görüşte daha çok etkilendi?', 'Who was more smitten at first sight?'),
      ],
    ),
  ];
}
