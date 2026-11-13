import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox/src/detail_screen.dart';
import 'package:vox/src/home_screen.dart';
import 'package:vox/src/vox_theme.dart';

import '../flutter_test_config.dart';
import '../support/fake_store.dart';

/// Sechs Referenzbilder aus WF-01 Tag 5: Start, Liste, Detail — je hell und
/// dunkel. Die Bildschirme sind die echten, die Daten fest.
///
/// Neu erzeugen NUR nach Sichtprüfung:
///   dart run melos run test-golden-update
/// Gelten ausschließlich unter Linux (CI und Sandbox) — Schriften werden auf
/// macOS und Windows anders gerastert.
void main() {
  for (final (String name, ThemeMode mode) in <(String, ThemeMode)>[
    ('hell', ThemeMode.light),
    ('dunkel', ThemeMode.dark),
  ]) {
    group(name, () {
      late FakeVox fake;

      /// Datenbank öffnen und befüllen — in echter Zeit, sonst wartet drift
      /// auf Timer der simulierten Testzeit.
      Future<String?> open(WidgetTester t, {bool seed = true}) async {
        fake = (await t.runAsync(FakeVox.open))!;
        return seed ? t.runAsync(fake.seed) : null;
      }

      Future<void> show(WidgetTester t, Widget screen) async {
        t.view
          ..physicalSize = kGoldenSurface
          ..devicePixelRatio = 1.0;
        addTearDown(t.view.reset);
        await t.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: VoxTheme.light(),
            darkTheme: VoxTheme.dark(),
            themeMode: mode,
            home: screen,
          ),
        );
        // Datenbankabfragen laufen in echter Zeit, die Oberfläche in
        // Testzeit. Abwechselnd beides — begrenzt, nie pumpAndSettle: das
        // wartet bei jeder Dauer-Animation (Ladekreisel) ewig.
        for (int i = 0; i < 10; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await t.pump(const Duration(milliseconds: 50));
        }
      }

      testWidgets('Start — noch nichts aufgenommen', (WidgetTester t) async {
        await open(t, seed: false);
        await show(t, HomeScreen(store: fake.store, recorder: FakeRecorder()));
        expect(find.text('Noch nichts aufgenommen.'), findsOneWidget);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/start_$name.png'),
        );
        // Am Ende des Tests, nicht in addTearDown: Flutter prüft auf
        // hängende Timer, BEVOR Aufräum-Callbacks laufen.
        await _close(t, fake);
      });

      testWidgets('Liste — drei Einträge', (WidgetTester t) async {
        await open(t);
        await show(t, HomeScreen(store: fake.store, recorder: FakeRecorder()));
        expect(find.byTooltip('Diesen Eintrag erweitern'), findsNWidgets(3));
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/liste_$name.png'),
        );
        // Am Ende des Tests, nicht in addTearDown: Flutter prüft auf
        // hängende Timer, BEVOR Aufräum-Callbacks laufen.
        await _close(t, fake);
      });

      testWidgets('Detail — zwei Segmente mit Abspielknopf',
          (WidgetTester t) async {
        final String id = (await open(t))!;
        await show(
          t,
          DetailScreen(
            store: fake.store,
            entryId: id,
            recorder: FakeRecorder(),
          ),
        );
        expect(find.byTooltip('Abspielen'), findsNWidgets(2));
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/detail_$name.png'),
        );
        // Am Ende des Tests, nicht in addTearDown: Flutter prüft auf
        // hängende Timer, BEVOR Aufräum-Callbacks laufen.
        await _close(t, fake);
      });
    });
  }
}

/// Abbauen in der richtigen Reihenfolge: Bildschirm weg, die Aufräum-Timer
/// von drift in Testzeit ablaufen lassen, DANN die Datenbank schließen.
/// Andersherum wartet close() ewig auf einen Timer, der nie feuert.
Future<void> _close(WidgetTester t, FakeVox fake) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 1));
  await t.runAsync(fake.close);
}
