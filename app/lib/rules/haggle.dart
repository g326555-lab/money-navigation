import 'thai_number.dart';

/// Currency of the market prices in the data file.
const marketCurrency = 'THB';

/// Highest price the manual entry accepts; above it a typo is likelier than
/// a real market price. Also bounds the digits a person can type.
const maxPriceThb = 999999.0;
const maxPriceChars = 9;

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

/// How far above the top of the usual range [asked] is, in percent of that
/// top ([high]); 0 when it is not above.
double percentOverUsual(double asked, double high) =>
    asked > high && high > 0 ? (asked - high) / high * 100 : 0;

/// The window a price scale shows around the usual range [low]–[high]: wide
/// enough for the usual range to read as a band, the asked price and any
/// past price on it, and capped so a wild price does not shrink the band to
/// a sliver. [farAbove] / [farBelow] say the asked price lies past the cap.
({double from, double to, bool farAbove, bool farBelow}) priceWindow({
  required double low,
  required double high,
  required double asked,
  double? lastPaid,
}) {
  final w = (high - low) > 0 ? high - low : high * priceWindowMinShare;
  final capHigh = high + w * priceWindowCap;
  final capLow = low - w * priceWindowCap;
  final farAbove = asked > capHigh;
  final farBelow = asked < capLow;
  var from = low - w * priceWindowPad;
  var to = high + w * priceWindowPad;
  for (final v in [asked, ?lastPaid]) {
    final clamped = v.clamp(capLow, capHigh);
    if (clamped + w * priceWindowEdge > to) {
      to = clamped + w * priceWindowEdge;
    }
    if (clamped - w * priceWindowEdge < from) {
      from = clamped - w * priceWindowEdge;
    }
  }
  if (from < 0) from = 0;
  return (from: from, to: to, farAbove: farAbove, farBelow: farBelow);
}

/// Window shape, in widths of the usual range.
const priceWindowPad = 0.6;
const priceWindowEdge = 0.15;
const priceWindowCap = 2.0;

/// For a one-price "range", the band is drawn this share of the price wide.
const priceWindowMinShare = 0.1;

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
