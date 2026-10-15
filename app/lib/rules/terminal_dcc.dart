import 'amount_parser.dart';
import 'exchange_rate.dart';

/// One currency choice on a card terminal screen, such as "F1:THB 12,851.82".
class TerminalOption {
  const TerminalOption({
    required this.key,
    required this.code,
    required this.amount,
  });

  /// The function key: 1 for F1, 2 for F2.
  final int key;

  /// The currency code as read. May be partial ("PY") or missing, because
  /// OCR drops letters on the terminal's dot-matrix font.
  final String? code;

  final double amount;
}

/// The lowest and highest mark-up, as a fraction of the fair amount, that a
/// home/local pairing may imply before it is rejected. Terminal conversion
/// (DCC) adds a few percent, usually up to about 12 %; the cap leaves room
/// for the worst terminals so a real trap is still reported. The reference
/// rate may lag the card network by a percent or two, so slightly negative
/// values are kept.
/// The wrong pairing of the demo amounts implies about +2,000 %, and a
/// misread amount far more, so neither passes.
const dccMarkupMin = -0.05;
const dccMarkupMax = 0.20;

// "F1:THB 12,851.82", "F2:PY 58, 000", "F1 : THB 12,851.82", "F1: 12,851.82".
// A colon or a code must sit between the key and the amount, so keypad rows
// such as "F2 6" or "F1 OR F2 6" are not taken for options.
final _optionRow = RegExp(
  '^F\\s*([12])\\s*(?::\\s*([A-Z]{1,3})?|\\s+([A-Z]{1,3}))\\s*'
  '($amountPattern)\\s*\$',
);

// More decimals than money has ("12851.8234", "12,851.823"). A 3-digit
// group after a dot is allowed only as a dot-grouped whole amount ("58.000").
final _tooManyDecimals = RegExp(r'[.,]\d{4,}$');
final _threeDecimals = RegExp(r'\.\d{3}$');
final _dotGrouped = RegExp(r'^\d{1,3}(?:\.\d{3})+$');

bool _moneyShaped(String raw) {
  final text = raw.replaceAll(' ', '');
  if (_tooManyDecimals.hasMatch(text)) return false;
  return !_threeDecimals.hasMatch(text) || _dotGrouped.hasMatch(text);
}

/// Reads the currency options from the rows of a terminal screen
/// (the output of `rowsFromLines`). Options come back in key order. A key
/// read twice with different amounts is dropped, since either could be the
/// misread. Returns an empty list when nothing matches.
List<TerminalOption> readTerminalOptions(String rowsText) {
  final byKey = <int, TerminalOption>{};
  final ambiguous = <int>{};
  for (final row in rowsText.split('\n')) {
    final m = _optionRow.firstMatch(row.trim());
    if (m == null) continue;
    final key = int.parse(m.group(1)!);
    final raw = m.group(4)!;
    final amount = _moneyShaped(raw) ? parseAmount(raw) : null;
    if (amount == null) continue;
    final seen = byKey[key];
    if (seen != null) {
      if (seen.amount != amount) ambiguous.add(key);
      continue;
    }
    byKey[key] = TerminalOption(
      key: key,
      code: m.group(2) ?? m.group(3),
      amount: amount,
    );
  }
  final keys = byKey.keys.where((k) => !ambiguous.contains(k)).toList()..sort();
  return [for (final k in keys) byKey[k]!];
}

/// Which terminal choice is cheaper, measured against a reference rate.
class DccVerdict {
  const DccVerdict({
    required this.homeOption,
    required this.localOption,
    required this.fairHomeAmount,
    required this.extraHome,
    required this.markupPercent,
    required this.payLocal,
    required this.rate,
  });

  /// The option charged in the traveler's home currency.
  final TerminalOption homeOption;

  /// The option charged in the local currency.
  final TerminalOption localOption;

  /// The local amount converted at [rate], rounded to 0.01.
  final double fairHomeAmount;

  /// How much more the home-currency option costs than [fairHomeAmount],
  /// rounded to 0.01. Zero or negative when it is not dearer.
  final double extraHome;

  final double markupPercent;

  /// True when paying in the local currency is cheaper.
  final bool payLocal;

  /// The reference rate used; it carries its date for the source line.
  final RateQuote rate;
}

/// Judges a terminal currency choice. [rate] goes from the traveler's home
/// currency (base) to the local currency (quote).
///
/// Which option is home and which is local is decided from the amounts: only
/// one pairing implies a plausible mark-up. Codes are not trusted for this,
/// because OCR drops letters ("F2:PY"). A code that was read must still fit:
/// a full code must be the expected one and a partial code part of it, so a
/// terminal in another currency, or a rate given the wrong way round, gives
/// null instead of a verdict.
DccVerdict? judgeTerminal(String rowsText, {required RateQuote rate}) {
  final options = readTerminalOptions(rowsText);
  if (options.length != 2) return null;
  final pairings = [
    (options[0], options[1]),
    (options[1], options[0]),
  ].where((p) => _plausible(p.$1, p.$2, rate)).toList();
  if (pairings.length != 1) return null;
  final (home, local) = pairings.single;
  if (!_codeFits(home.code, rate.base) || !_codeFits(local.code, rate.quote)) {
    return null;
  }

  final fair = _round2(local.amount / rate.rate);
  final extra = _round2(home.amount - fair);
  return DccVerdict(
    homeOption: home,
    localOption: local,
    fairHomeAmount: fair,
    extraHome: extra,
    markupPercent: extra / fair * 100,
    payLocal: extra > 0,
    rate: rate,
  );
}

bool _plausible(TerminalOption home, TerminalOption local, RateQuote rate) {
  if (home.amount <= 0 || local.amount <= 0) return false;
  final markup = home.amount * rate.rate / local.amount - 1;
  return markup >= dccMarkupMin && markup <= dccMarkupMax;
}

bool _codeFits(String? read, String expected) {
  if (read == null) return true;
  if (read.length >= expected.length) return read == expected;
  return expected.contains(read);
}

double _round2(double v) => (v * 100).roundToDouble() / 100;
