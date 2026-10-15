/// One line of recognized text with its bounding box in image pixels.
///
/// A plain value type so layout logic stays free of plugin and Flutter types.
class OcrLine {
  const OcrLine({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get height => bottom - top;
}

/// Minimum vertical overlap, as a share of the smaller line height, for two
/// lines to count as the same visual row. Tolerates a slightly tilted photo
/// (labels sat up to 28 px lower than their values on a 40 px line, 45 %
/// overlap). Neighbouring rows on the ATM screen do not overlap at all.
const rowOverlapThreshold = 0.3;

/// Rebuilds visual rows from OCR lines.
///
/// OCR returns screen columns as separate blocks, so a label and its values
/// are far apart in the raw text. Grouping by vertical overlap puts each
/// label back on one line with its values: "Amount charged 4.220 THB 144.71 USD".
String rowsFromLines(List<OcrLine> lines) {
  final sorted = [...lines]..sort((a, b) => a.top.compareTo(b.top));
  final rows = <List<OcrLine>>[];
  for (final line in sorted) {
    List<OcrLine>? best;
    var bestOverlap = rowOverlapThreshold;
    for (final row in rows) {
      final overlap = _overlapRatio(row.first, line);
      if (overlap >= bestOverlap) {
        best = row;
        bestOverlap = overlap;
      }
    }
    if (best == null) {
      rows.add([line]);
    } else {
      best.add(line);
    }
  }
  return rows
      .map((row) {
        row.sort((a, b) => a.left.compareTo(b.left));
        return row.map((l) => l.text.trim()).join(' ');
      })
      .join('\n');
}

double _overlapRatio(OcrLine a, OcrLine b) {
  final overlap =
      (a.bottom < b.bottom ? a.bottom : b.bottom) -
      (a.top > b.top ? a.top : b.top);
  final smaller = a.height < b.height ? a.height : b.height;
  if (overlap <= 0 || smaller <= 0) return 0;
  return overlap / smaller;
}
