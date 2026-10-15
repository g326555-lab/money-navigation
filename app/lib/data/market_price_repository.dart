import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../rules/haggle.dart';

/// Where a usual price range comes from.
class PriceSource {
  const PriceSource({
    required this.title,
    required this.url,
    required this.date,
  });

  final String title;
  final String url;

  /// Publication or access date, as written in the data file (YYYY-MM-DD).
  final String date;
}

/// A market item together with the sources behind its range.
class SourcedItem {
  const SourcedItem({required this.item, required this.sources});

  final MarketItem item;
  final List<PriceSource> sources;
}

/// Usual market prices, loaded from the sourced data file
/// `assets/data/market_prices.json`. The file is the only place ranges live.
class MarketPriceRepository {
  static const assetPath = 'assets/data/market_prices.json';

  List<SourcedItem>? _cache;

  Future<List<SourcedItem>> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = jsonDecode(
      await rootBundle.loadString(assetPath),
    ) as Map<String, dynamic>;
    final items = [
      for (final e in raw['items'] as List<dynamic>)
        _parse(e as Map<String, dynamic>),
    ];
    return _cache = items;
  }

  static SourcedItem _parse(Map<String, dynamic> json) => SourcedItem(
    item: MarketItem(
      key: json['key'] as String,
      nameEn: json['nameEn'] as String,
      nameTh: json['nameTh'] as String,
      keywordsTh: [for (final k in json['keywordsTh'] as List) k as String],
      unit: PriceUnit.values.byName(json['unit'] as String),
      low: (json['low'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
    ),
    sources: [
      for (final s in json['sources'] as List)
        PriceSource(
          title: (s as Map<String, dynamic>)['title'] as String,
          url: s['url'] as String,
          date: s['date'] as String,
        ),
    ],
  );
}
