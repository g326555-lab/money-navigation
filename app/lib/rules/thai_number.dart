/// Reads amounts from Thai speech-recognition text: Arabic digits, Thai
/// digits and Thai number words ("ร้อยห้าสิบ" = 150).
library;

const _digitWords = {
  'ศูนย์': 0,
  'หนึ่ง': 1,
  'นึง': 1,
  'เอ็ด': 1,
  'สอง': 2,
  'ยี่': 2,
  'สาม': 3,
  'สี่': 4,
  'ห้า': 5,
  'หก': 6,
  'เจ็ด': 7,
  'แปด': 8,
  'เก้า': 9,
};

const _multiplierWords = {
  'สิบ': 10,
  'ร้อย': 100,
  'พัน': 1000,
  'หมื่น': 10000,
  'แสน': 100000,
  'ล้าน': 1000000,
};

/// Every number word, longest first so "หนึ่ง" never matches as a prefix
/// of something longer by accident.
final _numberWords = [..._digitWords.keys, ..._multiplierWords.keys]
  ..sort((a, b) => b.length.compareTo(a.length));

const _thaiDigits = '๐๑๒๓๔๕๖๗๘๙';

/// Converts a run of Thai number words to an integer. Returns null when the
/// text is not made only of number words (spaces allowed).
int? parseThaiNumberWords(String text) {
  final compact = text.replaceAll(RegExp(r'\s+'), '');
  if (compact.isEmpty) return null;
  final tokens = <String>[];
  var i = 0;
  while (i < compact.length) {
    final word = _numberWords.where((w) => compact.startsWith(w, i));
    if (word.isEmpty) return null;
    tokens.add(word.first);
    i += word.first.length;
  }
  return _valueOf(tokens);
}

/// Values the number words. Market sellers shorten numbers: a single digit
/// word right after ร้อย/พัน/หมื่น/แสน means that digit of the next lower
/// place ("ร้อยห้า" = 150, "พันห้า" = 1500). "นึง" after a multiplier only
/// confirms "one" of it ("ร้อยนึง" = 100), and "เอ็ด" keeps its literal
/// meaning ("ร้อยเอ็ด" = 101).
int _valueOf(List<String> tokens) {
  var total = 0;
  var millions = 0;
  var pending = 0;
  String? pendingWord;
  int? lastMultiplier;
  for (final token in tokens) {
    final digit = _digitWords[token];
    if (digit != null) {
      pending = digit;
      pendingWord = token;
      continue;
    }
    final multiplier = _multiplierWords[token]!;
    if (multiplier == 1000000) {
      millions += total + (pending == 0 ? 1 : pending);
      total = 0;
    } else {
      total += (pending == 0 ? 1 : pending) * multiplier;
    }
    pending = 0;
    pendingWord = null;
    lastMultiplier = multiplier;
  }
  if (pendingWord != null && lastMultiplier != null && lastMultiplier >= 100) {
    if (pendingWord == 'นึง') {
      pending = 0;
    } else if (pendingWord != 'เอ็ด') {
      pending *= lastMultiplier ~/ 10;
    }
  }
  return millions * 1000000 + total + pending;
}

/// One number found in a sentence, with its position.
class _NumberRun {
  const _NumberRun(this.start, this.end, this.value);

  final int start;
  final int end;
  final double value;
}

List<_NumberRun> _numberRuns(String text) {
  final runs = <_NumberRun>[];
  // Arabic and Thai digits, with optional thousands commas and decimals.
  final digits = RegExp('[0-9$_thaiDigits][0-9$_thaiDigits,]*(?:\\.[0-9]+)?');
  for (final m in digits.allMatches(text)) {
    final western = m
        .group(0)!
        .split('')
        .map((c) {
          final thai = _thaiDigits.indexOf(c);
          return thai >= 0 ? '$thai' : c;
        })
        .join()
        .replaceAll(',', '');
    final value = double.tryParse(western);
    if (value != null) runs.add(_NumberRun(m.start, m.end, value));
  }
  // Runs of number words.
  var i = 0;
  while (i < text.length) {
    final start = i;
    final tokens = <String>[];
    while (i < text.length) {
      final word = _numberWords.where((w) => text.startsWith(w, i));
      if (word.isEmpty) break;
      tokens.add(word.first);
      i += word.first.length;
    }
    if (tokens.isNotEmpty) {
      runs.add(_NumberRun(start, i, _valueOf(tokens).toDouble()));
    } else {
      i++;
    }
  }
  runs.sort((a, b) => a.start.compareTo(b.start));
  return runs;
}

/// The price in a spoken sentence. When the sentence says "ละ" (per), the
/// price is the first number after it ("กิโลละ 150"); otherwise it is the
/// last number ("มะม่วง 2 กิโล 250 บาท"). Returns null when there is none.
double? findAmount(String text) {
  final runs = _numberRuns(text);
  if (runs.isEmpty) return null;
  final per = text.indexOf('ละ');
  if (per >= 0) {
    for (final run in runs) {
      if (run.start >= per) return run.value;
    }
  }
  return runs.last.value;
}
