import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../data/market_price_repository.dart';
import '../../rules/haggle.dart';
import 'item_matcher.dart';

/// On-device AI step of haggling: names the item when speech recognition
/// misheard it, using the recognizer's alternatives, the sourced item list
/// and the mishearings logged in the data file. No network, no guessing.
class ItemResolver {
  Map<String, List<String>>? _heardAs;

  Future<Map<String, List<String>>> _aliases() async {
    final cached = _heardAs;
    if (cached != null) return cached;
    final raw = jsonDecode(
      await rootBundle.loadString(MarketPriceRepository.assetPath),
    ) as Map<String, dynamic>;
    return _heardAs = {
      for (final e in raw['items'] as List<dynamic>)
        if ((e as Map<String, dynamic>)['heardAsTh'] is List)
          e['key'] as String: [
            for (final a in e['heardAsTh'] as List) a as String,
          ],
    };
  }

  /// The item in [alternatives] (recognizer transcripts, best first), or
  /// null when no item is close enough. [unit] narrows the choice when the
  /// seller said one ("กิโลละ").
  Future<ItemMatch?> resolve(
    List<String> alternatives,
    List<SourcedItem> items, {
    PriceUnit? unit,
  }) async => matchItem(
    alternatives,
    [for (final s in items) s.item],
    heardAs: await _aliases(),
    unit: unit,
  );
}
