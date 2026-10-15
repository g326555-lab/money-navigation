// The arrival warning: once the phone is in a country whose money differs
// from the traveler's own, say once which currency to pick at card
// terminals and ATMs.

import 'pay_facts.dart';

class ArrivalAlert {
  const ArrivalAlert({
    required this.country,
    required this.localCurrency,
    required this.homeCurrency,
    required this.atmOffersConversion,
  });

  /// ISO code, upper case.
  final String country;
  final String localCurrency;
  final String homeCurrency;
  final bool atmOffersConversion;
}

/// Null when the country is unknown, already alerted, not in [facts], or
/// uses the traveler's own currency.
ArrivalAlert? arrivalAlert({
  required String homeCurrency,
  required String? currentCountry,
  required String? lastAlertedCountry,
  required PayFacts facts,
}) {
  if (currentCountry == null || currentCountry.trim().isEmpty) return null;
  final country = currentCountry.trim().toUpperCase();
  if (country == lastAlertedCountry?.trim().toUpperCase()) return null;
  final local = facts.country(country);
  if (local == null || local.currency == homeCurrency.toUpperCase()) {
    return null;
  }
  return ArrivalAlert(
    country: country,
    localCurrency: local.currency,
    homeCurrency: homeCurrency.toUpperCase(),
    atmOffersConversion: local.atmOffersConversion,
  );
}
