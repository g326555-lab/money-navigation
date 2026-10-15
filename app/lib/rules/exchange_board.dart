import 'exchange_rate.dart';

/// One currency row of an exchange booth's rate board, in the board's home
/// currency per one unit of [code].
class BoardRate {
  const BoardRate({
    required this.code,
    required this.buying,
    required this.selling,
  });

  final String code;

  /// What the booth pays when you sell it [code].
  final double buying;

  /// What the booth charges when you buy [code].
  final double selling;

  double get mid => (buying + selling) / 2;

  /// How much less than [mid] you get when you sell [code] here, in percent.
  double get sellLossPercent => (mid - buying) / mid * 100;

  /// How much more than [mid] you pay when you buy [code] here, in percent.
  double get buyLossPercent => (selling - mid) / mid * 100;

  /// What selling [amount] of [code] here loses against [mid], in the
  /// board's home currency.
  double lossWhenSelling(double amount) => amount * (mid - buying);
}

/// Highest selling/buying ratio accepted for one row. A dropped decimal point
/// multiplies a value by 10 or more ("576" for 5.76); the widest real spread
/// on the demo board is about 1.6 (Bahrain 59.63 / 96.33).
const boardMaxSpreadRatio = 2.0;

// A board rate: "35.03", "0.2879", "28,32" (comma read for the decimal point).
final _rateToken = RegExp(r'^\d+(?:[.,]\d{1,4})?$');
final _edgeJunk = RegExp(r'^[^\dA-Za-z]+|[^\dA-Za-z]+$');
// The next row's currency code, when a tilted photo merges two rows.
final _codeLike = RegExp(r'^[A-Z]{2,4}$');

/// Reads the buying and selling rate for [code] from the rows of a rate
/// board (the output of `rowsFromLines`). Buying is the first number after
/// the code, selling the last before the next code-like token, matching
/// boards that list Buying (notes, and sometimes cheques) left of Selling.
///
/// Rows that mention the code with fewer than two numbers (a caption such as
/// "Rates per 1 USD") are skipped. When other rows carry more numbers (a
/// cheque column), a shorter row is not trusted. Returns null when no row gives a pair, the
/// code appears with two different readings, or a pair cannot be right
/// (buying not below selling, or a spread only a misread explains). It never
/// repairs a number.
BoardRate? readExchangeBoard(String rowsText, {required String code}) {
  BoardRate? found;
  var foundCount = 0;
  var widest = 0;
  for (final row in rowsText.split('\n')) {
    final tokens = [
      for (final t in row.split(RegExp(r'\s+')))
        if (t.replaceAll(_edgeJunk, '').isNotEmpty) t.replaceAll(_edgeJunk, ''),
    ];
    final codeAt = tokens.indexWhere(_codeLike.hasMatch);
    if (codeAt < 0) continue;
    final at = tokens.indexOf(code);
    final numbers = _numbersAfter(tokens, at < 0 ? codeAt : at);
    if (numbers.length > widest) widest = numbers.length;
    if (at < 0 || numbers.length < 2) continue;
    final rate = _validPair(code, numbers);
    if (rate == null) return null;
    if (found != null &&
        (found.buying != rate.buying || found.selling != rate.selling)) {
      return null;
    }
    found = rate;
    foundCount = numbers.length;
  }
  // On a board with a cheque column, two numbers could be buying and selling
  // (no cheque price) or buying and cheque (selling not read); a keystoned
  // photo gave CAD 29.65 / 29.98, the cheque price. Only full rows count.
  if (found != null && foundCount < widest) return null;
  return found;
}

List<double> _numbersAfter(List<String> tokens, int at) {
  final numbers = <double>[];
  for (final t in tokens.skip(at + 1)) {
    if (_codeLike.hasMatch(t)) break;
    if (_rateToken.hasMatch(t)) {
      numbers.add(double.parse(t.replaceAll(',', '.')));
    }
  }
  return numbers;
}

BoardRate? _validPair(String code, List<double> numbers) {
  final buying = numbers.first;
  final selling = numbers.last;
  if (!(buying > 0) || buying >= selling) return null;
  // A middle column (cheques) is priced between the two; "3503 35.60 3510"
  // shows both outer values lost their decimal point.
  for (final middle in numbers.sublist(1, numbers.length - 1)) {
    if (middle < buying || middle > selling) return null;
  }
  if (selling / buying > boardMaxSpreadRatio) return null;
  return BoardRate(code: code, buying: buying, selling: selling);
}

/// How much less than a published mid rate you get when you sell
/// [board.code] here, in percent. [home] is the board's home currency;
/// [reference] must go from [home] (base) to [board.code] (quote), otherwise
/// the result is null.
double? lossVsReferencePercent(
  BoardRate board,
  RateQuote reference, {
  required String home,
}) {
  if (reference.base != home || reference.quote != board.code) return null;
  if (!(reference.rate > 0)) return null;
  final referenceMid = 1 / reference.rate;
  return (referenceMid - board.buying) / referenceMid * 100;
}

/// The band, in percent, that a board's buying rate may sit below a
/// published mid, and its selling rate above it, for the reading to be
/// believed. Booths buy and sell a few percent around the mid; the demo board
/// is an older photo and buys about 4 % above today's mid, hence the low end.
/// A value with a dropped decimal point ("3503 3610") or a rate pulled in from
/// the next row by a keystoned photo (EUR selling read as GBP's 70.90, +53 %)
/// falls far outside.
const boardReferenceMinPercent = -10.0;
const boardReferenceMaxPercent = 25.0;

/// Whether [board]'s buying and selling rates are believable next to a
/// published rate. [home] and [reference] are as in [lossVsReferencePercent].
bool boardRatePlausible(
  BoardRate board,
  RateQuote reference, {
  required String home,
}) {
  final buyingGap = lossVsReferencePercent(board, reference, home: home);
  if (buyingGap == null) return false;
  final referenceMid = 1 / reference.rate;
  final sellingGap = (board.selling - referenceMid) / referenceMid * 100;
  bool inBand(double v) =>
      v >= boardReferenceMinPercent && v <= boardReferenceMaxPercent;
  return inBand(buyingGap) && inBand(sellingGap);
}

/// The board reading a screen should use: [readExchangeBoard] followed by
/// [boardRatePlausible] against a published rate (live Frankfurter, or the
/// demo file in the demo state). A keystoned photo can pull the next row's
/// rate in (EUR selling read as GBP's 70.90) in a way the text alone cannot
/// show, so an unchecked reading is never returned.
BoardRate? readCheckedBoardRate(
  String rowsText, {
  required String code,
  required RateQuote reference,
  required String home,
}) {
  final board = readExchangeBoard(rowsText, code: code);
  if (board == null) return null;
  return boardRatePlausible(board, reference, home: home) ? board : null;
}
