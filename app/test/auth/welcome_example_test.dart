import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/core/formatters.dart';
import 'package:money_navigation/features/auth/welcome_example.dart';

void main() {
  group('welcome example (demo ATM prop)', () {
    test('keeps about 245.75 THB', () {
      expect(welcomeExampleKeptThb(), closeTo(245.75, 0.01));
    });

    test('reads "246 THB" with a non-breaking space', () {
      expect(
        AppFormat.roundedAmount(welcomeExampleKeptThb(), 'THB'),
        '246 THB',
      );
    });
  });
}
