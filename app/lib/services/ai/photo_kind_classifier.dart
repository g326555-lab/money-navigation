import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import 'ai_trace.dart';

/// What a photo shows, as the on-device model was trained to tell apart.
/// The names match `assets/models/photo_kind_labels.txt`.
enum PhotoKind { atm, cardTerminal, receiptMenu, priceTag, other }

/// On-device AI step before any reading: tells an ATM screen, a card
/// terminal, a receipt or menu and a price tag apart, so the app can open the
/// right check. MobileNetV2 fine-tuned on 15 Oct 2026 with 442 licensed
/// Wikimedia Commons photos (sources in `photo_kind_sources.csv`); 85.5 %
/// on 110 held-out photos in the training pipeline (`photo_kind_eval.json`;
/// accuracy under ML Kit's own scaling on the phone is not measured yet).
/// Never leaves the phone.
class PhotoKindClassifier {
  static const modelAsset = 'assets/models/photo_kind.tflite';

  /// Below this the photo is reported as unknown instead of guessed.
  static const minConfidence = 0.6;

  static const _labels = {
    'atm': PhotoKind.atm,
    'card_terminal': PhotoKind.cardTerminal,
    'receipt_menu': PhotoKind.receiptMenu,
    'price_tag': PhotoKind.priceTag,
    'other': PhotoKind.other,
  };

  ImageLabeler? _labeler;

  Future<ImageLabeler> _open() async {
    final ready = _labeler;
    if (ready != null) return ready;
    // ML Kit reads the model from a file path, not from the asset bundle.
    final file = File('${Directory.systemTemp.path}/photo_kind.tflite');
    final bytes = await rootBundle.load(modelAsset);
    await file.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
    return _labeler = ImageLabeler(
      options: LocalLabelerOptions(
        modelPath: file.path,
        confidenceThreshold: minConfidence,
        maxCount: 1,
      ),
    );
  }

  /// The kind of the photo at [path] with its confidence and a measured
  /// trace, or null when the model is not sure enough.
  Future<(PhotoKind, double, AiTrace)?> classify(String path) async {
    final labeler = await _open();
    final (labels, trace) = await AiTrace.measure(
      AiEngine.onDevice,
      () => labeler.processImage(InputImage.fromFilePath(path)),
    );
    if (labels.isEmpty) return null;
    final kind = _labels[labels.first.label];
    if (kind == null) return null;
    return (kind, labels.first.confidence, trace);
  }

  Future<void> close() async {
    await _labeler?.close();
    _labeler = null;
  }
}
