import 'package:ciftapp/core/premium/plan_pricing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting());

  test('savings are computed from real store prices', () {
    // The old paywall claimed 38% here; the real saving is 33%.
    expect(PlanPricing.savingsPercent(monthlyPrice: 4.99, yearlyPrice: 39.99), 33);
    expect(PlanPricing.savingsPercent(monthlyPrice: 79.99, yearlyPrice: 599.99), 37);
    expect(PlanPricing.savingsPercent(monthlyPrice: 10, yearlyPrice: 130), isNull);
    expect(PlanPricing.savingsPercent(monthlyPrice: 0, yearlyPrice: 10), isNull);
  });

  test('monthly equivalent uses the store currency', () {
    // The old paywall showed ₺49,99; 599,99 / 12 is ₺50,00.
    expect(
      PlanPricing.monthlyEquivalent(yearlyPrice: 599.99, currencyCode: 'TRY', locale: 'tr'),
      contains('50,00'),
    );
    expect(
      PlanPricing.monthlyEquivalent(yearlyPrice: 39.99, currencyCode: 'USD', locale: 'en'),
      r'$3.33',
    );
  });
}
