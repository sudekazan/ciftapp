class SubscriptionPlan {
  final String id;
  final String titleTr;
  final String titleEn;
  final String priceTr;
  final String priceEn;
  final String periodTr;
  final String periodEn;
  final String? badgeTr;
  final String? badgeEn;
  final int trialDays;
  final bool isFeatured;

  const SubscriptionPlan({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.priceTr,
    required this.priceEn,
    required this.periodTr,
    required this.periodEn,
    this.badgeTr,
    this.badgeEn,
    this.trialDays = 7,
    this.isFeatured = false,
  });

  String getTitle(String lang) => lang == 'en' ? titleEn : titleTr;
  String getPrice(String lang) => lang == 'en' ? priceEn : priceTr;
  String getPeriod(String lang) => lang == 'en' ? periodEn : periodTr;
  String? getBadge(String lang) => lang == 'en' ? badgeEn : badgeTr;
}

class PremiumFeatures {
  static const List<Map<String, String>> features = [
    {
      'icon': 'infinite',
      'title_tr': 'Sınırsız Fotoğraf & Medya',
      'title_en': 'Unlimited Photos & Media',
      'desc_tr': 'Tüm anılarınızı ve fotoğraflarınızı yüksek kalitede saklayın.',
      'desc_en': 'Store all your memories and photos in high resolution.',
    },
    {
      'icon': 'mic',
      'title_tr': 'Sesli Notlar & Sürpriz Mesajlar',
      'title_en': 'Voice Notes & Surprise Messages',
      'desc_tr': 'Zaman ayarlı açılan aşk notları ve sesli mesajlar gönderin.',
      'desc_en': 'Send timed love surprises and high-fidelity voice notes.',
    },
    {
      'icon': 'gamepad',
      'title_tr': 'Tüm Çift Oyunları & Testler',
      'title_en': 'All Couple Games & Quizzes',
      'desc_tr': 'Birbirinizi daha iyi tanıyacağınız yüzlerce soru paketi.',
      'desc_en': 'Hundreds of questions to deepen your connection.',
    },
    {
      'icon': 'calendar',
      'title_tr': 'Gelişmiş Takvim & Bütçe',
      'title_en': 'Advanced Calendar & Budget',
      'desc_tr': 'Ortak etkinliklerinizi ve harcamalarınızı kusursuz yönetin.',
      'desc_en': 'Flawlessly manage your events and shared finances.',
    },
    {
      'icon': 'book',
      'title_tr': 'Yıllık Anı Kitabı Çıktısı',
      'title_en': 'Annual Memory Book PDF Export',
      'desc_tr': 'Yıl sonunda anılarınızdan oluşan dijital kitap oluşturun.',
      'desc_en': 'Generate an elegant printable book of your shared year.',
    },
    {
      'icon': 'heart',
      'title_tr': '1 Üyelik = 2 Kişi',
      'title_en': '1 Subscription = 2 Users',
      'desc_tr': 'Tek bir partner öder, iki kişi de tüm ayrıcalıklardan yararlanır.',
      'desc_en': 'One person pays, both partners enjoy full premium access.',
    },
  ];
}
