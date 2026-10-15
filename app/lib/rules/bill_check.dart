import 'ocr_layout.dart';
import 'receipt_roles.dart';

/// Thailand's standard VAT rate in percent. It is only used when the bill
/// itself prints it.
const double thaiVatPercent = 7;

/// How the total of a receipt was built, as proven by its own numbers.
enum BillKind {
  /// subtotal - discount + service charge = total (VAT, if printed, inside).
  serviceCharge,

  /// The item prices add up to the amount before VAT and VAT was added on
  /// top of them: menu prices did not include it.
  vatOnTop,

  /// VAT is inside the total (total - VAT = the printed amount before tax).
  vatIncluded,

  /// No charge was added: the item amounts add up to the total.
  itemsOnly,
}

/// A receipt whose figures were verified by arithmetic.
///
/// Labels on a photographed Thai receipt come back partly garbled from OCR
/// (ยอดชำระ was read as มองชาระ), and the amounts often sit in a separate
/// column block from their labels. So a receipt is never read by its labels:
/// it is accepted only when its printed amounts, in print order, fit one of
/// the [BillKind] equations exactly. Nothing is filled in or guessed.
class BillCheck {
  const BillCheck({
    required this.kind,
    required this.total,
    this.subtotal,
    this.discount,
    this.serviceCharge,
    this.servicePercent,
    this.vat,
    this.vatPercent,
    this.beforeVat,
    this.itemCount,
    bool? vatOnTop,
  }) : vatOnTop = vatOnTop ?? kind == BillKind.vatOnTop;

  final BillKind kind;
  final double total;

  /// The printed subtotal, or for [BillKind.itemsOnly] the sum of the items.
  final double? subtotal;
  final double? discount;
  final double? serviceCharge;
  final double? servicePercent;
  final double? vat;
  final double? vatPercent;
  final double? beforeVat;

  /// How many item amounts were added up, when that was verified.
  final int? itemCount;

  /// VAT was added on top (of the items, or of items plus a service
  /// charge as on a "++" restaurant bill) rather than inside the prices.
  final bool vatOnTop;

  /// The service charge was added after the subtotal, not hidden in prices.
  bool get serviceAddedOnTop => serviceCharge != null;

  /// The VAT amount is already inside the total (total - VAT = before tax).
  bool get vatIncluded => vat != null && beforeVat != null && !vatOnTop;

  /// VAT was added on top of prices that did not include it.
  bool get vatAddedOnTop => vatOnTop;

  /// Nothing was added on top of what the goods cost.
  bool get nothingAdded => serviceCharge == null && !vatAddedOnTop;
}

/// Checks a bill from Cloud Vision's `read-text` answer:
/// `{"lines": [{"text": ..., "corners": [[x, y] x4]}]}`.
BillCheck? checkBillFromVision(
  Map<String, dynamic> json, {
  double vatPercent = thaiVatPercent,
}) {
  final raw = json['lines'];
  if (raw is! List) return null;
  final quads = <OcrQuad>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final text = item['text'];
    final corners = item['corners'];
    if (text is! String || corners is! List) continue;
    quads.add(
      OcrQuad(
        text: text,
        corners: [
          for (final c in corners)
            if (c is List && c.length >= 2 && c[0] is num && c[1] is num)
              ((c[0] as num).toDouble(), (c[1] as num).toDouble()),
        ],
      ),
    );
  }
  return checkBill(straightenLines(quads), vatPercent: vatPercent);
}

/// Returns the verified receipt, or null when its printed amounts fit no
/// [BillKind] or fit more than one way.
/// It never fills in a missing figure.
BillCheck? checkBill(
  List<OcrLine> lines, {
  double vatPercent = thaiVatPercent,
}) {
  if (lines.isEmpty) return null;
  final text = rowsFromLines(lines);
  // Read the rows by their labels first; a receipt whose labels OCR garbled
  // falls back to the amounts alone below.
  final byRoles = readByRoles(text.split('\n'), vatPercent: vatPercent);
  if (byRoles != null) return byRoles;
  // An amount tagged with another currency ("144.71 USD" on an ATM screen)
  // is not a bill figure; without this an ATM fee line balances like a
  // service charge.
  final cents = <int>[];
  // Whether each amount is the last one on its printed row: the line total
  // of an item row ("Latte 2 x 45.00 90.00" -> 90.00). Item sums use only
  // these, so unit prices and repeated columns are not added twice.
  final lineTotal = <bool>[];
  // Rows that print a percent: an amount there is a charge or discount
  // line, so its percent tells which.
  final rowPercents = <Set<double>>[];
  // The role each amount's row reads as, from its words.
  final rowRoles = <RowRole>[];
  for (final row in text.split('\n')) {
    final start = cents.length;
    final inRow = {
      for (final m in _percent.allMatches(row)) ?double.tryParse(m.group(1)!),
    };
    for (final m in _amount.allMatches(row)) {
      if (_foreignCode.hasMatch(row.substring(m.end))) continue;
      final c = _toCents(m);
      if (c == null) continue;
      cents.add(c);
      lineTotal.add(false);
      rowPercents.add(inRow);
      rowRoles.add(roleOf(row));
    }
    if (cents.length > start) lineTotal[cents.length - 1] = true;
  }
  final percents = {
    for (final m in _percent.allMatches(text))
      if (double.tryParse(m.group(1)!) case final p? when p > 0 && p < 100) p,
  };
  if (cents.length < 2) return null;
  final hasVat = percents.contains(vatPercent);
  final at = <int, List<int>>{};
  for (var i = 0; i < cents.length; i++) {
    (at[cents[i]] ??= []).add(i);
  }

  // 1. Service charge. Every reading that balances, in the order a bill
  // prints it: subtotal, then discount, then service charge, then total. The
  // order keeps cash, change and item amounts from posing as a subtotal or a
  // total. The VAT rate is never read as a service charge: "before tax + VAT
  // = total" balances just like a service line.
  final servicePercents = percents.where((p) => p != vatPercent);
  final found = <_Core>{};
  for (var t = 0; t < cents.length; t++) {
    for (var c = 0; c < t; c++) {
      if (cents[c] >= cents[t]) continue;
      for (var d = -1; d < c; d++) {
        final discount = d < 0 ? 0 : cents[d];
        final subtotal = cents[t] - cents[c] + discount;
        final before = d < 0 ? c : d;
        if (!(at[subtotal]?.any((s) => s < before) ?? false)) continue;
        final base = subtotal - discount;
        for (final p in servicePercents) {
          if (!_isCharge(cents[c], base * p / 100)) continue;
          // A bill that prints the VAT rate must also show the VAT inside
          // this total; otherwise the reading is not the bill's own.
          final vat = hasVat
              ? _vatInside(cents, rowPercents, t, vatPercent)?.$1
              : null;
          if (hasVat && vat == null) continue;
          found.add(
            _Core(
              subtotal,
              d < 0 ? null : discount,
              cents[c],
              p,
              cents[t],
              vat == null ? null : cents[vat],
            ),
          );
        }
      }
    }
  }
  // Two different sets of numbers that both balance: the bill is ambiguous.
  if (found.length > 1) return null;
  if (found.length == 1) {
    final core = found.first;
    final vat = core.vat;
    return BillCheck(
      kind: BillKind.serviceCharge,
      subtotal: core.subtotal / 100,
      discount: core.discount == null ? null : core.discount! / 100,
      serviceCharge: core.service / 100,
      servicePercent: core.percent,
      total: core.total / 100,
      vat: vat == null ? null : vat / 100,
      vatPercent: vat == null ? null : vatPercent,
      beforeVat: vat == null ? null : (core.total - vat) / 100,
    );
  }

  // A printed percent other than VAT that is not a service charge must be a
  // discount that checks out; a charge that fails its own percent means the
  // receipt does not add up, and nothing below may call it "nothing added".
  for (final p in servicePercents) {
    if (!_isPercentDiscount(cents, lineTotal, at, p)) return null;
  }

  // 2. VAT. total * 7/107 and total - VAT both printed. Arithmetic alone
  // cannot tell "7 % added to 300.00" from "7 % inside 321.00"; the items
  // can. Printed before-tax, VAT, total in that order: on top when the items
  // above add up to the before-tax figure, included when they add up to the
  // total, and unknown (null) otherwise. VAT lines printed after the total
  // (the 7-Eleven layout) mean it is included.
  if (hasVat) {
    final totals = <int, (int, int, int)>{};
    for (var t = 0; t < cents.length; t++) {
      final found = _vatInside(cents, rowPercents, t, vatPercent);
      if (found != null) totals[cents[t]] = (t, found.$1, found.$2);
    }
    if (totals.length > 1) return null;
    if (totals.length == 1) {
      final total = totals.keys.first;
      final (t, v, b) = totals.values.first;
      final vat = cents[v];
      final before = total - vat;
      final taxRows = {v, b};
      if (b < v && v < t) {
        final onTop = _itemsBefore(cents, lineTotal, b, before);
        if (onTop != null) {
          return BillCheck(
            kind: BillKind.vatOnTop,
            total: total / 100,
            subtotal: before / 100,
            vat: vat / 100,
            vatPercent: vatPercent,
            beforeVat: before / 100,
            itemCount: onTop,
          );
        }
      }
      final items = _itemsBefore(cents, lineTotal, t, total, skip: taxRows);
      if (b < v && v < t && items == null) return null;
      return BillCheck(
        kind: BillKind.vatIncluded,
        total: total / 100,
        subtotal: items == null ? null : total / 100,
        vat: vat / 100,
        vatPercent: vatPercent,
        beforeVat: before / 100,
        itemCount: items,
      );
    }
  }

  // 3. Nothing added: the item lines right above a total add up to it, or
  // to a verified subtotal from which a printed discount brings it down.
  // Once a total verifies, nothing at or above it is added again, so cash
  // and change below it cannot pose as another total.
  final readings = <BillCheck>[];
  final verifiedAt = <int, BillCheck>{};
  var floor = 0;
  // The floor before the last reading: a line taken as a total too early
  // (an item that equals the items above it) is given back as an item when
  // a later line adds up over it.
  var lastFloor = 0;
  for (var t = 1; t < cents.length; t++) {
    if (!lineTotal[t] || cents[t] <= 0) continue;
    BillCheck? reading;
    var start = floor;
    for (final from in {floor, lastFloor}) {
      final items = _itemsBefore(
        cents,
        lineTotal,
        t,
        cents[t],
        from: from,
        whole: true,
      );
      if (items == null) continue;
      if (from != floor && readings.isNotEmpty) {
        verifiedAt.removeWhere((_, r) => identical(r, readings.last));
        readings.removeLast();
      }
      start = from;
      reading = BillCheck(
        kind: BillKind.itemsOnly,
        total: cents[t] / 100,
        subtotal: cents[t] / 100,
        itemCount: items,
      );
      break;
    }
    for (var d = t - 1; d > 0 && reading == null; d--) {
      // The VAT line is never a discount, and a plain item or total line
      // is not one either (two receipts in one photo would otherwise read
      // as "100.00 less 50.00").
      if (rowPercents[d].contains(vatPercent)) continue;
      if (rowRoles[d] != RowRole.discount) continue;
      final subtotal = cents[t] + cents[d];
      if (floor == d) {
        // Discount below a verified subtotal line.
        final sub = verifiedAt.entries
            .where((e) => e.key < d && cents[e.key] == subtotal)
            .lastOrNull;
        if (sub == null) continue;
        readings.remove(sub.value);
        start = lastFloor;
        reading = BillCheck(
          kind: BillKind.itemsOnly,
          total: cents[t] / 100,
          subtotal: sub.value.total,
          discount: cents[d] / 100,
          itemCount: sub.value.itemCount,
        );
      } else if (d == t - 1) {
        // Discount right after the items, no subtotal printed.
        final counted = _itemsBefore(
          cents,
          lineTotal,
          d,
          subtotal,
          from: floor,
          whole: true,
        );
        if (counted == null) continue;
        reading = BillCheck(
          kind: BillKind.itemsOnly,
          total: cents[t] / 100,
          subtotal: subtotal / 100,
          discount: cents[d] / 100,
          itemCount: counted,
        );
      }
    }
    if (reading == null) continue;
    readings.add(reading);
    verifiedAt[t] = reading;
    lastFloor = start;
    floor = t + 1;
  }
  final values = {for (final r in readings) r.total};
  if (values.length != 1) return null;
  // Below the total only payment may follow: cash, or cash and change that
  // give back exactly the total. Any other line means items were missed.
  final total = (readings.last.total * 100).round();
  final rest = [
    for (var i = floor; i < cents.length; i++)
      if (lineTotal[i]) cents[i],
  ];
  final paid = switch (rest) {
    [] => true,
    [final cash] => cash >= total,
    [final cash, final change] => cash - change == total,
    _ => false,
  };
  return paid ? readings.last : null;
}

/// Whether percent [p] is a discount that verifies: an amount D printed
/// after item lines whose sum S has D = p % of S (to the satang or the
/// nearest baht), and S - D printed later.
bool _isPercentDiscount(
  List<int> cents,
  List<bool> lineTotal,
  Map<int, List<int>> at,
  double p,
) {
  for (var d = 1; d < cents.length; d++) {
    var sum = 0;
    for (var i = d - 1; i >= 0; i--) {
      if (!lineTotal[i]) continue;
      sum += cents[i];
      if (_isCharge(cents[d], sum * p / 100) &&
          (at[sum - cents[d]]?.any((t) => t > d) ?? false)) {
        return true;
      }
    }
  }
  return false;
}

/// How many item lines directly above index [end], and at or below index
/// [from], add up to [value], or null. Only line totals ([lineTotal]) are
/// added, never the rows in [skip]. With [whole], every line from [from]
/// must be in the sum, so a few items that happen to equal another line
/// cannot pose as a total. A single line counts only when it is the
/// first amount on the receipt and is printed again as [value] (one item
/// and its total); otherwise two equal neighbours would pose as a total.
int? _itemsBefore(
  List<int> cents,
  List<bool> lineTotal,
  int end,
  int value, {
  int from = 0,
  Set<int> skip = const {},
  bool whole = false,
}) {
  var sum = 0;
  var count = 0;
  for (var i = end - 1; i >= from; i--) {
    if (!lineTotal[i] || skip.contains(i)) continue;
    sum += cents[i];
    count++;
    final reachedStart = !Iterable<int>.generate(
      i - from,
      (k) => from + k,
    ).any((j) => lineTotal[j] && !skip.contains(j));
    if (sum == value && (!whole || reachedStart)) {
      final first = !Iterable<int>.generate(i).any((j) => lineTotal[j]);
      return count > 1 || first ? count : null;
    }
    if (sum > value) return null;
  }
  return null;
}

/// VAT inside the amount at index [t] (total * q / (100 + q), to the satang)
/// when it and total - VAT are both printed: (VAT index, before-tax index).
/// An exact amount on a row that prints the VAT rate wins over a near one,
/// so an item a satang away is not taken as the VAT.
(int, int)? _vatInside(
  List<int> cents,
  List<Set<double>> rowPercents,
  int t,
  double percent,
) {
  final total = cents[t];
  final exact = total * percent / (100 + percent);
  (int, int)? best;
  var bestScore = -1;
  for (var v = 0; v < cents.length; v++) {
    if (v == t || !_within(cents[v], exact.round(), 1)) continue;
    // The before-tax figure nearest above the VAT line, else any.
    final before = total - cents[v];
    var b = cents.lastIndexWhere((c) => c == before, v - 1);
    if (b < 0) b = cents.indexWhere((c) => c == before);
    if (b < 0 || b == t || b == v) continue;
    final score =
        (rowPercents[v].contains(percent) ? 2 : 0) +
        (cents[v] == exact.round() ? 1 : 0);
    if (score > bestScore) {
      best = (v, b);
      bestScore = score;
    }
  }
  return best;
}

class _Core {
  const _Core(
    this.subtotal,
    this.discount,
    this.service,
    this.percent,
    this.total,
    this.vat,
  );

  final int subtotal;
  final int? discount;
  final int service;
  final double percent;
  final int total;
  final int? vat;

  @override
  bool operator ==(Object other) =>
      other is _Core &&
      other.subtotal == subtotal &&
      other.discount == discount &&
      other.service == service &&
      other.total == total;

  @override
  int get hashCode => Object.hash(subtotal, discount, service, total);
}

bool _within(int a, int b, int tolerance) => (a - b).abs() <= tolerance;

/// A printed charge matches its percent when it is exact to the satang, or
/// rounded to the nearest whole baht: the demo bill prints 10 % of 212.00
/// (21.20) as 21.00.
bool _isCharge(int printed, double exactCents) =>
    (printed - exactCents).abs() <= 1 ||
    (printed % 100 == 0 && (printed - exactCents).abs() <= 50);

/// Money printed with two decimals: "225.00", "1,225.00", and the OCR comma
/// decimal "85,00". Digits glued to letters or other digits (IDs, dates) are
/// not amounts.
final _amount = RegExp(
  r'(?<![\d.,/:#])(\d{1,3}(?:,\d{3})+|\d+)[.,](\d{2})(?![\d%])',
);

/// A currency code right after an amount, other than baht ("144.71 USD").
/// Only real codes: "21.59 VAT" is a tax line, not a currency.
final _foreignCode = RegExp(
  r'^ *(?:USD|EUR|JPY|GBP|CNY|RMB|KRW|SGD|AUD|NZD|HKD|TWD|MYR|IDR|PHP|VND|INR|CHF|CAD|SEK|NOK|DKK|AED|LAK|KHR|MMK)\b',
);

final _percent = RegExp(r'(\d{1,2}(?:\.\d{1,2})?)\s*%');

int? _toCents(RegExpMatch m) {
  final whole = int.tryParse(m.group(1)!.replaceAll(',', ''));
  final fraction = int.tryParse(m.group(2)!);
  if (whole == null || fraction == null) return null;
  return whole * 100 + fraction;
}
