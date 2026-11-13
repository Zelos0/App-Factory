/// Sammelt, was eine Live-Engine während einer Aufnahme hört.
///
/// Live-Erkenner liefern zwei Sorten Ergebnisse: vorläufige, die sich noch
/// ändern, und endgültige, nach denen ein neuer Abschnitt beginnt. Außerdem
/// beenden sie sich nach einer Sprechpause von selbst und müssen neu
/// gestartet werden — jeder Neustart beginnt wieder bei null. Dieser Puffer
/// fügt das zu EINEM Text zusammen.
///
/// Reine Logik ohne Plattform, damit sie ohne Gerät testbar ist.
class LiveTranscript {
  final List<String> _done = <String>[];
  String _partial = '';
  String? _error;

  /// Zwischenstand während der Aufnahme.
  String get text => _join(<String>[..._done, _partial]);

  /// Letzter gemeldeter Fehler in Klartext, oder null.
  String? get error => _error;

  bool get isEmpty => text.isEmpty;

  /// Alles verwerfen — neue Aufnahme.
  void reset() {
    _done.clear();
    _partial = '';
    _error = null;
  }

  /// Ergebnis der Engine einspeisen.
  void add(String words, {required bool isFinal}) {
    if (isFinal) {
      if (words.trim().isNotEmpty) {
        _done.add(words.trim());
      }
      _partial = '';
    } else {
      _partial = words.trim();
    }
  }

  /// Die Engine hat sich beendet (Sprechpause). Ein noch vorläufiges
  /// Ergebnis gilt dann als endgültig — sonst ginge es beim Neustart verloren.
  void commitPartial() => add(_partial, isFinal: true);

  /// Fehlercode der Engine merken. „Nichts erkannt" ist kein Fehler, wenn
  /// vorher schon etwas erkannt wurde — Erkenner melden das nach jeder
  /// längeren Pause.
  void fail(String code) {
    if (isNoMatch(code) && !isEmpty) {
      return;
    }
    _error = describe(code);
  }

  static bool isNoMatch(String code) =>
      code.contains('no_match') || code.contains('no-speech');

  /// Übersetzt Fehlercodes von Android, iOS und Web Speech API in Sätze,
  /// die man ohne Fachwissen versteht. Unbekannte Codes bleiben sichtbar.
  static String describe(String code) {
    final String c = code.toLowerCase();
    if (isNoMatch(c)) {
      return 'Nichts verstanden. Die Aufnahme ist gespeichert.';
    }
    if (c.contains('permission') || c.contains('not-allowed')) {
      return 'Spracherkennung ist nicht erlaubt. In den Einstellungen '
          'freigeben — die Aufnahme ist gespeichert.';
    }
    if (c.contains('network') || c.contains('server')) {
      return 'Spracherkennung braucht gerade Internet. '
          'Die Aufnahme ist gespeichert.';
    }
    if (c.contains('audio') || c.contains('busy')) {
      return 'Das Mikrofon war für die Erkennung belegt. '
          'Die Aufnahme ist gespeichert.';
    }
    if (c.contains('unavailable') || c.contains('not-supported')) {
      return 'Dieses Gerät oder dieser Browser bietet keine '
          'Spracherkennung. Die Aufnahme ist gespeichert.';
    }
    return 'Spracherkennung fehlgeschlagen ($code). '
        'Die Aufnahme ist gespeichert.';
  }

  static String _join(List<String> parts) => parts
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .join(' ');
}
