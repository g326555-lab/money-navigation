import 'package:flutter/services.dart';

import '../rules/card_catalog.dart';

/// The bundled card catalogue, read once per run. Empty when the file is
/// missing or unreadable, so the screens fall back to typed-in fees.
class CardCatalogRepository {
  CardCatalogRepository({this._bundle});

  final AssetBundle? _bundle;
  static List<CatalogCard>? _cache;

  Future<List<CatalogCard>> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final text = await (_bundle ?? rootBundle).loadString(cardCatalogAsset);
      return _cache = parseCardCatalog(text) ?? const [];
    } on Object {
      return const [];
    }
  }

  /// The card with [id], when it is in the catalogue.
  Future<CatalogCard?> byId(String? id) async {
    if (id == null) return null;
    for (final c in await load()) {
      if (c.id == id) return c;
    }
    return null;
  }
}
