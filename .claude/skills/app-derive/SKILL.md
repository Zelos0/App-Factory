---
name: app-derive
description: Leitet eine neue App aus einem der beiden Kerne ab — fragt genau fünf Dinge ab und erzeugt danach Flavor, App-Verzeichnis, Theme, Interpreter mit zwölf Testsätzen, Startbildschirm, Store-Gerüst, Golden-Tests und den Eintrag in der Web-Demo. Auslösen mit "leite App X ab", "neue App aus dem Kern", "bau mir die App <Name>", "App Nummer 7 anlegen", "derive <flavor>". Wird 26-mal ausgeführt.
---

# Eine App aus dem Kern ableiten

Der wichtigste Skill des Pakets. Alles andere existiert, damit dieser hier in
unter zwei Stunden durchläuft.

## Wann dieser Skill greift

**Greift**, wenn ein Bauplan vorliegt oder der Nutzer eine App beim Namen nennt
und der zugehörige Kern steht.

**Greift nicht** bei:

| Wunsch | Zuständiger Skill |
|---|---|
| Der Steckbrief ist noch Prosa, kein Bauplan | `konzept-zu-bauplan` — dessen Ausgabe ist die Eingabe hier |
| Repo existiert nicht | `monorepo-bootstrap` |
| Sprach-Kern fehlt oder ist unvollständig | `capture-core-build` |
| Kamera-Kern fehlt oder ist unvollständig | `lens-core-build` |
| Werbefläche, Kauf-Schnittstelle einbauen | `monetize-modul` — läuft einmal, nicht je App |
| Store-Texte und Screenshots erzeugen | `store-assets` |
| Tests und Web-Deploy einrichten | `test-loop-free` |

**Die eine Regel, die diesen Skill zusammenhält:** In `apps/<flavor>/` steht
kein Code, der in einer zweiten App nützlich wäre. Wenn während des Laufs
auffällt, dass etwas in eine zweite App gehören würde, wandert es in
`shared_base` oder den Kern — sofort, nicht später. Siehe Abbruchkriterium 4.

## Voraussetzungen

| Was | Wer liefert es | Prüfbefehl |
|---|---|---|
| `melos.yaml`, `tool/flavors.yaml`, `tool/gen_flavors.dart` | `monorepo-bootstrap` | `test -f tool/flavors.yaml` |
| `packages/shared_base/lib/src/storage/entry_store.dart` | `capture-core-build` A | `test -f packages/shared_base/lib/src/storage/entry_store.dart` |
| Bei `core: capture` oder `both`: `packages/capture_core/lib/capture_core.dart` | `capture-core-build` C | `test -f packages/capture_core/lib/capture_core.dart` |
| Bei `core: lens` oder `both`: `packages/lens_core/lib/lens_core.dart` | `lens-core-build` C | `test -f packages/lens_core/lib/lens_core.dart` |
| `packages/shared_base/lib/src/monetize/ad_safe_area.dart` | `monetize-modul` | `test -f packages/shared_base/lib/src/monetize/ad_safe_area.dart` |
| `melos run analyze` ohne Befund | vorheriger Lauf | `melos run analyze` |

Fehlt einer der Kerne, den die App braucht: abbrechen und den Kern-Skill nennen.
Der Kern wird **nicht** nebenbei mitgebaut — das ist der schnellste Weg, die
Zwei-Stunden-Marke zu reißen.

## Ablauf

### Schritt 0 — Zeit stempeln

Die Zielzeit ist Teil des Skills, nicht ein Wunsch. Der Skill notiert den
Startzeitpunkt und prüft ihn in Schritt 12.

```bash
date -u +%s > /tmp/app_derive_start
echo "Start: $(date -u +%H:%M) UTC"
```

---

### Schritt 1 — Der geführte Dialog: genau fünf Fragen

Der Skill fragt **fünf** Dinge. Nicht vier, nicht sieben. Jede Antwort wird
zurückgelesen, bevor irgendetwas erzeugt wird. Liegt ein Bauplan aus
`konzept-zu-bauplan` vor, sind alle fünf bereits beantwortet — dann wird der
Bauplan vorgelesen und nur um Bestätigung gebeten.

**Frage 1 — Kern.**

> Welcher Kern trägt die App?
> `capture` (Sprache), `lens` (Kamera) oder `both`?
> Bei `both` bitte sagen, welcher die Startansicht besetzt.

**Frage 2 — Interpreter- bzw. Pipeline-Logik.**

> Was soll aus der Rohaufnahme herauskommen?
> Nenne die Felder mit Typ und ein Beispiel, das reingeht, und was rauskommen soll.
> Beispiel: „zweiundzwanzig fünfzig bei Rewe" → `{betrag: 22.50, waehrung: "EUR", haendler: "Rewe", datum: heute}`

**Frage 3 — Auswertungsansicht.**

> Was zeigt die Auswertung?
> Summe · Verlauf über Zeit · Karte · Zeitachse · Häufigkeitsliste — eines oder
> mehrere. Über welchen Zeitraum wird gruppiert (Tag, Woche, Monat)?

**Frage 4 — Exportformate mit Empfänger.**

> Welche Exporte, und für wen?
> Vorgabe aus `ARCHITEKTUR.md` Abschnitt 7 — vier Empfänger, mindestens die
> Fluchttür ist Pflicht:
>
> | Empfänger | Format |
> |---|---|
> | Der Nutzer selbst, später | Markdown mit YAML-Frontmatter und `[[Verweisen]]` |
> | Ein KI-Modell | Kontextbündel mit Schema-Kopf und vorformuliertem Auftrag |
> | Ein Mensch mit Autorität | PDF, gestaltet nach Empfänger — wer ist es konkret? |
> | Andere Software | CSV, JSON oder GPX — welches? |
>
> Die Fluchttür (vollständiges JSON + ZIP der Originale) wird immer erzeugt,
> immer kostenlos, immer sichtbar. Darüber wird nicht abgestimmt.

**Frage 5 — Gestaltung.**

> Vier Farben (Primär, Sekundär, Fläche, Akzent) als Hex,
> zwei Schriftfamilien (Überschrift, Fließtext),
> und der Aufbau des Startbildschirms:
> Was steht oben, was in der Mitte, wo sitzt die Primäraktion?
> Kein Willkommenstext, keine Tour, keine Kontoabfrage — das ist gesetzt.

**Der Skill fragt nichts Sechstes.** Alles Weitere folgt aus der Architektur:
Datenmodell, Speicher, Suche, Theming-System, Bannerfläche, Schriftgrößen,
Hell/Dunkel, Fluchttür. Wenn eine sechste Frage nötig scheint, ist das das
Signal aus Abbruchkriterium 4.

---

### Schritt 2 — Flavor eintragen

Datei: `tool/flavors.yaml` — anhängen, nicht ersetzen.

```yaml
  <flavor>:
    label: <Label>
    core: <capture|lens|both>
    applicationId: de.zeta.<flavor>
```

Dann:

```bash
dart run tool/gen_flavors.dart
```

Namenskonventionen aus `ARCHITEKTUR.md` Abschnitt 9 sind bindend:
Flavor kleingeschrieben, Paket-ID `de.zeta.<flavor>`, Verzeichnis
`apps/<flavor>/`, Interpreter `<Flavor>Interpreter`, Theme `<Flavor>Theme`,
Store-Material `apps/<flavor>/store/`.

---

### Schritt 3 — App-Gerüst anlegen

**Fallunterscheidung zuerst.** Ist der Flavor die Gerüst-App aus
`monorepo-bootstrap` Schritt 7b, wird sie gefüllt statt neu angelegt — Details
in Abbruchkriterium 3.

```bash
FLAVOR=<flavor>

if test -f "apps/$FLAVOR/lib/main.dart" \
   && grep -q 'class ScaffoldShell' "apps/$FLAVOR/lib/main.dart" \
   && ! test -f "apps/$FLAVOR/lib/src/${FLAVOR}_interpreter.dart"; then
  echo "Gerüst erkannt — fülle apps/$FLAVOR, kein flutter create."
  mkdir -p "apps/$FLAVOR/lib/src" "apps/$FLAVOR/test/golden" \
           "apps/$FLAVOR/integration_test" "apps/$FLAVOR/store"
  rm -f "apps/$FLAVOR/lib/main.dart"
  SKIP_CREATE=1
else
  SKIP_CREATE=0
fi
```

Nur wenn `SKIP_CREATE=0`:

```bash
flutter create \
  --project-name "$FLAVOR" \
  --org de.zeta \
  --platforms=android,ios,web \
  --template=app \
  "apps/$FLAVOR"

rm -rf "apps/$FLAVOR/test"
rm -f "apps/$FLAVOR/lib/main.dart"
mkdir -p "apps/$FLAVOR/lib/src" \
         "apps/$FLAVOR/test/golden" \
         "apps/$FLAVOR/integration_test" \
         "apps/$FLAVOR/store"
```

Datenbank-Unterstützung für den Web-Build besorgen — ohne diese zwei Dateien
startet drift im Browser nicht:

```bash
curl -L -o "apps/$FLAVOR/web/sqlite3.wasm" \
  https://github.com/simolus3/sqlite3.dart/releases/latest/download/sqlite3.wasm
dart run drift_dev make-worker -o "apps/$FLAVOR/web/drift_worker.js"
```

Datei: `apps/<flavor>/pubspec.yaml`

```yaml
name: <flavor>
description: <Label> — App-Fabrik.
publish_to: none
version: 0.1.0+1

environment:
  sdk: ">=3.5.0 <4.0.0"
  flutter: ">=3.24.0"

dependencies:
  capture_core:            # nur wenn core capture oder both
    path: ../../packages/capture_core
  flutter:
    sdk: flutter
  lens_core:               # nur wenn core lens oder both
    path: ../../packages/lens_core
  shared_base:
    path: ../../packages/shared_base

dev_dependencies:
  flutter_lints: ^4.0.0
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

Nicht benötigte Kern-Abhängigkeit wird gelöscht, nicht auskommentiert.

---

### Schritt 4 — Theme

Genau vier Farben, zwei Schriftfamilien, sonst nichts. Alle Skalen, Abstände
und Komponenten kommen aus `shared_base/design/`.

Datei: `apps/<flavor>/lib/src/<flavor>_theme.dart`

```dart
import 'package:flutter/material.dart';

/// Vier Farben, zwei Schriften. Mehr gehört keiner App.
/// ARCHITEKTUR.md Abschnitt 8.
class <Flavor>Theme {
  const <Flavor>Theme._();

  static const Color primary = Color(0xFF<HEX1>);
  static const Color secondary = Color(0xFF<HEX2>);
  static const Color surface = Color(0xFF<HEX3>);
  static const Color accent = Color(0xFF<HEX4>);

  static const String headlineFamily = '<Schrift A>';
  static const String bodyFamily = '<Schrift B>';

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      secondary: secondary,
      tertiary: accent,
      surface: brightness == Brightness.light ? surface : null,
    );

    final TextTheme base = brightness == Brightness.light
        ? Typography.material2021().black
        : Typography.material2021().white;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: base.copyWith(
        displayLarge: base.displayLarge?.copyWith(fontFamily: headlineFamily),
        displayMedium: base.displayMedium?.copyWith(fontFamily: headlineFamily),
        headlineLarge: base.headlineLarge?.copyWith(fontFamily: headlineFamily),
        headlineMedium: base.headlineMedium?.copyWith(fontFamily: headlineFamily),
        headlineSmall: base.headlineSmall?.copyWith(fontFamily: headlineFamily),
        titleLarge: base.titleLarge?.copyWith(fontFamily: headlineFamily),
        bodyLarge: base.bodyLarge?.copyWith(fontFamily: bodyFamily),
        bodyMedium: base.bodyMedium?.copyWith(fontFamily: bodyFamily),
        labelLarge: base.labelLarge?.copyWith(fontFamily: bodyFamily),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // Primäraktion mindestens 56 dp — ARCHITEKTUR.md Abschnitt 8.
          minimumSize: const Size.fromHeight(56),
        ),
      ),
    );
  }
}
```

---

### Schritt 5 — Interpreter

Das eigentliche Herz der App und der einzige Teil mit hoher Fehlerdichte bei
geringem Testaufwand: ein Satz geht rein, eine Struktur kommt raus.

> **Vor dem Schreiben prüfen, was der Kern schon kann.** Seit dem
> vox-Lauf stehen deutsche Zahlwörter und Zeitangaben in
> `shared_base/src/text/`:
>
> ```dart
> SpokenNumbers.parseAmount('zweiundzwanzig fünfzig bei Rewe')  // 22.50
> SpokenNumbers.parseWord('hundertvierundachtzig')              // 184
> SpokenDates.parse('letzten Freitag', now: DateTime.now())     // Datum
> ```
>
> Der Betrags- und Zahlwort-Code weiter unten ist **Vorlage zum Verstehen,
> nicht zum Kopieren**. Wer ihn in eine App schreibt, hat ihn beim fünften
> Flavor fünfmal — und behebt jeden Fehler fünfmal. Ein Interpreter ruft
> den Kern auf und macht nur noch das, was seiner App eigen ist.

Datei: `apps/<flavor>/lib/src/<flavor>_interpreter.dart`

```dart
/// Wandelt den Volltext eines Eintrags in strukturierte Felder.
///
/// Reine Funktion: kein Zustand, kein Speicher, keine Plattform.
/// Deshalb vollständig im Unit-Test prüfbar — und deshalb testbar,
/// bevor irgendeine Oberfläche existiert.
class <Flavor>Interpreter {
  const <Flavor>Interpreter();

  /// Kennung, die in Entry.data unter '_interpreter' landet.
  static const String id = '<flavor>';

  /// Schema-Version. Bei Feldänderungen erhöhen und in
  /// migrateData() den alten Stand überführen.
  static const int schemaVersion = 1;

  <Flavor>Result parse(String text) {
    final String normalized = _normalize(text);

    // ---- app-spezifische Regeln, aus Frage 2 des Dialogs ----
    // Beispielhaft für einen Betrags-Interpreter; wird beim Ableiten
    // durch die tatsächlichen Regeln des Bauplans ersetzt.
    final double? amount = _parseAmount(normalized);
    final String? merchant = _parseMerchant(normalized);

    return <Flavor>Result(
      amount: amount,
      merchant: merchant,
      confidence: _confidence(<Object?>[amount, merchant]),
      raw: text,
    );
  }

  /// Kleinschreibung, Umlaute normalisieren, Mehrfachleerzeichen weg.
  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Deutsche Zahlwörter und Ziffern. Deckt die Fälle ab, die im Alltag
  /// gesprochen werden: "zweiundzwanzig fünfzig", "22,50", "22 Euro 50".
  static double? _parseAmount(String s) {
    final RegExpMatch? digits =
        RegExp(r'(\d{1,6})[,.](\d{1,2})').firstMatch(s);
    if (digits != null) {
      return double.parse('${digits.group(1)}.${digits.group(2)}');
    }

    final RegExpMatch? euroCents =
        RegExp(r'(\d{1,6})\s*euro\s*(\d{1,2})').firstMatch(s);
    if (euroCents != null) {
      return double.parse('${euroCents.group(1)}.${euroCents.group(2)}');
    }

    final RegExpMatch? plain = RegExp(r'(\d{1,6})\s*euro').firstMatch(s);
    if (plain != null) {
      return double.parse(plain.group(1)!);
    }

    return _parseSpokenAmount(s);
  }

  static const Map<String, int> _units = <String, int>{
    'null': 0, 'ein': 1, 'eins': 1, 'eine': 1, 'zwei': 2, 'zwo': 2,
    'drei': 3, 'vier': 4, 'fuenf': 5, 'fünf': 5, 'sechs': 6, 'sieben': 7,
    'acht': 8, 'neun': 9, 'zehn': 10, 'elf': 11, 'zwoelf': 12, 'zwölf': 12,
    'dreizehn': 13, 'vierzehn': 14, 'fuenfzehn': 15, 'fünfzehn': 15,
    'sechzehn': 16, 'siebzehn': 17, 'achtzehn': 18, 'neunzehn': 19,
  };

  static const Map<String, int> _tens = <String, int>{
    'zwanzig': 20, 'dreissig': 30, 'dreißig': 30, 'vierzig': 40,
    'fuenfzig': 50, 'fünfzig': 50, 'sechzig': 60, 'siebzig': 70,
    'achtzig': 80, 'neunzig': 90,
  };

  /// "zweiundzwanzig fünfzig" -> 22.50
  static double? _parseSpokenAmount(String s) {
    final List<String> tokens = s.split(' ');
    int? euros;
    int? cents;

    for (final String token in tokens) {
      final int? value = _spokenNumber(token);
      if (value == null) {
        continue;
      }
      if (euros == null) {
        euros = value;
      } else if (cents == null) {
        cents = value;
      }
    }

    if (euros == null) {
      return null;
    }
    return euros + (cents ?? 0) / 100;
  }

  static int? _spokenNumber(String token) {
    if (_units.containsKey(token)) {
      return _units[token];
    }
    if (_tens.containsKey(token)) {
      return _tens[token];
    }
    final RegExpMatch? compound =
        RegExp(r'^([a-zäöü]+)und([a-zäöü]+)$').firstMatch(token);
    if (compound != null) {
      final int? unit = _units[compound.group(1)];
      final int? ten = _tens[compound.group(2)];
      if (unit != null && ten != null) {
        return ten + unit;
      }
    }
    if (_hundreds(token) != null) {
      return _hundreds(token);
    }
    return null;
  }

  static int? _hundreds(String token) {
    final RegExpMatch? m =
        RegExp(r'^([a-zäöü]+)hundert([a-zäöü]*)$').firstMatch(token);
    if (m == null) {
      return null;
    }
    final int base = _units[m.group(1)] ?? 1;
    final String rest = m.group(2) ?? '';
    final int add = rest.isEmpty ? 0 : (_spokenNumber(rest) ?? 0);
    return base * 100 + add;
  }

  static String? _parseMerchant(String s) {
    final RegExpMatch? m =
        RegExp(r'\b(?:bei|von|im|in der|beim)\s+([a-zäöüß0-9\- ]{2,30})')
            .firstMatch(s);
    if (m == null) {
      return null;
    }
    final String raw = m.group(1)!.trim();
    return raw.isEmpty ? null : _capitalize(raw.split(' ').first);
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static double _confidence(List<Object?> fields) {
    final int filled = fields.where((Object? f) => f != null).length;
    return fields.isEmpty ? 0 : filled / fields.length;
  }
}

/// Ergebnis des Interpreters. Landet als JSON in Entry.data.
class <Flavor>Result {
  const <Flavor>Result({
    required this.confidence,
    required this.raw,
    this.amount,
    this.merchant,
  });

  final double? amount;
  final String? merchant;

  /// 0.0–1.0. Unter 0.5 zeigt die Oberfläche den Rohtext zur Korrektur an,
  /// statt ein halbes Ergebnis als sicher darzustellen.
  final double confidence;

  final String raw;

  Map<String, dynamic> toJson() => <String, dynamic>{
        '_interpreter': <Flavor>Interpreter.id,
        '_schema': <Flavor>Interpreter.schemaVersion,
        'amount': amount,
        'merchant': merchant,
        'confidence': confidence,
        'raw': raw,
      };

  static <Flavor>Result fromJson(Map<String, dynamic> json) => <Flavor>Result(
        amount: (json['amount'] as num?)?.toDouble(),
        merchant: json['merchant'] as String?,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        raw: json['raw'] as String? ?? '',
      );
}
```

---

### Schritt 6 — Zwölf realistische Beispielsätze

Pflicht, nicht Kür — `TESTLEITER.md` Stufe 0. Die Sätze müssen so klingen, wie
jemand tatsächlich spricht, samt Erkennungsfehlern der Gratis-Engine
(„zwo" statt „zwei"), nicht wie Testdaten.

Datei: `apps/<flavor>/test/<flavor>_interpreter_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:<flavor>/src/<flavor>_interpreter.dart';

void main() {
  const <Flavor>Interpreter interpreter = <Flavor>Interpreter();

  group('zwölf realistische Beispielsätze', () {
    // Jede Zeile: gesprochener Satz -> erwartete Felder.
    // Beim Ableiten durch die Sätze des Bauplans ersetzen.
    const List<(String, double?, String?)> cases = <(String, double?, String?)>[
      ('zweiundzwanzig fünfzig bei Rewe', 22.50, 'Rewe'),
      ('22,50 bei Rewe', 22.50, 'Rewe'),
      ('zwo und zwanzig fünfzig rewe', 22.50, 'Rewe'),
      ('acht euro neunzig beim Bäcker', 8.90, 'Baecker'),
      ('hundertvierundachtzig neunzig von der Werkstatt', 184.90, 'Werkstatt'),
      ('drei euro im Kiosk', 3.0, 'Kiosk'),
      ('neunundneunzig cent bei Aldi', null, 'Aldi'),
      ('sechzig euro tanken', 60.0, null),
      ('vierzehn siebzig', 14.70, null),
      ('bei dm gewesen', null, 'Dm'),
      ('zwölf euro fünfzig für das Ticket', 12.50, null),
      ('', null, null),
    ];

    for (final (String input, double? amount, String? merchant) in cases) {
      test('"$input"', () {
        final <Flavor>Result r = interpreter.parse(input);
        expect(r.amount, amount, reason: 'Betrag aus "$input"');
        if (merchant != null) {
          expect(r.merchant?.toLowerCase(), merchant.toLowerCase(),
              reason: 'Händler aus "$input"');
        }
      });
    }
  });

  test('Vertrauenswert sinkt, wenn Felder fehlen', () {
    expect(interpreter.parse('zweiundzwanzig fünfzig bei Rewe').confidence, 1.0);
    expect(interpreter.parse('irgendwas').confidence, lessThan(0.5));
  });

  test('Ergebnis überlebt die JSON-Runde', () {
    final <Flavor>Result before = interpreter.parse('zweiundzwanzig fünfzig bei Rewe');
    final <Flavor>Result after = <Flavor>Result.fromJson(before.toJson());
    expect(after.amount, before.amount);
    expect(after.merchant, before.merchant);
  });

  test('Interpreter ist zustandsfrei — zweimal derselbe Satz, gleiches Ergebnis', () {
    final <Flavor>Result a = interpreter.parse('drei euro im Kiosk');
    final <Flavor>Result b = interpreter.parse('drei euro im Kiosk');
    expect(a.toJson(), b.toJson());
  });
}
```

Sofort ausführen:

```bash
melos exec --scope=<flavor> -- flutter test test/<flavor>_interpreter_test.dart
```

**Erst wenn diese Tests grün sind, wird eine Oberfläche gebaut.** Ein
Interpreter, der erst über die Oberfläche geprüft wird, kostet das Zehnfache.

---

### Schritt 7 — Startbildschirm

Ohne Willkommenstext, ohne Tour, ohne Kontoabfrage. Primäraktion im
Daumenbereich, mindestens 56 dp hoch, mindestens 16 dp über der Bannerfläche.

Datei: `apps/<flavor>/lib/src/home_screen.dart`

```dart
import 'package:capture_core/capture_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_base/shared_base.dart';

import '<flavor>_interpreter.dart';

/// Startbildschirm. Aufbau aus Frage 5 des Dialogs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.store, super.key});

  final EntryStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioRecorder _recorder = PlatformAudioRecorder();
  final <Flavor>Interpreter _interpreter = const <Flavor>Interpreter();

  RecordingState _state = RecordingState.idle;
  String? _activeEntryId;

  @override
  void initState() {
    super.initState();
    _recorder.state.listen((RecordingState s) {
      if (mounted) {
        setState(() => _state = s);
      }
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await _recorder.start();
  }

  Future<void> _stop() async {
    final RecordingResult? result = await _recorder.stop();
    if (result == null) {
      return;
    }

    final SttEngine stt = Registry.instance.get<SttEngine>();
    final Entry entry = _activeEntryId == null
        ? await widget.store.createEntry()
        : (await widget.store.byId(_activeEntryId!))!.entry;

    String? text;
    try {
      text = (await stt.transcribe(result.path)).text;
    } on SttFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }

    await widget.store.appendSegment(
      entry.id,
      mediaPath: result.path,
      transcript: text,
      engine: stt.id,
    );

    final EntryWithSegments? full = await widget.store.byId(entry.id);
    if (full != null) {
      await widget.store.updateData(
        entry.id,
        _interpreter.parse(full.fullText).toJson(),
      );
    }

    if (mounted) {
      setState(() => _activeEntryId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('<Label>')),
      // AdSafeArea hält Bannerfläche und Mindestabstand frei —
      // aus monetize-modul, ARCHITEKTUR.md Abschnitt 8.
      body: AdSafeArea(
        bottomAction: RecordButton(
          state: _state,
          onStart: _start,
          onStop: _stop,
          label: _activeEntryId == null ? 'Aufnehmen' : 'Erweitern',
          // Der Mindestabstand kommt von AdSafeArea. Ohne dieses Flag
          // stünden 32 dp statt 16 dp.
          insideAdSafeArea: true,
        ),
        child: Column(
        children: <Widget>[
          if (_state == RecordingState.recording)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Waveform(amplitude: _recorder.amplitude),
            ),
          Expanded(
            child: StreamBuilder<List<Entry>>(
              stream: widget.store.watchAll(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<Entry>> snapshot) {
                final List<Entry> items = snapshot.data ?? const <Entry>[];
                if (items.isEmpty) {
                  return const Center(child: Text('Noch nichts aufgenommen.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                  // Kein zusätzlicher unterer Abstand nötig: die Liste steckt
                  // bereits in AdSafeArea. Freistehende Listen und Raster
                  // nutzen AdSafeArea.scrollPadding(context).
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) {
                    final Entry e = items[i];
                    return ListTile(
                      title: Text(e.title ?? _summary(e)),
                      subtitle: Text(_when(e.createdAt)),
                      onTap: () => setState(() => _activeEntryId = e.id),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'Diesen Eintrag erweitern',
                        onPressed: () {
                          setState(() => _activeEntryId = e.id);
                          _start();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }

  static String _summary(Entry e) {
    final Object? amount = e.data['amount'];
    final Object? merchant = e.data['merchant'];
    if (amount == null && merchant == null) {
      return 'Ohne Titel';
    }
    return <String>[
      if (amount != null) '${(amount as num).toStringAsFixed(2)} €',
      if (merchant != null) merchant as String,
    ].join(' · ');
  }

  static String _when(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}
```

Datei: `apps/<flavor>/lib/main.dart`

```dart
import 'package:capture_core/capture_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_base/shared_base.dart';

import 'src/home_screen.dart';
import 'src/<flavor>_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Reihenfolge: erst alle Schnittstellen binden, dann Oberfläche starten.
  // Keine dieser Zeilen liest einen Schalter — das tun ausschließlich die
  // register*-Funktionen selbst. ARCHITEKTUR.md Abschnitt 5.
  registerFileVault();
  await registerSttEngine();
  await registerMonetize();

  final AppDatabase db = AppDatabase(openConnection(kFlavor));
  final EntryStore store = EntryStore(db, type: kFlavor);

  runApp(<Flavor>App(store: store));
}

class <Flavor>App extends StatelessWidget {
  const <Flavor>App({required this.store, super.key});

  final EntryStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '<Label>',
      theme: <Flavor>Theme.light(),
      darkTheme: <Flavor>Theme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: HomeScreen(store: store),
    );
  }
}
```

---

### Schritt 8 — Auswertung

Aus Frage 3. Eine Datei, keine Bibliothek — die Zeichen-Grundlagen kommen aus
`shared_base/design/`.

Datei: `apps/<flavor>/lib/src/insights_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:shared_base/shared_base.dart';

/// Auswertung. Der Zuschnitt kommt aus Frage 3 des Dialogs:
/// Summe je Zeitraum, Verlauf, Häufigkeitsliste.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({required this.entries, super.key});

  final List<Entry> entries;

  @override
  Widget build(BuildContext context) {
    final Map<String, double> byMonth = <String, double>{};
    for (final Entry e in entries) {
      final Object? amount = e.data['amount'];
      if (amount is! num) {
        continue;
      }
      final String key =
          '${e.createdAt.year}-${e.createdAt.month.toString().padLeft(2, '0')}';
      byMonth[key] = (byMonth[key] ?? 0) + amount.toDouble();
    }

    final List<String> months = byMonth.keys.toList()..sort();
    final double total =
        byMonth.values.fold<double>(0, (double a, double b) => a + b);
    final double max = byMonth.values.isEmpty
        ? 1
        : byMonth.values.reduce((double a, double b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Auswertung')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: <Widget>[
          Text('Gesamt', style: Theme.of(context).textTheme.labelLarge),
          Text('${total.toStringAsFixed(2)} €',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 24),
          for (final String m in months)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(m),
                      Text('${byMonth[m]!.toStringAsFixed(2)} €'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: byMonth[m]! / max,
                    minHeight: 8,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

---

### Schritt 9 — Export

Vier Empfänger plus die Fluchttür. Die Formate liegen in
`shared_base/export/`; die App liefert nur die Zuordnung ihrer Felder.

Datei: `apps/<flavor>/lib/src/<flavor>_export.dart`

```dart
import 'dart:convert';

import 'package:shared_base/shared_base.dart';

/// Die vier Empfänger aus ARCHITEKTUR.md Abschnitt 7, plus Fluchttür.
class <Flavor>Export {
  const <Flavor>Export();

  /// Empfänger: der Nutzer selbst, später.
  String markdown(EntryWithSegments e) {
    final Object? amount = e.entry.data['amount'];
    final Object? merchant = e.entry.data['merchant'];

    return '''
---
id: ${e.entry.id}
typ: ${e.entry.type}
erstellt: ${e.entry.createdAt.toIso8601String()}
${amount == null ? '' : 'betrag: $amount\n'}${merchant == null ? '' : 'haendler: "$merchant"\n'}schlagworte: [${e.entry.tags.map((String t) => '"$t"').join(', ')}]
---

# ${e.entry.title ?? 'Eintrag vom ${_date(e.entry.createdAt)}'}

${merchant == null ? '' : '[[$merchant]]\n'}
${e.segments.map((Segment s) => '## ${_time(s.createdAt)}\n\n${s.transcript ?? '(kein Text)'}').join('\n\n')}
''';
  }

  /// Empfänger: ein KI-Modell. Schema-Kopf, Einträge, vorformulierter Auftrag,
  /// Token-Schätzung.
  String aiBundle(List<EntryWithSegments> entries, {String? auftrag}) {
    final StringBuffer b = StringBuffer()
      ..writeln('# Kontextbündel — <Label>')
      ..writeln()
      ..writeln('## Schema')
      ..writeln('- amount: Zahl, Betrag in Euro')
      ..writeln('- merchant: Zeichenkette, Händler oder Empfänger')
      ..writeln('- confidence: 0..1, Zuverlässigkeit der Erkennung')
      ..writeln('- segments: geordnete Abschnitte eines Eintrags')
      ..writeln()
      ..writeln('## Einträge (${entries.length})')
      ..writeln();

    for (final EntryWithSegments e in entries) {
      b
        ..writeln('### ${e.entry.id}')
        ..writeln('erstellt: ${e.entry.createdAt.toIso8601String()}')
        ..writeln('daten: ${jsonEncode(e.entry.data)}')
        ..writeln('text: ${e.fullText}')
        ..writeln();
    }

    b
      ..writeln('## Auftrag')
      ..writeln(auftrag ??
          'Fasse die Einträge nach Monat und Händler zusammen und '
              'nenne die drei größten Posten.')
      ..writeln()
      ..writeln('## Umfang')
      ..writeln('geschätzte Token: ${_estimateTokens(b.toString())}');

    return b.toString();
  }

  /// Empfänger: andere Software.
  String csv(List<EntryWithSegments> entries) {
    final StringBuffer b = StringBuffer('id;datum;betrag;haendler;text\n');
    for (final EntryWithSegments e in entries) {
      b.writeln(<String>[
        e.entry.id,
        e.entry.createdAt.toIso8601String(),
        (e.entry.data['amount'] ?? '').toString(),
        (e.entry.data['merchant'] ?? '').toString().replaceAll(';', ','),
        e.fullText.replaceAll('\n', ' ').replaceAll(';', ','),
      ].join(';'));
    }
    return b.toString();
  }

  /// Fluchttür: vollständiges JSON. Immer kostenlos, immer sichtbar.
  /// Das ZIP der Originaldateien erzeugt shared_base/export/vault_export.dart.
  String escapeHatch(List<EntryWithSegments> entries) =>
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'app': '<flavor>',
        'exportiert': DateTime.now().toIso8601String(),
        'eintraege': entries
            .map((EntryWithSegments e) => <String, dynamic>{
                  'entry': e.entry.toJson(),
                  'segments':
                      e.segments.map((Segment s) => s.toJson()).toList(),
                })
            .toList(),
      });

  static int _estimateTokens(String s) => (s.length / 3.6).round();

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';

  static String _time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}
```

Der PDF-Export (Empfänger: Mensch mit Autorität) wird über
`shared_base/export/pdf_export.dart` erzeugt; die App liefert nur die
Empfängergestaltung als Parametersatz. Er kommt zur Kaufversion — die
Fluchttür nie.

---

### Schritt 10 — Golden-Tests

Startbildschirm, Liste, Detail — je hell und dunkel. Sechs Bilder,
`ARCHITEKTUR.md` Abschnitt 10.

Datei: `apps/<flavor>/test/golden/home_golden_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:<flavor>/src/<flavor>_theme.dart';

import '../support/fake_store.dart';

void main() {
  for (final (String name, ThemeData theme) in <(String, ThemeData)>[
    ('hell', <Flavor>Theme.light()),
    ('dunkel', <Flavor>Theme.dark()),
  ]) {
    testWidgets('Startbildschirm $name', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844)); // iPhone 14
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: buildFakeHome(),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/home_$name.png'),
      );
    });

    testWidgets('Liste $name', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: buildFakeList(),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/list_$name.png'),
      );
    });

    testWidgets('Detail $name', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: buildFakeDetail(),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/detail_$name.png'),
      );
    });
  }
}
```

Die Hilfsdatei mit den drei `buildFake*`-Funktionen erzeugt `test-loop-free`
zusammen mit der Golden-Einrichtung; sie liefert feste Beispieldaten und eine
feste Uhrzeit, damit die Bilder reproduzierbar sind.

Referenzbilder erzeugen und **auf dem iPhone ansehen, bevor sie eingecheckt
werden**:

```bash
melos exec --scope=<flavor> -- flutter test --update-goldens
```

---

### Schritt 11 — Store-Gerüst und Web-Demo

Datei: `apps/<flavor>/store/metadata.yaml`

```yaml
# Gerüst. Schema identisch zu dem, was store-assets liest und füllt —
# dieser Skill legt nur die leere Form an. Die Texte schreibt store-assets,
# die Screenshots entstehen aus den Integrationstests von test-loop-free
# Stufe 1 und liegen unter integration_test/screenshots/.
flavor: <flavor>
applicationId: de.zeta.<flavor>
sprachen:
  - de-DE

titel: ""              # max 30 Zeichen
kurzbeschreibung: ""   # max 80 Zeichen
langbeschreibung: ""   # max 4000 Zeichen

kategorie: ""
schlagworte: []

datenschutz:
  url: ""                       # trägt store-assets nach
  quelle: store/datenschutz.md
  erhebt_daten: false
  gibt_daten_weiter: false
  hinweis: Verarbeitung ausschliesslich auf dem Geraet, kein Konto, kein Server.

screenshots:
  quelle: integration_test/screenshots
  auswahl:
    - 01-start
    - 02-aufnahme-laeuft
    - 03-erster-eintrag
    - 04-erweitert
    - 05-liste
    - 06-detail
  hintergrund: '101018'
```

Die Web-Demo-Übersicht braucht **keine** Änderung: `tool/gen_web_index.dart`
liest das Verzeichnis `build/web` und nimmt jeden Flavor auf, den `web.yml`
gebaut hat. Der Eintrag entsteht also allein dadurch, dass der Flavor in
`tool/flavors.yaml` steht. Prüfen:

```bash
grep -A3 "^  <flavor>:" tool/flavors.yaml
```

---

### Schritt 12 — Zeitprüfung und Abschluss

```bash
START=$(cat /tmp/app_derive_start)
NOW=$(date -u +%s)
MIN=$(( (NOW - START) / 60 ))
echo "Laufzeit: ${MIN} Minuten"
test "$MIN" -le 120 || echo "ÜBER ZIELZEIT — siehe Abbruchkriterium 1."
```

```bash
melos bootstrap
melos run analyze
melos exec --scope=<flavor> -- flutter test
flutter build web --release --dart-define=FLAVOR=<flavor> \
  --dart-define=STT_ENGINE=web --base-href=/<flavor>/ \
  --output=build/web/<flavor>
git add -A
git commit -m "feat(<flavor>): App aus dem <core>-Kern abgeleitet"
git push
```

Danach die Cloudflare-Vorschau-URL auf dem iPhone öffnen und die manuelle
Prüfliste aus `test-loop-free` durchgehen.

## Abbruchkriterien

Der Skill stoppt und fragt, statt zu raten, wenn:

1. **Die Laufzeit überschreitet zwei Stunden.**
   Das ist kein Zeitproblem, sondern ein Architekturbefund: Es steckt zu viel in
   der App und zu wenig im Kern. Der Skill hält an und legt dem Nutzer die
   konkrete Liste vor — welche Dateien in `apps/<flavor>/` größer als
   ~200 Zeilen sind und welche davon in `shared_base` oder den Kern gehören.
   Er baut **nicht** weiter, bis entschieden ist, was wandert.

   ```bash
   find apps/<flavor>/lib -name '*.dart' -exec wc -l {} + | sort -rn | head
   ```

2. Der benötigte Kern fehlt oder ist unter seiner letzten Pflichtstufe
   (`capture-core-build` bis C, `lens-core-build` bis C).

3. Der Flavor-Name existiert bereits in `tool/flavors.yaml`. Überschreiben wäre
   Datenverlust.

   **Die eine dokumentierte Ausnahme:** `monorepo-bootstrap` legt in
   Schritt 7b die Gerüst-App `apps/vox` an, damit Tag 1 aus
   `WF-01-ERSTE-APP.md` mit einer bedienbaren URL endet. Erkennt der Skill
   genau diese Hülle — `apps/vox/lib/main.dart` enthält `class ScaffoldShell`
   und es gibt weder `lib/src/vox_interpreter.dart` noch `lib/src/vox_theme.dart` —,
   dann füllt er sie und bricht nicht ab. Schritt 2 entfällt in diesem Fall
   (der Flavor-Eintrag steht schon), Schritt 3 beschränkt sich auf das Anlegen
   der fehlenden Verzeichnisse und `drift_worker.js`. Jede andere bestehende
   App wird nicht angefasst.

   ```bash
   test -f apps/<flavor>/lib/main.dart \
     && grep -q 'class ScaffoldShell' apps/<flavor>/lib/main.dart \
     && ! test -f apps/<flavor>/lib/src/<flavor>_interpreter.dart \
     && echo "Gerüst erkannt — füllen statt abbrechen"
   ```

4. **Während des Laufs entsteht Code, der in einer zweiten App nützlich wäre.**
   Sofort anhalten, den Fund benennen, den Nutzer entscheiden lassen: wandert er
   in `shared_base` oder in den Kern? Erst danach weiter. Das ist die Regel aus
   `ARCHITEKTUR.md` Abschnitt 2, und sie zu verschieben kostet später das
   Sechsundzwanzigfache.

5. Eine der fünf Fragen ist unbeantwortet oder widersprüchlich. Nicht raten —
   insbesondere nicht bei Frage 2 (Interpreter-Regeln) und Frage 4 (Empfänger
   des PDF-Exports).

6. Weniger als zwölf Beispielsätze für den Interpreter vorliegen. Der Skill
   erfindet keine — er fragt nach den fehlenden.

7. Der Nutzer verlangt, die Bannerfläche oder den 16-dp-Abstand anzupassen.
   Das ist ein Sperrgrund im Store, keine Gestaltungsfrage.

8. Der Nutzer verlangt eine sechste Konfigurationsdimension über die vier aus
   `ARCHITEKTUR.md` Abschnitt 1 hinaus. Dann gehört sie in den Kern.

## Fertig, wenn

- [ ] `tool/flavors.yaml` enthält den neuen Flavor mit `applicationId de.zeta.<flavor>`
- [ ] `dart run tool/gen_flavors.dart` lief und erzeugte Gradle- und Xcode-Fragmente
- [ ] `apps/<flavor>/` existiert mit `lib/`, `test/`, `integration_test/`, `store/`
- [ ] `apps/<flavor>/web/sqlite3.wasm` und `drift_worker.js` liegen vor
- [ ] `<Flavor>Theme` hat genau vier Farben und zwei Schriftfamilien
- [ ] `<Flavor>Interpreter` ist eine reine Funktion ohne Zustand und ohne Plattform
- [ ] Der Interpreter-Test enthält **mindestens zwölf** realistische Beispielsätze
      und ist grün
- [ ] Der Startbildschirm hat keinen Willkommenstext, keine Tour, keine Kontoabfrage
- [ ] Die Primäraktion ist mindestens 56 dp hoch und hält 16 dp Abstand nach unten
- [ ] Ein bestehender Eintrag lässt sich über „Erweitern" um ein Segment ergänzen
- [ ] Alle vier Exportformate erzeugen gültige Dateien
- [ ] Die Fluchttür ist vorhanden, kostenlos und in den Einstellungen sichtbar
- [ ] Sechs Golden-Bilder existieren: Start, Liste, Detail — je hell und dunkel
- [ ] `apps/<flavor>/integration_test/app_test.dart` spielt den Hauptablauf von
      Anfang bis Ende durch (Definition of Done, Punkt 4 — die Datei liefert
      `test-loop-free` Stufe 1; `app-derive` legt nur das Verzeichnis an und
      prüft, dass der Lauf grün ist)
- [ ] `main.dart` ruft `registerFileVault()`, `registerSttEngine()` und
      `registerMonetize()` vor `runApp`
- [ ] Der Startbildschirm steckt in `AdSafeArea`, Bannerfläche ist reserviert
- [ ] `apps/<flavor>/store/metadata.yaml` existiert
- [ ] `melos run analyze` ohne Befund
- [ ] `flutter build web` läuft durch, der Flavor erscheint in der Übersicht
- [ ] Keine Datei in `apps/<flavor>/lib/` enthält Code, der in eine zweite App gehört
- [ ] Die gemessene Laufzeit liegt unter 120 Minuten

## Beispielaufruf

```
Leite die App onira ab. Kern: capture. Bauplan liegt in
docs/baupläne/onira.md — lies ihn und bestätige die fünf Punkte,
dann bau alles.
```

```
Neue App aus dem Kern: prisma, lens-Kern, Quittungen scannen.
Frag mich die fünf Dinge ab.
```

```
App Nummer 7 anlegen — vox2, capture, gleiche Struktur wie vox,
aber Interpreter für Termine statt Beträge.
```

Weitere Formulierungen, die diesen Skill auslösen:

```
Bau mir die App <Name>.
derive <flavor>.
Neue App ableiten.
```
