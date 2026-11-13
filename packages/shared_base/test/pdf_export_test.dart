import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_base/shared_base.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final DateTime t = DateTime(2026, 11, 13, 9, 30);

  EntryWithSegments entry(String title, String text) => EntryWithSegments(
        Entry(id: 'a', type: 'test', title: title, createdAt: t, updatedAt: t),
        <Segment>[
          Segment(
            id: 's',
            entryId: 'a',
            order: 0,
            transcript: text,
            engine: 'web',
            createdAt: t,
          ),
        ],
      );

  /// Baut das PDF und fängt alles ab, was das pdf-Paket über fehlende
  /// Zeichen meldet — es bricht dabei nicht ab, sondern lässt sie still weg.
  Future<(Uint8List, List<String>)> build(EntryWithSegments e) async {
    final List<String> log = <String>[];
    final Uint8List bytes = await runZoned(
      () => const PdfExport().build(
        entries: <EntryWithSegments>[e],
        recipient: const PdfRecipient(
          name: 'Archiv',
          headline: 'Sprachnotizen',
          subline: '13.11.2026',
          footer: 'Test · Fuß',
        ),
      ),
      zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) =>
            log.add(line),
      ),
    );
    return (bytes, log);
  }

  test('Euro, deutsche Anführungszeichen und Gedankenstrich kommen an',
      () async {
    final (Uint8List bytes, List<String> log) = await build(
      entry('Rechnung „Werkstatt" — 184,90 €', 'Zahlung → erledigt, 22,50 €'),
    );
    expect(
      log.where((String l) => l.contains('Unable to find a font')),
      isEmpty,
      reason: log.join('\n'),
    );
    expect(log.where((String l) => l.contains('no Unicode support')), isEmpty);
    expect(bytes.length, greaterThan(1000));
  });

  test('Die Schrift ist eingebettet, nicht nur benannt', () async {
    final (Uint8List bytes, _) = await build(entry('Titel', 'Text'));
    expect(
      latin1.decode(bytes, allowInvalid: true),
      contains('LiberationSans'),
    );
  });

  test('Ein PDF ist ein PDF', () async {
    final (Uint8List bytes, _) = await build(entry('Titel', 'Text'));
    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
  });
}
