import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/new_item_counter.dart';
import 'package:money_navigation/rules/personal_context.dart';

void main() {
  final now = DateTime(2026, 10, 16, 10);
  PastPurchase p(String key, double asked, double paid, {bool sample = false}) =>
      PastPurchase(
        itemKey: key,
        paidThb: paid,
        askedThb: asked,
        at: now.subtract(const Duration(days: 1)),
        isSample: sample,
      );

  test('uses the item\'s own records first', () {
    final c = counterForNewItem('new:ร่ม', 200, [
      p('new:ร่ม', 200, 150),
      p('mango', 150, 90),
    ], now)!;
    expect(c.recordsUsed, 1);
    expect(c.offerThb, 150); // 25 % off, to 5 baht
  });

  test('falls back to the discount on any item, counting those records', () {
    final c = counterForNewItem('new:ร่ม', 200, [
      p('mango', 150, 90, sample: true),
      p('coconut', 70, 60, sample: true),
    ], now)!;
    expect(c.recordsUsed, 2);
    expect(c.sampleRecords, 2);
  });

  test('no records, no counter', () {
    expect(counterForNewItem('new:ร่ม', 200, const [], now), isNull);
  });
}
