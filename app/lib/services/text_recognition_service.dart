import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../rules/ocr_layout.dart';

/// Result of reading one photo on the device.
class TextReadResult {
  const TextReadResult({required this.lines, required this.elapsed});

  final List<OcrLine> lines;
  final Duration elapsed;
}

/// On-device text recognition (ML Kit, Latin script). Photos never leave
/// the phone.
class TextRecognitionService {
  TextRecognitionService()
    : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  Future<TextReadResult> readFile(String path) async {
    final stopwatch = Stopwatch()..start();
    final result = await _recognizer.processImage(
      InputImage.fromFilePath(path),
    );
    stopwatch.stop();
    final lines = [
      for (final block in result.blocks)
        for (final line in block.lines)
          OcrLine(
            text: line.text,
            left: line.boundingBox.left,
            top: line.boundingBox.top,
            right: line.boundingBox.right,
            bottom: line.boundingBox.bottom,
          ),
    ];
    return TextReadResult(lines: lines, elapsed: stopwatch.elapsed);
  }

  Future<void> close() => _recognizer.close();
}
