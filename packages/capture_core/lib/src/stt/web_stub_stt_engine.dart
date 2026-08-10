import 'dart:async';
import 'dart:math';

import 'stt_engine.dart';

/// Liefert hinterlegten Beispieltext. Nur Testkanal, nie in einem
/// Release-Build eines Geräts.
class WebStubSttEngine implements SttEngine {
  WebStubSttEngine({
    List<String>? samples,
    this.delay = const Duration(milliseconds: 900),
    this.failureRate = 0.0,
    int seed = 7,
  })  : _samples = samples ?? _defaultSamples,
        _random = Random(seed);

  /// Verzögerung, damit Ladezustände sichtbar werden.
  final Duration delay;

  /// 0.0–1.0. Auf 0.2 setzen, um den Fehlerweg auf dem iPhone durchzuspielen.
  final double failureRate;

  final List<String> _samples;
  final Random _random;
  int _calls = 0;

  static const List<String> _defaultSamples = <String>[
    'zweiundzwanzig fünfzig bei Rewe',
    'Termin nächsten Dienstag um viertel nach zehn beim Zahnarzt',
    'Idee für die App: Segmente einzeln neu transkribieren lassen',
    'sechs Komma vier Kilometer gelaufen in achtunddreißig Minuten',
    'Rechnung von der Werkstatt, hundertvierundachtzig Euro neunzig',
  ];

  @override
  String get id => 'web';

  @override
  bool get isAvailable => true;

  @override
  Future<Transcript> transcribe(String path, {String lang = 'de-DE'}) async {
    await Future<void>.delayed(delay);
    if (failureRate > 0 && _random.nextDouble() < failureRate) {
      throw const SttFailure(
        'Beispiel-Fehlerfall der Stub-Engine.',
        engine: 'web',
      );
    }
    final String text = _samples[_calls++ % _samples.length];
    return Transcript(text: text, engine: id, confidence: 0.99);
  }
}
