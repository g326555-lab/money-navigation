import 'dart:convert';

/// Everyday things with no sourced usual price: offered by name on the
/// haggle screen, their price is looked up online when chosen.
const quickItemsAsset = 'assets/data/quick_items.json';

class QuickItem {
  const QuickItem({required this.en, required this.th});

  final String en;
  final String th;
}

/// The names in [json]; entries without both names are skipped. Empty when
/// the file is not readable.
List<QuickItem> parseQuickItems(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return const [];
  }
  if (decoded is! Map || decoded['items'] is! List) return const [];
  return [
    for (final i in decoded['items'] as List)
      if (i is Map &&
          i['en'] is String &&
          i['th'] is String &&
          (i['en'] as String).trim().isNotEmpty &&
          (i['th'] as String).trim().isNotEmpty)
        QuickItem(
          en: (i['en'] as String).trim(),
          th: (i['th'] as String).trim(),
        ),
  ];
}
