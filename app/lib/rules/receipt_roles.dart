import 'bill_check.dart';

/// What a printed receipt row is, from the words on it. Thai and English
/// keywords that survive OCR on real receipts (7-Eleven, Big C, Starbucks,
/// McDonald's, local restaurants).
enum RowRole {
  item,
  subtotal,
  total,
  discount,
  service,
  vat,
  vatable,
  payment,
  change,
  cashAndChange,

  /// "Rounding 0.49" / "ปัดเศษ": a few satang either way.
  rounding,

  /// A Thai coupon line (คูปอง): a discount on one receipt (Makro), money
  /// handed over on another (Lotus's). The arithmetic decides which.
  coupon,
}

/// One receipt row with an amount.
class RoleRow {
  const RoleRow(
    this.role,
    this.cents, {
    this.change,
    this.percent,
    this.included = false,
  });

  /// The row says its charge is already inside the prices ("(รวม)",
  /// "incl").
  final bool included;

  /// A percent printed on the row ("Service 10%"), if any.
  final double? percent;

  final RowRole role;

  /// The row's amount in satang; negative for a minus-signed line.
  final int cents;

  /// The second amount on a combined "Cash/Change 20.00 11.00" row.
  final int? change;
}

/// Reads [rows] (printed receipt rows, top to bottom) by their labels and
/// accepts a total only when the arithmetic proves it: items, less
/// discounts (labelled, or unlabelled amounts between the items and the
/// total), plus a service charge and VAT added on top, plus or minus a
/// rounding line, give the total; or VAT inside the total checks out and the
/// payment gives it back exactly. Every printed subtotal, total, service and
/// VAT figure must fit the accepted reading, and printed payments must give
/// back exactly the total; anything else makes the receipt unverified.
BillCheck? readByRoles(List<String> rows, {double vatPercent = 7}) {
  final parsed = parseRoleRows(rows);
  if (parsed.isEmpty) return null;

  // Item lines: every amount row above the first summary row. Trailing
  // lines that repeat the sum of the items above them are an unlabelled
  // subtotal and total (labels printed elsewhere), not more items.
  final firstSummary = parsed.indexWhere((r) => r.role != RowRole.item);
  var items = [
    for (final r in firstSummary < 0 ? parsed : parsed.sublist(0, firstSummary))
      r.cents,
  ];
  final unlabelledTotals = <int>[];
  for (var k = 1; k < items.length; k++) {
    final head = items.sublist(0, k).fold<int>(0, (a, b) => a + b);
    if (head > 0 && items.sublist(k).every((v) => v == head)) {
      unlabelledTotals.add(head);
      items = items.sublist(0, k);
      break;
    }
  }
  final rest = firstSummary < 0
      ? const <RoleRow>[]
      : parsed.sublist(firstSummary);

  // A VAT row printing another rate is not this country's VAT.
  if (rest.any(
    (r) =>
        r.role == RowRole.vat && r.percent != null && r.percent != vatPercent,
  )) {
    return null;
  }
  List<int> amountsOf(RowRole role) => [
    for (final r in rest)
      if (r.role == role) r.cents,
  ];
  final printedSubtotals = amountsOf(RowRole.subtotal);
  final totals = amountsOf(RowRole.total);
  final vats = amountsOf(RowRole.vat);
  final vatables = amountsOf(RowRole.vatable);
  final roundings = amountsOf(RowRole.rounding);
  final payments = [
    ...amountsOf(RowRole.payment),
    for (final r in rest)
      if (r.role == RowRole.cashAndChange) r.cents,
  ];
  final changes = [
    ...amountsOf(RowRole.change),
    for (final r in rest)
      if (r.role == RowRole.cashAndChange && r.change != null) r.change!,
  ];
  final labelledDiscount = amountsOf(RowRole.discount)
      .fold<int>(0, (a, b) => a + b.abs());
  final coupons = [for (final c in amountsOf(RowRole.coupon)) c.abs()];
  final serviceRows = [
    for (final r in rest)
      if (r.role == RowRole.service) r,
  ];
  final serviceAdded = serviceRows
      .where((r) => !r.included)
      .fold<int>(0, (a, r) => a + r.cents.abs());
  final serviceInside = serviceRows
      .where((r) => r.included)
      .fold<int>(0, (a, r) => a + r.cents.abs());
  final servicePercents = {
    for (final r in serviceRows)
      if (r.percent != null && r.cents != 0) r.percent!,
  };

  // Where the subtotal can come from: all item lines, only the positive
  // ones (when a discount is printed both inline and again below), or the
  // category subtotals of a bar bill.
  final itemSum = items.fold<int>(0, (a, b) => a + b);
  final subtotals = <int>{
    if (items.isNotEmpty) itemSum,
    if (items.any((v) => v < 0))
      items.where((v) => v > 0).fold<int>(0, (a, b) => a + b),
    ?_categorySplit(items),
    if (items.isEmpty) ...printedSubtotals,
  };
  if (printedSubtotals.isNotEmpty) {
    subtotals.removeWhere((v) => !printedSubtotals.contains(v));
    if (subtotals.isEmpty) return null;
  }

  // Candidate totals, latest printed first: the payable one comes last.
  final candidates = <int>{
    ...totals.reversed,
    ...unlabelledTotals,
    ...printedSubtotals.reversed,
  };
  for (final t in candidates) {
    if (t <= 0) continue;
    // Unlabelled amounts between the items and this total.
    final tIndex = rest.lastIndexWhere(
      (r) =>
          r.cents == t &&
          (r.role == RowRole.total || r.role == RowRole.subtotal),
    );
    final middle = [
      if (tIndex >= 0)
        for (final r in rest.sublist(0, tIndex))
          if (r.role == RowRole.item && r.cents != 0) r.cents.abs(),
    ];
    final middleSum = middle.fold<int>(0, (a, b) => a + b);
    for (final couponIsDiscount in coupons.isEmpty ? [false] : [true, false]) {
      for (final int? subtotal
          in subtotals.isEmpty ? <int?>[null] : subtotals) {
        final discount =
            labelledDiscount +
            (couponIsDiscount ? coupons.fold<int>(0, (a, b) => a + b) : 0);
        final paidWith = [...payments, if (!couponIsDiscount) ...coupons];
        // Category lines that add up to the subtotal are explained. Other
        // unlabelled lines count as discounts only beside labelled ones (a
        // 7-Eleven "M-Stamp 1.00" among its coupons); alone they may be a
        // second receipt in the same photo, so the reading is refused.
        final explained = subtotal != null && middleSum == subtotal;
        // Unusable items: only VAT inside the total plus an exact payment
        // can still prove it (Starbucks prints split payments unlabelled).
        final itemsUsable = explained || middleSum == 0 || discount > 0;
        final adjustments = explained || !itemsUsable ? 0 : middleSum;
        final reading = _prove(
          t: t,
          subtotal: itemsUsable ? subtotal : null,
          itemCount: items.isEmpty || !itemsUsable ? null : items.length,
          discount: discount + adjustments,
          serviceAdded: serviceAdded,
          serviceInside: serviceInside,
          servicePercents: servicePercents,
          vats: vats,
          vatables: vatables,
          roundings: roundings,
          payments: paidWith,
          changes: changes,
          vatPercent: vatPercent,
        );
        if (reading == null) continue;
        // Every printed summary figure must fit this reading.
        final net = subtotal == null || !itemsUsable
            ? null
            : subtotal - discount - adjustments;
        final known = <int>{
          t,
          ?subtotal,
          ?net,
          if (net != null) net + serviceAdded,
          if (reading.vat != null)
            ((reading.total - reading.vat!) * 100).round(),
        };
        if ([...totals, ...printedSubtotals].any((v) => !known.contains(v))) {
          continue;
        }
        if (paidWith.isNotEmpty && !_paysExactly(t, paidWith, changes)) {
          continue;
        }
        return reading;
      }
    }
  }
  return null;
}

BillCheck? _prove({
  required int t,
  required int? subtotal,
  required int? itemCount,
  required int discount,
  required int serviceAdded,
  required int serviceInside,
  required Set<double> servicePercents,
  required List<int> vats,
  required List<int> vatables,
  required List<int> roundings,
  required List<int> payments,
  required List<int> changes,
  required double vatPercent,
}) {
  final vatShare = vatPercent / (100 + vatPercent);
  int? vatInside;
  for (final v in vats) {
    if ((v - (t * vatShare).round()).abs() <= 1) vatInside = v;
    // VAT on the VAT-able part only (VAT-exempt items such as rice).
    for (final x in vatables) {
      if (x <= t && (v - (x * vatShare).round()).abs() <= 1) vatInside = v;
    }
  }
  // A service charge already inside the prices ("ค่าบริการ 10% (รวม)"):
  // it must be that share of the total before VAT.
  if (serviceInside > 0) {
    final beforeVat = vatInside != null ? t - vatInside : t;
    final ok = servicePercents.any(
      (p) => (serviceInside - (beforeVat * p / (100 + p)).round()).abs() <= 1,
    );
    if (!ok) return null;
  }
  final rounding = roundings.fold<int>(0, (a, b) => a + b.abs());

  if (subtotal != null) {
    final net = subtotal - discount;
    final withService = net + serviceAdded;
    // A printed service rate must match the charge added: exact to the
    // satang or rounded to the nearest baht.
    if (serviceAdded > 0) {
      for (final p in servicePercents) {
        final exact = net * p / 100;
        final ok =
            (serviceAdded - exact).abs() <= 1 ||
            (serviceAdded % 100 == 0 && (serviceAdded - exact).abs() <= 50);
        if (!ok) return null;
      }
    }
    for (final r in <int>{0, rounding, -rounding}) {
      // VAT on top of everything above it.
      for (final v in vats) {
        final onTop = (withService * vatPercent / 100).round();
        if ((v - onTop).abs() <= 1 && withService + v + r == t) {
          return _check(
            kind: serviceAdded > 0 ? BillKind.serviceCharge : BillKind.vatOnTop,
            t: t,
            subtotal: subtotal,
            discount: discount,
            service: serviceAdded,
            net: net,
            vat: v,
            vatOnTop: true,
            beforeVat: withService,
            vatPercent: vatPercent,
            itemCount: itemCount,
          );
        }
      }
      if (withService + r == t && (vats.isEmpty || vatInside != null)) {
        return _check(
          kind: serviceAdded > 0
              ? BillKind.serviceCharge
              : (vatInside != null ? BillKind.vatIncluded : BillKind.itemsOnly),
          t: t,
          subtotal: subtotal,
          discount: discount,
          service: serviceAdded > 0 ? serviceAdded : serviceInside,
          serviceIncluded: serviceAdded == 0 && serviceInside > 0,
          net: net,
          vat: vatInside,
          vatOnTop: false,
          vatPercent: vatPercent,
          itemCount: itemCount,
        );
      }
    }
  }
  // No usable items: VAT inside the total and an exact payment together.
  if (vatInside != null &&
      serviceAdded == 0 &&
      _paysExactly(t, payments, changes)) {
    return _check(
      kind: BillKind.vatIncluded,
      t: t,
      subtotal: null,
      discount: 0,
      service: serviceInside,
      serviceIncluded: serviceInside > 0,
      net: null,
      vat: vatInside,
      vatOnTop: false,
      vatPercent: vatPercent,
      itemCount: null,
    );
  }
  return null;
}

BillCheck _check({
  required BillKind kind,
  required int t,
  required int? subtotal,
  required int discount,
  required int service,
  bool serviceIncluded = false,
  required int? net,
  required int? vat,
  required bool vatOnTop,
  int? beforeVat,
  required double vatPercent,
  required int? itemCount,
}) {
  final servicePercent = service > 0 && net != null && net > 0
      ? (serviceIncluded
            ? (service * 1000 / (net - service)).round() / 10
            : (service * 1000 / net).round() / 10)
      : null;
  return BillCheck(
    kind: kind,
    total: t / 100,
    subtotal: subtotal == null ? null : subtotal / 100,
    discount: discount > 0 ? discount / 100 : null,
    serviceCharge: service > 0 ? service / 100 : null,
    servicePercent: servicePercent?.roundToDouble(),
    vat: vat == null ? null : vat / 100,
    vatPercent: vat == null ? null : vatPercent,
    beforeVat: vat == null ? null : (beforeVat ?? t - vat) / 100,
    itemCount: itemCount,
    vatOnTop: vatOnTop,
    serviceIncluded: serviceIncluded,
  );
}

/// Payment rows give back exactly [t]: one payment equals it, one payment
/// minus the change does, or all payments minus all change do.
bool _paysExactly(int t, List<int> payments, List<int> changes) {
  if (payments.isEmpty) return false;
  final change = changes.fold<int>(0, (a, b) => a + b);
  if (payments.any((p) => p == t || p - change == t)) return true;
  return payments.fold<int>(0, (a, b) => a + b) - change == t;
}

/// The subtotal of a bill whose last few item lines are category subtotals
/// of the lines above them ("Food 1300.00, Wine 900.00"): they add up to
/// the lines above, counted with or without an inline discount line.
int? _categorySplit(List<int> items) {
  if (items.length < 3) return null;
  var suffix = 0;
  for (var i = items.length - 1; i > 0; i--) {
    if (items[i] <= 0) return null;
    suffix += items[i];
    final head = items.sublist(0, i);
    final all = head.fold<int>(0, (a, b) => a + b);
    final gross = head.where((v) => v > 0).fold<int>(0, (a, b) => a + b);
    if (suffix == all || suffix == gross) return suffix;
    if (suffix > gross) return null;
  }
  return null;
}

/// Splits receipt rows into roles and amounts. Rows without an amount are
/// dropped. When any amount on the receipt has two decimals, whole numbers
/// count only on payment rows (quantities, table numbers and dates are not
/// money); otherwise the receipt is read in whole baht.
List<RoleRow> parseRoleRows(List<String> rows) {
  final decimal = rows.any(
    (r) => _amount.allMatches(r).any((m) => m[3] != null),
  );
  final out = <RoleRow>[];
  // A "Payment" label on its own row, its amount on the next.
  var paymentLabel = false;
  for (final row in rows) {
    final lower = row.toLowerCase();
    final afterPaymentLabel = paymentLabel;
    paymentLabel =
        roleOf(row) == RowRole.payment && _amount.allMatches(row).isEmpty;
    // Piece counts, dates and document numbers are not money.
    if (_metaRow.hasMatch(lower) || _unitOnlyRow.hasMatch(lower)) continue;
    // "Total Qty 2" counts pieces; a column header "Qty Description ...
    // 220.00" that OCR merged into an item row still carries its amount.
    if (_quantityRow.hasMatch(lower) &&
        !_amount.allMatches(row).any((m) => m[3] != null)) {
      continue;
    }
    final bare = !RegExp(r'[A-Za-z\u0E00-\u0E7F]').hasMatch(row);
    final role = afterPaymentLabel && bare ? RowRole.payment : roleOf(row);
    final percent = double.tryParse(_percent.firstMatch(row)?[1] ?? '');
    final amounts = [
      for (final m in _amount.allMatches(row))
        // An amount tagged with another currency is not a baht figure.
        // Not another currency, and not an ID (no receipt total has more
        // than seven baht digits).
        if (!_foreignCode.hasMatch(row.substring(m.end)) &&
            m[2]!.replaceAll(RegExp('[,.]'), '').length <= 7)
          if (m[3] != null ||
              !decimal ||
              role == RowRole.payment ||
              role == RowRole.change ||
              role == RowRole.cashAndChange)
            _cents(m),
    ];
    if (amounts.isEmpty) continue;
    if (role == RowRole.cashAndChange) {
      out.add(
        RoleRow(
          RowRole.cashAndChange,
          amounts[amounts.length >= 2 ? amounts.length - 2 : 0],
          change: amounts.length >= 2 ? amounts.last : null,
        ),
      );
      continue;
    }
    var cents = amounts.last;
    // "9.81 VAT TTL 150.00" (Starbucks Thailand): the VAT figure is printed
    // before its label and the VAT-inclusive total after it.
    if (role == RowRole.vat && amounts.length >= 2) {
      final label = lower.indexOf('vat');
      final before = [
        for (final m in _amount.allMatches(row))
          if (m.end <= label && m[3] != null) m,
      ];
      if (label > 0 && before.length == 1) cents = _cents(before.single);
    }
    // A minus-signed line without a discount word is part of the item list
    // (a cup discount under its drink); with one, it is a discount.
    out.add(
      RoleRow(
        role,
        cents,
        percent: percent,
        included: role == RowRole.service && _included.hasMatch(lower),
      ),
    );
  }
  // "Receive Cash:/Change 85.00" with one amount, below a separate cash
  // row, is the change.
  final otherPayment = out.any((r) => r.role == RowRole.payment);
  return [
    for (final r in out)
      if (r.role == RowRole.cashAndChange && r.change == null && otherPayment)
        RoleRow(RowRole.change, r.cents)
      else
        r,
  ];
}

/// The role of one printed row, from its words. English words match whole
/// words only ("Cashew chicken" is not cash, "Bottle" is not a total).
RowRole roleOf(String row) {
  final t = row.toLowerCase();
  final cash = _payment.hasMatch(t);
  final change = _change.hasMatch(t);
  if (cash && change) return RowRole.cashAndChange;
  if (change) return RowRole.change;
  if (_vatable.hasMatch(t)) return RowRole.vatable;
  if (_subtotal.hasMatch(t)) return RowRole.subtotal;
  final vat = _vat.hasMatch(t);
  final total = _total.hasMatch(t);
  if (vat && (!total || t.contains('vat ttl'))) return RowRole.vat;
  // "Total Discount 0.00" is a discount line, not a total.
  if (total && _discount.hasMatch(t)) return RowRole.discount;
  if (total) return RowRole.total;
  if (_service.hasMatch(t)) return RowRole.service;
  if (_rounding.hasMatch(t)) return RowRole.rounding;
  if (_coupon.hasMatch(t)) return RowRole.coupon;
  if (_discount.hasMatch(t)) return RowRole.discount;
  if (cash) return RowRole.payment;
  return RowRole.item;
}

final _change = RegExp(r'\bchange\b|ทอน');
final _payment = RegExp(
  r'\b(?:cash|tend(?:er(?:ed)?)?|payments?|paid|received|visa|mastercard|'
  r'wallet|redeem|cpn|coupon|voucher|qr|promptpay)\b|เงินสด|วอลเล็ท|'
  r'ชำระเงิน|พร้อมเพย์|'
  r'(?<!ยอด)ชำระ',
);
// "Net TTL." under a "VAT TTL" line is the amount before VAT (Starbucks).
final _vatable = RegExp(
  r'\bvatable\b|\bbefore (?:vat|tax)\b|\bnet ttl\b|ก่อนภาษี',
);
final _subtotal = RegExp(r'\bsub[\s-]?total\b|ยอดรวม|\border amt\b');
final _vat = RegExp(r'\bvat\b|\btax\b|ภาษี');
// รวม alone means total only as the row's first word: ผลไม้รวม is "mixed
// fruit" and รวมมิตร a dessert.
final _total = RegExp(
  r'\btotal\b|\bttl\b|\bnet\b|\bgrand total\b|\bamount due\b|สุทธิ|ยอดชำระ|'
  r'คงเหลือ|รวมเงิน|ทั้งหมด|รวมสุทธิ|รวมจำนวนเงิน|^\s*รวม(?=[\s\d:]|$)',
);
final _service = RegExp(r'\bservice\b|\bsvc\b|\bs/c\b|ค่าบริการ');
final _discount = RegExp(r'\bdiscount\b|ส่วนลด|ลด|ฟรี');
final _coupon = RegExp(r'คูปอง');
final _rounding = RegExp(r'\bround(?:ing)?\b|ปัดเศษ');

/// A charge printed as already inside the prices.
final _included = RegExp(r'\(รวม\)|\bincl(?:uded)?\b');

/// Date, document-number and phone rows.
final _metaRow = RegExp(
  r'\bdate\b|\breceipt no\b|\btel\b|\btax id\b|เลขที่|เล่มที่|วันที่|โทร|'
  // A stored-value card's balance or loyalty points, not this bill.
  r'\b(?:card|star|reward|point)s? balance\b',
);

/// A row holding only "1 x 50.00": the quantity and unit price printed
/// under an item whose line total is already counted.
final _unitOnlyRow = RegExp(r'^\s*\d+\s*[x×]\s*[\d,.]+\s*$');

/// Rows that count pieces, not money ("Total Qty 2").
final _quantityRow = RegExp(r'\bqty\b');

/// Money in a row: optional minus and baht sign, digits with or without
/// thousands commas, optional two decimals (dot, or OCR's comma). Numbers
/// glued to other digits, a slash, a colon, '@', '#' or a Latin letter
/// (IDs, dates, unit prices, "s1"), or followed by '@', '/', ':' or '%'
/// (quantities, per-unit prices, times, rates) are not amounts.
final _percent = RegExp(r'(\d{1,2}(?:\.\d{1,2})?)\s*%');
final _foreignCode = RegExp(
  r'^ *(?:USD|EUR|JPY|GBP|CNY|RMB|KRW|SGD|AUD|NZD|HKD|TWD|MYR|IDR|PHP|VND|INR|CHF|CAD|SEK|NOK|DKK|AED|LAK|KHR|MMK)\b',
);

final _amount = RegExp(
  r'(?<![\d.,/:@#A-Za-z])(-?)฿?\s?(\d{1,3}(?:,\d{3})+|\d{1,3}(?:\.\d{3})+(?=\.\d{2})|\d+)'
  r'(?:[.,](\d{2}))?(?![\d@/:]|[.,]\d|\s*%)',
);

int _cents(RegExpMatch m) {
  // Thousands grouped with commas, or with dots before two decimals as on
  // a Boots receipt ("3.025.00").
  final whole = int.parse(m[2]!.replaceAll(RegExp('[,.]'), ''));
  final cents = whole * 100 + (m[3] == null ? 0 : int.parse(m[3]!));
  return m[1] == '-' ? -cents : cents;
}

/// "THB160.00" or "฿ 160.00": an amount glued to the baht code or sign,
/// as card-terminal and QR slips print it.
final _bahtTagged = RegExp(
  r'(?:THB|฿)\s?(\d{1,3}(?:,\d{3})+|\d+)[.,](\d{2})\b',
);

/// The payable total printed on a bill whose lines could not be checked
/// (or a card or QR slip that prints only a total): the amount on, or
/// right under, the last "Total" row. Null when no total is printed.
/// Nothing here is checked against items, so a record made from it is
/// saved as not verified.
double? printedTotalOnly(List<String> rows) {
  double? found;
  for (var i = 0; i < rows.length; i++) {
    if (roleOf(rows[i]) != RowRole.total) continue;
    for (final row in rows.skip(i).take(4)) {
      final tagged = _bahtTagged.firstMatch(row);
      if (tagged != null) {
        found =
            double.parse(tagged[1]!.replaceAll(',', '')) +
            int.parse(tagged[2]!) / 100;
        break;
      }
      final plain = [
        for (final m in _amount.allMatches(row))
          if (m[3] != null) _cents(m) / 100,
      ];
      if (plain.isNotEmpty) {
        found = plain.last;
        break;
      }
    }
  }
  return found == null || found <= 0 ? null : found;
}
