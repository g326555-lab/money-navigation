import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'scan_guide.dart';

import '../../rules/atm_conversion.dart';
import '../../rules/exchange_board.dart';
import '../../rules/exchange_rate.dart';
import '../../rules/terminal_dcc.dart';
import '../../rules/ocr_layout.dart';
import '../../services/text_recognition_service.dart';

import 'dart:async';

import '../../services/ai/ai_trace.dart';
import '../../services/ai/photo_kind_classifier.dart';

enum ScanStepId {
  readText,
  findAtm,
  readValues,
  compare,

  /// Part B: a card terminal offering two currencies (F1 / F2).
  findTerminal,

  /// Part B: a money changer's buying and selling board.
  findBoard,
}

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
    this.dcc,
    this.board,
    this.boardReference,
    this.kindGuess,
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

  /// Part B verdicts, from the same photo when it was not an ATM.
  final DccVerdict? dcc;
  final BoardRate? board;

  /// The live rate the board was checked against, when there was one.
  final RateQuote? boardReference;

  /// What the on-device photo classifier thinks the photo shows, with its
  /// confidence and measured time. A hint shown beside the steps; the
  /// verdict itself always comes from the numbers read.
  final (PhotoKind, double, AiTrace)? kindGuess;

  bool get hasResult => verdict != null || dcc != null || board != null;

  bool get isWorking => photoPath != null && !hasResult && failure == null;

  ScanState copyWith({
    ui.Size? photoSize,
    List<ScanStep>? steps,
    Duration? readElapsed,
    List<OcrLine>? lines,
    AtmScreenReading? reading,
    AtmVerdict? verdict,
    String? declineLabel,
    ScanFailure? failure,
    DccVerdict? dcc,
    BoardRate? board,
    RateQuote? boardReference,
    (PhotoKind, double, AiTrace)? kindGuess,
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
    dcc: dcc ?? this.dcc,
    board: board ?? this.board,
    boardReference: boardReference ?? this.boardReference,
    kindGuess: kindGuess ?? this.kindGuess,
  );
}

/// Runs one scan: read text on the device, find the ATM offer, read the
/// values, compare totals. Each step is published as soon as it really
/// finishes; nothing is scripted.
class ScanController extends ChangeNotifier {
  ScanController({
    TextRecognitionService? recognition,
    this.rateFor,
    this.classifier,
  }) : _recognition = recognition ?? TextRecognitionService();

  /// The on-device model trained for this app (ATM, card terminal, bill or
  /// menu, price tag). Optional; runs beside OCR.
  final PhotoKindClassifier? classifier;

  /// The rate from THB to a currency, for card terminals and rate boards:
  /// the fixed demo rate in the demo state, otherwise the live daily rate.
  final RateQuote? Function(String quote)? rateFor;

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

    // The classifier runs beside OCR and reports whenever it is done.
    final classify = classifier;
    if (classify != null) {
      unawaited(
        classify.classify(path).then((guess) {
          if (run != _run || guess == null) return;
          _set(_state.copyWith(kindGuess: guess));
        }, onError: (Object _) {}),
      );
    }
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
    if (!looksLikeAtm) {
      _scanPartB(rows, size: size, read: read, lines: lines);
      return;
    }
    _set(
      _state.copyWith(
        photoSize: size,
        readElapsed: read.elapsed,
        lines: lines,
        steps: const [
          ScanStep(ScanStepId.readText, ScanStepState.done),
          ScanStep(ScanStepId.findAtm, ScanStepState.done),
        ],
      ),
    );

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

  /// Not an ATM: a card terminal asking which currency to pay in, or a money
  /// changer's board. Only what the photo proves is shown.
  void _scanPartB(
    String rows, {
    required ui.Size? size,
    required TextReadResult read,
    required List<OcrLine> lines,
  }) {
    final base = _state.copyWith(
      photoSize: size,
      readElapsed: read.elapsed,
      lines: lines,
    );
    final jpy = rateFor?.call('JPY');
    final dcc = jpy == null ? null : judgeTerminal(rows, rate: jpy);
    if (dcc != null) {
      _set(
        base.copyWith(
          dcc: dcc,
          steps: const [
            ScanStep(ScanStepId.readText, ScanStepState.done),
            ScanStep(ScanStepId.findTerminal, ScanStepState.done),
            ScanStep(ScanStepId.compare, ScanStepState.done),
          ],
        ),
      );
      return;
    }
    final board = readExchangeBoard(rows, code: 'USD');
    final usd = rateFor?.call('USD');
    // A live rate rules out misread boards ("3503 3610").
    final plausible =
        board != null &&
        (usd == null || boardRatePlausible(board, usd, home: 'THB'));
    if (plausible) {
      _set(
        base.copyWith(
          board: board,
          boardReference: usd,
          steps: const [
            ScanStep(ScanStepId.readText, ScanStepState.done),
            ScanStep(ScanStepId.findBoard, ScanStepState.done),
            ScanStep(ScanStepId.compare, ScanStepState.done),
          ],
        ),
      );
      return;
    }
    _set(
      base.copyWith(
        steps: const [
          ScanStep(ScanStepId.readText, ScanStepState.done),
          ScanStep(ScanStepId.findAtm, ScanStepState.failed),
        ],
        failure: ScanFailure.notAtm,
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
    classifier?.close();
    super.dispose();
  }
}
