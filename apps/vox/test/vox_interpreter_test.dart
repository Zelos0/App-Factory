import 'package:flutter_test/flutter_test.dart';
import 'package:vox/src/vox_interpreter.dart';

void main() {
  const VoxInterpreter interpreter = VoxInterpreter();

  group('zwölf realistische Beispielsätze', () {
    // Die Sätze stehen in docs/baupläne/vox.md Abschnitt 8.
    // Zusammensetzung nach TESTLEITER.md Stufe 0:
    // vier normal, drei Engine-Fehler, zwei unvollständig, zwei Grenzfall,
    // einer leer.

    test('1 normal — zwei Sätze, wiederkehrendes Wort', () {
      final VoxResult r = interpreter.parse(
        'Ich muss morgen den Vertrag prüfen. Der Vertrag läuft im März aus.',
      );
      expect(r.title, 'Ich muss morgen den Vertrag prüfen.');
      expect(
        r.keywords.map((String k) => k.toLowerCase()),
        contains('vertrag'),
      );
      expect(r.confidence, 1.0);
    });

    test('2 normal — Doppelpunkt beendet den Titel, ohne mitzukommen', () {
      final VoxResult r = interpreter.parse(
        'Idee für die App: Die App soll offline laufen. '
        'Offline ist das Argument.',
      );
      expect(r.title, 'Idee für die App');
      expect(
        r.keywords.map((String k) => k.toLowerCase()),
        contains('offline'),
      );
      expect(r.confidence, 1.0);
    });

    test('3 normal — Schlagwort trotz Groß- und Kleinschreibung', () {
      final VoxResult r =
          interpreter.parse('Einkaufen nicht vergessen. Einkaufen am Freitag.');
      expect(r.title, 'Einkaufen nicht vergessen.');
      expect(
        r.keywords.map((String k) => k.toLowerCase()),
        contains('einkaufen'),
      );
    });

    test('4 normal — ein einziger Satz, Wortzahl stimmt', () {
      final VoxResult r = interpreter.parse(
        'Der Termin beim Steuerberater ist verschoben worden '
        'auf nächste Woche.',
      );
      expect(
        r.title,
        'Der Termin beim Steuerberater ist verschoben worden auf nächste '
            'Woche.',
      );
      expect(r.wordCount, 10);
    });

    test('5 Engine-Fehler — Füllwörter am Anfang fallen weg', () {
      final VoxResult r = interpreter.parse(
        'also ähm ich wollte sagen dass das Projekt Projekt fertig ist',
      );
      expect(r.title, isNotNull);
      expect(r.title!.startsWith('ich wollte'), isTrue,
          reason: 'Füllwörter "also" und "ähm" müssen weg sein');
      expect(
        r.keywords.map((String k) => k.toLowerCase()),
        contains('projekt'),
      );
    });

    test('6 Engine-Fehler — kein Satzzeichen, alles klein', () {
      final VoxResult r = interpreter
          .parse('hm die besprechung war gut die besprechung war lang');
      expect(r.title, isNotNull);
      expect(r.title!.startsWith('die besprechung'), isTrue);
      expect(
        r.keywords.map((String k) => k.toLowerCase()),
        contains('besprechung'),
      );
    });

    test('7 Engine-Fehler — fehlender Umlaut wird nicht korrigiert', () {
      final VoxResult r = interpreter.parse(
        'Muss noch die Rueckmeldung schreiben. Rueckmeldung bis Montag.',
      );
      expect(r.title, 'Muss noch die Rueckmeldung schreiben.');
      expect(
        r.keywords.map((String k) => k.toLowerCase()),
        contains('rueckmeldung'),
        reason: 'Der Interpreter rät nicht, er zählt',
      );
    });

    test('8 unvollständig — ein Wort, kein Schlagwort', () {
      final VoxResult r = interpreter.parse('Notiz');
      expect(r.title, 'Notiz');
      expect(r.keywords, isEmpty);
      expect(r.confidence, 0.5, reason: 'Kurz ist kein Fehler');
    });

    test('9 unvollständig — nur ein Füllwort bleibt nichts übrig', () {
      final VoxResult r = interpreter.parse('ähm');
      expect(r.title, isNull);
      expect(r.confidence, 0.0);
    });

    test('10 Grenzfall — 900 Wörter ohne Satzzeichen', () {
      final String long =
          List<String>.generate(900, (int i) => 'wort$i').join(' ');
      final VoxResult r = interpreter.parse(long);
      expect(r.wordCount, 900);
      expect(r.title, isNotNull);
      expect(r.title!.length, lessThanOrEqualTo(VoxInterpreter.titleMaxLength));
      expect(r.title!.endsWith('…'), isTrue);
    });

    test('11 Grenzfall — nur Sonderzeichen, der Interpreter wirft nicht', () {
      final VoxResult r = interpreter.parse('§§ 1,2,3 — *** ###');
      expect(r.title, '§§ 1,2,3 — *** ###');
      expect(r.keywords, isEmpty);
    });

    test('12 leer — alle Felder leer, nichts wirft', () {
      final VoxResult r = interpreter.parse('');
      expect(r.title, isNull);
      expect(r.keywords, isEmpty);
      expect(r.wordCount, 0);
      expect(r.charCount, 0);
      expect(r.confidence, 0.0);
    });
  });

  group('Eigenschaften des Interpreters', () {
    test('Vertrauenswert sinkt, wenn Schlagworte fehlen', () {
      expect(
        interpreter
            .parse('Ich muss morgen den Vertrag prüfen. Der Vertrag läuft aus.')
            .confidence,
        1.0,
      );
      expect(interpreter.parse('irgendwas').confidence, lessThan(1.0));
      expect(interpreter.parse('').confidence, 0.0);
    });

    test('Ergebnis überlebt die JSON-Runde', () {
      final VoxResult before = interpreter.parse(
        'Der Vertrag muss geprüft werden. Der Vertrag läuft aus.',
      );
      final VoxResult after = VoxResult.fromJson(before.toJson());
      expect(after.title, before.title);
      expect(after.keywords, before.keywords);
      expect(after.wordCount, before.wordCount);
      expect(after.charCount, before.charCount);
      expect(after.confidence, before.confidence);
      expect(after.raw, before.raw);
    });

    test('zustandsfrei — zweimal derselbe Satz, gleiches Ergebnis', () {
      const String text = 'Notiz zur Besprechung. Besprechung';
      final VoxResult a = interpreter.parse(text);
      final VoxResult b = interpreter.parse(text);
      expect(a.toJson(), b.toJson());
    });

    test('raw trägt den Text unverändert, auch mit Leerraum', () {
      const String text = '  Ein Gedanke.  ';
      expect(interpreter.parse(text).raw, text);
      expect(interpreter.parse(text).charCount, 'Ein Gedanke.'.length);
    });

    test('höchstens fünf Schlagworte, absteigend nach Häufigkeit', () {
      final VoxResult r = interpreter.parse(
        'alpha alpha alpha beta beta gamma gamma delta delta '
        'epsilon epsilon zeta zeta',
      );
      expect(r.keywords.length, VoxInterpreter.keywordMaxCount);
      expect(r.keywords.first.toLowerCase(), 'alpha');
    });

    test('VOX erkennt bewusst KEINE Beträge — das ist KASSAs Aufgabe', () {
      final VoxResult r = interpreter.parse('zweiundzwanzig fünfzig bei Rewe');
      expect(r.toJson().containsKey('amount'), isFalse);
      expect(r.toJson().containsKey('merchant'), isFalse);
      expect(r.raw, 'zweiundzwanzig fünfzig bei Rewe');
    });
  });
}
