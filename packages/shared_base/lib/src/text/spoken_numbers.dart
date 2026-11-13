/// Deutsche Zahlwörter und Beträge aus gesprochenem Text.
///
/// Steht bewusst im Unterbau und nicht in einer App: KASSA (Beträge),
/// RITUS (Mengen), FAHRTLOG (Kilometerstände) und WERKBUCH (Maße) brauchen
/// dieselbe Erkennung. Wer sie in die erste App schreibt, schreibt sie
/// viermal. ARCHITEKTUR.md Abschnitt 2.
///
/// VOX benutzt diese Klasse **nicht** — dort bleibt Text Text.
///
/// Die Regeln folgen dem gesprochenen Deutsch, nicht dem geschriebenen:
/// niemand sagt „zweiundzwanzig Euro fünfzig Cent", alle sagen
/// „zweiundzwanzig fünfzig".
class SpokenNumbers {
  const SpokenNumbers._();

  static const Map<String, int> _units = <String, int>{
    'null': 0,
    'ein': 1,
    'eins': 1,
    'eine': 1,
    'einen': 1,
    'zwei': 2,
    'zwo': 2,
    'drei': 3,
    'vier': 4,
    'fuenf': 5,
    'fünf': 5,
    'sechs': 6,
    'sieben': 7,
    'acht': 8,
    'neun': 9,
    'zehn': 10,
    'elf': 11,
    'zwoelf': 12,
    'zwölf': 12,
    'dreizehn': 13,
    'vierzehn': 14,
    'fuenfzehn': 15,
    'fünfzehn': 15,
    'sechzehn': 16,
    'siebzehn': 17,
    'achtzehn': 18,
    'neunzehn': 19,
  };

  static const Map<String, int> _tens = <String, int>{
    'zwanzig': 20,
    'dreissig': 30,
    'dreißig': 30,
    'vierzig': 40,
    'fuenfzig': 50,
    'fünfzig': 50,
    'sechzig': 60,
    'siebzig': 70,
    'achtzig': 80,
    'neunzig': 90,
  };

  /// Ein einzelnes Zahlwort. Deckt Einer, Zehner, Zusammensetzungen
  /// („einundzwanzig"), Hunderter und Tausender ab.
  ///
  /// Gibt `null` zurück, wenn das Wort keine Zahl ist — nicht 0. Der
  /// Unterschied zwischen „keine Zahl gefunden" und „die Zahl null" ist
  /// bei Beträgen der Unterschied zwischen leer und geschenkt.
  static int? parseWord(String word) {
    final String w = word.toLowerCase().trim();
    if (w.isEmpty) {
      return null;
    }

    final int? digits = int.tryParse(w);
    if (digits != null) {
      return digits;
    }

    if (_units.containsKey(w)) {
      return _units[w];
    }
    if (_tens.containsKey(w)) {
      return _tens[w];
    }

    final int? thousands = _split(w, 'tausend', 1000);
    if (thousands != null) {
      return thousands;
    }
    final int? hundreds = _split(w, 'hundert', 100);
    if (hundreds != null) {
      return hundreds;
    }

    return _compound(w);
  }

  /// „zweitausendfünfhundert" -> 2500, „hundertvier" -> 104.
  /// Der Teil vor dem Trenner ist der Faktor, der Teil danach der Rest.
  /// Fehlt der Faktor („hundert"), ist er 1.
  static int? _split(String w, String marker, int factor) {
    final int at = w.indexOf(marker);
    if (at < 0) {
      return null;
    }
    final String before = w.substring(0, at);
    final String after = w.substring(at + marker.length);

    final int multiplier = before.isEmpty ? 1 : (parseWord(before) ?? 0);
    if (before.isNotEmpty && multiplier == 0) {
      return null;
    }
    final int rest = after.isEmpty ? 0 : (parseWord(after) ?? 0);

    return multiplier * factor + rest;
  }

  /// „einundzwanzig" -> 21. Im Deutschen steht der Einer vorn.
  static int? _compound(String w) {
    final Match? m = RegExp(r'^([a-zäöüß]+)und([a-zäöüß]+)$').firstMatch(w);
    if (m == null) {
      return null;
    }
    final int? unit = _units[m.group(1)];
    final int? ten = _tens[m.group(2)];
    if (unit == null || ten == null) {
      return null;
    }
    return ten + unit;
  }

  /// Alle Zahlen eines Satzes, in Reihenfolge des Vorkommens.
  static List<int> allIn(String text) {
    final List<int> found = <int>[];
    for (final String token in _tokens(text)) {
      final int? value = parseWord(token);
      if (value != null) {
        found.add(value);
      }
    }
    return found;
  }

  /// Ein Geldbetrag in Euro.
  ///
  /// Erkannt werden, in dieser Reihenfolge:
  /// `22,50` · `22.50` · `22 euro 50` · `22 euro` · `99 cent` ·
  /// `zweiundzwanzig fünfzig` · `acht euro neunzig` · `neunundneunzig cent`
  ///
  /// Gibt `null` zurück, wenn keine Zahl im Text steht.
  static double? parseAmount(String text) {
    final String s = text.toLowerCase();

    final RegExpMatch? decimal =
        RegExp(r'(\d{1,9})[,.](\d{1,2})\b').firstMatch(s);
    if (decimal != null) {
      final String cents = decimal.group(2)!.padRight(2, '0');
      return double.parse('${decimal.group(1)}.$cents');
    }

    final List<String> tokens = _tokens(s);
    final int euroAt = tokens.indexWhere(_isEuroMarker);
    final int centAt = tokens.indexWhere(_isCentMarker);

    // „acht euro neunzig" — der Wert vor dem Marker sind Euro,
    // der unmittelbar danach sind Cent.
    if (euroAt >= 0) {
      final int? euros = _numberBefore(tokens, euroAt);
      if (euros != null) {
        final int? cents = _numberAfter(tokens, euroAt);
        return euros + (cents ?? 0) / 100;
      }
    }

    // „neunundneunzig cent" — ohne Euro-Anteil.
    if (centAt >= 0) {
      final int? cents = _numberBefore(tokens, centAt);
      if (cents != null) {
        return cents / 100;
      }
    }

    // „zweiundzwanzig fünfzig" — erste Zahl Euro, zweite Cent.
    final List<int> numbers = allIn(s);
    if (numbers.isEmpty) {
      return null;
    }
    if (numbers.length == 1) {
      return numbers.first.toDouble();
    }
    final int cents = numbers[1];
    // „drei fünf" sind nicht 3,05 — zweistellig gesprochene Cent sind
    // Zehntel-Cent-frei, einstellige stehen für Zehner.
    return numbers.first + (cents < 10 ? cents * 10 : cents) / 100;
  }

  static bool _isEuroMarker(String t) =>
      t == 'euro' || t == 'euros' || t == '€';

  static bool _isCentMarker(String t) => t == 'cent' || t == 'cents';

  static int? _numberBefore(List<String> tokens, int index) =>
      index == 0 ? null : parseWord(tokens[index - 1]);

  static int? _numberAfter(List<String> tokens, int index) =>
      index + 1 >= tokens.length ? null : parseWord(tokens[index + 1]);

  static List<String> _tokens(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^0-9a-zäöüß€\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((String t) => t.isNotEmpty)
      .toList();
}
