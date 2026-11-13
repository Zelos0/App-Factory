/// Zeitangaben aus gesprochenem Text.
///
/// Wie [SpokenNumbers] steht das hier im Unterbau, weil KASSA („gestern bei
/// Rewe"), RITUS („heute früh genommen"), FAHRTLOG („die Fahrt am Montag")
/// und ANAMNESE („seit letztem Freitag") dieselbe Erkennung brauchen.
///
/// Reine Funktion: [now] wird hereingereicht, nie selbst geholt. Ein
/// Datumsparser, der `DateTime.now()` aufruft, ist um Mitternacht nicht
/// testbar — und genau dann wird er benutzt.
class SpokenDates {
  const SpokenDates._();

  static const Map<String, int> _weekdays = <String, int>{
    'montag': DateTime.monday,
    'dienstag': DateTime.tuesday,
    'mittwoch': DateTime.wednesday,
    'donnerstag': DateTime.thursday,
    'freitag': DateTime.friday,
    'samstag': DateTime.saturday,
    'sonnabend': DateTime.saturday,
    'sonntag': DateTime.sunday,
  };

  /// Der letzte Treffer gewinnt: „gestern habe ich am Montag gesagt" meint
  /// den Montag, nicht gestern. Wer zuletzt spricht, korrigiert sich.
  ///
  /// Gibt `null` zurück, wenn keine Angabe im Text steht. Der Aufrufer
  /// setzt dann den Aufnahmezeitpunkt ein — das ist seine Entscheidung,
  /// nicht die dieses Parsers.
  static DateTime? parse(String text, {required DateTime now}) {
    final String s = text.toLowerCase();
    final DateTime today = DateTime(now.year, now.month, now.day);

    DateTime? result;
    int lastAt = -1;

    void take(int at, DateTime value) {
      if (at > lastAt) {
        lastAt = at;
        result = value;
      }
    }

    // Explizites Datum: 12.03.2026 · 12.3.26 · 12.3.
    for (final RegExpMatch m
        in RegExp(r'\b(\d{1,2})\.\s?(\d{1,2})\.(\s?(\d{2,4}))?')
            .allMatches(s)) {
      final int day = int.parse(m.group(1)!);
      final int month = int.parse(m.group(2)!);
      final String? rawYear = m.group(4);
      final int year = rawYear == null
          ? now.year
          : (rawYear.length == 2
              ? 2000 + int.parse(rawYear)
              : int.parse(rawYear));
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        take(m.start, DateTime(year, month, day));
      }
    }

    for (final MapEntry<String, int> named in <String, int>{
      'vorgestern': -2,
      'gestern': -1,
      'heute': 0,
      'morgen': 1,
      'übermorgen': 2,
      'uebermorgen': 2,
    }.entries) {
      final int at = _lastStandalone(s, named.key);
      if (at >= 0) {
        take(at, today.add(Duration(days: named.value)));
      }
    }

    // „letzten Freitag" · „am Montag" · „nächsten Dienstag"
    for (final MapEntry<String, int> day in _weekdays.entries) {
      final int at = _lastStandalone(s, day.key);
      if (at < 0) {
        continue;
      }
      final String before = s.substring(0, at);
      final bool forward = _endsWithAny(
        before,
        <String>['nächsten ', 'naechsten ', 'kommenden ', 'diesen '],
      );
      take(at, _nearestWeekday(today, day.value, forward: forward));
    }

    return result;
  }

  /// Letztes Vorkommen, das ein eigenes Wort ist.
  ///
  /// Ohne diese Prüfung gewinnt „gestern" gegen „vorgestern": es steckt
  /// darin und steht drei Zeichen weiter rechts, und der letzte Treffer
  /// gewinnt. Dasselbe gilt für „morgen" in „übermorgen". `\b` hilft hier
  /// nicht, weil Umlaute in Dart nicht als Wortzeichen gelten.
  static int _lastStandalone(String s, String needle) {
    int at = s.lastIndexOf(needle);
    while (at >= 0) {
      final int end = at + needle.length;
      final bool leftFree = at == 0 || !_isLetter(s[at - 1]);
      final bool rightFree = end >= s.length || !_isLetter(s[end]);
      if (leftFree && rightFree) {
        return at;
      }
      if (at == 0) {
        return -1;
      }
      at = s.lastIndexOf(needle, at - 1);
    }
    return -1;
  }

  static bool _isLetter(String c) => RegExp('[a-zäöüß]').hasMatch(c);

  static bool _endsWithAny(String s, List<String> endings) {
    for (final String e in endings) {
      if (s.endsWith(e)) {
        return true;
      }
    }
    return false;
  }

  /// Ohne Richtungswort meint ein genannter Wochentag den vergangenen —
  /// festgehalten wird, was war, nicht was kommt. „Nächsten Montag" dreht
  /// die Richtung um.
  static DateTime _nearestWeekday(
    DateTime today,
    int weekday, {
    required bool forward,
  }) {
    if (forward) {
      final int ahead = (weekday - today.weekday + 7) % 7;
      return today.add(Duration(days: ahead == 0 ? 7 : ahead));
    }
    final int back = (today.weekday - weekday + 7) % 7;
    return today.subtract(Duration(days: back == 0 ? 7 : back));
  }
}
