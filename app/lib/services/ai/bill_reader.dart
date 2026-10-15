import 'dart:convert';
import 'dart:typed_data';

import '../../rules/bill_check.dart';
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
            // A server error is usually momentary (seen 3 times in 80 real
            // photos, each fine on resend): try once more. No connection
            // or a timeout is not retried.
            if (e.reason == 'timeout' || e.reason.startsWith('offline')) {
              rethrow;
            }
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
    if (check == null) {
      return BillReading.failed(BillFailure.doesNotAddUp, traces: traces);
    }
    return BillReading(check: check, traces: traces);
  }
}

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
  const BillReading({required BillCheck this.check, required this.traces})
    : failure = null;

  const BillReading.failed(BillFailure this.failure, {this.traces = const []})
    : check = null;

  final BillCheck? check;
  final BillFailure? failure;

  /// Cloud Vision (count = lines read; time includes encoding and upload,
  /// i.e. what the user waited), then the on-device check.
  final List<AiTrace> traces;
}
