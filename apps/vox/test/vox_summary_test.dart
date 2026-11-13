import 'package:flutter_test/flutter_test.dart';
import 'package:shared_base/shared_base.dart';
import 'package:vox/src/insights_screen.dart';
import 'package:vox/src/vox_interpreter.dart';

Entry _entry(String text, DateTime at) {
  const VoxInterpreter interpreter = VoxInterpreter();
  return Entry(
    id: 'e-${at.microsecondsSinceEpoch}',
    type: 'vox',
    createdAt: at,
    updatedAt: at,
    data: interpreter.parse(text).toJson(),
  );
}

void main() {
  group('VoxSummary — die Rechnung hinter der Auswertung', () {
    test('addiert die Wörter aller Einträge', () {
      final VoxSummary s = VoxSummary.of(<Entry>[
        _entry('eins zwei drei', DateTime(2026, 8, 3)),
        _entry('vier fünf', DateTime(2026, 8, 4)),
      ]);
      expect(s.entryCount, 2);
      expect(s.totalWords, 5);
    });

    test('gruppiert nach Kalenderwoche, nicht nach Tag', () {
      // 3.8.2026 ist ein Montag, 9.8.2026 der Sonntag derselben Woche.
      final VoxSummary s = VoxSummary.of(<Entry>[
        _entry('eins zwei', DateTime(2026, 8, 3)),
        _entry('drei', DateTime(2026, 8, 9)),
        _entry('vier', DateTime(2026, 8, 10)),
      ]);
      expect(s.byWeek.length, 2, reason: 'Zwei Wochen, nicht drei Tage');
      expect(s.byWeek[VoxSummary.weekKey(DateTime(2026, 8, 3))], 3);
      expect(s.byWeek[VoxSummary.weekKey(DateTime(2026, 8, 10))], 1);
    });

    test('Sonntag gehört zur Woche davor, Montag beginnt die neue', () {
      expect(
        VoxSummary.weekKey(DateTime(2026, 8, 9)),
        VoxSummary.weekKey(DateTime(2026, 8, 3)),
      );
      expect(
        VoxSummary.weekKey(DateTime(2026, 8, 10)),
        isNot(VoxSummary.weekKey(DateTime(2026, 8, 9))),
      );
    });

    test('Wochenschlüssel sortiert alphabetisch = chronologisch', () {
      final List<String> keys = <String>[
        VoxSummary.weekKey(DateTime(2026, 1, 5)),
        VoxSummary.weekKey(DateTime(2026, 8, 3)),
        VoxSummary.weekKey(DateTime(2026, 12, 21)),
      ];
      final List<String> sorted = List<String>.of(keys)..sort();
      expect(sorted, keys);
    });

    test('zählt Schlagworte über alle Einträge, häufigstes zuerst', () {
      final VoxSummary s = VoxSummary.of(<Entry>[
        _entry('Vertrag prüfen. Vertrag läuft aus.', DateTime(2026, 8, 3)),
        _entry('Vertrag lesen. Vertrag unterschreiben.', DateTime(2026, 8, 4)),
        _entry('Termin schieben. Termin bestätigen.', DateTime(2026, 8, 5)),
      ]);
      expect(s.topKeywords.first.key, 'vertrag');
      expect(s.topKeywords.first.value, 2);
    });

    test('leere Liste rechnet nicht durch null', () {
      final VoxSummary s = VoxSummary.of(<Entry>[]);
      expect(s.totalWords, 0);
      expect(s.peakWeekWords, 0);
      expect(s.spokenMinutesEstimate, 0);
      expect(s.spokenMinutesLabel, '0 Minuten');
      expect(s.topKeywords, isEmpty);
    });

    test('die große Zahl rundet kurze Aufnahmen nicht auf null Minuten', () {
      final VoxSummary kurz = VoxSummary.of(<Entry>[
        _entry('nur drei wörter', DateTime(2026, 8, 3)),
      ]);
      expect(kurz.spokenMinutesLabel, 'unter 1 Minute');
    });

    test('gesprochen gegen getippt — die Zahl, die das Versprechen trägt', () {
      final VoxSummary s = VoxSummary.of(<Entry>[
        _entry(
          List<String>.generate(1300, (int i) => 'wort$i').join(' '),
          DateTime(2026, 8, 3),
        ),
      ]);
      expect(s.totalWords, 1300);
      expect(s.spokenMinutesEstimate, 10);
      expect(s.typedMinutesEstimate, 33);
      expect(s.spokenMinutesLabel, '10 Minuten');
    });

    test('genau eine Minute wird im Singular geschrieben', () {
      final VoxSummary s = VoxSummary.of(<Entry>[
        _entry(
          List<String>.generate(130, (int i) => 'wort$i').join(' '),
          DateTime(2026, 8, 3),
        ),
      ]);
      expect(s.spokenMinutesLabel, '1 Minute');
    });

    test('Eintrag ohne Interpreter-Daten zählt 0 statt zu werfen', () {
      final VoxSummary s = VoxSummary.of(<Entry>[
        Entry(
          id: 'alt',
          type: 'vox',
          createdAt: DateTime(2026, 8, 3),
          updatedAt: DateTime(2026, 8, 3),
        ),
      ]);
      expect(s.entryCount, 1);
      expect(s.totalWords, 0);
    });
  });
}
