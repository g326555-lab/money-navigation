// Market item fixtures for demo scene 2 (voice haggling) unit tests.
//
// These ranges exist only to exercise the parsing and verdict rules. They are
// NOT the app's price data: the real usual ranges come from the app's sourced
// data file (with source and date), never from these fixtures.

import 'package:money_navigation/rules/haggle.dart';

const MarketItem mangoFixture = MarketItem(
  key: 'mango',
  nameEn: 'Mango',
  nameTh: 'มะม่วง',
  keywordsTh: ['มะม่วง'],
  unit: PriceUnit.perKg,
  low: 60,
  high: 80,
);

/// Second item with a different unit and range, so nothing can be
/// mango-specific.
const MarketItem coconutFixture = MarketItem(
  key: 'coconut',
  nameEn: 'Coconut',
  nameTh: 'มะพร้าว',
  keywordsTh: ['มะพร้าว'],
  unit: PriceUnit.each,
  low: 40,
  high: 60,
);

/// Short keyword that is a prefix of [friedRiceFixture]'s keyword, to prove
/// the longest keyword match wins.
const MarketItem riceFixture = MarketItem(
  key: 'rice',
  nameEn: 'Rice',
  nameTh: 'ข้าว',
  keywordsTh: ['ข้าว'],
  unit: PriceUnit.perKg,
  low: 30,
  high: 50,
);

const MarketItem friedRiceFixture = MarketItem(
  key: 'fried_rice',
  nameEn: 'Fried rice',
  nameTh: 'ข้าวผัด',
  keywordsTh: ['ข้าวผัด'],
  unit: PriceUnit.perPlate,
  low: 50,
  high: 70,
);

/// High bound that is not a multiple of 5, for counter-offer rounding.
const MarketItem oddHighFixture = MarketItem(
  key: 'odd_high',
  nameEn: 'Odd high',
  nameTh: 'ลำไย',
  keywordsTh: ['ลำไย'],
  unit: PriceUnit.perKg,
  low: 70,
  high: 83,
);

/// Keyword contains [mangoFixture]'s keyword, so the longest match must pick
/// this item for "ข้าวเหนียวมะม่วง".
const MarketItem mangoStickyRiceFixture = MarketItem(
  key: 'mango_sticky_rice',
  nameEn: 'Mango sticky rice',
  nameTh: 'ข้าวเหนียวมะม่วง',
  keywordsTh: ['ข้าวเหนียวมะม่วง'],
  unit: PriceUnit.perPlate,
  low: 80,
  high: 120,
);

const List<MarketItem> mangoOnly = [mangoFixture];

const List<MarketItem> allFixtureItems = [
  mangoFixture,
  coconutFixture,
  riceFixture,
  friedRiceFixture,
  oddHighFixture,
  mangoStickyRiceFixture,
];
