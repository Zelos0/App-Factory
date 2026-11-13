/// Ergebnis einer Transkription.
class Transcript {
  const Transcript({
    required this.text,
    required this.engine,
    this.confidence,
    this.words = const <TranscriptWord>[],
  });

  final String text;
  final String engine;

  /// 0.0–1.0, wenn die Engine das liefert. Sonst null.
  final double? confidence;

  /// Wortweise Zeitmarken, wenn verfügbar. Trägt „Präzision prüfen".
  final List<TranscriptWord> words;
}

class TranscriptWord {
  const TranscriptWord({
    required this.text,
    required this.start,
    required this.end,
  });

  final String text;
  final Duration start;
  final Duration end;
}

/// Schnittstelle aus ARCHITEKTUR.md Abschnitt 4.
abstract class SttEngine {
  Future<Transcript> transcribe(String path, {String lang});
  bool get isAvailable;
  String get id;
}

/// Wird geworfen, wenn eine Engine nicht arbeiten kann. Die UI zeigt die
/// Meldung an und bietet erneutes Versuchen — sie stürzt nicht ab.
class SttFailure implements Exception {
  const SttFailure(this.message, {this.engine});

  final String message;
  final String? engine;

  @override
  String toString() => 'SttFailure(${engine ?? "?"}): $message';
}

/// Engines, die am Mikrofon MITHÖREN, statt eine fertige Datei zu lesen —
/// Android SpeechRecognizer, iOS Speech, im Browser die Web Speech API.
///
/// Apps rufen diese Methoden nie selbst auf. [PlatformAudioRecorder] startet
/// die Erkennung mit der Aufnahme und beendet sie mit ihr; danach liefert
/// [SttEngine.transcribe] das Mitgehörte. Für die App sieht der Ablauf damit
/// genauso aus wie bei einer Datei-Engine: aufnehmen, stoppen, transcribe().
abstract interface class LiveSttEngine implements SttEngine {
  /// Beginnt mitzuhören. [append] hängt an das bisher Gehörte an (nach einer
  /// Pause), statt neu zu beginnen. Wirft nie: Geht es nicht, merkt sich die
  /// Engine den Grund und [SttEngine.transcribe] meldet ihn als [SttFailure].
  /// Die Aufnahme selbst darf an der Erkennung niemals scheitern.
  Future<void> beginLive({String lang, bool append});

  /// Hört auf und wartet kurz auf das letzte Ergebnis. Wirft nie.
  Future<void> endLive();
}
