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
      'notif_prompt_title': 'Partnerinden haberin olsun 💌',
      'notif_prompt_body': 'Partnerin seni düşündüğünde, günün sorusunu cevapladığında veya yeni bir anı eklediğinde sana haber verelim.',
      'notif_prompt_allow': 'Bildirimlere İzin Ver',
      'notif_prompt_later': 'Şimdi Değil',

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
      'premium_feat_memories_title': 'Sınırsız Anı ve Fotoğraf',
      'premium_feat_memories_desc': 'Anı sınırı olmadan, her anıya {m} fotoğrafa kadar ekleyin.',
      'premium_feat_love_title': 'Sınırsız Sevgi Dokunuşu ve Zaman Kapsülü',
      'premium_feat_love_desc': '"Seni düşünüyorum" sinyalini ve zaman kapsülü notlarını sınırsız gönderin.',
      'premium_feat_questions_title': 'Tüm Soru Paketleri ve Cevap Arşivi',
      'premium_feat_questions_desc': 'Premium çift oyunu paketlerinin tamamı ve 1 yıllık günün sorusu arşivi.',
      'premium_feat_couple_title': '1 Üyelik = 2 Kişi',
      'premium_feat_couple_desc': 'Tek bir partner öder, eşleştiğiniz sürece ikiniz de Premium olursunuz.',
      'monthly_plan': 'Aylık Plan',
      'yearly_plan': 'Yıllık Plan (En Popüler)',
      'start_trial_btn': '{n} Gün Ücretsiz Dene',
      'subscribe_btn': 'Premium’a Geç',
      'trial_info': '{n} gün ücretsiz, ardından {price}. Deneme bitmeden iptal edersen ücret alınmaz.',
      'plan_renews_monthly': 'Her ay yenilenir',
      'plan_yearly_detail': 'Aylık yalnızca {price}',
      'plan_yearly_detail_savings': 'Aylık yalnızca {price} (%{p} tasarruf)',
      'plan_savings_badge': '%{p} TASARRUF',
      'per_month': 'ay',
      'per_year': 'yıl',
      'offerings_loading': 'Planlar yükleniyor...',
      'retry': 'Tekrar Dene',
      'subscription_title': 'Aboneliğim',
      'subscription_plan_monthly': 'Aylık Premium',
      'subscription_plan_yearly': 'Yıllık Premium',
      'subscription_plan_unknown': 'Yanyana Premium',
      'subscription_trial': 'Ücretsiz deneme süresindesin',
      'subscription_renews_on': 'Yenilenme tarihi: {date}',
      'subscription_ends_on': 'Bitiş tarihi: {date} (otomatik yenileme kapalı)',
      'subscription_from_partner': '{name} aboneliği sayesinde Premium’sun ❤️',
      'subscription_from_partner_until': 'Geçerlilik: {date}',
      'subscription_manage': 'Aboneliği Yönet veya İptal Et',
      'subscription_manage_hint': 'İptal ve plan değişikliği App Store / Google Play hesabından yapılır.',
      'restore_purchases': 'Satın Alımları Geri Yükle',
      'terms_of_use': 'Kullanım Şartları',
      'auto_renew_info': 'Abonelik, dönem bitiminden en az 24 saat önce iptal edilmezse otomatik yenilenir. App Store / Google Play hesap ayarlarından yönetebilirsiniz.',
      'premium_activated': 'Yanyana Premium aktif edildi! ❤️',
      'purchases_restored': 'Satın alımlarınız kontrol edildi.',
      'purchase_pending': 'Ödemen onay bekliyor. Onaylandığında Premium otomatik olarak açılacak.',
      'purchase_err_notConfigured': 'Satın alma şu anda kullanılamıyor. Lütfen daha sonra tekrar dene.',
      'purchase_err_network': 'İnternet bağlantısı yok gibi görünüyor. Bağlantını kontrol edip tekrar dene.',
      'purchase_err_store': 'Mağazada geçici bir sorun var. Lütfen biraz sonra tekrar dene.',
      'purchase_err_notAllowed': 'Bu cihazda satın alma yapılmasına izin verilmiyor.',
      'purchase_err_productUnavailable': 'Bu plan şu anda satın alınamıyor.',
      'purchase_err_unknown': 'Satın alma tamamlanamadı. Lütfen tekrar dene.',
      'offerings_unavailable': 'Planlar mağazadan yüklenemedi. Lütfen internet bağlantını kontrol et.',
      'restore_success': 'Aboneliğin başarıyla geri yüklendi! ❤️',
      'restore_none': 'Bu hesaba ait aktif bir abonelik bulunamadı.',
      'paywall_reason_memoryLimit': 'Ücretsiz planda {n} anı ekleyebilirsin. Sınırsız anı için Premium’a geç.',
      'paywall_reason_photoLimit': 'Ücretsiz planda anı başına {n} fotoğraf ekleyebilirsin. Premium ile {m} fotoğrafa kadar.',
      'paywall_reason_pulseLimit': 'Bugünkü {n} ücretsiz "Seni düşünüyorum" hakkını kullandın. Premium ile sınırsız gönder.',
      'paywall_reason_capsuleLimit': 'Ücretsiz planda ayda {n} zaman kapsülü oluşturabilirsin. Premium ile sınırsız.',
      'paywall_reason_questionArchive': 'Son {n} günden eski cevaplarınızı görmek için Premium’a geç.',
      'paywall_reason_questionPack': 'Bu soru paketi Premium’a özel. Tüm paketleri birlikte açın.',
      'memories_free_usage': 'Ücretsiz plan: {n}/{m} anı',
      'memories_upgrade_hint': 'Sınırsız anı ve anı başına {m} fotoğraf için Premium’a geç',
      'photo_limit_reached': 'Bu anıya en fazla {n} fotoğraf ekleyebilirsin.',
      'pulse_remaining': 'Bugün {n} ücretsiz dokunuş hakkın kaldı',
      'archive_locked': '{n} günden eski cevaplar Premium’da',
      'capsule_free_note': 'Ücretsiz planda ayda {n} zaman kapsülü oluşturabilirsin.',
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
      'notif_prompt_title': 'Never miss your partner 💌',
      'notif_prompt_body': 'We will let you know when your partner is thinking of you, answers the daily question or adds a new memory.',
      'notif_prompt_allow': 'Allow Notifications',
      'notif_prompt_later': 'Not Now',

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
      'premium_feat_memories_title': 'Unlimited Memories & Photos',
      'premium_feat_memories_desc': 'No memory limit and up to {m} photos per memory.',
      'premium_feat_love_title': 'Unlimited Love Taps & Time Capsules',
      'premium_feat_love_desc': 'Send unlimited "Thinking of you" taps and time capsule notes.',
      'premium_feat_questions_title': 'All Question Packs & Answer Archive',
      'premium_feat_questions_desc': 'Every premium couple game pack and a 1-year daily question archive.',
      'premium_feat_couple_title': '1 Subscription = 2 Users',
      'premium_feat_couple_desc': 'One partner pays and you are both Premium while you are paired.',
      'monthly_plan': 'Monthly Plan',
      'yearly_plan': 'Yearly Plan (Best Value)',
      'start_trial_btn': 'Start {n}-Day Free Trial',
      'subscribe_btn': 'Go Premium',
      'trial_info': 'Free for {n} days, then {price}. Cancel before the trial ends and you will not be charged.',
      'plan_renews_monthly': 'Renews monthly',
      'plan_yearly_detail': 'Only {price} / month',
      'plan_yearly_detail_savings': 'Only {price} / month (save {p}%)',
      'plan_savings_badge': 'SAVE {p}%',
      'per_month': 'month',
      'per_year': 'year',
      'offerings_loading': 'Loading plans...',
      'retry': 'Try Again',
      'subscription_title': 'My Subscription',
      'subscription_plan_monthly': 'Monthly Premium',
      'subscription_plan_yearly': 'Yearly Premium',
      'subscription_plan_unknown': 'Yanyana Premium',
      'subscription_trial': 'You are on a free trial',
      'subscription_renews_on': 'Renews on {date}',
      'subscription_ends_on': 'Ends on {date} (auto-renew is off)',
      'subscription_from_partner': "You're Premium thanks to {name}'s subscription ❤️",
      'subscription_from_partner_until': 'Valid until {date}',
      'subscription_manage': 'Manage or Cancel Subscription',
      'subscription_manage_hint': 'Cancellation and plan changes are done in your App Store / Google Play account.',
      'restore_purchases': 'Restore Purchases',
      'terms_of_use': 'Terms of Use',
      'auto_renew_info': 'Subscription renews automatically unless cancelled at least 24 hours before the end of the period. Manage it in your App Store / Google Play account settings.',
      'premium_activated': 'Yanyana Premium is now active! ❤️',
      'purchases_restored': 'Your purchases have been checked.',
      'purchase_pending': 'Your payment is awaiting approval. Premium will unlock automatically once it is approved.',
      'purchase_err_notConfigured': 'Purchases are not available right now. Please try again later.',
      'purchase_err_network': 'You seem to be offline. Check your connection and try again.',
      'purchase_err_store': 'The store is having a temporary problem. Please try again shortly.',
      'purchase_err_notAllowed': 'Purchases are not allowed on this device.',
      'purchase_err_productUnavailable': 'This plan is not available for purchase right now.',
      'purchase_err_unknown': 'The purchase could not be completed. Please try again.',
      'offerings_unavailable': "Plans couldn't be loaded from the store. Please check your connection.",
      'restore_success': 'Your subscription has been restored! ❤️',
      'restore_none': 'No active subscription was found for this account.',
      'paywall_reason_memoryLimit': 'The free plan includes {n} memories. Go Premium for unlimited memories.',
      'paywall_reason_photoLimit': 'The free plan allows {n} photos per memory. Premium allows up to {m}.',
      'paywall_reason_pulseLimit': 'You used today\'s {n} free "Thinking of you" taps. Go Premium to send unlimited.',
      'paywall_reason_capsuleLimit': 'The free plan includes {n} time capsule per month. Premium is unlimited.',
      'paywall_reason_questionArchive': 'Go Premium to see your answers older than {n} days.',
      'paywall_reason_questionPack': 'This question pack is Premium. Unlock every pack together.',
      'memories_free_usage': 'Free plan: {n}/{m} memories',
      'memories_upgrade_hint': 'Go Premium for unlimited memories and {m} photos per memory',
      'photo_limit_reached': 'You can add up to {n} photos to this memory.',
      'pulse_remaining': '{n} free taps left today',
      'archive_locked': 'Answers older than {n} days are Premium',
      'capsule_free_note': 'The free plan includes {n} time capsule per month.',
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

  /// [text] with `{name}` placeholders replaced, e.g. `textf('k', {'n': 3})`.
  String textf(String key, Map<String, Object> args) {
    var value = text(key);
    args.forEach((name, arg) => value = value.replaceAll('{$name}', '$arg'));
    return value;
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
