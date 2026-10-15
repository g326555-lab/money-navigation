import 'thai_number.dart';

/// Currency of the market prices in the data file.
const marketCurrency = 'THB';

enum PriceUnit { each, perKg, perPlate, perHour, perRide }

/// An item with its usual price range. Real ranges come from the sourced
/// data file in assets/data/, never from code.
class MarketItem {
  const MarketItem({
    required this.key,
    required this.nameEn,
    required this.nameTh,
    required this.keywordsTh,
    required this.unit,
    required this.low,
    required this.high,
  });

  final String key;
  final String nameEn;
  final String nameTh;
  final List<String> keywordsTh;
  final PriceUnit unit;
  final double low;
  final double high;
}

/// What was understood from the seller's sentence.
class HeardPrice {
  const HeardPrice({required this.amount, this.item, this.unit});

  final double amount;

  /// The item named in the sentence, if it is one we know.
  final MarketItem? item;

  /// The unit said in the sentence, if any.
  final PriceUnit? unit;
}

enum PriceVerdict { low, fair, high }

class HaggleVerdict {
  const HaggleVerdict({
    required this.verdict,
    required this.overBy,
    this.counterOffer,
  });

  final PriceVerdict verdict;

  /// How far the asked price is above the usual high end; 0 otherwise.
  final double overBy;

  /// A price to ask for instead, only when the asked price is high.
  final double? counterOffer;
}

/// Unit words, longest first so "กิโล" wins over "โล".
const _unitWords = <String, PriceUnit>{
  'ชั่วโมง': PriceUnit.perHour,
  'เที่ยว': PriceUnit.perRide,
  'กิโล': PriceUnit.perKg,
  'กล่อง': PriceUnit.perPlate,
  'แก้ว': PriceUnit.each,
  'ชม.': PriceUnit.perHour,
  'กก.': PriceUnit.perKg,
  'ลูก': PriceUnit.each,
  'ชิ้น': PriceUnit.each,
  'ผืน': PriceUnit.each,
  'จาน': PriceUnit.perPlate,
  'อัน': PriceUnit.each,
  'ตัว': PriceUnit.each,
  'โล': PriceUnit.perKg,
};

/// Understands a seller's sentence. Returns null when it holds no amount.
HeardPrice? parseHeardPrice(String thaiText, List<MarketItem> items) {
  final amount = findAmount(thaiText);
  if (amount == null) return null;

  MarketItem? item;
  var longest = 0;
  for (final candidate in items) {
    for (final keyword in candidate.keywordsTh) {
      if (keyword.length > longest && thaiText.contains(keyword)) {
        item = candidate;
        longest = keyword.length;
      }
    }
  }

  PriceUnit? unit;
  for (final entry in _unitWords.entries) {
    if (thaiText.contains(entry.key)) {
      unit = entry.value;
      break;
    }
  }
  return HeardPrice(amount: amount, item: item, unit: unit);
}

/// Steps counter-offers land on, in baht.
const counterOfferStep = 5;

/// Judges the asked price against the item's usual range. Returns null when
/// the heard unit differs from the range's unit, because they can't be
/// compared.
HaggleVerdict? judgePrice(HeardPrice heard, MarketItem item) {
  if (heard.unit != null && heard.unit != item.unit) return null;
  final amount = heard.amount;
  if (amount > item.high) {
    final offer = (item.high / counterOfferStep).floor() * counterOfferStep;
    return HaggleVerdict(
      verdict: PriceVerdict.high,
      overBy: amount - item.high,
      counterOffer: offer < amount ? offer.toDouble() : null,
    );
  }
  return HaggleVerdict(
    verdict: amount < item.low ? PriceVerdict.low : PriceVerdict.fair,
    overBy: 0,
  );
}
