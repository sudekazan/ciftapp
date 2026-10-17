enum RelationshipMode {
  longDistance,
  coLiving,
}

extension RelationshipModeExtension on RelationshipMode {
  String get id => this == RelationshipMode.longDistance ? 'long_distance' : 'co_living';

  String getTitle(String languageCode) {
    if (languageCode == 'tr') {
      return this == RelationshipMode.longDistance
          ? 'Uzak Mesafe'
          : 'Birlikte Yaşıyoruz';
    } else {
      return this == RelationshipMode.longDistance
          ? 'Long Distance'
          : 'Living Together';
    }
  }

  String getDescription(String languageCode) {
    if (languageCode == 'tr') {
      return this == RelationshipMode.longDistance
          ? 'Farklı şehirlerde veya ülkelerde olan, geri sayım ve özlem odaklı çiftler için.'
          : 'Aynı evi paylaşan, takvim, görev ve alışveriş koordinasyonu odaklı çiftler için.';
    } else {
      return this == RelationshipMode.longDistance
          ? 'For couples separated by distance, focused on countdowns & staying close.'
          : 'For couples living under the same roof, coordinating tasks, calendar & home.';
    }
  }
}
