import '../../app/app_scope.dart';
import '../../rules/exchange_rate.dart';
import '../../rules/haggle.dart' show marketCurrency;
import '../../rules/pay_facts.dart';
import '../../rules/trip_ledger.dart';
import '../../rules/personal_context.dart';

/// Where the traveler is paying and how its money converts to baht, for
/// the state in view (the traveler's own trip, or a demo state).
class TripContext {
  const TripContext({
    required this.localCurrency,
    required this.homeCurrency,
    required this.localFacts,
    required this.localToThb,
    required this.homeToThb,
    required this.rateIsDemo,
    required this.history,
  });

  /// The currency prices are asked in here.
  final String localCurrency;
  final String homeCurrency;

  /// The sourced facts for the country of [localCurrency], when known.
  final CountryPayFacts? localFacts;

  /// Null while the rate is not known.
  final double? localToThb;
  final double? homeToThb;
  final bool rateIsDemo;

  /// The purchases behind personal estimates, from the ledger in view.
  final List<PastPurchase> history;

  static TripContext of(AppScope scope, PayFacts? facts) {
    final persona = scope.settings.demoPersona;
    final local = persona?.localCurrency ?? marketCurrency;
    final home = scope.settings.homeCurrency;
    final demo = scope.settings.demoState;
    double? toThb(String currency) {
      if (currency == marketCurrency) return 1;
      final RateQuote? quote = demo
          ? scope.demoRates?.quoteFor(marketCurrency, currency)
          : scope.rates.quoteFor(currency);
      if (quote == null || quote.rate <= 0) return null;
      return 1 / quote.rate;
    }

    CountryPayFacts? factsFor(String currency) {
      if (facts == null) return null;
      for (final c in facts.countries.values) {
        if (c.currency == currency) return c;
      }
      return null;
    }

    return TripContext(
      localCurrency: local,
      homeCurrency: home,
      localFacts: factsFor(local),
      localToThb: toThb(local),
      homeToThb: toThb(home),
      rateIsDemo: demo,
      history: pastPurchasesFromSaves(scope.trip.saves),
    );
  }
}
