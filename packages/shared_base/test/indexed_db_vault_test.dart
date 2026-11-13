import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_base/shared_base.dart';

void main() {
  late IndexedDbVault vault;

  setUp(() => vault = IndexedDbVault(prefix: 'vox'));

  Uint8List bytes(int n) => Uint8List.fromList(List<int>.generate(n, (i) => i));

  test('put vergibt einen eigenen Pfad mit Endung', () async {
    final String path = await vault.put(bytes(4), extension: 'webm');
    expect(path, startsWith('vox/'));
    expect(path, endsWith('.webm'));
    expect(vault.owns(path), isTrue);
    expect(vault.owns('blob:http://x/123'), isFalse);
  });

  test('Bytes kommen unverändert zurück', () async {
    final String path = await vault.put(bytes(300), extension: 'm4a');
    expect(await vault.get(path), bytes(300));
    expect(await vault.exists(path), isTrue);
  });

  test('Unbekannter Pfad liefert null statt zu werfen', () async {
    expect(await vault.get('vox/gibt-es-nicht.webm'), isNull);
    expect(await vault.exists('vox/gibt-es-nicht.webm'), isFalse);
  });

  test('list, usedBytes und delete arbeiten zusammen', () async {
    final String a = await vault.put(bytes(10), extension: 'webm');
    final String b = await vault.put(bytes(20), extension: 'webm');
    expect(await vault.list(), unorderedEquals(<String>[a, b]));
    expect(await vault.usedBytes(), 30);

    await vault.delete(a);
    expect(await vault.list(), <String>[b]);
    expect(await vault.usedBytes(), 20);
  });

  test('Ohne Browser ist die Ablage ehrlich flüchtig', () async {
    expect(await vault.isPersistent, isFalse);
  });

  test('Fluchttür-ZIP findet Aufnahmen aus der Ablage', () async {
    Registry.instance.reset();
    Registry.instance.bind<FileVault>(vault);
    final String path = await vault.put(bytes(64), extension: 'webm');
    final DateTime t = DateTime(2026, 11, 13);
    final Uint8List zip = await const VaultExport().toZip(
      <EntryWithSegments>[
        EntryWithSegments(
          Entry(id: 'e', type: 'vox', createdAt: t, updatedAt: t),
          <Segment>[
            Segment(
              id: 's',
              entryId: 'e',
              order: 0,
              mediaPath: path,
              engine: 'platform',
              createdAt: t,
            ),
          ],
        ),
      ],
      app: 'vox',
    );
    final String listing = String.fromCharCodes(zip);
    expect(listing, contains('medien/e/0_'));
    expect(listing, isNot(contains('fehlend.txt')));
  });

  group('mimeForExtension', () {
    final Map<String, String> cases = <String, String>{
      'vox/a.webm': 'audio/webm',
      'vox/a.m4a': 'audio/mp4',
      'vox/a.wav': 'audio/wav',
      '/data/x/a.M4A': 'audio/mp4',
      'vox/a.bin': 'application/octet-stream',
    };
    cases.forEach((String path, String mime) {
      test('$path → $mime', () => expect(mimeForExtension(path), mime));
    });
  });
}
