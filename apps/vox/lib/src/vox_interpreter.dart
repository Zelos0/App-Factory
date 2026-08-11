import 'package:shared_base/shared_base.dart';

/// Ordnet den Volltext eines Eintrags — er zerlegt ihn nicht.
///
/// Der Steckbrief ist an dieser Stelle eindeutig: „Kein Interpreter — Text
/// bleibt Text." Der Text wird deshalb nie ersetzt, nie umgeschrieben, nie
/// weggeworfen. Was der Interpreter tut, kommt oben drauf: einen Titel aus
/// dem ersten Satz bilden und Schlagworte über Häufigkeit finden.
///
/// Zwei Felder sind **Beiwerk**, kein Kern: ein Betrag und ein Zeitpunkt,
/// beide nur wenn eindeutig gesprochen, beide über die geteilten Parser aus
/// `shared_base/src/text/`. Sie senken den Vertrauenswert nicht, wenn sie
/// fehlen — sie sind da, wenn sie da sind. Wer Beträge systematisch erfassen
/// will, nimmt KASSA; wer Mengen und Zeiten braucht, RITUS.
///
/// Reine Funktion: kein Zustand, kein Speicher, keine Plattform. Deshalb
/// vollständig im Unit-Test prüfbar — und deshalb testbar, bevor irgendeine
/// Oberfläche existiert.
///
/// Bauplan: docs/baupläne/vox.md Abschnitt 2.
class VoxInterpreter {
  const VoxInterpreter();

  /// Kennung, die in Entry.data unter '_interpreter' landet.
  static const String id = 'vox';

  /// Schema-Version. Bei Feldänderungen erhöhen.
  static const int schemaVersion = 1;

  /// Ohne Satzzeichen wird nach dieser Länge abgeschnitten, an der letzten
  /// Wortgrenze. Die Gratis-Engine setzt oft gar keine Satzzeichen — dann
  /// ist der „erste Satz" der ganze Text, und der braucht eine Grenze.
  static const int titleMaxLength = 60;

  /// Ein erkannter Satz darf länger sein: er ist eine Einheit, kein
  /// willkürlicher Anschnitt. Erst hier wird auch er gekürzt.
  static const int sentenceMaxLength = 120;

  /// Ein Wort wird erst ab dieser Länge als Schlagwort erwogen.
  static const int keywordMinLength = 4;

  /// So oft muss ein Wort vorkommen, um Schlagwort zu werden.
  static const int keywordMinOccurrences = 2;

  static const int keywordMaxCount = 5;

  /// [now] wird nur gebraucht, um relative Zeitangaben aufzulösen
  /// („gestern", „letzten Freitag"). Ohne [now] bleibt `occurredAt` null —
  /// dann ist der Interpreter vollständig deterministisch und im Test
  /// ohne Uhr prüfbar. Der Aufrufer entscheidet, ob er die Uhr reicht.
  VoxResult parse(String text, {DateTime? now}) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return VoxResult(raw: text, confidence: 0);
    }

    final String withoutFillers = _stripLeadingFillers(trimmed);
    final String? title = _firstSentence(withoutFillers);
    final List<String> keywords = _keywords(trimmed);

    return VoxResult(
      title: title,
      keywords: keywords,
      wordCount: _countWords(trimmed),
      charCount: trimmed.length,
      amount: _unambiguousAmount(trimmed),
      occurredAt: now == null ? null : SpokenDates.parse(trimmed, now: now),
      confidence: _confidence(title: title, keywords: keywords),
      raw: text,
    );
  }

  // --- Beiwerk: Betrag und Zeitpunkt -------------------------------------

  /// Ein Betrag, aber nur wenn er **eindeutig** ist.
  ///
  /// VOX ist eine Notiz-App, keine Haushaltsführung. Hier gilt deshalb eine
  /// strengere Regel als in KASSA: Es braucht ein Währungswort („euro",
  /// „€", „cent") oder eine Zahl mit genau zwei Nachkommastellen. Ein
  /// gesprochenes „vierzehn siebzig" ohne Währungswort bleibt liegen — in
  /// einer freien Notiz ist das öfter eine Uhrzeit oder eine Seitenzahl als
  /// ein Preis. In KASSA rechtfertigt der Zusammenhang die Vermutung, hier
  /// nicht.
  ///
  /// Der Betrag senkt `confidence` nicht, wenn er fehlt. Er ist Beiwerk:
  /// da, wenn er da ist, und sonst kein Mangel.
  static double? _unambiguousAmount(String text) {
    final String s = text.toLowerCase();
    final bool hasCurrencyWord =
        RegExp(r'(^|\s)(euro|euros|cent|cents)(\s|$)|€').hasMatch(s);
    final bool hasTwoDecimals = RegExp(r'\d+[,.]\d{2}(\s|$)').hasMatch(s);

    if (!hasCurrencyWord && !hasTwoDecimals) {
      return null;
    }
    return SpokenNumbers.parseAmount(s);
  }

  // --- Titel ---------------------------------------------------------------

  /// Die Gratis-Engine schreibt Füllwörter mit. Sie am Satzanfang stehen zu
  /// lassen hieße, jede zweite Notiz „also ähm" zu nennen.
  static const Set<String> _fillers = <String>{
    'also',
    'ähm',
    'ähem',
    'öhm',
    'äh',
    'hm',
    'hmm',
    'so',
    'ja',
    'okay',
    'ok',
  };

  static String _stripLeadingFillers(String s) {
    final List<String> tokens = s.split(RegExp(r'\s+'));
    int start = 0;
    while (start < tokens.length &&
        _fillers.contains(_bare(tokens[start].toLowerCase()))) {
      start++;
    }
    return tokens.skip(start).join(' ').trim();
  }

  /// Satzzeichen, die zum Titel gehören. `:` und Zeilenumbruch beenden den
  /// Satz ebenfalls, kommen aber nicht mit.
  static const Set<String> _keptTerminators = <String>{'.', '!', '?'};

  /// Erster Satz. Satzende ist `.`, `!`, `?` — die bleiben stehen —
  /// oder `:` und Zeilenumbruch, die fallen weg. Ohne jedes davon:
  /// gekürzt auf [titleMaxLength] an der letzten Wortgrenze.
  static String? _firstSentence(String s) {
    if (s.isEmpty) {
      return null;
    }

    final Match? end = RegExp(r'[.!?:\n]').firstMatch(s);
    if (end != null) {
      final String terminator = s.substring(end.start, end.start + 1);
      final bool keep = _keptTerminators.contains(terminator);
      final String sentence =
          s.substring(0, keep ? end.start + 1 : end.start).trim();
      if (sentence.isNotEmpty) {
        return _shorten(sentence, sentenceMaxLength);
      }
    }

    return _shorten(s, titleMaxLength);
  }

  static String _shorten(String s, int max) {
    if (s.length <= max) {
      return s;
    }
    final String cut = s.substring(0, max);
    final int lastSpace = cut.lastIndexOf(' ');
    final String base = lastSpace > 0 ? cut.substring(0, lastSpace) : cut;
    return '${base.trimRight()}…';
  }

  // --- Schlagworte ---------------------------------------------------------

  /// Deutsche Stoppwörter ab vier Zeichen — kürzere fallen ohnehin durch
  /// [keywordMinLength]. Bewusst knapp gehalten: eine zu lange Liste
  /// entfernt Wörter, die in einer Notiz gerade das Thema sind.
  static const Set<String> _stopwords = <String>{
    'aber',
    'alle',
    'allem',
    'allen',
    'aller',
    'alles',
    'also',
    'andere',
    'anderen',
    'auch',
    'beim',
    'bereits',
    'bevor',
    'bin',
    'bis',
    'bist',
    'damit',
    'dann',
    'dass',
    'dein',
    'deine',
    'dem',
    'den',
    'denn',
    'der',
    'dere',
    'deren',
    'derer',
    'des',
    'dessen',
    'diese',
    'diesem',
    'diesen',
    'dieser',
    'dieses',
    'doch',
    'dort',
    'durch',
    'eigentlich',
    'ein',
    'eine',
    'einem',
    'einen',
    'einer',
    'eines',
    'einfach',
    'etwas',
    'euch',
    'euer',
    'für',
    'ganz',
    'gegen',
    'gewesen',
    'habe',
    'haben',
    'hast',
    'hatte',
    'hatten',
    'heute',
    'hier',
    'hinter',
    'ich',
    'ihm',
    'ihn',
    'ihnen',
    'ihr',
    'ihre',
    'ihrem',
    'ihren',
    'ihrer',
    'immer',
    'jede',
    'jedem',
    'jeden',
    'jeder',
    'jedes',
    'jetzt',
    'kann',
    'kannst',
    'kein',
    'keine',
    'keinem',
    'keinen',
    'keiner',
    'können',
    'könnte',
    'machen',
    'mehr',
    'mein',
    'meine',
    'meinem',
    'meinen',
    'meiner',
    'mich',
    'mir',
    'mit',
    'muss',
    'musste',
    'nach',
    'nicht',
    'nichts',
    'noch',
    'nun',
    'oder',
    'ohne',
    'schon',
    'sehr',
    'sein',
    'seine',
    'seinem',
    'seinen',
    'seiner',
    'seit',
    'selbst',
    'sich',
    'sind',
    'soll',
    'sollen',
    'sollte',
    'sondern',
    'sonst',
    'über',
    'und',
    'uns',
    'unser',
    'unsere',
    'unter',
    'vom',
    'von',
    'vor',
    'wann',
    'war',
    'waren',
    'warum',
    'was',
    'weil',
    'weiter',
    'welche',
    'welchem',
    'welchen',
    'welcher',
    'wenn',
    'werde',
    'werden',
    'wieder',
    'will',
    'wir',
    'wird',
    'wirst',
    'wo',
    'wollen',
    'wollte',
    'worden',
    'wurde',
    'wurden',
    'zum',
    'zur',
    'zwar',
    'zwischen',
  };

  /// Häufigkeitsanalyse. Gezählt wird kleingeschrieben, ausgegeben wird in
  /// der Schreibweise des ersten Vorkommens. Gleichstand wird alphabetisch
  /// aufgelöst, damit dasselbe Transkript immer dieselbe Liste ergibt —
  /// ein Interpreter, dessen Ausgabe schwankt, ist nicht prüfbar.
  static List<String> _keywords(String s) {
    final Map<String, int> counts = <String, int>{};
    final Map<String, String> firstForm = <String, String>{};

    for (final String token in s.split(RegExp(r'\s+'))) {
      final String bare = _bare(token);
      if (bare.isEmpty) {
        continue;
      }
      final String key = bare.toLowerCase();
      if (key.length < keywordMinLength || _stopwords.contains(key)) {
        continue;
      }
      counts[key] = (counts[key] ?? 0) + 1;
      firstForm.putIfAbsent(key, () => bare);
    }

    final List<String> keys = counts.keys
        .where((String k) => counts[k]! >= keywordMinOccurrences)
        .toList()
      ..sort((String a, String b) {
        final int byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });

    return keys
        .take(keywordMaxCount)
        .map((String k) => firstForm[k]!)
        .toList(growable: false);
  }

  /// Satz- und Sonderzeichen an den Rändern weg, der Kern bleibt.
  static String _bare(String token) =>
      token.replaceAll(RegExp(r'''^[^0-9a-zA-ZäöüÄÖÜß]+'''), '').replaceAll(
            RegExp(r'''[^0-9a-zA-ZäöüÄÖÜß]+$'''),
            '',
          );

  static int _countWords(String s) =>
      s.isEmpty ? 0 : s.split(RegExp(r'\s+')).where(_isNotBlank).length;

  static bool _isNotBlank(String s) => s.trim().isNotEmpty;

  /// Zwei Anteile zu je 0,5. Ein kurzer Text ohne wiederkehrendes Wort ist
  /// kein Fehler — deshalb 0,5 und nicht 0. Nur der leere Text ergibt 0.
  static double _confidence({
    required String? title,
    required List<String> keywords,
  }) {
    double value = 0;
    if (title != null && title.isNotEmpty) {
      value += 0.5;
    }
    if (keywords.isNotEmpty) {
      value += 0.5;
    }
    return value;
  }
}

/// Ergebnis des Interpreters. Landet als JSON in Entry.data.
class VoxResult {
  const VoxResult({
    required this.confidence,
    required this.raw,
    this.title,
    this.keywords = const <String>[],
    this.wordCount = 0,
    this.charCount = 0,
    this.amount,
    this.occurredAt,
  });

  /// Erster Satz, gekürzt. Null, wenn nichts übrig blieb.
  final String? title;

  /// Höchstens fünf, absteigend nach Häufigkeit.
  final List<String> keywords;

  final int wordCount;
  final int charCount;

  /// Betrag in Euro, wenn eindeutig gesprochen. Beiwerk — VOX ordnet
  /// Text, es führt kein Haushaltsbuch. Dafür gibt es KASSA.
  final double? amount;

  /// Zeitpunkt, von dem die Rede war. Null, wenn nichts gesagt wurde
  /// oder wenn beim Auswerten keine Uhr gereicht wurde.
  final DateTime? occurredAt;

  /// 0.0–1.0. Unter 0.5 zeigt die Oberfläche den Rohtext zur Korrektur an,
  /// statt ein halbes Ergebnis als sicher darzustellen.
  final double confidence;

  /// Der Volltext. Die Fluchttür im Kleinen.
  final String raw;

  Map<String, dynamic> toJson() => <String, dynamic>{
        '_interpreter': VoxInterpreter.id,
        '_schema': VoxInterpreter.schemaVersion,
        'title': title,
        'keywords': keywords,
        'wordCount': wordCount,
        'charCount': charCount,
        'amount': amount,
        'occurredAt': occurredAt?.toIso8601String(),
        'confidence': confidence,
        'raw': raw,
      };

  static VoxResult fromJson(Map<String, dynamic> json) => VoxResult(
        title: json['title'] as String?,
        keywords: (json['keywords'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e as String)
            .toList(growable: false),
        wordCount: (json['wordCount'] as num?)?.toInt() ?? 0,
        charCount: (json['charCount'] as num?)?.toInt() ?? 0,
        amount: (json['amount'] as num?)?.toDouble(),
        occurredAt: json['occurredAt'] == null
            ? null
            : DateTime.tryParse(json['occurredAt']! as String),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        raw: json['raw'] as String? ?? '',
      );
}
