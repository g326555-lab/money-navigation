import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/features/home/save_row.dart';
import 'package:money_navigation/rules/trip_ledger.dart';

import 'harness.dart';

void main() {
  setUp(resetPreferences);

  testWidgets('a haggle of an item outside the list shows its Thai name', (
    tester,
  ) async {
    final save = saveFromHaggle(
      id: 'new-1',
      savedAt: savedAt,
      itemKey: 'new:ลาเต้วานิลลา',
      askedThb: 120,
      paidThb: 100,
    )!;
    await tester.pumpWidget(
      wrap(Stores(), Material(child: SaveRow(save: save, items: const {}))),
    );
    await tester.pump();
    expect(find.textContaining('ลาเต้วานิลลา'), findsOneWidget);
    expect(find.textContaining('Market price'), findsNothing);
  });
}
