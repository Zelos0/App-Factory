---
name: test-loop-free
description: Richtet die vierstufige Prüfleiter aus TESTLEITER.md ein — Golden-Einrichtung samt fake_store.dart, Web-Integrationstest mit Screenshots, Firebase-Test-Lab-Lauf auf echter Hardware und die stillgelegte Vorbereitung für TestFlight — ohne Gerät, ohne Terminal, ohne bezahltes Konto. Auslösen mit "richte die Tests ein", "Teststufe 0 einrichten", "Golden-Tests aufsetzen", "Integrationstest mit Screenshots", "Test Lab anschalten", "Prüfliste fürs iPhone", "test-loop-free für <flavor>". Jede Stufe ist einzeln aufrufbar.
---

# Prüfleiter ohne Geld, ohne PC, ohne Testgerät

Vier Stufen, exakt nach `TESTLEITER.md`. Jede Stufe läuft einzeln. Wer alle
vier will, ruft sie nacheinander auf — nicht als einen Block, sonst ist bei
einem Bruch nicht feststellbar, welche Stufe ihn verursacht hat.

## Wann dieser Skill greift

**Greift**, wenn das Fundament steht und mindestens eine App abgeleitet ist:
"Richte die Tests ein", "Ich will Screenshots sehen", "Warum ist die CI rot",
"Mach Test Lab an".

**Greift nicht** bei:

| Wunsch | Zuständiger Skill |
|---|---|
| `ci.yml`, `web.yml`, `testlab.yml` fehlen noch | `monorepo-bootstrap` |
| App existiert noch nicht | `app-derive` |
| Interpreter-Testsätze fehlen inhaltlich | `app-derive`, Schritt 6 |
| Screenshots für den Play Store aufbereiten | `store-assets` — verbraucht die PNGs aus Stufe 1 |
| Freigabe vor Veröffentlichung | `release-gate` |
| Schalter umlegen, wenn Geld da ist | `workflows/WF-04-GELD-DA.md` |

Dieser Skill **erfindet keine Workflow-Dateien.** `ci.yml`, `web.yml` und
`testlab.yml` stammen aus `monorepo-bootstrap`; hier werden nur Schritte
ergänzt. Gleiche Dateinamen, gleiche Melos-Skriptnamen, keine Zweitfassung.

## Voraussetzungen

| Was | Wer liefert es | Prüfbefehl |
|---|---|---|
| `melos.yaml` mit `analyze`, `format-check`, `test`, `test-golden-update`, `build-web`, `check-ad-ids` | `monorepo-bootstrap` | `grep -c test-golden-update melos.yaml` |
| `.github/workflows/ci.yml`, `web.yml`, `testlab.yml` | `monorepo-bootstrap` | `ls .github/workflows/` |
| `packages/shared_base/lib/src/storage/entry_store.dart` | `capture-core-build` A | `test -f packages/shared_base/lib/src/storage/entry_store.dart` |
| `WebStubSttEngine`, `Registry.instance.bind<T>()` | `capture-core-build` C | `grep -rl WebStubSttEngine packages/capture_core/lib` |
| `apps/<flavor>/test/golden/home_golden_test.dart` | `app-derive` Schritt 10 | `ls apps/<flavor>/test/golden/` |
| `integration_test` als dev-Abhängigkeit der App | `app-derive` Schritt 3 | `grep -c integration_test apps/<flavor>/pubspec.yaml` |

Nicht vorausgesetzt: Terminal des Nutzers, Desktop, Mac, Android-Gerät,
Play-Konto, Apple-Konto, Cloudflare-Konto, Firebase-Konto. Fehlende Secrets
führen zu einem übersprungenen Schritt, nie zu einem roten Lauf.

## Ablauf

---

### Stufe 0 — CI-Prüfungen bei jedem Push, kein Gerät

Läuft auf Linux in GitHub Actions, wenige Minuten, kostet nichts. Fängt grob
die Hälfte aller Fehler, bevor irgendjemand etwas ansieht.

#### 0.1 — Golden-Einrichtung: `flutter_test_config.dart`

**Entscheidung: kein `golden_toolkit`, sondern fünfzig eigene Zeilen.**
Begründung, damit sie nicht halbjährlich neu diskutiert wird: `golden_toolkit`
wird nicht mehr gepflegt, nagelt `flutter_test`-Versionen fest und wäre eine
zusätzliche Abhängigkeit **mal sechsundzwanzig Apps**. Gebraucht wird davon
allein `loadAppFonts` — zwei Schleifen über `FontManifest.json`. Und
`flutter_test_config.dart` führt Flutter automatisch vor **jeder** Testdatei
im Verzeichnisbaum aus: kein Test muss etwas aufrufen, keiner kann es vergessen.

Datei: `apps/<flavor>/test/flutter_test_config.dart`

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_base/shared_base.dart';

/// Feste Fläche aller Golden-Bilder: iPhone 14, 390x844 logische Pixel.
/// Dieselbe Größe steht in test/golden/home_golden_test.dart.
const Size kGoldenSurface = Size(390, 844);

/// Läuft vor jeder Testdatei unterhalb von test/.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  // Schnittstellen binden, bevor irgendetwas rendert. Golden-Bilder müssen
  // dasselbe Layout zeigen wie der laufende Web-Build — dort steckt der
  // Startbildschirm in AdSafeArea, und AdSafeArea liest
  // Registry.instance.get<AdSurface>(). Ohne Bindung wirft jeder Golden-Lauf
  // StateError, statt ein Bild zu erzeugen. reset() davor, weil die
  // Registrierung im selben Prozess über mehrere Testdateien hinweg lebt.
  Registry.instance.reset();
  await registerMonetize();
  // Ohne geladene Schriften rendert der Test Kästchen statt Buchstaben.
  await _ladeSchriften();
  // Schatten werden je nach Treiber anders gerastert — häufigste Ursache
  // für Ein-Pixel-Abweichungen zwischen CI und Sandkasten.
  debugDisableShadows = true;
  // Fläche, Pixeldichte, Systemränder, Systemschriftgröße festnageln.
  final TestFlutterView view = binding.platformDispatcher.implicitView!;
  view.devicePixelRatio = 1.0;
  view.physicalSize = kGoldenSurface;
  view.padding = const FakeViewPadding();
  view.viewPadding = const FakeViewPadding();
  view.viewInsets = const FakeViewPadding();
  binding.platformDispatcher.textScaleFactorTestValue = 1.0;
  await testMain();
}

Future<void> _ladeSchriften() async {
  final String? manifest = await _leseManifest();
  if (manifest == null) {
    return;
  }
  for (final dynamic roh in json.decode(manifest) as List<dynamic>) {
    final Map<String, dynamic> familie = roh as Map<String, dynamic>;
    final List<Future<ByteData>> daten = <Future<ByteData>>[
      for (final dynamic a in familie['fonts'] as List<dynamic>)
        rootBundle.load((a as Map<String, dynamic>)['asset'] as String),
    ];
    // 'packages/shared_base/Inter' wird zusätzlich als 'Inter' registriert,
    // weil Themes die Familie ohne Paketpräfix benennen.
    final String voll = familie['family'] as String;
    final List<String> namen = voll.startsWith('packages/')
        ? <String>[voll, voll.split('/').sublist(2).join('/')]
        : <String>[voll];
    for (final String name in namen) {
      final FontLoader loader = FontLoader(name);
      for (final Future<ByteData> d in daten) {
        loader.addFont(d);
      }
      await loader.load();
    }
  }
}

Future<String?> _leseManifest() async {
  try {
    return await rootBundle.loadString('FontManifest.json');
  } on FlutterError {
    return null; // Keine Schriften deklariert — Werksschrift bleibt.
  }
}
```

Referenzbilder gelten **ausschließlich für Linux**, weil dort verglichen wird —
siehe Abbruchkriterium 4.

#### 0.2a — Erfahrung aus vox (13.11.2026): echte Bildschirme statt Attrappen

Die Vorlage in 0.2 fotografiert **nachgebaute** Bildschirme. Das fängt keine
Layoutfehler der echten `HomeScreen` und lief bei vox an mehreren echten
Fehlern vorbei. vox macht es deshalb so — **Vorbild für alle weiteren Apps:**
`apps/vox/test/support/fake_store.dart` und
`apps/vox/test/golden/screens_golden_test.dart`.

- Echter `EntryStore` auf `NativeDatabase.memory()` mit fester Uhr
  (`EntryStore(db, type: …, clock: () => kFixedNow)`). Deterministisch wie
  eine Attrappe, aber die echten Bildschirme mit echten Daten.
- Bildschirme nehmen eine Recorder-Attrappe an (`HomeScreen(recorder: …)`),
  sonst springt im Test das Mikrofon-Plugin an.
- Roboto lädt `flutter_test_config.dart` aus
  `$FLUTTER_ROOT/bin/cache/artifacts/material_fonts/` — sie steht nicht im
  FontManifest, ohne sie zeigen Golden-Bilder Kästchen.
- **Drei Fallen mit drift, alle drei kosten sonst Stunden:**
  1. Datenbank öffnen und befüllen in `tester.runAsync(…)`, nicht in
     `setUp` oder direkt im Test.
  2. Nie `pumpAndSettle`: Ein Ladekreisel dreht ewig, der Test hängt bis
     zum Timeout von zehn Minuten. Begrenzt pumpen — abwechselnd
     `runAsync(kurze Pause)` und `pump(50 ms)`.
  3. Abbauen am **Ende des Testkörpers**, in dieser Reihenfolge:
     `pumpWidget(SizedBox())`, `pump(1 s)`, `runAsync(db.close)`. In
     `addTearDown` ist es zu spät (Flutter prüft hängende Timer vorher),
     und ohne das `pump` wartet `close()` ewig auf einen Aufräum-Timer von
     drift, der nur in Testzeit feuert.

#### 0.2 — `fake_store.dart` — die drei Funktionen, die `app-derive` erwartet

`test/golden/home_golden_test.dart` importiert `../support/fake_store.dart` und
ruft `buildFakeHome()`, `buildFakeList()`, `buildFakeDetail()`. Alle drei sind
**synchron, ohne Datenbank, ohne Uhr**: ein Golden-Test, der eine Datei
anfasst oder `DateTime.now()` liest, prüft am nächsten Tag etwas anderes.

Datei: `apps/<flavor>/test/support/fake_store.dart`

```dart
import 'package:capture_core/capture_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_base/shared_base.dart';

/// Feste Uhrzeit aller Testdaten. Ohne sie ändert sich jedes Golden-Bild mit
/// jedem Tag und die Prüfung wäre wertlos.
final DateTime kFesteZeit = DateTime.utc(2026, 3, 14, 9, 41);

const String kFakeTitel = '<Label>';

/// Drei Einträge, bewusst gemischt: vollständig erkannt, halb erkannt, gar
/// nicht erkannt — damit das Bild auch den Zustand „Interpreter unsicher"
/// zeigt und nicht nur den Schönfall.
final List<Entry> kFakeEntries = <Entry>[
  _eintrag('eintrag-1', Duration.zero, tags: <String>['einkauf'],
      daten: <String, dynamic>{
        'amount': 22.50,
        'merchant': 'Rewe',
        'confidence': 1.0,
        'raw': 'zweiundzwanzig fünfzig bei Rewe',
      }),
  _eintrag('eintrag-2', const Duration(days: -1), daten: <String, dynamic>{
    'amount': 184.90,
    'confidence': 0.5,
    'raw': 'hundertvierundachtzig neunzig',
  }),
  _eintrag('eintrag-3', const Duration(days: -5), titel: 'Ohne Erkennung',
      daten: <String, dynamic>{'confidence': 0.0, 'raw': 'äh, moment'}),
];

/// Zwei Segmente am ersten Eintrag — der Beleg im Bild, dass ein Eintrag eine
/// geordnete Kette ist und kein Textblock.
final List<Segment> kFakeSegments = <Segment>[
  _segment('segment-1', 0, 'zweiundzwanzig fünfzig bei Rewe', Duration.zero),
  _segment('segment-2', 1, 'war für die Grillsachen am Samstag',
      const Duration(minutes: 3)),
];

Entry _eintrag(String id, Duration versatz,
        {String? titel, List<String>? tags, Map<String, dynamic>? daten}) =>
    Entry(
      id: id,
      type: kFlavor,
      title: titel,
      createdAt: kFesteZeit.add(versatz),
      updatedAt: kFesteZeit.add(versatz),
      tags: tags,
      data: daten,
    );

Segment _segment(String id, int order, String text, Duration versatz) => Segment(
      id: id,
      entryId: 'eintrag-1',
      order: order,
      transcript: text,
      engine: 'web',
      createdAt: kFesteZeit.add(versatz),
    );

/// Startbildschirm — derselbe Aufbau wie in `home_screen.dart`: Inhalt in
/// `AdSafeArea`, Aufnahmeknopf als `bottomAction`. Nur so belegt das
/// Golden-Bild den Punkt „Bannerfläche reserviert, Abstand geprüft" aus
/// ARCHITEKTUR.md Abschnitt 10.
Widget buildFakeHome() => Scaffold(
      appBar: AppBar(title: const Text(kFakeTitel)),
      body: AdSafeArea(
        bottomAction: RecordButton(
          state: RecordingState.idle,
          onStart: _nichts,
          onStop: _nichts,
          // Mindestabstand kommt von AdSafeArea. Ohne dieses Flag stünden
          // 32 dp statt 16 dp — und das Bild zeigte ein falsches Layout.
          insideAdSafeArea: true,
        ),
        child: _liste(kFakeEntries.take(2).toList()),
      ),
    );

/// Vollständige Liste, inklusive des Eintrags ohne Erkennung. Ebenfalls in
/// `AdSafeArea`, damit die Bannerfläche auch hier im Bild steht.
Widget buildFakeList() => Scaffold(
      appBar: AppBar(title: const Text('Alle Einträge')),
      body: AdSafeArea(child: _liste(kFakeEntries)),
    );

/// Detail: die Segmentkette in Reihenfolge, je mit Uhrzeit und erzeugender
/// Engine — Grundlage der späteren Neu-Transkription.
Widget buildFakeDetail() => Scaffold(
      appBar: AppBar(title: Text(_titel(kFakeEntries.first))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: <Widget>[
          Text(_datum(kFakeEntries.first.createdAt)),
          for (final Segment s in kFakeSegments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${_uhrzeit(s.createdAt)} · ${s.engine}'),
              subtitle: Text(s.transcript ?? '(kein Text)'),
            ),
        ],
      ),
    );

Widget _liste(List<Entry> items) => ListView.builder(
      itemCount: items.length,
      itemBuilder: (BuildContext context, int i) => ListTile(
        title: Text(_titel(items[i])),
        subtitle: Text(_datum(items[i].createdAt)),
        trailing: const Icon(Icons.add_rounded),
      ),
    );

String _titel(Entry e) {
  final Object? betrag = e.data['amount'];
  final Object? haendler = e.data['merchant'];
  if (e.title != null || (betrag == null && haendler == null)) {
    return e.title ?? 'Ohne Titel';
  }
  return <String>[
    if (betrag != null) '${(betrag as num).toStringAsFixed(2)} €',
    if (haendler != null) haendler as String,
  ].join(' · ');
}

String _datum(DateTime d) => '${d.day.toString().padLeft(2, '0')}.'
    '${d.month.toString().padLeft(2, '0')}.${d.year}';

String _uhrzeit(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}';

void _nichts() {}
```

Referenzbilder erzeugen, **erst nach Sichtprüfung einchecken**:

```bash
melos run test-golden-update && melos run test
```

#### 0.3 — Zwölf Beispielsätze je Interpreter, maschinell erzwungen

Die Regel steht in `TESTLEITER.md` Stufe 0 und `app-derive` Schritt 6. Sie
hält nur, wenn sie geprüft wird — sonst sind es beim zwanzigsten Ableiten
sieben. Gezählt werden die Zeilen der `cases`-Liste, die mit `('` beginnen.

In `melos.yaml` unter `scripts` ergänzen, bestehende Skripte bleiben unberührt:

```yaml
  check-cases:
    description: Bricht, wenn ein Interpreter weniger als zwölf Beispielsätze hat.
    run: |
      fehler=0
      for t in apps/*/test/*_interpreter_test.dart; do
        [ -e "$t" ] || continue
        n=$(grep -cE "^[[:space:]]*\('" "$t" || true)
        if [ "$n" -lt 12 ]; then
          echo "ABBRUCH: $t hat nur $n Beispielsätze, verlangt sind 12."
          fehler=1
        fi
      done
      test "$fehler" -eq 0 && echo "OK: zwölf Sätze je Interpreter."
      exit "$fehler"
```

In `ci.yml` einen Schritt vor „Tests inklusive Golden" einfügen:

```yaml
      - name: Zwölf Beispielsätze je Interpreter
        run: melos run check-cases
```

#### 0.4 — Golden-Abweichungen ansehen

Der Schritt „Golden-Abweichungen als Artefakt ablegen" steht bereits in
`ci.yml` (`monorepo-bootstrap`, Schritt 8) und lädt `**/test/**/failures/**`
hoch. Er wird **nicht** verändert. Ansehen auf dem iPhone: GitHub-App oder
Safari → Actions → roter Lauf → Artifacts → `golden-failures` → ZIP öffnen.
Vier Bilder je Abweichung; angesehen wird `*_maskedDiff`.

**Beispielaufruf Stufe 0**

```
Richte Teststufe 0 für onira ein: flutter_test_config.dart, fake_store.dart
mit den drei buildFake-Funktionen, den Zwölf-Sätze-Prüfer und den CI-Schritt.
Danach Referenzbilder erzeugen und mir sagen, wo ich sie ansehe.
```

---

### Stufe 1 — Web-Build, der wichtigste Kanal

Rund zwei Drittel der tatsächlichen Arbeit ist hier prüfbar. Die App läuft in
Safari auf dem iPhone, unter der Branch-Vorschau-URL von Cloudflare Pages:
`https://<branch>.app-fabrik.pages.dev/<flavor>/`. Erzeugt von `web.yml`
(`monorepo-bootstrap`, Schritt 9). Fehlen `CLOUDFLARE_API_TOKEN` und
`CLOUDFLARE_ACCOUNT_ID`, bleibt der Lauf grün und das Artefakt `web-<branch>`
ist trotzdem herunterladbar.

#### 1.1 — Der Hauptablauf mit Screenshots

Datei: `apps/<flavor>/integration_test/app_test.dart`

```dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:<flavor>/main.dart' as app;

Future<void> main() async {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Hauptablauf: aufnehmen, erweitern, wiederfinden',
      (WidgetTester tester) async {
    // Auf Android muss die Oberfläche vor dem ersten Screenshot in ein Bild
    // umgewandelt werden. Im Web und auf iOS entfällt das.
    if (!kIsWeb && Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
    }

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));
    await _bild(binding, tester, '01-start');
    await tester.tap(find.text('Aufnehmen'));
    await tester.pump(const Duration(milliseconds: 300));
    await _bild(binding, tester, '02-aufnahme-laeuft');
    // Der Stub braucht seine Verzögerung — hier wird gewartet, nicht gepumpt.
    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(ListTile), findsOneWidget,
        reason: 'Nach der ersten Aufnahme existiert genau ein Eintrag.');
    await _bild(binding, tester, '03-erster-eintrag');
    // Denselben Eintrag um ein zweites Segment erweitern.
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(ListTile), findsOneWidget,
        reason: 'Erweitern legt keinen zweiten Eintrag an, sondern ein '
            'zweites Segment am bestehenden.');
    await _bild(binding, tester, '04-erweitert');
    // Zweiter Eintrag, damit die Liste als Liste erkennbar ist.
    await tester.tap(find.text('Aufnehmen'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(ListTile), findsNWidgets(2));
    await _bild(binding, tester, '05-liste');
    // Detailansicht — der Beleg, dass die Segmentkette geordnet ist.
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await _bild(binding, tester, '06-detail');
  });
}

/// Screenshot mit stabilem Namen. Die Nummer ist die Reihenfolge;
/// store-assets sortiert danach.
Future<void> _bild(IntegrationTestWidgetsFlutterBinding binding,
    WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await binding.takeScreenshot(name);
}
```

#### 1.1a — Erfahrung aus vox (13.11.2026): so läuft es wirklich

Die Vorlage 1.1 läuft so NICHT durch. Vorbild ist
`apps/vox/integration_test/app_test.dart`; die Unterschiede:

- **`flutter drive --profile`**, nie Debug: Im Debug-Modus wartet
  `web-server` auf die Dart-Debug-Erweiterung, die headless Chrome nie lädt.
  Der Lauf hängt wortlos bis zum Timeout.
- **`--no-web-resources-cdn`**: sonst CanvasKit von gstatic.com — ohne Netz
  eine weiße Seite.
- **`--browser-dimension=390,987`** plus
  `--web-browser-flag=--force-device-scale-factor=3`: ergibt 1170×2532, die
  iPhone-14-Auflösung. Ohne das sind die Store-Bilder 1600×881 Desktop.
- **Mikrofon:** `--web-browser-flag=--use-fake-device-for-media-stream`
  und `--use-fake-ui-for-media-stream`.
- **Nie `pumpAndSettle`** — Wellenform und Ladekreisel „settlen" nie.
  Eigener Helfer `_until(finder)`, der begrenzt pumpt.
- **Auf das Ergebnis warten, nicht auf das erste Lebenszeichen:** Ein
  Eintrag erscheint sofort, sein Text erst nach der Erkennung.
- **`enterText` erreicht im Browser kein Feld** (echte Tastatur). Begriff
  über `controller.text` setzen und `onChanged` auslösen.
- **Im Profile-Modus sind Fehlermeldungen leer.** Bei Rot: vorübergehend
  `_shot(binding, t, 'zz-…')` zwischen die Schritte, das letzte Bild zeigt
  die Stelle.
- Lokal: `chromedriver --port=4444 &`, dann
  `dart run melos run integration -- <flavor>`. Der chromedriver muss zur
  Chrome-Version passen; alte Chrome-Sitzungen vorher beenden.

#### 1.2 — Der Treiber, der die PNG-Dateien schreibt

Datei: `apps/<flavor>/test_driver/integration_test.dart`

```dart
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes,
        [Map<String, Object?>? args]) async {
      final File datei = File('integration_test/screenshots/$name.png');
      await datei.parent.create(recursive: true);
      await datei.writeAsBytes(bytes);
      stdout.writeln('Screenshot: ${datei.path} (${bytes.length} Bytes)');
      return true;
    },
  );
}
```

`integration_test/screenshots/` steht in `.gitignore` — die Bilder sind
Artefakte, keine Quelldateien. `store-assets` zieht sie aus dem CI-Lauf und
skaliert sie in die Play-Formate. Ohne Gerät laufen lassen, über Chrome:

```bash
melos exec --scope=<flavor> -- flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d web-server --browser-name=chrome --headless \
  --dart-define=FLAVOR=<flavor> --dart-define=STT_ENGINE=web
```

#### 1.3 — Ergänzung in `ci.yml`

Als **zweiter Job** anhängen; `analyze-and-test` bleibt unverändert. Die Matrix
wächst mit jedem abgeleiteten Flavor um einen Eintrag — die einzige Stelle, an
der `app-derive` diese Datei anfasst.

```yaml
  screenshots:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    needs: analyze-and-test
    strategy:
      fail-fast: false
      matrix:
        flavor: [vox]
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - uses: nanasess/setup-chromedriver@v2
      - name: Melos und Bootstrap
        run: dart pub global activate melos && melos bootstrap
      - name: chromedriver starten
        run: chromedriver --port=4444 &
      - name: Integrationstest im Browser
        working-directory: apps/${{ matrix.flavor }}
        run: |
          flutter drive \
            --driver=test_driver/integration_test.dart \
            --target=integration_test/app_test.dart \
            -d web-server --browser-name=chrome --headless \
            --dart-define=FLAVOR=${{ matrix.flavor }} \
            --dart-define=STT_ENGINE=web
      - name: Screenshots als Artefakt ablegen
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: screenshots-${{ matrix.flavor }}
          path: apps/${{ matrix.flavor }}/integration_test/screenshots
          if-no-files-found: error
          retention-days: 14
```

#### 1.4 — Fehlerweg der Stub-Engine erzwingbar machen

Der Erfolgsfall ist der uninteressante. In
`packages/capture_core/lib/src/stt/stt_registration.dart` ergänzen und den
Web-Zweig ersetzen:

```dart
/// Erzwingt den Fehlerweg der Stub-Engine. Ausschließlich über
/// --dart-define=STUB_FAILURE=1, nie im Quelltext gesetzt.
const bool _stubFailure = bool.fromEnvironment('STUB_FAILURE');

    case 'web':
      Registry.instance.bind<SttEngine>(
        WebStubSttEngine(failureRate: _stubFailure ? 1.0 : 0.0),
      );
```

In `web.yml` hinter der Flavor-Schleife einen zweiten Build ergänzen:

```yaml
      - name: Fehlerweg-Build je Flavor
        run: |
          IFS=',' read -ra F <<< "${{ steps.flavors.outputs.list }}"
          for f in "${F[@]}"; do
            flutter build web --release --no-web-resources-cdn \
              --dart-define=FLAVOR="$f" \
              --dart-define=STT_ENGINE=web \
              --dart-define=STUB_FAILURE=1 \
              --base-href="/$f-fehler/" \
              --output="build/web/$f-fehler"
          done
```

Erreichbar unter `https://<branch>.app-fabrik.pages.dev/<flavor>-fehler/`. Dort
scheitert **jede** Transkription — genau so, wie es auf einem echten Gerät bei
Funkloch, vollem Speicher oder abgelehnter Berechtigung passiert.

#### 1.5 — Manuelle Prüfliste auf dem iPhone

Die acht Punkte stehen wörtlich in `TESTLEITER.md`, Punkt 9 kommt hinzu.

- [ ] **1. Neuen Eintrag anlegen, Stub-Transkript erscheint**
  Tippen: „Aufnehmen", eine Sekunde warten, „Fertig". Sichtbar: neuer
  Listeneintrag mit dem Beispieltext des Stubs, nach maximal zwei Sekunden.
  Bricht: nichts erscheint → `stt_registration.dart` bindet keine Engine;
  Eintrag ohne Text → `entry_store.dart`, `appendSegment`.

- [ ] **2. Denselben Eintrag um ein zweites Segment erweitern, Reihenfolge stimmt**
  Tippen: Pluszeichen rechts am Eintrag, dann „Fertig". Sichtbar: **kein**
  zweiter Eintrag; im Detail zwei Abschnitte, der neue unten mit späterer
  Uhrzeit. Bricht: zweiter Eintrag → `home_screen.dart`, `_activeEntryId`;
  falsche Reihenfolge → `entry_store.dart`, `_nextOrder`.

- [ ] **3. Interpreter-Ergebnis prüfen — Felder korrekt gefüllt**
  Tippen: Eintrag öffnen. Sichtbar: Betrag und Händler getrennt, nicht der
  Rohtext; unter 0,5 Vertrauenswert stattdessen der Rohtext zur Korrektur.
  Bricht: → `<flavor>_interpreter.dart`. Der Fall wird als dreizehnter Satz in
  `<flavor>_interpreter_test.dart` eingetragen, **bevor** er behoben wird.

- [ ] **4. Eintrag suchen, finden, öffnen**
  Tippen: Suchfeld, Wortteil („rew"), Treffer. Sichtbar: Treffer erscheint
  während des Tippens, Öffnen zeigt die Segmentkette. Bricht: →
  `shared_base/lib/src/search/`; nur ganze Wörter → Präfixsuche fehlt.

- [ ] **5. Alle vier Exporte auslösen, Dateien öffnen sich und sind vollständig**
  Tippen: Einstellungen → Export → Markdown, KI-Bündel, PDF, CSV/JSON.
  Sichtbar: je eine Datei; Markdown mit YAML-Frontmatter, KI-Bündel mit
  Schema-Kopf und Token-Schätzung, PDF mit Inhalt. Bricht: →
  `<flavor>_export.dart`, beim PDF `shared_base/export/pdf_export.dart`.

- [ ] **6. Fluchttür-Export prüfen: enthält er wirklich alles?**
  Tippen: Einstellungen → Fluchttür. Sichtbar: JSON mit jedem Eintrag **und**
  jedem Segment plus ZIP der Originale; Stichprobe: Anzahl in der Liste gegen
  `eintraege.length`. Bricht: → `escapeHatch()`, `vault_export.dart`. Fehlt sie
  oder kostet sie Geld: **Sperrgrund**, `ARCHITEKTUR.md` Abschnitt 7.

- [ ] **7. Hell und dunkel umschalten, Schriftgröße hoch, nichts bricht**
  Tippen: iOS-Einstellungen → Anzeige → Dunkel; Bedienungshilfen → Textgröße
  größter Schritt; Safari neu laden. Sichtbar: lesbarer Kontrast in beiden
  Modi, kein abgeschnittener Text, kein Überlaufstreifen. Bricht: →
  `<flavor>_theme.dart` (Kontrast) oder feste `height:`-Werte um Text.

- [ ] **8. Auf schmalem Fenster: Bannerfläche kollidiert mit nichts**
  Tippen: quer drehen, Safari in Split View schmal ziehen. Sichtbar: mindestens
  16 dp zwischen Aufnahmeknopf und Bannerfläche, Knopf vollständig tippbar.
  Bricht: → `RecordButton.bannerGap`, `monetize-modul`. **Sperrgrund im Store**,
  keine Gestaltungsfrage.

- [ ] **9. Fehlerweg der Stub-Engine prüfen**
  Tippen: `https://<branch>.app-fabrik.pages.dev/<flavor>-fehler/` öffnen
  (`--dart-define=STUB_FAILURE=1`, also `WebStubSttEngine(failureRate: 1.0)`),
  dann „Aufnehmen", „Fertig". Sichtbar: verständliche deutsche Meldung, **kein**
  roter Bildschirm, **kein** Einfrieren; der Eintrag entsteht trotzdem, mit
  Segment ohne Text — die Aufnahme darf nie verloren gehen, nur die Erkennung.
  Bricht: Absturz → `home_screen.dart` fängt `SttFailure` nicht; Segment fehlt
  → `appendSegment` steht im `try`-Block statt dahinter.

**Beispielaufruf Stufe 1**

```
Stufe 1 für onira: integration_test/app_test.dart mit Screenshots an sechs
Punkten, test_driver dazu, den screenshots-Job in ci.yml, den STUB_FAILURE-
Schalter und den Fehlerweg-Build in web.yml. Dann gib mir die Prüfliste mit
beiden URLs.
```

---

### Stufe 2 — Firebase Test Lab bei jedem Merge, Gratis-Kontingent

Echte Android-Hardware in Googles Rechenzentrum, ohne ein Gerät zu besitzen.
Fängt genau das, was der Web-Build nicht sieht: Berechtigungsdialoge,
Speicherprobleme, Abstürze in nativen Plugins, Verhalten bei Drehung.

**Kontingent zuerst prüfen, nicht danach.** Der Gratis-Tarif enthält ein
tägliches Kontingent an Testläufen; die Höhe ändert sich gelegentlich und wird
**vor** der Einrichtung nachgesehen: console.firebase.google.com → Projekt →
Test Lab → Nutzung. Reicht sie nicht für einen Lauf je Merge, wird der Auslöser
in `testlab.yml` von `push: branches: [main]` auf `workflow_dispatch` allein
zurückgestellt — nicht das Testen aufgegeben.

**Robo-Test: bereits vorhanden.** Der Job `robo` steht vollständig in
`testlab.yml` (`monorepo-bootstrap`, Schritt 10) und wird **nicht** verändert:
Secret-Prüfung, APK-Bau, `google-github-actions/auth`,
`gcloud firebase test android run --type robo` auf `model=redfin,version=30`.

#### 2.1 — Integrationstest auf echten Geräten ergänzen

Als zweiter Job an `testlab.yml` anhängen:

```yaml
  instrumentation:
    runs-on: ubuntu-latest
    timeout-minutes: 45
    env:
      FLAVOR: ${{ github.event.inputs.flavor || 'vox' }}
    steps:
      - uses: actions/checkout@v4
      - name: Firebase-Zugang vorhanden?
        id: fb
        run: |
          if [ -n "${{ secrets.FIREBASE_SERVICE_ACCOUNT }}" ]; then
            echo "ready=true" >> "$GITHUB_OUTPUT"
          else
            echo "ready=false" >> "$GITHUB_OUTPUT"
            echo "FIREBASE_SERVICE_ACCOUNT fehlt — Lauf wird übersprungen."
          fi
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "17"
      - name: Melos und Bootstrap
        run: dart pub global activate melos && melos bootstrap
      - name: App-APK und Test-APK bauen
        if: steps.fb.outputs.ready == 'true'
        run: |
          cd "apps/$FLAVOR"
          flutter build apk --debug --flavor "$FLAVOR" \
            --dart-define=FLAVOR="$FLAVOR" --dart-define=STT_ENGINE=web
          flutter build apk --debug --flavor "$FLAVOR" \
            --dart-define=FLAVOR="$FLAVOR" --dart-define=STT_ENGINE=web \
            --target=integration_test/app_test.dart
          cd android
          ./gradlew app:assembleAndroidTest \
            -Ptarget=integration_test/app_test.dart
      - uses: google-github-actions/auth@v2
        if: steps.fb.outputs.ready == 'true'
        with:
          credentials_json: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
      - uses: google-github-actions/setup-gcloud@v2
        if: steps.fb.outputs.ready == 'true'
      - name: Integrationstest auf echten Geräten
        if: steps.fb.outputs.ready == 'true'
        run: |
          APP="apps/$FLAVOR/build/app/outputs/flutter-apk/app-$FLAVOR-debug.apk"
          TEST="apps/$FLAVOR/build/app/outputs/apk/androidTest/$FLAVOR/debug/app-$FLAVOR-debug-androidTest.apk"
          gcloud firebase test android run \
            --type instrumentation \
            --use-orchestrator \
            --app "$APP" \
            --test "$TEST" \
            --device model=redfin,version=30,locale=de,orientation=portrait \
            --timeout 10m \
            --grant-permissions all \
            --results-bucket "${{ secrets.FIREBASE_RESULTS_BUCKET }}" \
            --results-dir "instr-$FLAVOR-${{ github.run_number }}"
```

**Warum `--use-orchestrator`:** ohne ihn laufen alle Fälle in einem Prozess.
Ein Absturz reißt den Rest mit, und im Bericht steht ein Fehler statt der
Stelle, an der es brach. Mit Orchestrator hat jeder Fall eigenen Prozess und
eigenen Speicherstand.

**Warum `--grant-permissions all`:** die App fragt Mikrofon und Kamera an. Ohne
den Schalter bleibt der Berechtigungsdialog stehen und der Lauf endet in der
Zeitüberschreitung — was wie ein Absturz aussieht, aber keiner ist.

#### 2.2 — Video, Screenshots und Absturzprotokolle auf dem iPhone ansehen

1. Safari → console.firebase.google.com → Projekt → **Test Lab**.
2. Lauf mit der passenden `results-dir` öffnen: `instr-<flavor>-<Laufnummer>`
   bzw. `robo-<flavor>-<Laufnummer>`.
3. Reiter **Video** — die vollständige Aufzeichnung; beim Robo-Test der
   interessantere, man sieht, wo er hängen blieb.
4. Reiter **Screenshots** — je Schritt ein Bild.
5. Reiter **Logs** — `logcat`; bei Absturz Suchbegriff `FATAL EXCEPTION`.
6. Reiter **Performance** — Speicher- und CPU-Verlauf. Die Stelle, an der
   später das 640-MB-Modell auffällig wird.

Die Adresse des Laufs steht auch am Ende des Actions-Protokolls: antippen
genügt, kein Suchen in der Konsole.

**Beispielaufruf Stufe 2**

```
Stufe 2 anschalten: häng den instrumentation-Job an testlab.yml, mit
--use-orchestrator und --grant-permissions all. Sag mir vorher, wo ich das
Gratis-Kontingent nachsehe, und danach, wo ich Video und Logs finde.
```

---

### Stufe 3 — später, wenn Geld da ist

**Nur vorbereiten, nicht einrichten.** Kein Konto, kein Schlüssel, kein Abo.
Am Ende fehlt genau ein Schalter.

| Kanal | Kosten | Was er zusätzlich bringt |
|---|---|---|
| TestFlight über Codemagic | 99 $/Jahr Apple | natives iOS auf dem eigenen iPhone, alle Plugins echt |
| Firebase App Distribution | 0 € | braucht ein Android-Gerät, sonst nutzlos |
| Gebrauchtes Android-Gerät | 60–120 € | Werbung, Kauf, Modellgröße, Mikrofonqualität |

**Reihenfolge, wenn Geld kommt:** zuerst 25 $ Play Console (schaltet
Veröffentlichung und den Zwölf-Tester-Lauf frei), dann das Android-Gerät,
zuletzt das Apple-Konto. Android ist die Auslieferungsplattform, iOS zunächst
nur Testkanal. Wellen, Vorbedingungen und Schalterzeilen stehen in
`workflows/WF-04-GELD-DA.md`.

Datei: `codemagic.yaml`

```yaml
# STILLGELEGT. Der Schalter heißt IOS_READY und steht auf "false" — genau
# wie PLAY_CONSOLE_READY in release-gate. Umgelegt wird er in Welle 3 von
# workflows/WF-04-GELD-DA.md, nicht vorher. Bis dahin löst nichts diesen
# Workflow aus: kein Trigger, kein Zeitplan, kein Push. Zum Aufwecken:
# 1. App-Store-Connect-Integration in Codemagic verbinden.
# 2. IOS_READY auf "true", FLAVOR setzen.
# 3. Auskommentierte Blöcke einkommentieren.
workflows:
  ios-testflight:
    name: iOS TestFlight (stillgelegt)
    instance_type: mac_mini_m2
    max_build_duration: 60
    environment:
      flutter: stable
      xcode: latest
      vars:
        FLAVOR: vox
        # Einziger Schalter dieses Workflows. Welle 3, WF-04-GELD-DA.md.
        IOS_READY: "false"
      # ios_signing:
      #   distribution_type: app_store
      #   bundle_identifier: de.zeta.vox
    # triggering:
    #   events: [tag]
    scripts:
      - name: IOS_READY prüfen
        script: |
          if [ "$IOS_READY" != "true" ]; then
            echo "codemagic stillgelegt: IOS_READY ist nicht true."
            echo "Es fehlt das Apple-Entwicklerkonto (99 USD/Jahr) samt"
            echo "App-Store-Connect-Integration — Welle 3 in WF-04-GELD-DA.md."
            echo "Der Lauf endet ohne Fehler."
          fi
      # Alles ab hier braucht ein Apple-Konto und läuft nur mit dem Schalter.
      - name: Melos
        script: dart pub global activate melos && melos bootstrap
        when:
          condition: env.IOS_READY == 'true'
      - name: Analyse und Tests
        script: melos run analyze && melos run test
        when:
          condition: env.IOS_READY == 'true'
      - name: iOS bauen
        script: |
          cd "apps/$FLAVOR"
          flutter build ipa --release --flavor "$FLAVOR" \
            --dart-define=FLAVOR="$FLAVOR" \
            --export-options-plist=/Users/builder/export_options.plist
        when:
          condition: env.IOS_READY == 'true'
    artifacts:
      - apps/$FLAVOR/build/ios/ipa/*.ipa
    # publishing:
    #   app_store_connect:
    #     auth: integration
    #     submit_to_testflight: true
```

**Was diese Leiter nicht kann** — ehrlich benannt, damit später keine
Überraschung entsteht. Keine der vier Stufen prüft:

- **Erkennungsqualität von Parakeet** bei echten Aufnahmen, echten Mikrofonen,
  Hintergrundgeräuschen. Nur auf echter Hardware beurteilbar.
- **Ladezeit und Speicherverhalten des 640-MB-Modells** auf Mittelklassegeräten.
  Test Lab zeigt den Speicherverlauf, lädt das Modell aber nie.
- **Werbung und Kaufabwicklung.** Nicht simulierbar — und nicht nötig, solange
  kein Play-Konto existiert.
- **Kamera unter realen Lichtverhältnissen.** `WebStubScanPipeline` prüft die
  Logik, nicht die Bildqualität.

Das sind die letzten zwanzig Prozent vor der Veröffentlichung. Die ersten
achtzig decken die Stufen 0 bis 2 vollständig ab.

**Beispielaufruf Stufe 3**

```
Stufe 3 vorbereiten, nicht einrichten: leg codemagic.yaml stillgelegt an und
sag mir in einem Absatz, was ich in welcher Reihenfolge kaufe, sobald Geld
da ist.
```

---

## Was wo gefangen wird

| Fehlerklasse | Stufe | Aufwand |
|---|---|---|
| Tippfehler, unbenutzte Importe, fehlende Rückgabetypen | 0 — `analyze` | 0, läuft mit |
| Interpreter liest „zwo und zwanzig fünfzig" falsch | 0 — Unit, zwölf Sätze | 10 Min je App, einmalig |
| Layout-Bruch nach Theme-Änderung, Textüberlauf | 0 — Golden, sechs Bilder | 0 nach Einrichtung |
| Erweitern legt neuen Eintrag an, Segmentreihenfolge kaputt | 1 — Integrationstest | 0 nach Einrichtung |
| Export unvollständig, Fluchttür lückenhaft | 1 — Prüfliste 5 und 6 | 3 Min je App |
| Bannerfläche kollidiert mit Aufnahmeknopf | 1 — Prüfliste 8 | 1 Min, Sperrgrund |
| Fehlerweg der Engine stürzt ab | 1 — `STUB_FAILURE=1`, Punkt 9 | 1 Min |
| Berechtigungsdialog blockiert den Start | 2 — Robo | 0 nach Einrichtung |
| Absturz in nativem Plugin, Drehung, Zurück-Taste | 2 — Robo, Video und logcat | 0 |
| Speicherverhalten auf echter Hardware | 2 — Reiter Performance | 0 |
| Erkennungsqualität, Modellladezeit, Werbung, Kauf | 3 — gar nicht | Gerät nötig |

## Abbruchkriterien

1. `ci.yml`, `web.yml` oder `testlab.yml` fehlt — dann läuft
   `monorepo-bootstrap`, und **keine** Zweitfassung entsteht hier.
2. Eine der drei Workflow-Dateien wurde außerhalb dieses Skills verändert und
   die zu ergänzende Stelle ist nicht mehr eindeutig — Abweichung benennen,
   nicht überschreiben.
3. Ein Interpreter-Test hat weniger als zwölf Beispielsätze. `check-cases`
   bricht; der Skill erfindet keine Sätze, er fragt nach den fehlenden
   (`app-derive` Schritt 6).
4. Golden-Referenzbilder sollen auf einem anderen System als Linux erzeugt
   werden. Erzeugt wird nur dort, wo auch verglichen wird.
5. Golden-Bilder weichen ab, **ohne** Layout- oder Theme-Änderung im Diff. Dann
   ist die Ursache Nichtdeterminismus — Uhrzeit, Zufall, Animation, Netzzugriff
   — und wird gesucht, nicht mit `test-golden-update` übermalt.
6. Der Integrationstest scheitert an `find.text('Aufnehmen')`, weil die App die
   Beschriftung geändert hat. Erst klären, ob das gewollt war — eine stumm
   umbenannte Primäraktion ist selbst ein Befund.
7. Das Gratis-Kontingent reicht nicht für einen Lauf je Merge. Auslöser auf
   `workflow_dispatch` zurückstellen; nicht überziehen, nicht in einen
   bezahlten Tarif wechseln.
8. Stufe 3 soll tatsächlich eingerichtet werden, obwohl kein Konto existiert.
   `codemagic.yaml` bleibt stillgelegt, `WF-04-GELD-DA.md` gilt.
9. Ein Test soll übersprungen oder gelockert werden, damit die CI grün wird.
   Der Befund wird behoben, nicht die Regel.

## Fertig, wenn

**Stufe 0**

- [ ] `apps/<flavor>/test/flutter_test_config.dart` existiert und lädt Schriften
- [ ] `debugDisableShadows`, `devicePixelRatio 1.0`, 390x844 und Textskalierung
      1.0 sind dort festgenagelt
- [ ] `flutter_test_config.dart` ruft `Registry.instance.reset()` und
      `await registerMonetize()`, bevor der erste Test rendert
- [ ] `test/support/fake_store.dart` liefert `buildFakeHome()`,
      `buildFakeList()`, `buildFakeDetail()` mit festen Daten
- [ ] `buildFakeHome()` steckt in `AdSafeArea`, der `RecordButton` sitzt als
      `bottomAction` mit `insideAdSafeArea: true` — Bannerfläche im Bild belegt
- [ ] `fake_store.dart` benutzt `kFesteZeit`, nirgends `DateTime.now()`
- [ ] `melos run test` grün, sechs Golden-Bilder unter `test/golden/goldens/`
- [ ] `melos run check-cases` meldet „OK" für jede abgeleitete App
- [ ] Der Schritt „Zwölf Beispielsätze je Interpreter" steht in `ci.yml`
- [ ] Ein verfälschtes Golden-Bild macht die CI rot, `golden-failures` ist auf
      dem iPhone herunterladbar

**Stufe 1**

- [ ] `integration_test/app_test.dart` spielt den Hauptablauf durch, inklusive
      Erweitern eines bestehenden Eintrags
- [ ] Sechs Screenshots entstehen: `01-start` bis `06-detail`
- [ ] `test_driver/integration_test.dart` schreibt sie nach
      `integration_test/screenshots/`
- [ ] Der Job `screenshots` steht in `ci.yml` und lädt `screenshots-<flavor>` hoch
- [ ] `STUB_FAILURE` ist verdrahtet, der Fehlerweg-Build steht in `web.yml`
- [ ] Beide URLs sind auf dem iPhone erreichbar: `.../<flavor>/` und
      `.../<flavor>-fehler/`
- [ ] Alle neun Punkte der Prüfliste sind abgehakt

**Stufe 2**

- [ ] Die Höhe des Gratis-Kontingents wurde in der Firebase-Konsole nachgesehen
      und reicht für einen Lauf je Merge
- [ ] Der Job `instrumentation` steht in `testlab.yml`, mit
      `--use-orchestrator` und `--grant-permissions all`
- [ ] Ein Lauf ist durch, Video und Screenshots wurden auf dem iPhone angesehen
- [ ] Ohne `FIREBASE_SERVICE_ACCOUNT` bleibt der Lauf grün und meldet
      „übersprungen"

**Stufe 3**

- [ ] `codemagic.yaml` existiert, ohne aktiven Auslöser, mit
      `IOS_READY: "false"`; jeder Schritt, der ein Apple-Konto braucht, steht
      unter `when: condition: env.IOS_READY == 'true'`
- [ ] Kein Konto angelegt, kein Schlüssel erzeugt, kein Abo geschlossen
- [ ] Die Kaufreihenfolge liegt dem Nutzer vor: 25 $ Play Console →
      Android-Gerät → 99 $ Apple, mit Verweis auf `WF-04-GELD-DA.md`
- [ ] Die vier Grenzen der Leiter wurden ausdrücklich benannt

## Beispielaufruf

```
Richte die Tests für onira ein — alle vier Stufen nacheinander, nach
TESTLEITER.md. Fang mit Stufe 0 an und halt an, bevor du Stufe 1 beginnst.
```

Weitere Formulierungen, die diesen Skill auslösen:

```
Teststufe 0 einrichten.
Golden-Tests aufsetzen, ich will die Bilder auf dem Handy sehen.
Bau mir den Integrationstest mit Screenshots.
Test Lab anschalten.
Gib mir die Prüfliste fürs iPhone.
test-loop-free für prisma.
```
