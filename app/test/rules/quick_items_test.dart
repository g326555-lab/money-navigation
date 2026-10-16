import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/quick_items.dart';

void main() {
  test('the bundled file lists names only, both languages', () {
    final items = parseQuickItems(File(quickItemsAsset).readAsStringSync());
    expect(items.length, greaterThanOrEqualTo(10));
    expect(items.every((i) => i.en.isNotEmpty && i.th.isNotEmpty), isTrue);
  });

  test('broken entries are skipped, a broken file gives none', () {
    expect(
      parseQuickItems('{"items":[{"en":"Hat","th":"หมวก"},{"en":""},1]}'),
      hasLength(1),
    );
    expect(parseQuickItems('nope'), isEmpty);
  });
}
