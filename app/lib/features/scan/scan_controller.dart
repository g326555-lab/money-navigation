import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'scan_guide.dart';

import '../../rules/atm_conversion.dart';
import '../../rules/ocr_layout.dart';
import '../../services/text_recognition_service.dart';

enum ScanStepId { readText, findAtm, readValues, compare }

enum ScanStepState { running, done, failed }

class ScanStep {
  const ScanStep(this.id, this.state);

  final ScanStepId id;
  final ScanStepState state;
}

enum ScanFailure { noText, notAtm, missingValues }

/// Everything the scan screens show, built only from the real work done on
/// the photo: OCR lines, the parsed reading and the verdict.
class ScanState {
  const ScanState({
    this.photoPath,
    this.scannedAt,
    this.photoSize,
    this.steps = const [],
    this.readElapsed,
    this.lines = const [],
    this.reading,
    this.verdict,
    this.declineLabel,
    this.failure,
  });

  final String? photoPath;
  final DateTime? scannedAt;
  final ui.Size? photoSize;
  final List<ScanStep> steps;
  final Duration? readElapsed;
  final List<OcrLine> lines;
  final AtmScreenReading? reading;
  final AtmVerdict? verdict;
  final String? declineLabel;
  final ScanFailure? failure;

  bool get isWorking => photoPath != null && verdict == null && failure == null;

  ScanState copyWith({
    ui.Size? photoSize,
    List<ScanStep>? steps,
    Duration? readElapsed,
    List<OcrLine>? lines,
    AtmScreenReading? reading,
    AtmVerdict? verdict,
    String? declineLabel,
    ScanFailure? failure,
  }) => ScanState(
    photoPath: photoPath,
    scannedAt: scannedAt,
    photoSize: photoSize ?? this.photoSize,
    steps: steps ?? this.steps,
    readElapsed: readElapsed ?? this.readElapsed,
    lines: lines ?? this.lines,
    reading: reading ?? this.reading,
    verdict: verdict ?? this.verdict,
    declineLabel: declineLabel ?? this.declineLabel,
    failure: failure ?? this.failure,
  );
}

/// Runs one scan: read text on the device, find the ATM offer, read the
/// values, compare totals. Each step is published as soon as it really
/// finishes; nothing is scripted.
class ScanController extends ChangeNotifier {
  ScanController({TextRecognitionService? recognition})
    : _recognition = recognition ?? TextRecognitionService();

  final TextRecognitionService _recognition;
  ScanState _state = const ScanState();
  int _run = 0;

  ScanState get state => _state;

  void reset() {
    _run++;
    _set(const ScanState());
  }

  /// Scans a photo. [region] is set for camera shots, so text outside the
  /// frame the user aimed with is ignored; picked photos use all text.
  Future<void> scanPhoto(String path, {ScanRegion? region}) async {
    final run = ++_run;
    _set(
      ScanState(
        photoPath: path,
        scannedAt: DateTime.now(),
        steps: const [ScanStep(ScanStepId.readText, ScanStepState.running)],
      ),
    );

    final (size, read) = await (
      _imageSize(path),
      _recognition.readFile(path),
    ).wait;
    if (run != _run) return;
    if (read.lines.isEmpty) {
      _set(
        _state.copyWith(
          photoSize: size,
          steps: const [ScanStep(ScanStepId.readText, ScanStepState.failed)],
          failure: ScanFailure.noText,
        ),
      );
      return;
    }

    final keep = [
      for (var i = 0; i < read.lines.length; i++)
        region == null || size == null || region.contains(read.lines[i], size),
    ];
    final lines = [
      for (var i = 0; i < read.lines.length; i++)
        if (keep[i]) read.lines[i],
    ];
    // Rows are rebuilt from the straightened lines, so a tilted photo still
    // lines each label up with its values.
    final rows = rowsFromLines(
      straightenLines([
        for (var i = 0; i < read.quads.length; i++)
          if (keep[i]) read.quads[i],
      ]),
    );
    if (kDebugMode) {
      // What OCR actually read, to diagnose misses on a real device.
      debugPrint('[scan] ${read.lines.length} lines, ${lines.length} in frame');
      debugPrint('[scan] rows:\n$rows');
    }
    final lower = rows.toLowerCase();
    // "conversion" alone also appears on card terminal stickers, so require
    // the ATM total row or the paired with/without conversion choice.
    final looksLikeAtm =
        lower.contains('amount charged') ||
        (lower.contains('without conversion') &&
            lower.contains('with conversion'));
    _set(
      _state.copyWith(
        photoSize: size,
        readElapsed: read.elapsed,
        lines: lines,
        steps: [
          const ScanStep(ScanStepId.readText, ScanStepState.done),
          ScanStep(
            ScanStepId.findAtm,
            looksLikeAtm ? ScanStepState.done : ScanStepState.failed,
          ),
        ],
        failure: looksLikeAtm ? null : ScanFailure.notAtm,
      ),
    );
    if (!looksLikeAtm) return;

    final reading = parseAtmScreen(rows);
    if (reading == null) {
      _set(
        _state.copyWith(
          steps: [
            ..._state.steps,
            const ScanStep(ScanStepId.readValues, ScanStepState.failed),
          ],
          failure: ScanFailure.missingValues,
        ),
      );
      return;
    }
    _set(
      _state.copyWith(
        reading: reading,
        steps: [
          ..._state.steps,
          const ScanStep(ScanStepId.readValues, ScanStepState.done),
          const ScanStep(ScanStepId.compare, ScanStepState.running),
        ],
      ),
    );

    final verdict = evaluateAtm(reading);
    final steps = [..._state.steps]
      ..removeLast()
      ..add(const ScanStep(ScanStepId.compare, ScanStepState.done));
    _set(
      _state.copyWith(
        steps: steps,
        verdict: verdict,
        declineLabel: declineButtonLabel(lines),
      ),
    );
  }

  void _set(ScanState next) {
    _state = next;
    notifyListeners();
  }

  /// Size of the photo as displayed, after EXIF orientation, so OCR boxes
  /// line up with the picture. Decodes at a small target width because
  /// only the aspect ratio and orientation matter.
  static Future<ui.Size?> _imageSize(String path) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromFilePath(path);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final rawWidth = descriptor.width;
      final rawHeight = descriptor.height;
      final codec = await descriptor.instantiateCodec(targetWidth: _probeWidth);
      final frame = await codec.getNextFrame();
      final probe = frame.image;
      // A rotated photo decodes with swapped proportions.
      final rotated = (probe.width > probe.height) != (rawWidth > rawHeight);
      probe.dispose();
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
      return rotated
          ? ui.Size(rawHeight.toDouble(), rawWidth.toDouble())
          : ui.Size(rawWidth.toDouble(), rawHeight.toDouble());
    } on Object {
      return null;
    }
  }

  static const _probeWidth = 64;

  @override
  void dispose() {
    _run++;
    _recognition.close();
    super.dispose();
  }
}
