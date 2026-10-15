import 'ocr_layout.dart';

/// Thailand's standard VAT rate in percent. It is only used when the bill
/// itself prints it.
const double thaiVatPercent = 7;

/// A Thai restaurant bill whose figures were verified by arithmetic.
///
/// Labels on a photographed Thai bill come back partly garbled from OCR
/// (ยอดชำระ was read as มองชาระ), and the amounts often sit in a separate
/// column block from their labels. So the bill is never read by its labels:
/// it is accepted only when the printed amounts fit together exactly as
/// subtotal - discount + service charge = total, with the service charge equal
/// to a percent printed on the bill. VAT is then checked against the total.
class BillCheck {
  const BillCheck({
    required this.subtotal,
    required this.discount,
    required this.serviceCharge,
    required this.servicePercent,
    required this.total,
    required this.vat,
    required this.vatPercent,
    required this.beforeVat,
  });

  final double subtotal;
  final double? discount;
  final double serviceCharge;
  final double servicePercent;
  final double total;
  final double? vat;
  final double? vatPercent;
  final double? beforeVat;

  /// The service charge was added after the subtotal, not hidden in prices.
  /// Always true for an accepted bill: acceptance requires
  /// subtotal - discount + service charge = total.
  bool get serviceAddedOnTop => true;

  /// The VAT amount is already inside the total (total - VAT = before tax).
  bool get vatIncluded => vat != null && beforeVat != null;
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

/// Returns the verified bill, or null when no set of printed amounts adds up.
/// It never fills in a missing figure.
BillCheck? checkBill(
  List<OcrLine> lines, {
  double vatPercent = thaiVatPercent,
}) {
  if (lines.isEmpty) return null;
  final text = rowsFromLines(lines);
  // An amount tagged with another currency ("144.71 USD" on an ATM screen)
  // is not a bill figure; without this an ATM fee line balances like a
  // service charge.
  final cents = [
    for (final m in _amount.allMatches(text))
      if (!_foreignCode.hasMatch(text.substring(m.end))) ?_toCents(m),
  ];
  final percents = {
    for (final m in _percent.allMatches(text))
      if (double.tryParse(m.group(1)!) case final p? when p > 0 && p < 100) p,
  };
  // The VAT rate is never read as a service charge: on a bill that prints
  // both, "before tax + VAT = total" balances just like a service line.
  final servicePercents = percents.where((p) => p != vatPercent);
  if (cents.length < 3 || servicePercents.isEmpty) return null;

  // Every reading that balances, in the order a bill prints it: subtotal,
  // then discount, then service charge, then total. The order keeps cash,
  // change and item amounts from posing as a subtotal or a total.
  final at = <int, List<int>>{};
  for (var i = 0; i < cents.length; i++) {
    (at[cents[i]] ??= []).add(i);
  }
  final hasVat = percents.contains(vatPercent);
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
          final vat = hasVat ? _vatInside(cents, cents[t], vatPercent) : null;
          if (hasVat && vat == null) continue;
          found.add(
            _Core(subtotal, d < 0 ? null : discount, cents[c], p, cents[t], vat),
          );
        }
      }
    }
  }
  // Two different sets of numbers that both balance: the bill is ambiguous.
  if (found.length != 1) return null;
  final core = found.first;
  final vat = core.vat;
  final beforeVat = vat == null ? null : core.total - vat;

  return BillCheck(
    subtotal: core.subtotal / 100,
    discount: core.discount == null ? null : core.discount! / 100,
    serviceCharge: core.service / 100,
    servicePercent: core.percent,
    total: core.total / 100,
    vat: vat == null ? null : vat / 100,
    vatPercent: vat == null ? null : vatPercent,
    beforeVat: beforeVat == null ? null : beforeVat / 100,
  );
}

/// VAT inside [total] (total * q / (100 + q), to the satang) when both it and
/// total - VAT are printed.
int? _vatInside(List<int> cents, int total, double percent) {
  final expected = (total * percent / (100 + percent)).round();
  for (final v in cents) {
    if (_within(v, expected, 1) && cents.contains(total - v)) return v;
  }
  return null;
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

/// A currency code right after an amount, other than baht.
final _foreignCode = RegExp(r'^ *(?!THB)[A-Z]{3}\b');

final _percent = RegExp(r'(\d{1,2}(?:\.\d{1,2})?)\s*%');

int? _toCents(RegExpMatch m) {
  final whole = int.tryParse(m.group(1)!.replaceAll(',', ''));
  final fraction = int.tryParse(m.group(2)!);
  if (whole == null || fraction == null) return null;
  return whole * 100 + fraction;
}
