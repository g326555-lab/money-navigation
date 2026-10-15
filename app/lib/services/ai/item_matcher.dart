// On-device item recognition for haggling. The Thai speech recognizer gets
// amounts and units right but often mishears item names, so this matches
// every recognizer alternative against the items we have sourced prices
// for: exact keywords first, then real logged mishearings, then Thai
// sound-alike similarity. It runs offline in well under a millisecond and
// returns null instead of guessing when nothing is close enough.
import '../../rules/haggle.dart';

/// Below this confidence the item is reported as unknown.
const itemMatchThreshold = 0.6;

/// Confidence of a match through a logged mishearing.
const heardAsConfidence = 0.9;

/// Sound-alike similarity is scaled down so it never outranks an alias.
const soundAlikeWeight = 0.8;

enum MatchReason { keyword, heardAs, soundAlike }

class ItemMatch {
  const ItemMatch({
    required this.item,
    required this.confidence,
    required this.reason,
  });

  final MarketItem item;
  final double confidence;
  final MatchReason reason;
}

/// Picks the item named in any of the recognizer's [alternatives] (best
/// first). [heardAs] maps an item key to transcripts it was really heard
/// as. When [unit] is given, items sold in another unit are skipped.
ItemMatch? matchItem(
  List<String> alternatives,
  List<MarketItem> items, {
  Map<String, List<String>> heardAs = const {},
  PriceUnit? unit,
}) {
  ItemMatch? best;
  var bestKeywordLength = 0;
  for (final text in alternatives) {
    if (text.trim().isEmpty) continue;
    final skeleton = thaiSkeleton(text);
    for (final item in items) {
      if (unit != null && item.unit != unit) continue;

      // Exact keyword; the longest keyword wins ties.
      for (final keyword in item.keywordsTh) {
        if (!text.contains(keyword)) continue;
        if (best == null ||
            best.confidence < 1 ||
            keyword.length > bestKeywordLength) {
          best = ItemMatch(
            item: item,
            confidence: 1,
            reason: MatchReason.keyword,
          );
          bestKeywordLength = keyword.length;
        }
      }

      for (final alias in heardAs[item.key] ?? const <String>[]) {
        if (alias.isNotEmpty &&
            text.contains(alias) &&
            heardAsConfidence > (best?.confidence ?? 0)) {
          best = ItemMatch(
            item: item,
            confidence: heardAsConfidence,
            reason: MatchReason.heardAs,
          );
        }
      }

      for (final keyword in item.keywordsTh) {
        final score =
            soundAlikeWeight *
            _windowSimilarity(skeleton, thaiSkeleton(keyword));
        if (score > (best?.confidence ?? 0)) {
          best = ItemMatch(
            item: item,
            confidence: score,
            reason: MatchReason.soundAlike,
          );
        }
      }
    }
  }
  if (best == null || best.confidence < itemMatchThreshold) return null;
  return best;
}

/// Thai consonants reduced to sound-alike groups, with tone marks, vowel
/// signs and anything non-Thai removed: "ผัดไทย" and "พัดไทย" both become
/// P-D-T-Y.
List<String> thaiSkeleton(String text) => [
  for (final rune in text.runes) ?_soundGroup[String.fromCharCode(rune)],
];

const _groups = <String, String>{
  'กขฃคฅฆ': 'K',
  'ง': 'NG',
  'จฉชฌ': 'CH',
  'ซศษส': 'S',
  'ญย': 'Y',
  'ดฎ': 'D',
  'ตฏ': 'TT',
  'ถฐทธฑฒ': 'T',
  'นณ': 'N',
  'บ': 'B',
  'ป': 'PP',
  'ผพภ': 'P',
  'ฝฟ': 'F',
  'ม': 'M',
  'รลฬ': 'R',
  'ว': 'W',
  'หฮ': 'H',
  'อ': 'O',
};

final Map<String, String> _soundGroup = {
  for (final entry in _groups.entries)
    for (final c in entry.key.split('')) c: entry.value,
};

/// Best similarity (0..1) between [word] and any equally long stretch of
/// [text]; the whole text when it is shorter than the word.
double _windowSimilarity(List<String> text, List<String> word) {
  if (word.isEmpty || text.isEmpty) return 0;
  if (text.length <= word.length) return _similarity(text, word);
  var best = 0.0;
  for (var i = 0; i + word.length <= text.length; i++) {
    final s = _similarity(text.sublist(i, i + word.length), word);
    if (s > best) best = s;
  }
  return best;
}

double _similarity(List<String> a, List<String> b) {
  final longest = a.length > b.length ? a.length : b.length;
  return 1 - _editDistance(a, b) / longest;
}

int _editDistance(List<String> a, List<String> b) {
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      current[j] = [
        previous[j] + 1,
        current[j - 1] + 1,
        previous[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    previous = current;
  }
  return previous[b.length];
}
