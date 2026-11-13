import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_base/shared_base.dart';
import 'package:vox/src/vox_export.dart';
import 'package:vox/src/vox_interpreter.dart';

EntryWithSegments _sample() {
  const VoxInterpreter interpreter = VoxInterpreter();
  const String first = 'Der Vertrag muss geprüft werden.';
  const String second = 'Der Vertrag läuft im März aus.';

  final DateTime at = DateTime(2026, 8, 3, 9, 5);
  final Entry entry = Entry(
    id: 'entry-1',
    type: 'vox',
    createdAt: at,
    updatedAt: at,
    tags: <String>['arbeit'],
    data: interpreter.parse('$first\n\n$second').toJson(),
  );

  return EntryWithSegments(entry, <Segment>[
    Segment(
      id: 's-1',
      entryId: 'entry-1',
      order: 0,
      engine: 'web',
      createdAt: at,
      transcript: first,
      mediaPath: 'blob:eins',
    ),
    Segment(
      id: 's-2',
      entryId: 'entry-1',
      order: 1,
      engine: 'web',
      createdAt: DateTime(2026, 8, 3, 14, 30),
      transcript: second,
    ),
  ]);
}

void main() {
  const VoxExport export = VoxExport();

  group('Markdown — Empfänger: der Nutzer selbst, später', () {
    test('Frontmatter trägt Titel, Wortzahl und Schlagworte', () {
      final String md = export.markdown(_sample());
      expect(md.startsWith('---\n'), isTrue);
      expect(md, contains('id: entry-1'));
      expect(md, contains('typ: vox'));
      expect(md, contains('woerter: 11'));
      expect(md, contains('schlagworte: ["Vertrag"]'));
    });

    test('Schlagworte werden zu [[Verweisen]]', () {
      expect(export.markdown(_sample()), contains('[[Vertrag]]'));
    });

    test('beide Segmente stehen drin, in Reihenfolge', () {
      final String md = export.markdown(_sample());
      final int a = md.indexOf('Der Vertrag muss geprüft werden.');
      final int b = md.indexOf('Der Vertrag läuft im März aus.');
      expect(a, greaterThan(-1));
      expect(b, greaterThan(a), reason: 'Reihenfolge der Kette bleibt');
    });

    test('Segment ohne Text bricht den Export nicht', () {
      final EntryWithSegments e = EntryWithSegments(
        _sample().entry,
        <Segment>[
          Segment(
            id: 's-leer',
            entryId: 'entry-1',
            order: 0,
            engine: 'web',
            createdAt: DateTime(2026, 8, 3),
          ),
        ],
      );
      expect(export.markdown(e), contains('(kein Text)'));
    });
  });

  group('Kontextbündel — Empfänger: ein KI-Modell', () {
    test('Schema-Kopf, Auftrag und Token-Schätzung sind vorhanden', () {
      final String b = export.aiBundle(<EntryWithSegments>[_sample()]);
      expect(b, contains('## Schema'));
      expect(b, contains('## Auftrag'));
      expect(b, contains('geschätzte Token:'));
      expect(b, contains('Einträge (1)'));
    });

    test('eigener Auftrag ersetzt den vorformulierten', () {
      final String b = export.aiBundle(
        <EntryWithSegments>[_sample()],
        auftrag: 'Nenne nur die Termine.',
      );
      expect(b, contains('Nenne nur die Termine.'));
    });
  });

  group('JSON und Text — Empfänger: andere Software', () {
    test('JSON ist gültig und trägt Zeitstempel je Segment', () {
      final Object? decoded =
          jsonDecode(export.json(<EntryWithSegments>[_sample()]));
      expect(decoded, isA<Map<String, dynamic>>());

      final Map<String, dynamic> map = decoded! as Map<String, dynamic>;
      expect(map['app'], 'vox');
      final List<dynamic> entries = map['eintraege'] as List<dynamic>;
      expect(entries.length, 1);

      final Map<String, dynamic> first =
          entries.first as Map<String, dynamic>;
      final List<dynamic> segments = first['segmente'] as List<dynamic>;
      expect(segments.length, 2);
      expect(
        (segments.first as Map<String, dynamic>)['zeit'],
        '2026-08-03T09:05:00.000',
      );
    });

    test('Nur-Text ist der Volltext, sonst nichts', () {
      final String txt = export.plainText(_sample());
      expect(txt, contains('Der Vertrag muss geprüft werden.'));
      expect(txt, isNot(contains('---')));
    });
  });

  group('Fluchttür', () {
    test('enthält Eintrag und alle Segmente, gültiges JSON', () {
      final Object? decoded =
          jsonDecode(export.escapeHatch(<EntryWithSegments>[_sample()]));
      final Map<String, dynamic> map = decoded! as Map<String, dynamic>;
      expect(map['app'], 'vox');
      expect(map['format'], 'app-fabrik-fluchttuer/1');

      final List<dynamic> list = map['eintraege'] as List<dynamic>;
      final Map<String, dynamic> one = list.first as Map<String, dynamic>;
      expect((one['segments'] as List<dynamic>).length, 2);
      expect(
        ((one['entry'] as Map<String, dynamic>)['data']
            as Map<String, dynamic>)['raw'],
        isNotNull,
        reason: 'Der Rohtext muss durch die Fluchttür kommen',
      );
    });

    test('leere Datenlage liefert eine gültige, leere Datei', () {
      final Object? decoded = jsonDecode(export.escapeHatch(
        <EntryWithSegments>[],
      ));
      expect((decoded! as Map<String, dynamic>)['eintraege'], isEmpty);
    });
  });

  group('PDF — Empfänger ist der Nutzer selbst, später', () {
    test('keine Behörden-Tabelle, sondern Protokoll-Optik', () {
      final PdfRecipient r =
          export.pdfRecipientFor(<EntryWithSegments>[_sample()]);
      expect(r.name, 'Eigenes Archiv');
      expect(r.columns, isEmpty, reason: 'Fließtext, keine Spalten');
      expect(r.showSegmentTimes, isTrue, reason: 'Uhrzeit je Segment');
    });

    test('Untertitel ist der Zeitraum, nicht Werbetext', () {
      final PdfRecipient r =
          export.pdfRecipientFor(<EntryWithSegments>[_sample()]);
      expect(r.subline, '03.08.2026');
    });

    test('im Fuß stehen die Schlagworte', () {
      final PdfRecipient r =
          export.pdfRecipientFor(<EntryWithSegments>[_sample()]);
      expect(r.footer, contains('vertrag'));
    });

    test('ohne Einträge bleibt der Fuß lesbar statt leer', () {
      final PdfRecipient r = export.pdfRecipientFor(<EntryWithSegments>[]);
      expect(r.subline, 'Keine Einträge');
      expect(r.footer, isNotEmpty);
    });
  });
}
