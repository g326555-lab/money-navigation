import 'dart:convert';
import 'dart:typed_data';

import '../../rules/bill_check.dart';
import '../../rules/ocr_layout.dart';
import '../../rules/receipt_record.dart';
import 'ai_trace.dart';
import 'cloud_functions.dart';

/// Reads a photographed Thai bill. Thai script is beyond on-device OCR, so
/// Google Cloud Vision reads the lines (function `read-text`), then the phone
/// straightens them and verifies the figures by arithmetic
/// (`lib/rules/bill_check.dart`). The photo is not stored anywhere.
class BillReader {
  BillReader({CloudFunctions? functions})
    : _functions = functions ?? CloudFunctions();

  final CloudFunctions _functions;

  /// Generous for a slow mobile upload; the trace shows the real wait.
  static const timeout = Duration(seconds: 10);

  /// The read-text function rejects images above about 4 MB. Pick photos
  /// with `maxWidth: 2000, imageQuality: 85` to stay well under it.
  static const maxBytes = 4 * 1024 * 1024;

  Future<BillReading> read(Uint8List jpeg) async {
    if (jpeg.length > maxBytes) {
      return const BillReading.failed(BillFailure.tooLarge);
    }
    final Map<String, dynamic> vision;
    final AiTrace visionTrace;
    try {
      final body = {'imageBase64': base64Encode(jpeg)};
      final measured = await AiTrace.measure(
        AiEngine.cloudVision,
        () async {
          try {
            return await _functions.call('read-text', body, timeout: timeout);
          } on CloudFunctionError catch (e) {
            // A momentary server error (seen 3 times in 80 real photos,
            // each fine on resend) is tried once more. A timeout on either
            // side, no connection or a rejected request is not.
            final status = int.tryParse(e.reason.split(':').first);
            if (status == null || status < 500 || status == 504) rethrow;
            return _functions.call('read-text', body, timeout: timeout);
          }
        },
        count: (json) =>
            json['lines'] is List ? (json['lines'] as List).length : null,
      );
      vision = measured.$1;
      visionTrace = measured.$2;
    } on CloudFunctionError catch (e) {
      return BillReading.failed(switch (e.reason) {
        'timeout' => BillFailure.timeout,
        final r when r.startsWith('offline') => BillFailure.offline,
        _ => BillFailure.service,
      });
    }
    final lines = vision['lines'];
    if (lines is! List || lines.isEmpty) {
      return BillReading.failed(BillFailure.noText, traces: [visionTrace]);
    }
    final (check, checkTrace) = AiTrace.measureSync(
      AiEngine.onDevice,
      () => checkBillFromVision(vision),
    );
    final traces = [visionTrace, checkTrace];
    final merchant = merchantFromRows(_rows(lines));
    if (check == null) {
      return BillReading.failed(
        BillFailure.doesNotAddUp,
        traces: traces,
        merchantName: merchant,
      );
    }
    return BillReading(check: check, traces: traces, merchantName: merchant);
  }
}

/// The receipt's rows as printed, from Vision lines with corners.
List<String> _rows(List<dynamic> lines) => rowsFromLines(
  straightenLines([
    for (final l in lines)
      if (l is Map && l['text'] is String && l['corners'] is List)
        OcrQuad(
          text: l['text'] as String,
          corners: [
            for (final c in l['corners'] as List)
              if (c is List && c.length >= 2 && c[0] is num && c[1] is num)
                ((c[0] as num).toDouble(), (c[1] as num).toDouble()),
          ],
        ),
  ]),
).split('\n');

enum BillFailure {
  /// No connection.
  offline,

  /// Connected, but Vision did not answer within [BillReader.timeout].
  timeout,

  /// The function answered with an error.
  service,

  /// The photo is above [BillReader.maxBytes].
  tooLarge,

  /// Vision found no text in the photo.
  noText,

  /// Text was read but no set of amounts balances; nothing is guessed.
  doesNotAddUp,
}

class BillReading {
  const BillReading({
    required BillCheck this.check,
    required this.traces,
    this.merchantName,
  }) : failure = null;

  const BillReading.failed(
    BillFailure this.failure, {
    this.traces = const [],
    this.merchantName,
  }) : check = null;

  /// The shop name printed at the top, when one was read
  /// ([merchantFromRows]); null otherwise.
  final String? merchantName;

  final BillCheck? check;
  final BillFailure? failure;

  /// Cloud Vision (count = lines read; time includes encoding and upload,
  /// i.e. what the user waited), then the on-device check.
  final List<AiTrace> traces;
}
