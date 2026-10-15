import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/haggle.dart';
import 'package:money_navigation/rules/haggle_rounds.dart';

/// Mango with the CLAUDE.md demo range (80-110 THB per kg). Test-only: the
/// app's real range comes from the sourced data file, never from this
/// constant. Declared here because the shared fixture's mango is 60-80.
const MarketItem _demoMango = MarketItem(
  key: 'mango',
  nameEn: 'Mango',
  nameTh: 'มะม่วง',
  keywordsTh: ['มะม่วง'],
  unit: PriceUnit.perKg,
  low: 80,
  high: 110,
);

/// The demo haggle after the first verdict: asked 150, we offered 110.
HaggleHistory _demoHistory() =>
    HaggleHistory(item: _demoMango, firstAsk: 150, firstOffer: 110);

/// Classifies [thai] and applies it, so each step reads like the demo.
NextMove _say(HaggleHistory history, String thai) =>
    history.respond(classifyReply(thai));

void _expectMove(NextMove move, MoveKind kind, double price) {
  expect(move.kind, kind);
  expect(move.price, price);
}

void main() {
  group('classifyReply: refusal without a number', () {
    for (final text in ['ไม่ได้', 'ลดไม่ได้', 'ไม่ลด']) {
      test('"$text" is refuse', () {
        final reply = classifyReply(text);
        expect(reply.kind, ReplyKind.refuse);
        expect(reply.amount, isNull);
      });
    }
  });

  group('classifyReply: acceptance', () {
    for (final text in ['ได้', 'โอเค', 'ตกลง', 'เอา']) {
      test('"$text" is accept', () {
        final reply = classifyReply(text);
        expect(reply.kind, ReplyKind.accept);
        expect(reply.amount, isNull);
      });
    }
  });

  group('classifyReply: counter with a new number', () {
    for (final text in ['130 ได้', 'ให้ 130', 'ร้อยสามสิบ', 'ร้อยสามสิบได้']) {
      test('"$text" is counter 130', () {
        final reply = classifyReply(text);
        expect(reply.kind, ReplyKind.counter);
        expect(reply.amount, 130);
      });
    }
  });

  group('classifyReply: refusal wins over a number, unrelated is unclear', () {
    test('"150 ลดไม่ได้" is refuse, not counter', () {
      expect(classifyReply('150 ลดไม่ได้').kind, ReplyKind.refuse);
    });

    for (final text in ['', '   ', 'สวัสดี']) {
      test('"$text" is unclear', () {
        expect(classifyReply(text).kind, ReplyKind.unclear);
      });
    }
  });

  group('HaggleHistory: starts from the first verdict', () {
    test('first offer equals judgePrice counter-offer for 150 (110)', () {
      const heard = HeardPrice(
        amount: 150,
        item: _demoMango,
        unit: PriceUnit.perKg,
      );
      expect(judgePrice(heard, _demoMango)!.counterOffer, 110);
    });

    test('sellerPrices [150], ourOffers [110]', () {
      final history = _demoHistory();
      expect(history.sellerPrices, [150]);
      expect(history.ourOffers, [110]);
      expect(history.sellerPrice, 150);
      expect(history.lastOffer, 110);
    });

    test('maxOffers is 3', () {
      expect(maxOffers, 3);
    });
  });

  group('Demo walk-through: counter, refuse, accept', () {
    test('"ร้อยสามสิบได้" -> offer 120, then "ไม่ได้" -> offer 125, '
        'then "โอเค" -> accept 125', () {
      final history = _demoHistory();

      _expectMove(_say(history, 'ร้อยสามสิบได้'), MoveKind.offer, 120);
      expect(history.sellerPrices, [150, 130]);
      expect(history.ourOffers, [110, 120]);

      _expectMove(_say(history, 'ไม่ได้'), MoveKind.offer, 125);
      expect(history.sellerPrices, [150, 130]);
      expect(history.ourOffers, [110, 120, 125]);

      _expectMove(_say(history, 'โอเค'), MoveKind.accept, 125);
    });

    test('"130 ได้" gives the same next offer 120', () {
      _expectMove(_say(_demoHistory(), '130 ได้'), MoveKind.offer, 120);
    });
  });

  group('Demo walk-through: three refusals end at the seller price', () {
    test('"ไม่ได้" -> 130, "ลดไม่ได้" -> 140, third refusal -> stop 150', () {
      final history = _demoHistory();

      _expectMove(_say(history, 'ไม่ได้'), MoveKind.offer, 130);
      _expectMove(_say(history, 'ลดไม่ได้'), MoveKind.offer, 140);
      expect(history.ourOffers, [110, 130, 140]);

      _expectMove(_say(history, 'ไม่ลด'), MoveKind.stop, 150);
      expect(history.ourOffers, [110, 130, 140]);
      expect(history.sellerPrice, 150);
    });
  });

  group('respond: accept', () {
    test('accept right after the first offer -> accept 110', () {
      _expectMove(_say(_demoHistory(), 'ได้'), MoveKind.accept, 110);
    });

    test('accept after a counter -> accept at our latest offer (120)', () {
      final history = _demoHistory();
      _say(history, '130 ได้');
      _expectMove(_say(history, 'ตกลง'), MoveKind.accept, 120);
    });
  });

  group('respond: counter at or below our offer, or inside the range', () {
    test('"100 ได้" after 110 -> accept 100', () {
      _expectMove(_say(_demoHistory(), '100 ได้'), MoveKind.accept, 100);
    });

    test('counter equal to our offer (110) -> accept 110', () {
      final move = _demoHistory().respond(
        const SellerReply(ReplyKind.counter, 110),
      );
      _expectMove(move, MoveKind.accept, 110);
    });

    test('"105" when high is 110 -> accept 105', () {
      _expectMove(_say(_demoHistory(), '105'), MoveKind.accept, 105);
    });

    test('counter at high after we offered above it -> accept at high', () {
      // Our offer 120 is above high 110; a counter of 110 is both <= our
      // offer and inside the usual range.
      final history = _demoHistory();
      _say(history, '130 ได้');
      _expectMove(
        history.respond(const SellerReply(ReplyKind.counter, 110)),
        MoveKind.accept,
        110,
      );
    });
  });

  group('respond: counter with no movement is a refusal', () {
    test('counter equal to the seller price (150) -> offer 130', () {
      final history = _demoHistory();
      final move = history.respond(const SellerReply(ReplyKind.counter, 150));
      _expectMove(move, MoveKind.offer, 130);
      expect(history.sellerPrices, [150]);
    });

    test(
      'counter above the seller price (160) -> offer 130, price stays 150',
      () {
        final history = _demoHistory();
        final move = history.respond(const SellerReply(ReplyKind.counter, 160));
        _expectMove(move, MoveKind.offer, 130);
        expect(history.sellerPrice, 150);
      },
    );
  });

  group('respond: next offer rounding and gaps', () {
    test(
      'midpoint rounds DOWN to 5: counter 145 -> mid 127.5 -> offer 125',
      () {
        final move = _demoHistory().respond(
          const SellerReply(ReplyKind.counter, 145),
        );
        _expectMove(move, MoveKind.offer, 125);
      },
    );

    test('no price strictly between offer and seller -> stop at seller', () {
      // 110 -> counter 130 -> offer 120; counter 125: mid 122.5 floors to
      // 120, which is not above our 120.
      final history = _demoHistory();
      _say(history, '130 ได้');
      final move = history.respond(const SellerReply(ReplyKind.counter, 125));
      _expectMove(move, MoveKind.stop, 125);
      expect(history.sellerPrice, 125);
      expect(history.ourOffers, [110, 120]);
    });

    test('counters keep lowering the seller price used for the midpoint', () {
      final history = _demoHistory();
      _expectMove(
        history.respond(const SellerReply(ReplyKind.counter, 140)),
        MoveKind.offer,
        125,
      );
      _expectMove(
        history.respond(const SellerReply(ReplyKind.counter, 135)),
        MoveKind.offer,
        130,
      );
      expect(history.sellerPrices, [150, 140, 135]);
      expect(history.ourOffers, [110, 125, 130]);
    });

    test('counter after maxOffers reached -> stop at the new seller price', () {
      final history = _demoHistory();
      _say(history, 'ไม่ได้'); // 130
      _say(history, 'ไม่ได้'); // 140
      final move = history.respond(const SellerReply(ReplyKind.counter, 145));
      _expectMove(move, MoveKind.stop, 145);
      expect(history.ourOffers.length, maxOffers);
    });
  });

  group('respond: unclear asks the same again without recording', () {
    for (final text in ['', 'สวัสดี']) {
      test('"$text" -> offer 110, history unchanged', () {
        final history = _demoHistory();
        _expectMove(_say(history, text), MoveKind.offer, 110);
        expect(history.sellerPrices, [150]);
        expect(history.ourOffers, [110]);
      });
    }

    test('unclear does not use up an offer', () {
      final history = _demoHistory();
      _say(history, 'ไม่ได้'); // 130
      _say(history, 'สวัสดี');
      _say(history, '');
      _expectMove(_say(history, 'ไม่ได้'), MoveKind.offer, 140);
      expect(history.ourOffers, [110, 130, 140]);
    });
  });
}
