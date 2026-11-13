import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vox/main.dart' as app;

/// Hauptablauf aus WF-01 Tag 5 / test-loop-free Stufe 1: die echte App, das
/// echte Mikrofon (im Browser ein Testgerät), die echte Datenbank — nur die
/// Spracherkennung ist der Stub (STT_ENGINE=web), damit die Texte fest sind.
///
/// Die Screenshots 01–06 sind die Store-Bilder; store-assets nimmt sie aus
/// dem CI-Artefakt `screenshots-vox`.
Future<void> main() async {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Hauptablauf: aufnehmen, erweitern, wiederfinden',
      (WidgetTester t) async {
    if (!kIsWeb && Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
    }

    unawaited(app.main());
    await _until(t, find.text('Noch nichts aufgenommen.'));
    await _shot(binding, t, '01-start');

    // --- Erste Aufnahme -------------------------------------------------
    await _record(t, binding, shotWhileRecording: '02-aufnahme-laeuft');
    await _until(t, find.text('zweiundzwanzig fünfzig bei Rewe'));
    expect(
      find.byTooltip('Diesen Eintrag erweitern'),
      findsOneWidget,
      reason: 'Nach der ersten Aufnahme existiert genau ein Eintrag.',
    );
    await _shot(binding, t, '03-erster-eintrag');

    // --- Denselben Eintrag erweitern -----------------------------------
    await t.tap(find.byTooltip('Diesen Eintrag erweitern'));
    await _until(t, find.text('Fertig'));
    await _pause(t, 1200);
    await t.tap(find.text('Fertig'));
    await _until(t, find.text('Aufnehmen'));
    await _pause(t, 800);
    expect(
      find.byTooltip('Diesen Eintrag erweitern'),
      findsOneWidget,
      reason: 'Erweitern legt keinen zweiten Eintrag an, sondern ein '
          'zweites Segment am bestehenden.',
    );
    await _shot(binding, t, '04-erweitert');

    // --- Zweiter Eintrag, damit die Liste eine Liste ist ----------------
    await _record(t, binding);
    // Der Eintrag erscheint sofort, sein Text erst nach der Erkennung —
    // auf den TEXT warten, sonst zeigt das Bild „Notiz vom …".
    await _until(t, find.textContaining('Idee für die App'));
    await _shot(binding, t, '05-liste');

    // --- Suche ----------------------------------------------------------
    // Im Browser hängt der Integrationstest an der ECHTEN Tastatur; weder
    // enterText noch die Test-Eingabe erreichen dort das Feld. Deshalb den
    // Begriff direkt setzen und den Änderungs-Callback auslösen — geprüft
    // wird dieselbe Suchlogik und dieselbe Liste.
    final TextField field = t.widget<TextField>(find.byType(TextField));
    field.controller!.text = 'Rewe';
    field.onChanged!('Rewe');
    await _until(
      t,
      find.byTooltip('Diesen Eintrag erweitern'),
      exactly: 1,
    );
    expect(find.textContaining('Idee für die App'), findsNothing);

    // --- Detail: zwei Segmente, beide abspielbar ------------------------
    // Nach dem Erweitern umfasst der Titel beide Segmente — nach dem Anfang
    // suchen, nicht nach dem ganzen Text.
    await t.tap(find.textContaining('zweiundzwanzig fünfzig').first);
    await _until(t, find.text('Eintrag'));
    await _until(t, find.byTooltip('Abspielen'), count: 2);
    expect(find.textContaining('Termin nächsten Dienstag'), findsWidgets);
    await _shot(binding, t, '06-detail');
  });
}

/// Aufnehmen, kurz sprechen lassen, beenden.
Future<void> _record(
  WidgetTester t,
  IntegrationTestWidgetsFlutterBinding binding, {
  String? shotWhileRecording,
}) async {
  await t.tap(find.text('Aufnehmen'));
  await _until(t, find.text('Fertig'));
  await _pause(t, 1200);
  if (shotWhileRecording != null) {
    await _shot(binding, t, shotWhileRecording);
  }
  await t.tap(find.text('Fertig'));
  await _until(t, find.text('Aufnehmen'));
}

/// Pumpt, bis [finder] [count]-mal da ist. Nie pumpAndSettle: Solange die
/// Wellenform oder ein Ladekreisel läuft, „settled" die App nie.
///
/// [exactly] wartet auf genau diese Anzahl — etwa bis eine Suche die Liste
/// eingeschränkt hat.
Future<void> _until(
  WidgetTester t,
  Finder finder, {
  int count = 1,
  int? exactly,
}) async {
  final DateTime end = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 100));
    final int n = finder.evaluate().length;
    if (exactly != null ? n == exactly : n >= count) {
      return;
    }
  }
  throw TestFailure(
    'Nach 20 s nicht erreicht: $finder — erwartet '
    '${exactly != null ? 'genau $exactly' : 'mindestens $count'}, '
    'gefunden ${finder.evaluate().length}',
  );
}

Future<void> _pause(WidgetTester t, int ms) async {
  final DateTime end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Screenshot mit stabilem Namen; store-assets sortiert nach der Nummer.
Future<void> _shot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester t,
  String name,
) async {
  await t.pump();
  await binding.takeScreenshot(name);
}
