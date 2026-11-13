import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'stt_engine.dart';

/// Gratis-Stufe: Android SpeechRecognizer / iOS Speech.
///
/// Diese Engines arbeiten am Mikrofon, nicht an einer Datei. Der Aufnahmefluss
/// ist deshalb: [listen] parallel zur Aufnahme laufen lassen, das Ergebnis dem
/// Segment beilegen. [transcribe] auf eine bestehende Datei wird von den
/// Plattform-Engines nicht unterstützt — das ist der Grund, warum Parakeet
/// später mehr kann als diese Stufe.
class PlatformSttEngine implements SttEngine {
  PlatformSttEngine();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;

  @override
  String get id => 'platform';

  @override
  bool get isAvailable => _initialized && _speech.isAvailable;

  Future<bool> init() async {
    _initialized = await _speech.initialize(
      onError: (SpeechRecognitionError _) {},
      onStatus: (String _) {},
    );
    return _initialized;
  }

  /// Live-Erkennung während der Aufnahme.
  Stream<String> listen({String lang = 'de_DE'}) {
    final StreamController<String> out = StreamController<String>();
    unawaited(
      _speech.listen(
        // Die Sprache gehoert seit speech_to_text 7 in SpeechListenOptions;
        // der gleichnamige Parameter von listen() ist abgekuendigt und
        // scheitert an --fatal-infos.
        listenOptions: stt.SpeechListenOptions(
          localeId: lang,
          partialResults: true,
          cancelOnError: false,
        ),
        onResult: (SpeechRecognitionResult result) {
          out.add(result.recognizedWords);
          if (result.finalResult) {
            unawaited(out.close());
          }
        },
      ),
    );
    return out.stream;
  }

  Future<void> stopListening() => _speech.stop();

  @override
  Future<Transcript> transcribe(String path, {String lang = 'de-DE'}) async {
    throw const SttFailure(
      'Die Plattform-Engine kann keine gespeicherte Datei lesen. '
      'Für Datei-Transkription ist die Pro-Engine nötig.',
      engine: 'platform',
    );
  }
}
