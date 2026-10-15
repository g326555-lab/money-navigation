import 'dart:convert';

/// The sourced payment facts per country: what local ATMs charge a foreign
/// card and whether they offer to convert. Every fee names its source and
/// the day it was checked.
const payFactsAsset = 'assets/data/pay_facts.json';

/// One fee and where it came from.
class SourcedFee {
  const SourcedFee({
    required this.value,
    required this.currency,
    required this.isPercent,
    required this.source,
    required this.checked,
    this.appliesTo,
  });

  /// An amount in [currency], or a percent when [isPercent].
  final double value;
  final String currency;
  final bool isPercent;
  final String source;

  /// Which machines or cards the figure is for, e.g. "Kasikorn K-ATM, Visa".
  /// Other banks may charge differently, so the screen names it.
  final String? appliesTo;

  /// ISO date the source was read, 'YYYY-MM-DD'.
  final String checked;

  static SourcedFee? _fromJson(Object? json) {
    if (json is! Map) return null;
    final value = json['value'];
    final currency = json['currency'];
    final source = json['source'];
    final checked = json['checked'];
    if (value is! num || value < 0) return null;
    if (currency is! String || currency.isEmpty) return null;
    if (source is! String || source.trim().isEmpty) return null;
    if (checked is! String || DateTime.tryParse(checked) == null) return null;
    final appliesTo = json['appliesTo'];
    return SourcedFee(
      appliesTo: appliesTo is String && appliesTo.trim().isNotEmpty
          ? appliesTo
          : null,
      value: value.toDouble(),
      currency: currency.toUpperCase(),
      isPercent: json['isPercent'] == true,
      source: source,
      checked: checked,
    );
  }
}

/// What paying costs in one country.
class CountryPayFacts {
  const CountryPayFacts({
    required this.country,
    required this.currency,
    this.foreignCardAtmFee,
    this.atmOffersConversion = false,
    this.atmConversionSource,
    this.atmConversionChecked,
  });

  /// ISO 3166 alpha-2, upper case.
  final String country;

  /// The local currency.
  final String currency;

  /// What a local ATM charges a foreign card per withdrawal.
  final SourcedFee? foreignCardAtmFee;

  /// Local ATMs may offer to charge in the card's own currency.
  final bool atmOffersConversion;

  /// Where [atmOffersConversion] comes from; without one the offer is not
  /// claimed.
  final String? atmConversionSource;
  final String? atmConversionChecked;

  static CountryPayFacts? _fromJson(Object? json) {
    if (json is! Map) return null;
    final country = json['country'];
    final currency = json['currency'];
    if (country is! String || country.length != 2) return null;
    if (currency is! String || currency.length != 3) return null;
    final conversionSource = json['atmConversionSource'];
    final hasSource =
        conversionSource is String && conversionSource.trim().isNotEmpty;
    return CountryPayFacts(
      country: country.toUpperCase(),
      currency: currency.toUpperCase(),
      foreignCardAtmFee: SourcedFee._fromJson(json['foreignCardAtmFee']),
      // No source, no claim.
      atmOffersConversion: json['atmOffersConversion'] == true && hasSource,
      atmConversionSource: hasSource ? conversionSource : null,
      atmConversionChecked: hasSource && json['atmConversionChecked'] is String
          ? json['atmConversionChecked'] as String
          : null,
    );
  }
}

/// Every country the facts file knows.
class PayFacts {
  const PayFacts(this.countries);

  final Map<String, CountryPayFacts> countries;

  CountryPayFacts? country(String code) => countries[code.toUpperCase()];

  String? currencyOf(String country) => this.country(country)?.currency;

  /// Null when [json] is not a facts file; a malformed country is skipped.
  static PayFacts? parse(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      return null;
    }
    if (decoded is! Map || decoded['countries'] is! List) return null;
    final countries = <String, CountryPayFacts>{};
    for (final entry in decoded['countries'] as List) {
      final country = CountryPayFacts._fromJson(entry);
      if (country != null) countries[country.country] = country;
    }
    return PayFacts(countries);
  }
}
