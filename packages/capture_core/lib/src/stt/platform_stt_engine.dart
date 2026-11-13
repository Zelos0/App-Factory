import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'live_transcript.dart';
import 'stt_engine.dart';

/// Gratis-Stufe: Android SpeechRecognizer, iOS Speech und im Browser die
/// Web Speech API (Chrome, Edge, Safari ab iOS 14.5).
///
/// Diese Engines arbeiten am Mikrofon, nicht an einer Datei. Sie hören
/// deshalb parallel zur Aufnahme mit: [PlatformAudioRecorder] ruft
/// [beginLive] und [endLive], danach liefert [transcribe] das Mitgehörte.
/// Eine bereits gespeicherte Datei können sie NICHT nachträglich lesen —
/// genau das kann Parakeet später mehr.
class PlatformSttEngine implements LiveSttEngine {
  PlatformSttEngine();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final LiveTranscript _buffer = LiveTranscript();

  bool _initialized = false;
  bool _live = false;
  bool _hasSession = false;
  bool _restartPending = false;
  DateTime? _sessionStartedAt;
  String _lang = 'de-DE';
  Completer<void>? _settled;

  @override
  String get id => 'platform';

  @override
  bool get isAvailable => _initialized && _speech.isAvailable;

  Future<bool> init() async {
    try {
      _initialized = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );
    } on Object {
      // Fehlende Plattform-Unterstützung (z. B. Firefox) ist kein Absturz,
      // sondern ein Zustand. beginLive() meldet ihn später verständlich.
      _initialized = false;
    }
    return _initialized;
  }

  @override
  Future<void> beginLive({String lang = 'de-DE', bool append = false}) async {
    if (!append) {
      _buffer.reset();
    }
    _hasSession = true;
    _lang = lang;
    if (!_initialized && !await init()) {
      _buffer.fail('unavailable');
      return;
    }
    _live = true;
    _restartPending = false;
    await _listen();
  }

  @override
  Future<void> endLive() async {
    if (!_live) {
      return;
    }
    _live = false;
    final Completer<void> settled = _settled = Completer<void>();
    try {
      await _speech.stop();
      // Das letzte Ergebnis kommt nach stop() asynchron. Kurz warten, aber
      // nie ewig: lieber ein Wort verlieren als die App hängen lassen.
      await settled.future.timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () {},
      );
    } on Object {
      // Siehe Vertrag in LiveSttEngine: endLive() wirft nie.
    }
    _buffer.commitPartial();
  }

  /// Nur der Vollständigkeit halber noch öffentlich; neue Apps lassen den
  /// Recorder die Erkennung steuern.
  Stream<String> listen({String lang = 'de-DE'}) {
    final StreamController<String> out = StreamController<String>();
    unawaited(
      _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: _localeFor(lang),
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

  Future<void> stopListening() => endLive();

  @override
  Future<Transcript> transcribe(String path, {String lang = 'de-DE'}) async {
    if (!_hasSession) {
      throw const SttFailure(
        'Die Plattform-Engine kann keine gespeicherte Datei lesen. '
        'Für Datei-Transkription ist die Pro-Engine nötig.',
        engine: 'platform',
      );
    }
    // Ergebnis gehört genau zu dieser einen Aufnahme — danach verbraucht.
    _hasSession = false;
    final String text = _buffer.text;
    final String? error = _buffer.error;
    _buffer.reset();

    if (text.isEmpty) {
      throw SttFailure(
        error ?? LiveTranscript.describe('no_match'),
        engine: id,
      );
    }
    return Transcript(text: text, engine: id);
  }

  Future<void> _listen() async {
    _sessionStartedAt = DateTime.now();
    try {
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: _localeFor(_lang),
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
          // Obergrenzen, damit lange Notizen nicht nach Sekunden abbrechen.
          // Endet die Erkennung trotzdem (Sprechpause), startet _onStatus
          // sie neu, solange die Aufnahme läuft.
          listenFor: const Duration(minutes: 10),
          pauseFor: const Duration(seconds: 30),
        ),
        onResult: (SpeechRecognitionResult r) {
          _buffer.add(r.recognizedWords, isFinal: r.finalResult);
          if (r.finalResult && !_live) {
            _settle();
          }
        },
      );
    } on Object catch (e) {
      _buffer.fail(e.toString());
      _live = false;
    }
  }

  void _onStatus(String status) {
    if (status == stt.SpeechToText.listeningStatus) {
      _restartPending = false;
      return;
    }
    // Das Ende einer Sitzung meldet sich je nach Plattform unterschiedlich:
    // im Browser oft NUR mit notListening (speech_to_text schluckt done,
    // solange das letzte Ergebnis vorläufig ist), auf Android mit
    // notListening und einem done, das auch erst nach dem Neustart kommen
    // kann. Deshalb: auf das erste Ende-Signal reagieren, weitere ignorieren,
    // bis die neue Sitzung wirklich läuft.
    final bool ended = status == stt.SpeechToText.doneStatus ||
        status == stt.SpeechToText.notListeningStatus;
    if (!ended) {
      return;
    }
    if (!_live) {
      _settle();
      return;
    }
    if (_restartPending) {
      return;
    }
    // Endet eine Sitzung sofort wieder, stimmt grundsätzlich etwas nicht
    // (Berechtigung, Mikrofon belegt). Dann nicht im Kreis neu starten —
    // der Fehler steht im Puffer und transcribe() meldet ihn.
    final DateTime? began = _sessionStartedAt;
    if (began != null &&
        DateTime.now().difference(began) < const Duration(milliseconds: 400)) {
      return;
    }
    // Erkenner beenden sich nach einer Sprechpause selbst. Die Aufnahme
    // läuft aber weiter — also nahtlos weiterhören.
    _restartPending = true;
    _buffer.commitPartial();
    unawaited(_listen());
  }

  void _onError(SpeechRecognitionError e) {
    _buffer.fail(e.errorMsg);
    if (!_live) {
      _settle();
    }
  }

  void _settle() {
    final Completer<void>? c = _settled;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
  }

  /// Browser erwarten BCP-47 (`de-DE`), Android und iOS nehmen den
  /// Unterstrich (`de_DE`), den speech_to_text als Kennung benutzt.
  static String _localeFor(String lang) =>
      kIsWeb ? lang.replaceAll('_', '-') : lang.replaceAll('-', '_');
}
