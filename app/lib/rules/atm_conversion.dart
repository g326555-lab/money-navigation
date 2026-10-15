import 'amount_parser.dart';

/// Values printed on an ATM screen that offers to convert the withdrawal
/// into the card's home currency (dynamic currency conversion).
class AtmScreenReading {
  const AtmScreenReading({
    required this.withdrawalThb,
    required this.accessFeeThb,
    required this.thbPerUsd,
    this.markupPercent,
    required this.chargedThb,
    required this.chargedUsd,
  });

  final double withdrawalThb;
  final double accessFeeThb;

  /// The rate printed on the screen, "1 USD = x THB".
  final double thbPerUsd;

  /// The mark-up the screen states, if it states one.
  final double? markupPercent;

  /// Total charged without conversion, in baht.
  final double chargedThb;

  /// Total charged with the ATM's conversion, in dollars.
  final double chargedUsd;
}

enum AtmChoice { declineConversion, acceptConversion }

class AtmVerdict {
  const AtmVerdict({
    required this.recommended,
    required this.extraCostUsd,
    required this.extraCostThb,
  });

  final AtmChoice recommended;

  /// How much more accepting the conversion costs. Zero or negative when
  /// converting is not more expensive.
  final double extraCostUsd;
  final double extraCostThb;
}

/// Reads the values of an ATM conversion screen from OCR text.
///
/// Works whether OCR returns each label on the same line as its values or
/// all labels first and the THB and USD columns after. Returns null when any
/// required value is missing or the numbers do not add up, never a default.
AtmScreenReading? parseAtmScreen(String ocrText) {
  final text = ocrText.replaceAll(RegExp(r'\s+'), ' ');
  final lower = text.toLowerCase();
  if (!_rowLabels.every(lower.contains)) return null;

  final rateMatch = _rate.firstMatch(text);
  if (rateMatch == null) return null;
  final thbPerUsd = parseAmount(rateMatch.group(1)!);
  if (thbPerUsd == null || thbPerUsd <= 0) return null;

  // Remove the rate so its "1 USD" and "30.86 THB" are not read as rows.
  final rows = text.replaceRange(rateMatch.start, rateMatch.end, ' ');
  final thb = _amountsIn(rows, 'THB');
  final usd = _amountsIn(rows, 'USD');
  // One THB and one USD value per row: withdrawal, access fee, charged.
  if (thb.length != _rowLabels.length || usd.length != _rowLabels.length) {
    return null;
  }

  final [withdrawalThb, accessFeeThb, chargedThb] = thb;
  if (chargedThb <= 0 || usd.last <= 0) return null;
  // A misread digit shows up here: the charged total must be the sum.
  if ((withdrawalThb + accessFeeThb - chargedThb).abs() >= 0.01) return null;

  final markupMatch = _markup.firstMatch(rows);
  return AtmScreenReading(
    withdrawalThb: withdrawalThb,
    accessFeeThb: accessFeeThb,
    thbPerUsd: thbPerUsd,
    markupPercent:
        markupMatch == null ? null : parseAmount(markupMatch.group(1)!),
    chargedThb: chargedThb,
    chargedUsd: usd.last,
  );
}

/// Compares the ATM's converted total with the baht total at the rate the
/// screen itself prints.
AtmVerdict evaluateAtm(AtmScreenReading reading) {
  if (reading.thbPerUsd <= 0) {
    throw ArgumentError.value(reading.thbPerUsd, 'thbPerUsd', 'must be > 0');
  }
  final fairUsd = reading.chargedThb / reading.thbPerUsd;
  final extraUsd = reading.chargedUsd - fairUsd;
  // Decide on whole cents so floating-point noise never claims a saving.
  final extraCents = (extraUsd * 100).round();
  return AtmVerdict(
    recommended:
        extraCents > 0 ? AtmChoice.declineConversion : AtmChoice.acceptConversion,
    extraCostUsd: extraUsd,
    extraCostThb: extraUsd * reading.thbPerUsd,
  );
}

const _rowLabels = ['withdrawal amount', 'access fee', 'amount charged'];

final _rate = RegExp('1 ?USD ?= ?($amountPattern) ?THB');
final _markup = RegExp(r'(\d+(?:\.\d+)?) ?%');

List<double> _amountsIn(String text, String currency) => RegExp(
      '(?<![\\d.,])($amountPattern) ?$currency\\b',
    )
        .allMatches(text)
        .map((m) => parseAmount(m.group(1)!))
        .whereType<double>()
        .toList();
