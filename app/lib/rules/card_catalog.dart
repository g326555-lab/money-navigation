import 'dart:convert';

import 'personal_context.dart';

/// The card catalogue: cards the traveler can pick instead of typing fees.
/// Every figure comes from the card's linked official page on its checked
/// date. The only place card facts are written down.
const cardCatalogAsset = 'assets/data/card_catalog.json';

enum CardFeeKind { foreignExchange, crossBorder, foreignTransaction }

/// One fee on a foreign purchase, as the issuer states it.
class CardFee {
  const CardFee({
    required this.kind,
    required this.percent,
    required this.upTo,
  });

  final CardFeeKind kind;
  final double percent;

  /// The issuer says "up to": the most it can be, not what it always is.
  final bool upTo;
}

class LocalizedLine {
  const LocalizedLine({required this.en, required this.th});

  final String en;
  final String th;

  String of(String languageCode) => languageCode == 'th' ? th : en;
}

class CardSource {
  const CardSource({
    required this.label,
    required this.url,
    required this.checked,
  });

  final String label;
  final String url;

  /// 'YYYY-MM-DD'.
  final String checked;
}

class CatalogCard {
  const CatalogCard({
    required this.id,
    required this.issuer,
    required this.name,
    required this.network,
    required this.kind,
    required this.homeCurrency,
    required this.faceColor,
    required this.faceTextLight,
    required this.fees,
    required this.atmPolicy,
    this.atmValue,
    this.atmCurrency,
    required this.benefits,
    required this.printedText,
    required this.sources,
    this.notes = const [],
  });

  final String id;
  final String issuer;
  final String name;

  /// 'visa', 'mastercard', 'amex', 'jcb' or 'unionpay'.
  final String network;

  /// 'credit', 'debit' or 'prepaid'.
  final String kind;
  final String homeCurrency;

  /// 0xAARRGGBB of the card face as the issuer shows it.
  final int faceColor;
  final bool faceTextLight;
  final List<CardFee> fees;
  final AtmFeePolicy atmPolicy;
  final double? atmValue;
  final String? atmCurrency;
  final List<LocalizedLine> benefits;

  /// Words printed on the card's front, for recognising a photo of it.
  final List<String> printedText;
  final List<CardSource> sources;
  final List<LocalizedLine> notes;
}

/// The fee a foreign-currency purchase can carry with this card: every
/// stated fee added up (an exchange fee and a cross-border fee both apply
/// to one purchase abroad). Null when the issuer states none.
({double percent, bool upTo})? cardForeignFee(CatalogCard card) {
  if (card.fees.isEmpty) return null;
  final total = card.fees.fold<double>(0, (sum, f) => sum + f.percent);
  return (
    percent: (total * 100).round() / 100,
    upTo: card.fees.any((f) => f.upTo),
  );
}

/// The comparison profile this card gives: its foreign fee and its ATM
/// policy. A fixed ATM fee in another currency than the traveler's is left
/// unknown rather than converted silently.
TravelerProfile profileFromCard(
  CatalogCard card, {
  required String homeCurrency,
}) {
  final fee = cardForeignFee(card)?.percent;
  final fixedElsewhere =
      card.atmPolicy == AtmFeePolicy.chargesFixed &&
      card.atmCurrency != null &&
      card.atmCurrency != homeCurrency;
  return TravelerProfile(
    cardFeePercent: fee,
    atmFeePolicy: fixedElsewhere ? AtmFeePolicy.unknown : card.atmPolicy,
    atmFeeValue: fixedElsewhere ? null : card.atmValue,
  );
}

/// Null when [json] is not a valid catalogue. A card missing a source or
/// carrying a malformed figure is dropped, never repaired.
List<CatalogCard>? parseCardCatalog(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return null;
  }
  if (decoded is! Map || decoded['cards'] is! List) return null;
  final cards = <CatalogCard>[];
  final ids = <String>{};
  for (final c in decoded['cards'] as List) {
    final card = _card(c);
    if (card != null && ids.add(card.id)) cards.add(card);
  }
  return cards;
}

final _hex = RegExp(r'^#([0-9a-fA-F]{6})$');
final _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');

CatalogCard? _card(Object? c) {
  if (c is! Map) return null;
  String? text(String key) {
    final v = c[key];
    return v is String && v.trim().isNotEmpty ? v.trim() : null;
  }

  final id = text('id'), issuer = text('issuer'), name = text('name');
  final network = text('network'), kind = text('kind');
  final home = text('homeCurrency');
  final color = text('faceColor');
  final hex = color == null ? null : _hex.firstMatch(color);
  if (id == null ||
      issuer == null ||
      name == null ||
      network == null ||
      kind == null ||
      home == null ||
      home.length != 3 ||
      hex == null ||
      c['faceTextLight'] is! bool) {
    return null;
  }
  final fees = <CardFee>[];
  final rawFees = c['fees'];
  if (rawFees is! List) return null;
  for (final f in rawFees) {
    if (f is! Map) return null;
    final feeKind = CardFeeKind.values.asNameMap()[f['kind']];
    final percent = f['percent'];
    if (feeKind == null ||
        percent is! num ||
        !percent.isFinite ||
        percent < 0 ||
        percent > 20 ||
        f['upTo'] is! bool) {
      return null;
    }
    fees.add(
      CardFee(
        kind: feeKind,
        percent: percent.toDouble(),
        upTo: f['upTo'] as bool,
      ),
    );
  }
  final atm = c['atm'];
  if (atm is! Map) return null;
  final policy = AtmFeePolicy.values.asNameMap()[atm['policy']];
  final atmValue = atm['value'];
  final atmCurrency = atm['currency'];
  if (policy == null ||
      (atmValue != null && (atmValue is! num || atmValue < 0)) ||
      (atmCurrency != null && atmCurrency is! String)) {
    return null;
  }
  final needsValue =
      policy == AtmFeePolicy.chargesFixed ||
      policy == AtmFeePolicy.chargesPercent;
  if (needsValue && atmValue == null) return null;
  final sources = <CardSource>[];
  final rawSources = c['sources'];
  if (rawSources is! List) return null;
  for (final s in rawSources) {
    if (s is! Map) continue;
    final url = s['url'], label = s['label'], checked = s['checked'];
    if (url is! String ||
        !url.startsWith('https://') ||
        label is! String ||
        checked is! String ||
        !_date.hasMatch(checked)) {
      continue;
    }
    sources.add(CardSource(label: label, url: url, checked: checked));
  }
  // No official page, no card.
  if (sources.isEmpty) return null;
  return CatalogCard(
    id: id,
    issuer: issuer,
    name: name,
    network: network.toLowerCase(),
    kind: kind,
    homeCurrency: home.toUpperCase(),
    faceColor: 0xFF000000 | int.parse(hex.group(1)!, radix: 16),
    faceTextLight: c['faceTextLight'] as bool,
    fees: fees,
    atmPolicy: policy,
    atmValue: (atmValue as num?)?.toDouble(),
    atmCurrency: atmCurrency as String?,
    benefits: _lines(c['benefits']),
    printedText: [
      for (final t in c['printedText'] is List ? c['printedText'] as List : [])
        if (t is String && t.trim().isNotEmpty) t.trim(),
    ],
    sources: sources,
    notes: _lines(c['notes']),
  );
}

List<LocalizedLine> _lines(Object? value) => [
  if (value is List)
    for (final l in value)
      if (l is Map &&
          l['en'] is String &&
          l['th'] is String &&
          (l['en'] as String).trim().isNotEmpty)
        LocalizedLine(en: l['en'] as String, th: l['th'] as String),
];

/// Letters only, upper case, single spaces: card numbers, expiry dates and
/// every other digit are dropped before anything is compared or kept.
String cardFaceWords(String ocrText) =>
    ocrText.toUpperCase().replaceAll(RegExp(r'[^A-Z]+'), ' ').trim();

/// Words printed on many cards; a phrase made only of these names no card.
const _genericCardWords = {
  'VISA',
  'MASTERCARD',
  'AMEX',
  'JCB',
  'UNIONPAY',
  'DEBIT',
  'CREDIT',
  'PREPAID',
  'CARD',
  'PLATINUM',
  'SIGNATURE',
  'WORLD',
  'ELITE',
  'GOLD',
  'CLASSIC',
  'INFINITE',
  'BUSINESS',
  'BANK',
  'THE',
  'OF',
};

/// The cards whose printed words appear on a photographed card face, best
/// first. A card counts only when every word of at least one of its
/// printed phrases is read; more matched phrases and longer phrases rank
/// higher. Empty when nothing on the photo names a catalogue card.
List<CatalogCard> matchCardFace(String ocrText, List<CatalogCard> cards) {
  final words = cardFaceWords(ocrText).split(' ').toSet();
  final scored = <(CatalogCard, int)>[];
  for (final card in cards) {
    var score = 0;
    for (final phrase in card.printedText) {
      final need = cardFaceWords(phrase).split(' ').where((w) => w.isNotEmpty);
      if (need.every(_genericCardWords.contains)) continue;
      if (need.every(words.contains)) {
        score += need.fold(0, (sum, w) => sum + w.length);
      }
    }
    if (score > 0) scored.add((card, score));
  }
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final (card, _) in scored) card];
}
