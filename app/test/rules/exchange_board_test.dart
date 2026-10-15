import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/exchange_board.dart';
import 'package:money_navigation/rules/exchange_rate.dart';
import 'package:money_navigation/rules/ocr_layout.dart';

import 'fixtures/exchange_board_ocr_real_ios.dart';

/// The USD row as printed on the demo prop (CLAUDE.md "Demo data"):
/// Buying Notes, Buying T/C, Selling Notes.
const demoUsdRow = 'USD 35.03 35.60 36.10';

/// A made-up reference rate: 1 THB = 0.02812 USD, about 35.56 THB per USD.
final referenceUsd = RateQuote(
  base: 'THB',
  quote: 'USD',
  rate: 0.02812,
  date: '2026-10-15',
  fetchedAt: DateTime.utc(2026, 10, 15),
);

final String realRows = rowsFromLines(exchangeBoardRealIosLines);

void _expectRate(BoardRate? r, String code, double buying, double selling) {
  expect(r, isNotNull, reason: '$code row should be read');
  expect(r!.code, code);
  expect(r.buying, closeTo(buying, 1e-9));
  expect(r.selling, closeTo(selling, 1e-9));
}

void main() {
  group('BoardRate: demo USD row', () {
    late BoardRate usd;
    setUp(() => usd = readExchangeBoard(demoUsdRow, code: 'USD')!);

    test('buying 35.03, selling 36.10', () {
      _expectRate(usd, 'USD', 35.03, 36.10);
    });

    test('mid is 35.565', () {
      expect(usd.mid, closeTo(35.565, 1e-9));
    });

    test('selling dollars here gets about 1.5 % less than mid', () {
      expect(usd.sellLossPercent, closeTo(1.504, 0.001));
      expect(usd.sellLossPercent.toStringAsFixed(1), '1.5');
    });

    test('buying dollars here costs about 1.5 % more than mid', () {
      expect(usd.buyLossPercent, closeTo(1.504, 0.001));
    });

    test('selling 100 USD loses 53.50 THB against mid', () {
      expect(usd.lossWhenSelling(100), closeTo(53.5, 0.001));
    });

    test('loss scales with the amount', () {
      expect(usd.lossWhenSelling(0), closeTo(0, 1e-9));
      expect(usd.lossWhenSelling(250), closeTo(133.75, 0.001));
    });
  });

  group('readExchangeBoard: real iOS capture via rowsFromLines', () {
    test('USD 35.03 / 36.10; the T/C column "35.601" is ignored', () {
      _expectRate(
        readExchangeBoard(realRows, code: 'USD'),
        'USD',
        35.03,
        36.10,
      );
    });

    test('USD mid and loss match the demo numbers', () {
      final usd = readExchangeBoard(realRows, code: 'USD')!;
      expect(usd.mid, closeTo(35.565, 1e-9));
      expect(usd.sellLossPercent, closeTo(1.504, 0.001));
      expect(usd.lossWhenSelling(100), closeTo(53.5, 0.001));
    });

    test('EUR 45.72 / 46.86', () {
      _expectRate(
        readExchangeBoard(realRows, code: 'EUR'),
        'EUR',
        45.72,
        46.86,
      );
    });

    test('GBP 68.96 / 70.90', () {
      _expectRate(
        readExchangeBoard(realRows, code: 'GBP'),
        'GBP',
        68.96,
        70.90,
      );
    });

    test('JPY 0.2879 / 0.2971', () {
      _expectRate(
        readExchangeBoard(realRows, code: 'JPY'),
        'JPY',
        0.2879,
        0.2971,
      );
    });

    test('SGD with comma decimal "22,89" reads 22.89 / 23.50', () {
      _expectRate(
        readExchangeBoard(realRows, code: 'SGD'),
        'SGD',
        22.89,
        23.50,
      );
    });

    test('CHF with trailing "|" on "27.99|" reads 27.99 / 28.81', () {
      _expectRate(
        readExchangeBoard(realRows, code: 'CHF'),
        'CHF',
        27.99,
        28.81,
      );
    });

    test('SEK with trailing ")" on "4.89)" reads 4.89 / 5.19', () {
      _expectRate(readExchangeBoard(realRows, code: 'SEK'), 'SEK', 4.89, 5.19);
    });

    test('ZAR with comma decimal and trailing "|" reads 3.65 / 5.45', () {
      _expectRate(readExchangeBoard(realRows, code: 'ZAR'), 'ZAR', 3.65, 5.45);
    });

    test('NZD row (code read as "INZD", selling "2531") gives null', () {
      expect(readExchangeBoard(realRows, code: 'NZD'), isNull);
    });

    test('AUD selling misread "21.97" is below buying 27.08: null', () {
      expect(readExchangeBoard(realRows, code: 'AUD'), isNull);
    });

    test('NOK selling misread "576" (5.76) is too far from buying 5.43: '
        'null', () {
      expect(readExchangeBoard(realRows, code: 'NOK'), isNull);
    });

    test('AED buying misread "775" is above selling 10.20: null', () {
      expect(readExchangeBoard(realRows, code: 'AED'), isNull);
    });

    test('a code not on the board gives null', () {
      expect(readExchangeBoard(realRows, code: 'XAU'), isNull);
    });

    test('a garbled code is not matched by a partial token ("DR" is not '
        '"IDR")', () {
      expect(readExchangeBoard(realRows, code: 'IDR'), isNull);
    });
  });

  group('readExchangeBoard: synthetic rows', () {
    test('comma decimals "SGD 22,89 22.99 23,59" give 22.89 / 23.59', () {
      _expectRate(
        readExchangeBoard('SGD 22,89 22.99 23,59', code: 'SGD'),
        'SGD',
        22.89,
        23.59,
      );
    });

    test('a row with no T/C column (two numbers) still reads', () {
      _expectRate(
        readExchangeBoard('KRW 0.029 0.043', code: 'KRW'),
        'KRW',
        0.029,
        0.043,
      );
    });

    test('only the row with the code is used', () {
      _expectRate(
        readExchangeBoard(
          'EUR 45.72 45.97 46.86\nUSD 35.03 35.60 36.10',
          code: 'USD',
        ),
        'USD',
        35.03,
        36.10,
      );
    });

    test('missing-dot "2531" as selling gives null, never a guess', () {
      expect(readExchangeBoard('NZD 24.18 24.32 2531', code: 'NZD'), isNull);
    });

    test('buying above selling gives null', () {
      expect(readExchangeBoard('USD 36.10 35.03', code: 'USD'), isNull);
    });

    test('buying equal to selling gives null', () {
      expect(readExchangeBoard('USD 35.50 35.50', code: 'USD'), isNull);
    });

    test('only one number after the code gives null', () {
      expect(readExchangeBoard('USD 35.03', code: 'USD'), isNull);
    });

    test('no numbers after the code gives null', () {
      expect(readExchangeBoard('USD', code: 'USD'), isNull);
    });

    test('empty text gives null', () {
      expect(readExchangeBoard('', code: 'USD'), isNull);
    });

    test('a code inside a longer token does not match', () {
      expect(readExchangeBoard('XUSD 35.03 36.10', code: 'USD'), isNull);
    });
  });

  group('lossVsReferencePercent', () {
    test('demo USD buying 35.03 against 35.56 THB per USD: about 1.5 %', () {
      final usd = readExchangeBoard(demoUsdRow, code: 'USD')!;
      final loss = lossVsReferencePercent(usd, referenceUsd, home: 'THB');
      expect(loss, isNotNull);
      // reference mid = 1 / 0.02812 THB per USD.
      expect(loss!, closeTo((1 - 35.03 * 0.02812) * 100, 1e-9));
      expect(loss, closeTo(1.4956, 0.0001));
    });

    test('a different reference changes the result', () {
      final usd = readExchangeBoard(demoUsdRow, code: 'USD')!;
      final other = RateQuote(
        base: 'THB',
        quote: 'USD',
        rate: 0.0280,
        date: '2026-10-06',
        fetchedAt: DateTime.utc(2026, 10, 6),
      );
      expect(
        lossVsReferencePercent(usd, other, home: 'THB'),
        closeTo((1 - 35.03 * 0.0280) * 100, 1e-9),
      );
    });

    test('a reference for another currency gives null', () {
      final usd = readExchangeBoard(demoUsdRow, code: 'USD')!;
      final eur = RateQuote(
        base: 'THB',
        quote: 'EUR',
        rate: 0.0216,
        date: '2026-10-15',
        fetchedAt: DateTime.utc(2026, 10, 15),
      );
      expect(lossVsReferencePercent(usd, eur, home: 'THB'), isNull);
    });
  });

  group('lossVsReferencePercent: home currency', () {
    test('a reference whose base is not the board home gives null', () {
      final usd = readExchangeBoard(demoUsdRow, code: 'USD')!;
      final eurUsd = RateQuote(
        base: 'EUR',
        quote: 'USD',
        rate: 1.08,
        date: '2026-10-15',
        fetchedAt: DateTime.utc(2026, 10, 15),
      );
      expect(lossVsReferencePercent(usd, eurUsd, home: 'THB'), isNull);
    });

    test('a board home other than the reference base gives null', () {
      final usd = readExchangeBoard(demoUsdRow, code: 'USD')!;
      expect(lossVsReferencePercent(usd, referenceUsd, home: 'JPY'), isNull);
    });
  });

  group('readExchangeBoard: row boundaries', () {
    const twoOnOneLine = 'USD 35.03 35.60 36.10 EUR 45.72 46.86';

    test('numbers stop at the next code: USD 35.03 / 36.10', () {
      _expectRate(
        readExchangeBoard(twoOnOneLine, code: 'USD'),
        'USD',
        35.03,
        36.10,
      );
    });

    test('the code after it reads its own numbers: EUR 45.72 / 46.86', () {
      _expectRate(
        readExchangeBoard(twoOnOneLine, code: 'EUR'),
        'EUR',
        45.72,
        46.86,
      );
    });

    test('the code in two rows with different numbers gives null', () {
      expect(
        readExchangeBoard('USD 35.03 35.60 36.10\nUSD 99 100', code: 'USD'),
        isNull,
      );
    });

    test('the code in two rows with the same numbers reads', () {
      _expectRate(
        readExchangeBoard(
          'USD 35.03 35.60 36.10\nUSD 35.03 35.60 36.10',
          code: 'USD',
        ),
        'USD',
        35.03,
        36.10,
      );
    });
  });

  group('boardRatePlausible', () {
    test('demo USD row against 35.56 THB per USD is plausible', () {
      final usd = readExchangeBoard(demoUsdRow, code: 'USD')!;
      expect(boardRatePlausible(usd, referenceUsd, home: 'THB'), isTrue);
    });

    test('a misread board 3503 / 3610 is not plausible', () {
      final misread = readExchangeBoard('USD 3503 3610', code: 'USD');
      expect(misread, isNotNull);
      expect(boardRatePlausible(misread!, referenceUsd, home: 'THB'), isFalse);
    });

    test('a wrong pair (home JPY) is not plausible', () {
      final usd = readExchangeBoard(demoUsdRow, code: 'USD')!;
      expect(boardRatePlausible(usd, referenceUsd, home: 'JPY'), isFalse);
    });
  });

  group('readExchangeBoard: rows that mention the code without numbers', () {
    test('a later text row with the code is skipped', () {
      _expectRate(
        readExchangeBoard(
          'USD 35.03 36.10\nPrices for USD notes only',
          code: 'USD',
        ),
        'USD',
        35.03,
        36.10,
      );
    });

    test('an earlier text row with the code is skipped', () {
      _expectRate(
        readExchangeBoard('Rates per 1 USD\nUSD 35.03 36.10', code: 'USD'),
        'USD',
        35.03,
        36.10,
      );
    });

    test('a row with the code and an invalid pair still gives null', () {
      expect(
        readExchangeBoard('USD 35.03 36.10\nUSD 36.10 35.03', code: 'USD'),
        isNull,
      );
    });
  });
}
