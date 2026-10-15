// Developer probe: runs real on-device ML Kit text recognition on an image
// file from the host and prints the raw result, so the OCR parser can be
// checked against real output instead of a reconstructed fixture.
//
// flutter test integration_test/ocr_probe_test.dart -d <simulator> \
//   --dart-define=OCR_IMAGE=/absolute/path/to/image.png
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:integration_test/integration_test.dart';
import 'package:money_navigation/rules/atm_conversion.dart';

const imagePath = String.fromEnvironment('OCR_IMAGE');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('print ML Kit text for OCR_IMAGE', (tester) async {
    expect(imagePath, isNotEmpty, reason: 'pass --dart-define=OCR_IMAGE');
    expect(File(imagePath).existsSync(), isTrue, reason: imagePath);

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final stopwatch = Stopwatch()..start();
    final result = await recognizer.processImage(
      InputImage.fromFilePath(imagePath),
    );
    stopwatch.stop();
    await recognizer.close();

    // ignore: avoid_print
    print('OCR_MS=${stopwatch.elapsedMilliseconds}');
    // ignore: avoid_print
    print('OCR_TEXT_BEGIN\n${result.text}\nOCR_TEXT_END');
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final b = line.boundingBox;
        // ignore: avoid_print
        print(
          'LINE ${b.left.round()},${b.top.round()},${b.right.round()},'
          '${b.bottom.round()} | ${line.text}',
        );
      }
    }
    final reading = parseAtmScreen(result.text);
    // ignore: avoid_print
    print(
      reading == null
          ? 'PARSE=null'
          : 'PARSE=${reading.withdrawalThb}/${reading.accessFeeThb}/'
                '${reading.thbPerUsd}/${reading.markupPercent}/'
                '${reading.chargedThb}/${reading.chargedUsd}',
    );
  });
}
