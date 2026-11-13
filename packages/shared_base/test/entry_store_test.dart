import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_base/shared_base.dart';

void main() {
  late AppDatabase db;
  late EntryStore store;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    store = EntryStore(db, type: 'test');
  });

  tearDown(() async => db.close());

  test('Eintrag ist jederzeit erweiterbar — Reihenfolge bleibt', () async {
    final Entry e = await store.createEntry(title: 'Kette');
    await store.appendSegment(e.id, transcript: 'erster', engine: 'web');
    await store.appendSegment(e.id, transcript: 'zweiter', engine: 'web');
    await store.appendSegment(e.id, transcript: 'dritter', engine: 'web');

    final EntryWithSegments? loaded = await store.byId(e.id);
    expect(loaded, isNotNull);
    expect(loaded!.segments.map((Segment s) => s.order), <int>[0, 1, 2]);
    expect(
      loaded.segments.map((Segment s) => s.transcript),
      <String>['erster', 'zweiter', 'dritter'],
    );
    expect(loaded.fullText, 'erster\n\nzweiter\n\ndritter');
  });

  test('Neu-Transkription ersetzt Text und merkt sich die Engine', () async {
    final Entry e = await store.createEntry();
    final Segment s = await store.appendSegment(
      e.id,
      transcript: 'zwo drei',
      engine: 'platform',
    );

    await store.retranscribe(s.id, transcript: 'zwei drei', engine: 'parakeet');

    final Segment? after = await store.segmentById(s.id);
    expect(after!.transcript, 'zwei drei');
    expect(after.engine, 'parakeet');
  });

  test('Volltextsuche findet über Segmentgrenzen', () async {
    final Entry a = await store.createEntry(title: 'A');
    await store.appendSegment(
      a.id,
      transcript: 'Milch und Brot',
      engine: 'web',
    );
    final Entry b = await store.createEntry(title: 'B');
    await store.appendSegment(b.id, transcript: 'Zement', engine: 'web');

    final List<Entry> hits = await store.search('Brot');
    expect(hits.map((Entry e) => e.id), <String>[a.id]);
  });

  test('Löschen entfernt Segmente und Suchindex', () async {
    final Entry e = await store.createEntry();
    await store.appendSegment(e.id, transcript: 'weg damit', engine: 'web');
    await store.deleteEntry(e.id);

    expect(await store.byId(e.id), isNull);
    expect(await store.search('weg'), isEmpty);
  });

  group('FileVault', () {
    test('Ablegen liefert einen Pfad, der zurücklesbar ist', () async {
      final IndexedDbVault vault = IndexedDbVault(prefix: 'test');
      final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);

      final String path = await vault.put(bytes, extension: 'm4a');
      expect(await vault.exists(path), isTrue);
      expect(await vault.get(path), bytes);
      expect(path, endsWith('.m4a'));
    });

    test('list und usedBytes tragen die Fluchttür', () async {
      final IndexedDbVault vault = IndexedDbVault(prefix: 'test');
      await vault.put(Uint8List(10), extension: 'm4a');
      await vault.put(Uint8List(20), extension: 'm4a');

      expect(await vault.list(), hasLength(2));
      expect(await vault.usedBytes(), 30);
    });

    test('Löschen entfernt die Datei', () async {
      final IndexedDbVault vault = IndexedDbVault(prefix: 'test');
      final String path = await vault.put(Uint8List(4), extension: 'm4a');
      await vault.delete(path);

      expect(await vault.exists(path), isFalse);
      expect(await vault.get(path), isNull);
    });
  });
}
