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
}

/// One receipt row with an amount.
class RoleRow {
  const RoleRow(this.role, this.cents, {this.change, this.percent});

  /// A percent printed on the row ("Service 10%"), if any.
  final double? percent;

  final RowRole role;

  /// The row's amount in satang; negative for a minus-signed line.
  final int cents;

  /// The second amount on a combined "Cash/Change 20.00 11.00" row.
  final int? change;
}

/// Reads [rows] (printed receipt rows, top to bottom) by their labels and
/// accepts a total only when the arithmetic proves it:
/// - the item lines add up to it (directly, through printed subtotals,
///   discounts, a service charge and VAT on top), or
/// - VAT inside it checks out and the payment gives it back exactly.
/// Every printed subtotal, total, service and VAT figure must fit the
/// accepted reading; one that does not makes the receipt unverified (null).
BillCheck? readByRoles(List<String> rows, {double vatPercent = 7}) {
  final parsed = parseRoleRows(rows);
  if (parsed.isEmpty) return null;

  // Item lines: every amount row above the first summary row.
  final firstSummary = parsed.indexWhere((r) => r.role != RowRole.item);
  final items = [
    for (final r in firstSummary < 0 ? parsed : parsed.sublist(0, firstSummary))
      r.cents,
  ];
  final rest = firstSummary < 0
      ? const <RoleRow>[]
      : parsed.sublist(firstSummary);
  final itemSum = items.fold<int>(0, (a, b) => a + b);

  int sumOf(RowRole role) => rest
      .where((r) => r.role == role)
      .fold<int>(0, (a, r) => a + r.cents.abs());
  final printedSubtotals = [
    for (final r in rest)
      if (r.role == RowRole.subtotal) r.cents,
  ];
  final totals = [
    for (final r in rest)
      if (r.role == RowRole.total) r.cents,
  ];
  final discount = sumOf(RowRole.discount);
  final service = sumOf(RowRole.service);
  final servicePercents = {
    for (final r in rest)
      if (r.role == RowRole.service && r.percent != null) r.percent!,
  };
  // A VAT row printing another rate is not this country's VAT.
  if (rest.any(
    (r) =>
        r.role == RowRole.vat && r.percent != null && r.percent != vatPercent,
  )) {
    return null;
  }
  final vats = [
    for (final r in rest)
      if (r.role == RowRole.vat) r.cents,
  ];
  final vatables = [
    for (final r in rest)
      if (r.role == RowRole.vatable) r.cents,
  ];
  final payments = [
    for (final r in rest)
      if (r.role == RowRole.payment || r.role == RowRole.cashAndChange) r.cents,
  ];
  final changes = [
    for (final r in rest)
      if (r.role == RowRole.change) r.cents,
    for (final r in rest)
      if (r.role == RowRole.cashAndChange && r.change != null) r.change!,
  ];

  // A bill may repeat its items as category subtotals right above the
  // total ("Food 345, Drinks 25, Food and drinks 370"): the items then add
  // up to twice the subtotal. That reading is used only when a printed
  // subtotal or total confirms it.
  final split = _categorySplit(items);
  final itemsBase =
      split != null &&
          [...printedSubtotals, ...totals].contains(split) &&
          ![...printedSubtotals, ...totals].contains(itemSum)
      ? split
      : itemSum;
  // The subtotal the chain starts from: the item sum, which a printed
  // subtotal must match when there are items.
  final subtotal = items.isNotEmpty
      ? itemsBase
      : (printedSubtotals.isNotEmpty ? printedSubtotals.last : null);
  if (items.isNotEmpty &&
      printedSubtotals.isNotEmpty &&
      !printedSubtotals.contains(itemsBase)) {
    return null;
  }

  // Candidate totals, latest printed first: the payable one comes last.
  final candidates = <int>{...totals.reversed, ...printedSubtotals.reversed};
  for (final t in candidates) {
    if (t <= 0) continue;
    final reading = _prove(
      t: t,
      subtotal: subtotal,
      itemCount: items.isEmpty ? null : items.length,
      discount: discount,
      service: service,
      vats: vats,
      vatables: vatables,
      payments: payments,
      changes: changes,
      vatPercent: vatPercent,
      serviceMustBeUsed: service > 0,
      servicePercents: servicePercents,
    );
    if (reading == null) continue;
    // Every printed summary figure must fit this reading.
    final known = <int>{
      t,
      ?subtotal,
      if (subtotal != null) subtotal - discount,
      if (reading.vat != null) ((reading.total - reading.vat!) * 100).round(),
      if (reading.vat != null && reading.vatAddedOnTop)
        ((reading.total - reading.vat!) * 100).round(),
    };
    final stray = [
      ...totals,
      ...printedSubtotals,
    ].any((v) => !known.contains(v));
    if (stray) return null;
    // Printed payments must give back exactly this total: a rounding line
    // or a discount the reading missed shows up here.
    if (payments.isNotEmpty && !_paysExactly(t, payments, changes)) {
      return null;
    }
    return reading;
  }
  return null;
}

BillCheck? _prove({
  required int t,
  required int? subtotal,
  required int? itemCount,
  required int discount,
  required int service,
  required List<int> vats,
  required List<int> vatables,
  required List<int> payments,
  required List<int> changes,
  required double vatPercent,
  required bool serviceMustBeUsed,
  required Set<double> servicePercents,
}) {
  int? vatInside;
  for (final v in vats) {
    final fromTotal = (t * vatPercent / (100 + vatPercent)).round();
    if ((v - fromTotal).abs() <= 1) vatInside = v;
    // VAT on the VAT-able part only (VAT-exempt items such as rice).
    for (final x in vatables) {
      final fromVatable = (x * vatPercent / (100 + vatPercent)).round();
      if (x <= t && (v - fromVatable).abs() <= 1) vatInside = v;
    }
  }
  final paid = _paysExactly(t, payments, changes);

  if (subtotal != null) {
    final net = subtotal - discount;
    final withService = net + service;
    // A printed service rate must match the charge: exact to the satang
    // or rounded to the nearest baht.
    for (final p in servicePercents) {
      final exact = net * p / 100;
      final ok =
          (service - exact).abs() <= 1 ||
          (service % 100 == 0 && (service - exact).abs() <= 50);
      if (!ok) return null;
    }
    // Service charge, then VAT on top of everything.
    for (final v in vats) {
      final onTop = (withService * vatPercent / 100).round();
      if ((v - onTop).abs() <= 1 && withService + v == t) {
        return _check(
          kind: service > 0 ? BillKind.serviceCharge : BillKind.vatOnTop,
          t: t,
          subtotal: subtotal,
          discount: discount,
          service: service,
          net: net,
          vat: v,
          vatOnTop: true,
          vatPercent: vatPercent,
          itemCount: itemCount,
        );
      }
    }
    if (withService == t && (vats.isEmpty || vatInside != null)) {
      return _check(
        kind: service > 0
            ? BillKind.serviceCharge
            : (vatInside != null ? BillKind.vatIncluded : BillKind.itemsOnly),
        t: t,
        subtotal: subtotal,
        discount: discount,
        service: service,
        net: net,
        vat: vatInside,
        vatOnTop: false,
        vatPercent: vatPercent,
        itemCount: itemCount,
      );
    }
    // Items add up to the total and the other lines are payments (a
    // Starbucks redemption, a coupon taken at the till).
    if (subtotal == t &&
        !serviceMustBeUsed &&
        (vats.isEmpty || vatInside != null)) {
      return _check(
        kind: vatInside != null ? BillKind.vatIncluded : BillKind.itemsOnly,
        t: t,
        subtotal: subtotal,
        discount: 0,
        service: 0,
        net: subtotal,
        vat: vatInside,
        vatOnTop: false,
        vatPercent: vatPercent,
        itemCount: itemCount,
      );
    }
  }
  // No usable items: VAT inside the total and an exact payment together.
  if (vatInside != null && paid && service == 0) {
    return _check(
      kind: BillKind.vatIncluded,
      t: t,
      subtotal: null,
      discount: 0,
      service: 0,
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
  required int? net,
  required int? vat,
  required bool vatOnTop,
  required double vatPercent,
  required int? itemCount,
}) {
  final servicePercent = service > 0 && net != null && net > 0
      ? (service * 1000 / net).round() / 10
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
    beforeVat: vat == null ? null : (t - vat) / 100,
    itemCount: itemCount,
    vatOnTop: vatOnTop,
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
/// of the lines above them: both halves add up to the same amount.
int? _categorySplit(List<int> items) {
  final total = items.fold<int>(0, (a, b) => a + b);
  if (total <= 0 || total.isOdd || items.length < 3) return null;
  var suffix = 0;
  for (var i = items.length - 1; i > 0; i--) {
    suffix += items[i];
    if (suffix == total ~/ 2) return suffix;
    if (suffix > total ~/ 2) return null;
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
  for (final row in rows) {
    if (_quantityRow.hasMatch(row.toLowerCase())) continue;
    final role = roleOf(row);
    final percent = double.tryParse(_percent.firstMatch(row)?[1] ?? '');
    final amounts = [
      for (final m in _amount.allMatches(row))
        // An amount tagged with another currency is not a baht figure.
        // Not another currency, and not an ID (no receipt total has more
        // than seven baht digits).
        if (!_foreignCode.hasMatch(row.substring(m.end)) &&
            m[2]!.replaceAll(',', '').length <= 7)
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
    final cents = amounts.last;
    // A minus-signed line without a discount word is part of the item list
    // (a cup discount under its drink); with one, it is a discount.
    out.add(RoleRow(role, cents, percent: percent));
  }
  return out;
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
  if (total) return RowRole.total;
  if (_service.hasMatch(t)) return RowRole.service;
  if (_discount.hasMatch(t)) return RowRole.discount;
  if (cash) return RowRole.payment;
  return RowRole.item;
}

final _change = RegExp(r'\bchange\b|ทอน');
final _payment = RegExp(
  r'\b(?:cash|tend(?:er(?:ed)?)?|payments?|paid|received|visa|mastercard|'
  r'wallet|redeem|cpn|coupon|voucher)\b|เงินสด|วอลเล็ท|ชำระเงิน|'
  r'(?<!ยอด)ชำระ',
);
final _vatable = RegExp(r'\bvatable\b|\bbefore vat\b|ก่อนภาษี');
final _subtotal = RegExp(r'\bsub[\s-]?total\b|ยอดรวม|\border amt\b');
final _vat = RegExp(r'\bvat\b|\btax\b|ภาษี');
// รวม alone means total only as the row's first word: ผลไม้รวม is "mixed
// fruit" and รวมมิตร a dessert.
final _total = RegExp(
  r'\btotal\b|\bttl\b|\bnet\b|\bgrand total\b|\bamount due\b|สุทธิ|ยอดชำระ|'
  r'คงเหลือ|รวมเงิน|รวมทั้งหมด|รวมสุทธิ|รวมจำนวนเงิน|^\s*รวม(?=[\s\d:]|$)',
);
final _service = RegExp(r'\bservice\b|\bsvc\b|\bs/c\b|ค่าบริการ');
final _discount = RegExp(
  r'\bdiscount\b|\bround(?:ing)?\b|ส่วนลด|ลด|ฟรี|ปัดเศษ',
);

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
  r'(?<![\d.,/:@#A-Za-z])(-?)฿?\s?(\d{1,3}(?:,\d{3})+|\d+)(?:[.,](\d{2}))?(?![\d@/:%]|[.,]\d)',
);

int _cents(RegExpMatch m) {
  final whole = int.parse(m[2]!.replaceAll(',', ''));
  final cents = whole * 100 + (m[3] == null ? 0 : int.parse(m[3]!));
  return m[1] == '-' ? -cents : cents;
}
