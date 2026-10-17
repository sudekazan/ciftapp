import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('tr'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'tr': {
      'app_name': 'ÇiftApp',
      'app_tagline': 'Birlikte, Her Mesafede',

      // Navigation
      'nav_home': 'Ana Sayfa',
      'nav_chat': 'Sohbet',
      'nav_dreams': 'Hayallerimiz',
      'nav_plans': 'Planlar',
      'nav_together': 'Birlikte',
      'nav_memories': 'Anılar',

      // Modes
      'mode_long_distance': 'Uzak Mesafe',
      'mode_co_living': 'Birlikte Yaşıyoruz',
      'mode_switch_title': 'İlişki Modunu Değiştir',
      'mode_switch_desc': 'İlişkinizin durumuna göre ana sayfa ve öne çıkan araçlar değişir.',

      // Home Screen - Common
      'days_together': 'Gündür Birlikteyiz',
      'connected_with': 'Partnerinle Bağlı',
      'unpaired_warning': 'Henüz bir partnerle eşleşmediniz.',
      'pair_now_btn': 'Partnerini Bağla',

      // Home Screen - Long Distance
      'thinking_of_you': 'Seni Düşünüyorum',
      'thinking_of_you_sub': 'Kalbe dokunarak sevgini anında hissettir',
      'thinking_sent_just_now': 'Partnerin az önce seni düşündü! ❤️',
      'next_reunion': 'Gelecek Buluşmamız',
      'reunion_countdown': 'Buluşmaya Kalan Süre',
      'partner_time': 'Partnerinin Saati',
      'my_time': 'Senin Saatin',
      'distance_km': 'Aramızdaki Mesafe',
      'time_difference': 'Saat Farkı',

      // Home Screen - Co-Living
      'today_overview': 'Bugünün Planı',
      'pending_tasks': 'Bekleyen Görevler',
      'shopping_summary': 'Ortak Alışveriş Listesi',
      'items_to_buy': 'alınacak ürün var',
      'no_pending_tasks': 'Bekleyen görev yok! 🎉',
      'quick_add_task': 'Hızlı Görev Ekle',

      // Daily Question
      'daily_question_title': 'Günün Sorusu',
      'daily_question_locked': 'İki taraf da yanıtladığında cevaplar açılacak.',
      'daily_question_answered_waiting': 'Cevabın kaydedildi! Partnerinin cevabı bekleniyor...',
      'daily_question_revealed': 'Her iki tarafın yanıtı açıldı!',
      'answer_btn': 'Soruyu Yanıtla',
      'your_answer': 'Senin Yanıtın',
      'partner_answer': 'Partnerinin Yanıtı',
      'write_your_answer': 'Düşüncelerini buraya yaz...',

      // Chat
      'chat_title': 'Özel Alanımız',
      'type_message': 'Mesajınızı yazın...',
      'voice_note': 'Sesli Not',
      'send_surprise': 'Sürpriz Mesaj Zamanla',
      'surprise_message_title': 'Sürpriz Mesaj',
      'surprise_message_desc': 'Partnerin bu mesajı belirlediğin tarihte açabilecek.',
      'scheduled_for': 'Açılma Zamanı',
      'surprise_locked': 'Bu sürpriz kilitli! 🎁',

      // Plans
      'plans_title': 'Ortak Planlar',
      'tab_calendar': 'Takvim',
      'tab_tasks': 'Görevler',
      'tab_shopping': 'Alışveriş',
      'add_event': 'Etkinlik Ekle',
      'add_task': 'Görev Ekle',
      'add_shopping_item': 'Ürün Ekle',
      'completed': 'Tamamlandı',
      'due_date': 'Tarih',

      // Together
      'together_title': 'Birlikte Vakit',
      'section_games': 'Çift Oyunları',
      'quiz_how_well': 'Beni Ne Kadar Tanıyorsun?',
      'quiz_who_more': 'Hangimiz Daha...?',
      'section_watchlist': 'Ortak İzleme Listesi',
      'add_to_watchlist': 'Dizi / Film Ekle',
      'watched': 'İzlendi',
      'to_watch': 'İzlenecek',

      // Memories
      'memories_title': 'Anılar ve Sayaçlar',
      'tab_memory_book': 'Anı Defteri',
      'tab_countdowns': 'Sayaçlar',
      'add_memory': 'Yeni Anı Ekle',
      'add_countdown': 'Yeni Sayaç Ekle',
      'memory_photo': 'Fotoğraf Ekle',
      'memory_note': 'Bu anı hakkında bir not yaz...',
      'photo_limit_notice': 'Ücretsiz planda 10 anı hakkınız bulunmaktadır.',

      // Profile & Settings
      'profile_title': 'Profil ve Ayarlar',
      'partner_pairing': 'Partner Eşleşmesi',
      'your_invite_code': 'Davet Kodun',
      'copy_code': 'Kodu Kopyala',
      'share_code': 'Kodu Paylaş',
      'enter_partner_code': 'Partnerin Kodunu Gir',
      'connect_button': 'Eşleşmeyi Tamamla',
      'change_mode': 'İlişki Modu',
      'language': 'Dil / Language',
      'subscription': 'Abonelik ve Premium',
      'notifications': 'Bildirim Ayarları',
      'privacy_policy': 'Gizlilik Politikası ve KVKK',
      'terms_of_service': 'Kullanım Şartları',
      'delete_account': 'Hesabı ve Verileri Sil',
      'delete_account_warning': 'Tüm mesajlarınız, anılarınız ve çift alanınız kalıcı olarak silinir. Bu işlem geri alınamaz.',
      'cancel': 'Vazgeç',
      'confirm': 'Onayla',
      'save': 'Kaydet',

      // Premium & Paywall
      'premium_title': 'ÇiftApp Premium',
      'premium_subtitle': 'İlişkinize özel tüm ayrıcalıkları sınırsız keşfedin',
      'feature_unlimited_photos': 'Sınırsız fotoğraf ve video anı saklama',
      'feature_voice_surprise': 'Sesli notlar ve zamanlanmış sürpriz mesajlar',
      'feature_all_games': 'Tüm ilişki oyunları ve derinleşme soru paketleri',
      'feature_advanced_calendar': 'Gelişmiş takvim ve ortak bütçe takibi',
      'feature_memory_book_export': 'Yıllık anı kitabı PDF çıktısı',
      'feature_single_payment': 'Tek bir kişi öder, iki partner de premium olur!',
      'monthly_plan': 'Aylık Plan',
      'yearly_plan': 'Yıllık Plan (En Popüler)',
      'start_trial_btn': '7 Gün Ücretsiz Dene ve Başla',
      'trial_info': '7 gün boyunca ücretsiz. Deneme süresi bitmeden önce iptal ederseniz ücret alınmaz. Dilediğiniz an tek tıkla iptal edebilirsiniz.',
      'restore_purchases': 'Satın Alımları Geri Yükle',
    },
    'en': {
      'app_name': 'ÇiftApp',
      'app_tagline': 'Together, Across Every Distance',

      // Navigation
      'nav_home': 'Home',
      'nav_chat': 'Chat',
      'nav_dreams': 'Bucket List',
      'nav_plans': 'Plans',
      'nav_together': 'Together',
      'nav_memories': 'Memories',

      // Modes
      'mode_long_distance': 'Long Distance',
      'mode_co_living': 'Living Together',
      'mode_switch_title': 'Switch Relationship Mode',
      'mode_switch_desc': 'The home dashboard adapts to your current relationship dynamic.',

      // Home Screen - Common
      'days_together': 'Days Together',
      'connected_with': 'Connected with',
      'unpaired_warning': 'You are not paired with a partner yet.',
      'pair_now_btn': 'Connect Partner',

      // Home Screen - Long Distance
      'thinking_of_you': 'Thinking of You',
      'thinking_of_you_sub': 'Tap the heart to instantly send love & warmth',
      'thinking_sent_just_now': 'Your partner just sent you love! ❤️',
      'next_reunion': 'Next Reunion',
      'reunion_countdown': 'Countdown to Next Reunion',
      'partner_time': "Partner's Time",
      'my_time': 'Your Time',
      'distance_km': 'Distance Between Us',
      'time_difference': 'Time Difference',

      // Home Screen - Co-Living
      'today_overview': "Today's Plan",
      'pending_tasks': 'Pending Tasks',
      'shopping_summary': 'Shared Shopping List',
      'items_to_buy': 'items to buy',
      'no_pending_tasks': 'No pending tasks! 🎉',
      'quick_add_task': 'Quick Add Task',

      // Daily Question
      'daily_question_title': 'Daily Question',
      'daily_question_locked': 'Answers unlock once both partners have submitted.',
      'daily_question_answered_waiting': 'Your answer is saved! Waiting for partner...',
      'daily_question_revealed': 'Both answers are revealed!',
      'answer_btn': 'Answer Question',
      'your_answer': 'Your Answer',
      'partner_answer': "Partner's Answer",
      'write_your_answer': 'Write your thoughts here...',

      // Chat
      'chat_title': 'Our Safe Space',
      'type_message': 'Type a message...',
      'voice_note': 'Voice Note',
      'send_surprise': 'Schedule Surprise Message',
      'surprise_message_title': 'Surprise Message',
      'surprise_message_desc': 'Your partner can only open this message on the chosen date.',
      'scheduled_for': 'Reveal Date',
      'surprise_locked': 'This surprise is locked! 🎁',

      // Plans
      'plans_title': 'Shared Plans',
      'tab_calendar': 'Calendar',
      'tab_tasks': 'Tasks',
      'tab_shopping': 'Shopping',
      'add_event': 'Add Event',
      'add_task': 'Add Task',
      'add_shopping_item': 'Add Item',
      'completed': 'Completed',
      'due_date': 'Due Date',

      // Together
      'together_title': 'Time Together',
      'section_games': 'Couple Games',
      'quiz_how_well': 'How Well Do You Know Me?',
      'quiz_who_more': "Who's More Likely To...?",
      'section_watchlist': 'Shared Watchlist',
      'add_to_watchlist': 'Add Movie / Show',
      'watched': 'Watched',
      'to_watch': 'Want to Watch',

      // Memories
      'memories_title': 'Memories & Timers',
      'tab_memory_book': 'Memory Book',
      'tab_countdowns': 'Countdowns',
      'add_memory': 'Add Memory',
      'add_countdown': 'Add Countdown',
      'memory_photo': 'Add Photo',
      'memory_note': 'Write a note about this memory...',
      'photo_limit_notice': 'Free plan includes up to 10 memories.',

      // Profile & Settings
      'profile_title': 'Profile & Settings',
      'partner_pairing': 'Partner Pairing',
      'your_invite_code': 'Your Invite Code',
      'copy_code': 'Copy Code',
      'share_code': 'Share Code',
      'enter_partner_code': "Enter Partner's Code",
      'connect_button': 'Complete Pairing',
      'change_mode': 'Relationship Mode',
      'language': 'Language / Dil',
      'subscription': 'Subscription & Premium',
      'notifications': 'Notification Settings',
      'privacy_policy': 'Privacy Policy & GDPR',
      'terms_of_service': 'Terms of Service',
      'delete_account': 'Delete Account & Data',
      'delete_account_warning': 'All messages, memories, and couple space will be permanently erased. This cannot be undone.',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',

      // Premium & Paywall
      'premium_title': 'ÇiftApp Premium',
      'premium_subtitle': 'Unlock the ultimate shared experience for you and your partner',
      'feature_unlimited_photos': 'Unlimited photos and video memories',
      'feature_voice_surprise': 'Voice notes & scheduled surprise messages',
      'feature_all_games': 'All couple games & deep relationship questions',
      'feature_advanced_calendar': 'Advanced calendar & shared budget tracking',
      'feature_memory_book_export': 'Annual Memory Book printable PDF export',
      'feature_single_payment': 'One subscription covers both partners!',
      'monthly_plan': 'Monthly Plan',
      'yearly_plan': 'Yearly Plan (Best Value)',
      'start_trial_btn': 'Start 7-Day Free Trial',
      'trial_info': 'Free for 7 days. Cancel anytime before trial ends and you will not be charged.',
      'restore_purchases': 'Restore Purchases',
    },
  };

  String text(String key) {
    final lang = locale.languageCode;
    return _localizedValues[lang]?[key] ??
        _localizedValues['tr']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['tr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
