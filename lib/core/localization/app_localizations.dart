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
      'app_name': 'Yanyana',
      'app_tagline': 'Birlikte, Her Mesafede',

      // Navigation
      'nav_home': 'Ana Sayfa',
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
      'delete_account_warning': 'Hesabın, cevapların ve davet kodun kalıcı olarak silinir. Partnerin varsa ortak anılarınız onun hesabında kalmaya devam eder; tek başınaysan çift alanın ve tüm fotoğrafların da silinir. Bu işlem geri alınamaz.',
      'delete_permanently': 'Kalıcı Olarak Sil',
      'delete_account_done': 'Hesabın ve verilerin silindi.',
      'unpair_title': 'Eşleşmeyi Sonlandır',
      'unpair_warning': 'Ortak alandan ayrılırsın. Ortak anılar partnerinde kalır, sen boş bir alanla devam edersin. Bu işlem geri alınamaz.',
      'unpair_btn': 'Eşleşmeyi Sonlandır',
      'unpair_done': 'Eşleşme sonlandırıldı.',
      'cancel': 'Vazgeç',
      'confirm': 'Onayla',
      'save': 'Kaydet',

      // Setup & Onboarding
      'setup_step_name_title': 'Adınızı Öğrenelim',
      'setup_step_name_sub': 'Sana ve sevgiline özel çift alanını hazırlıyoruz',
      'setup_name_hint': 'Adınız veya Takma Adınız',
      'setup_step_date_title': 'Birliktelik Başlangıç Tarihi',
      'setup_step_date_sub': 'Aşkınızın başladığı özel günü seçin',
      'setup_step_mode_title': 'İlişki Modunuz',
      'setup_step_mode_sub': 'Uygulamayı ilişkinizin dinamiğine göre optimize edeceğiz',
      'setup_step_pair_title': 'Çift Alanınızı Seçin',
      'setup_step_pair_sub': 'Birlikte bağlanın veya partnerini hemen davet et',
      'setup_btn_continue': 'Devam Et',
      'setup_btn_start': 'Çift Alanımıza Başla',
      'setup_have_code': 'Eşleşme Kodum Var',
      'setup_create_space': 'Yeni Çift Alanı Oluştur',
      'setup_code_hint': 'Örn: LOVE-2024',
      'setup_share_invite': 'Davet Kodunu Paylaş',
      'setup_copy_code': 'Kodu Kopyala',
      'setup_copied_snack': 'Davet kodu kopyalandı!',
      'setup_enter_name_snack': 'Lütfen devam etmek için adınızı girin ❤️',
      'setup_enter_code_snack': 'Lütfen partnerinizin eşleşme kodunu girin',
      'pair_err_notFound': 'Bu koda ait bir çift alanı bulunamadı. Lütfen kodu kontrol et.',
      'pair_err_ownCode': 'Kendi davet kodunla eşleşemezsin. Partnerinin kodunu gir.',
      'pair_err_alreadyUsed': 'Bu davet kodu zaten başka bir eşleşmede kullanılmış.',
      'pair_err_unavailable': 'Şu an eşleşme yapılamadı. İnternet bağlantını kontrol edip tekrar dene.',
      'pair_success': 'Partnerinle başarıyla eşleştin! ❤️',

      // Dreams & Love Capsules
      'dreams_tab_bucket': 'Hayal Listesi ✈️',
      'dreams_tab_capsule': 'Aşk Kapsülü 💌',
      'dreams_add_dream': 'Yeni Hayal Ekle',
      'dreams_add_note': 'Zaman Kapsülü Mektubu',
      'dreams_empty_bucket': 'Henüz eklenmiş bir hayal yok',
      'dreams_empty_capsule': 'Henüz kilitli bir mektup bırakmadınız',
      'cat_all': 'Tümü',
      'cat_travel': 'Seyahat ✈️',
      'cat_romantic': 'Romantik 🍷',
      'cat_adventure': 'Macera 🏕️',
      'cat_future_home': 'Gelecek & Ev 🏡',
      'cat_experience': 'Deneyim 🎨',

      // Profile & Settings additions
      'profile_section_relationship': 'İlişki & Eşleşme',
      'profile_section_preferences': 'Uygulama Tercihleri',
      'profile_section_legal': 'Güvenlik & Yasal',
      'profile_start_date': 'Birliktelik Başlangıç Tarihi',
      'profile_dark_mode': 'Karanlık Mod',
      'profile_edit_name': 'Adını Düzenle',
      'profile_premium_active': 'Yanyana Premium Aktif ✨',
      'profile_upgrade_premium': 'Yanyana Premium’a Geçin',
      'profile_days_together_suffix': 'gündür birlikte',

      // Premium & Paywall
      'premium_title': 'Yanyana Premium',
      'premium_subtitle': 'İlişkinize özel tüm ayrıcalıkları sınırsız keşfedin',
      'feature_unlimited_photos': 'Sınırsız fotoğraf ve video anı saklama',
      'feature_all_games': 'Tüm ilişki oyunları ve derinleşme soru paketleri',
      'feature_advanced_calendar': 'Gelişmiş takvim ve ortak bütçe takibi',
      'feature_memory_book_export': 'Yıllık anı kitabı PDF çıktısı',
      'feature_single_payment': 'Tek bir kişi öder, iki partner de premium olur!',
      'monthly_plan': 'Aylık Plan',
      'yearly_plan': 'Yıllık Plan (En Popüler)',
      'start_trial_btn': '7 Gün Ücretsiz Dene ve Başla',
      'trial_info': '7 gün boyunca ücretsiz. Deneme süresi bitmeden önce iptal ederseniz ücret alınmaz. Dilediğiniz an tek tıkla iptal edebilirsiniz.',
      'restore_purchases': 'Satın Alımları Geri Yükle',
      'terms_of_use': 'Kullanım Şartları',
      'auto_renew_info': 'Abonelik, dönem bitiminden en az 24 saat önce iptal edilmezse otomatik yenilenir. App Store / Google Play hesap ayarlarından yönetebilirsiniz.',
      'premium_activated': 'Yanyana Premium aktif edildi! ❤️',
      'purchases_restored': 'Satın alımlarınız kontrol edildi.',
    },
    'en': {
      'app_name': 'Yanyana',
      'app_tagline': 'Together, Across Every Distance',

      // Navigation
      'nav_home': 'Home',
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
      'delete_account_warning': 'Your account, answers and invite code will be permanently deleted. If you have a partner, your shared memories stay in their account; if you are alone, your couple space and all photos are deleted too. This cannot be undone.',
      'delete_permanently': 'Delete Permanently',
      'delete_account_done': 'Your account and data have been deleted.',
      'unpair_title': 'End Pairing',
      'unpair_warning': 'You will leave the shared space. Shared memories stay with your partner and you continue with an empty space. This cannot be undone.',
      'unpair_btn': 'End Pairing',
      'unpair_done': 'Pairing ended.',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',

      // Setup & Onboarding
      'setup_step_name_title': 'What is Your Name?',
      'setup_step_name_sub': 'Creating your private couple space',
      'setup_name_hint': 'Your Name or Nickname',
      'setup_step_date_title': 'Relationship Start Date',
      'setup_step_date_sub': 'Select the special day your love began',
      'setup_step_mode_title': 'Your Relationship Dynamic',
      'setup_step_mode_sub': 'We will tailor the app to your dynamic',
      'setup_step_pair_title': 'Choose Your Couple Space',
      'setup_step_pair_sub': 'Connect together or invite your partner now',
      'setup_btn_continue': 'Continue',
      'setup_btn_start': 'Enter Our Couple Space',
      'setup_have_code': 'I Have an Invite Code',
      'setup_create_space': 'Create New Couple Space',
      'setup_code_hint': 'e.g. LOVE-2024',
      'setup_share_invite': 'Share Invite Code',
      'setup_copy_code': 'Copy Code',
      'setup_copied_snack': 'Invite code copied!',
      'setup_enter_name_snack': 'Please enter your name to continue ❤️',
      'setup_enter_code_snack': "Please enter your partner's invite code",
      'pair_err_notFound': 'No couple space was found for this code. Please check it.',
      'pair_err_ownCode': "You can't pair with your own invite code. Enter your partner's code.",
      'pair_err_alreadyUsed': 'This invite code has already been used by another couple.',
      'pair_err_unavailable': "Pairing isn't possible right now. Check your connection and try again.",
      'pair_success': 'You are now paired with your partner! ❤️',

      // Dreams & Love Capsules
      'dreams_tab_bucket': 'Bucket List ✈️',
      'dreams_tab_capsule': 'Love Capsule 💌',
      'dreams_add_dream': 'Add New Dream',
      'dreams_add_note': 'Add Love Letter',
      'dreams_empty_bucket': 'No dreams added yet',
      'dreams_empty_capsule': 'No love capsules written yet',
      'cat_all': 'All',
      'cat_travel': 'Travel ✈️',
      'cat_romantic': 'Romantic 🍷',
      'cat_adventure': 'Adventure 🏕️',
      'cat_future_home': 'Future & Home 🏡',
      'cat_experience': 'Experience 🎨',

      // Profile & Settings additions
      'profile_section_relationship': 'Relationship & Pairing',
      'profile_section_preferences': 'App Preferences',
      'profile_section_legal': 'Security & Legal',
      'profile_start_date': 'Relationship Start Date',
      'profile_dark_mode': 'Dark Mode',
      'profile_edit_name': 'Edit Name',
      'profile_premium_active': 'Yanyana Premium Active ✨',
      'profile_upgrade_premium': 'Upgrade to Yanyana Premium',
      'profile_days_together_suffix': 'days together',

      // Premium & Paywall
      'premium_title': 'Yanyana Premium',
      'premium_subtitle': 'Unlock the ultimate shared experience for you and your partner',
      'feature_unlimited_photos': 'Unlimited photos and video memories',
      'feature_all_games': 'All couple games & deep relationship questions',
      'feature_advanced_calendar': 'Advanced calendar & shared budget tracking',
      'feature_memory_book_export': 'Annual Memory Book printable PDF export',
      'feature_single_payment': 'One subscription covers both partners!',
      'monthly_plan': 'Monthly Plan',
      'yearly_plan': 'Yearly Plan (Best Value)',
      'start_trial_btn': 'Start 7-Day Free Trial',
      'trial_info': 'Free for 7 days. Cancel anytime before trial ends and you will not be charged.',
      'restore_purchases': 'Restore Purchases',
      'terms_of_use': 'Terms of Use',
      'auto_renew_info': 'Subscription renews automatically unless cancelled at least 24 hours before the end of the period. Manage it in your App Store / Google Play account settings.',
      'premium_activated': 'Yanyana Premium is now active! ❤️',
      'purchases_restored': 'Your purchases have been checked.',
    },
  };

  static Set<String> get supportedKeys => _localizedValues['tr']!.keys.toSet();
  static Set<String> keysFor(String lang) => _localizedValues[lang]?.keys.toSet() ?? {};

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
