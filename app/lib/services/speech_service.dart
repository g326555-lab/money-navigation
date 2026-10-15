import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Thai speech recognition. Keeps text only; audio is never stored.
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _ready = false;

  /// The locale id the device uses for Thai ("th_TH" or "th-TH"), if any.
  String? _thaiLocale;

  /// Starts the recognizer and finds a Thai locale. Returns false when
  /// speech recognition or Thai is not available on this device.
  Future<bool> prepare({
    required void Function(String status) onStatus,
    required void Function(SpeechRecognitionError error) onError,
  }) async {
    if (!_ready) {
      _ready = await _speech.initialize(onStatus: onStatus, onError: onError);
      if (!_ready) return false;
      final locales = await _speech.locales();
      final thai = locales.where(
        (l) => l.localeId.toLowerCase().startsWith('th'),
      );
      _thaiLocale = thai.isEmpty ? null : thai.first.localeId;
    }
    return _thaiLocale != null;
  }

  bool get isListening => _speech.isListening;

  /// Whether microphone and speech recognition access are granted.
  Future<bool> get hasPermission => _speech.hasPermission;

  /// Listens to a seller. [onWords] gets partial and final text, plus every
  /// transcript the recognizer considered (best first), which the on-device
  /// item matcher uses; [isFinal] is true once the sentence has settled.
  Future<void> listen({
    required void Function(
      String words,
      bool isFinal,
      List<String> alternatives,
    )
    onWords,
    required void Function(double level) onLevel,
    required List<String> phrases,
  }) async {
    await _speech.listen(
      onResult: (SpeechRecognitionResult r) => onWords(
        r.recognizedWords,
        r.finalResult,
        [for (final a in r.alternates) a.recognizedWords],
      ),
      onSoundLevelChange: onLevel,
      listenOptions: SpeechListenOptions(
        localeId: _thaiLocale,
        partialResults: true,
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        autoPunctuation: false,
        listenFor: speechListenFor,
        pauseFor: speechWaitForSpeech,
        contextualPhrases: phrases,
      ),
    );
  }

  /// Shortens the end-of-sentence silence once the seller has started
  /// talking; until then the long [speechWaitForSpeech] applies.
  void speechStarted() => _speech.changePauseFor(speechPauseAfterWords);

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();
}

/// Longest a single listen may run.
const speechListenFor = Duration(seconds: 30);

/// Silence allowed before the seller starts talking. The plugin's pause
/// timer runs from the start of a listen, so it must be long here.
const speechWaitForSpeech = Duration(seconds: 10);

/// Silence after the first words that ends the sentence.
const speechPauseAfterWords = Duration(milliseconds: 1500);
