// An item the seller named that is not in our sourced price list ("vanilla
// latte"). The list is open, but a new item may only be a name that is
// literally in what was heard: a model may propose it, this check decides.
import 'haggle.dart';

enum ItemCategory { food, drink, transport, service, goods, other }

/// An item taken from the seller's own words, without a sourced price range.
class NewItem {
  const NewItem({
    required this.nameTh,
    required this.nameEn,
    required this.unit,
    required this.category,
  });

  final String nameTh;
  final String nameEn;
  final PriceUnit unit;
  final ItemCategory category;

  String get key => 'new:${nameTh.replaceAll(RegExp(r'\s+'), '')}';
}

const _minNameLength = 2;
const _maxNameLength = 40;

final _thaiLetter = RegExp('[ก-ฮ]');
final _digit = RegExp(r'[0-9๐-๙]');
final _latinName = RegExp(r"^[A-Za-z][A-Za-z \-']{0,39}$");

/// The proposed item when every check passes, otherwise null:
/// - [nameTh] (spaces ignored) appears in at least one of [transcripts];
/// - it is 2-40 characters, has a Thai letter, no digit, no บาท, and does
///   not end with the price word ละ (กิโลละ, แก้วละ are units, not names);
/// - [nameEn] is plain Latin words;
/// - [unit] names a [PriceUnit] that agrees with [heardUnit] when known.
NewItem? acceptNewItem({
  required String nameTh,
  required String nameEn,
  required String unit,
  required String category,
  required List<String> transcripts,
  PriceUnit? heardUnit,
}) {
  final name = nameTh.replaceAll(RegExp(r'\s+'), '');
  if (name.length < _minNameLength || name.length > _maxNameLength) {
    return null;
  }
  if (!_thaiLetter.hasMatch(name) || _digit.hasMatch(name)) return null;
  if (name.contains('บาท') || name.endsWith('ละ')) return null;
  final heard = transcripts.any(
    (t) => t.replaceAll(RegExp(r'\s+'), '').contains(name),
  );
  if (!heard) return null;
  final english = nameEn.trim();
  if (!_latinName.hasMatch(english)) return null;
  final priceUnit = PriceUnit.values.asNameMap()[unit];
  if (priceUnit == null) return null;
  if (heardUnit != null && priceUnit != heardUnit) return null;
  return NewItem(
    nameTh: name,
    nameEn: english,
    unit: priceUnit,
    category: ItemCategory.values.asNameMap()[category] ?? ItemCategory.other,
  );
}
