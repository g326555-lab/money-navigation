/// The licensed photos the on-device photo-kind model was trained on,
/// listed in assets/models/photo_kind_sources.csv. CC BY and CC BY-SA
/// require the author and licence to be credited, so Settings shows them.
const photoCreditsAsset = 'assets/models/photo_kind_sources.csv';

class PhotoCredit {
  const PhotoCredit({
    required this.title,
    required this.source,
    required this.license,
    required this.author,
  });

  final String title;
  final String source;
  final String license;
  final String author;
}

/// Every row of the credits file, in file order. Null when the header is
/// not the expected one or a row cannot be read, so no credit is ever
/// shown half-filled.
List<PhotoCredit>? parsePhotoCredits(String csv) {
  final rows = _csvRows(csv);
  if (rows == null || rows.isEmpty) return null;
  final header = rows.first;
  final title = header.indexOf('title');
  final source = header.indexOf('source');
  final license = header.indexOf('license');
  final author = header.indexOf('author');
  if ([title, source, license, author].contains(-1)) return null;
  final credits = <PhotoCredit>[];
  for (final row in rows.skip(1)) {
    if (row.length == 1 && row.first.isEmpty) continue;
    if (row.length != header.length) return null;
    final credit = PhotoCredit(
      title: row[title].replaceFirst('File:', '').trim(),
      source: row[source].trim(),
      license: row[license].trim(),
      author: row[author].trim(),
    );
    if (credit.title.isEmpty || credit.license.isEmpty) return null;
    credits.add(credit);
  }
  return credits;
}

/// RFC 4180 rows: commas inside double quotes, "" for a quote. Null on an
/// unclosed quote.
List<List<String>>? _csvRows(String csv) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < csv.length; i++) {
    final c = csv[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < csv.length && csv[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      row.add(field.toString());
      field.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < csv.length && csv[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
    } else {
      field.write(c);
    }
  }
  if (quoted) return null;
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}
