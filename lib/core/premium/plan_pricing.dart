import 'package:intl/intl.dart';

/// Price texts derived from the real store prices (never hard-coded).
class PlanPricing {
  PlanPricing._();

  /// Yearly savings compared to paying monthly for 12 months, e.g. 33.
  /// `null` when there is no saving.
  static int? savingsPercent({required double monthlyPrice, required double yearlyPrice}) {
    if (monthlyPrice <= 0 || yearlyPrice <= 0) return null;
    final percent = ((1 - yearlyPrice / (monthlyPrice * 12)) * 100).floor();
    return percent > 0 ? percent : null;
  }

  /// Yearly price spread over 12 months in the store currency, e.g. "₺50,00".
  static String monthlyEquivalent({
    required double yearlyPrice,
    required String currencyCode,
    required String locale,
  }) {
    final format = NumberFormat.simpleCurrency(name: currencyCode, locale: locale);
    return format.format(yearlyPrice / 12);
  }
}
