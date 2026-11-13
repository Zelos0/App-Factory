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
