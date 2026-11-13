import 'package:capture_core/capture_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mediaKindOf', () {
    test('ohne Pfad keine Aufnahme', () {
      expect(mediaKindOf(null), MediaKind.none);
      expect(mediaKindOf(''), MediaKind.none);
    });

    test('Adressen spielt der Player selbst', () {
      for (final String p in <String>[
        'blob:https://x.github.io/123',
        'https://example.org/a.m4a',
        'data:audio/wav;base64,AAAA',
      ]) {
        expect(mediaKindOf(p), MediaKind.url, reason: p);
        expect(mediaKindOf(p, web: true), MediaKind.url, reason: p);
      }
    });

    test('im Browser ist jeder andere Pfad ein Vault-Pfad', () {
      expect(mediaKindOf('vox/abc.webm', web: true), MediaKind.vault);
    });

    test('auf dem Gerät: absolute Pfade sind Dateien', () {
      expect(
        mediaKindOf('/data/user/0/de.zeta.vox/app_flutter/a.m4a', web: false),
        MediaKind.file,
      );
      expect(mediaKindOf('vox/abc.m4a', web: false), MediaKind.vault);
    });
  });

  testWidgets('ohne Aufnahme zeichnet der Knopf nichts',
      (WidgetTester t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SegmentPlayButton(mediaPath: null)),
      ),
    );
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('mit Aufnahme ein Abspielknopf', (WidgetTester t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SegmentPlayButton(mediaPath: 'vox/a.webm')),
      ),
    );
    expect(find.byTooltip('Abspielen'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });
}
