---
name: monorepo-bootstrap
description: Legt das komplette Fundament der App-Fabrik an — Melos-Monorepo, shared_base, beide Kernpakete als Gerüst, strenge Analyse-Regeln, Flavor-Konfiguration, alle drei GitHub-Actions-Workflows und features.dart mit allen Schaltern im kostenlosen Zustand. Auslösen mit "Fundament anlegen", "Monorepo aufsetzen", "App-Fabrik starten", "bootstrap das Repo", "leg die Struktur an". Läuft genau einmal pro Repository.
---

# Fundament der App-Fabrik anlegen

## Wann dieser Skill greift

**Greift**, wenn das Repository leer ist oder nur `README.md`, `ARCHITEKTUR.md`
und `TESTLEITER.md` enthält. Der Nutzer sagt sinngemäß: "Leg das Fundament an",
"Setz das Monorepo auf", "Fang an".

**Greift nicht**, wenn `melos.yaml` bereits existiert. Dann ist das Fundament da.
Weiter mit:

| Wunsch | Zuständiger Skill |
|---|---|
| Sprach-Kern bauen | `capture-core-build` |
| Kamera-Kern bauen | `lens-core-build` |
| Neue App ableiten | `app-derive` |
| Tests einrichten | `test-loop-free` |
| Werbung/Kauf-Schnittstellen | `monetize-modul` |

Bei Unsicherheit: `ls melos.yaml` ausführen. Existiert die Datei, abbrechen und
den passenden Skill nennen.

## Voraussetzungen

| Was | Wer liefert es | Prüfbefehl |
|---|---|---|
| Git-Repository, verbunden mit Claude Code | Nutzer (einmalig) | `git rev-parse --show-toplevel` |
| Flutter SDK ≥ 3.24 | Umgebung von Claude Code | `flutter --version` |
| Dart SDK ≥ 3.5 | mit Flutter | `dart --version` |
| `ARCHITEKTUR.md` und `TESTLEITER.md` im Repo-Wurzelverzeichnis | Paket „App-Fabrik" | `ls ARCHITEKTUR.md TESTLEITER.md` |

Fehlt Flutter, bricht der Skill ab und meldet es. Er installiert kein SDK.

Nicht vorausgesetzt: Terminal des Nutzers, Desktop, Android-Gerät, Mac,
bezahltes Konto. Cloudflare- und Firebase-Zugang werden **eingerichtet, aber
nicht benötigt**, damit der Skill durchläuft — fehlende Secrets führen zu einem
übersprungenen CI-Schritt, nicht zu einem Fehler.

## Ablauf

### Schritt 1 — Vorprüfung

```bash
set -e
test -f melos.yaml && { echo "ABBRUCH: melos.yaml existiert bereits."; exit 1; }
flutter --version
git rev-parse --show-toplevel
```

Bricht einer der Befehle, stoppt der Skill hier.

### Schritt 2 — Verzeichnisse anlegen

```bash
mkdir -p \
  .github/workflows \
  packages/shared_base/lib/src/{storage,search,export,monetize,design,config} \
  packages/shared_base/test \
  packages/capture_core/lib/src/{audio,stt,ui} \
  packages/capture_core/test \
  packages/lens_core/lib/src/{camera,recognize,pdf,ui} \
  packages/lens_core/test \
  apps \
  tool \
  ops/policy \
  ops/reviews \
  web_demo
```

### Schritt 3 — `melos.yaml`

Datei: `melos.yaml`

```yaml
name: app_fabrik

packages:
  - packages/**
  - apps/**

command:
  bootstrap:
    runPubGetInParallel: true

scripts:
  analyze:
    description: Statische Analyse über alle Pakete, bricht bei jedem Befund.
    run: melos exec -c 1 -- flutter analyze --fatal-infos --fatal-warnings

  format-check:
    description: Formatierung prüfen, ohne zu ändern.
    run: dart format --output=none --set-exit-if-changed .

  test:
    description: Unit-, Widget- und Golden-Tests aller Pakete mit Tests.
    run: melos exec -c 1 --dir-exists=test -- flutter test --reporter expanded

  test-golden-update:
    description: Golden-Referenzbilder neu erzeugen. Nur nach Sichtprüfung aufrufen.
    run: melos exec -c 1 --dir-exists=test -- flutter test --update-goldens

  build-web:
    description: Web-Build eines Flavors. Aufruf-  melos run build-web -- vox
    run: |
      flutter build web --release \
        --dart-define=FLAVOR=$1 \
        --dart-define=STT_ENGINE=web \
        --base-href=/$1/ \
        --output=build/web/$1

  check-ad-ids:
    description: Bricht, wenn eine echte AdMob-ID im Quelltext auftaucht.
    run: dart run tool/check_ad_ids.dart
```

### Schritt 4 — Strenge Analyse-Regeln

Datei: `analysis_options.yaml`

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    missing_required_param: error
    missing_return: error
    todo: warning
    deprecated_member_use_from_same_package: error
    invalid_annotation_target: ignore
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/generated_plugin_registrant.dart"
    - "build/**"

linter:
  rules:
    always_declare_return_types: true
    avoid_dynamic_calls: true
    avoid_print: true
    avoid_relative_lib_imports: true
    avoid_slow_async_io: true
    cancel_subscriptions: true
    close_sinks: true
    directives_ordering: true
    implicit_call_tearoffs: true
    only_throw_errors: true
    prefer_const_constructors: true
    prefer_const_declarations: true
    prefer_final_locals: true
    prefer_single_quotes: true
    public_member_api_docs: false
    require_trailing_commas: true
    sort_pub_dependencies: true
    unawaited_futures: true
    unnecessary_lambdas: true
    use_build_context_synchronously: true
    use_super_parameters: true
```

`--fatal-infos` in `melos run analyze` macht jeden Hinweis zum Baustopp. Das ist
Absicht: auf dem iPhone ist Nachbessern teurer als Vermeiden.

### Schritt 4b — `pubspec.yaml` im Wurzelverzeichnis

Melos verlangt **ab Version 3.0.0** eine lokale Installation neben
`melos.yaml`. Ein nur global aktiviertes Melos bricht sonst sofort ab:

```
Found a melos.yaml file in "…" but no local installation of Melos.
```

Deshalb bekommt das Wurzelverzeichnis eine eigene `pubspec.yaml`. Sie trägt
keinen Quelltext und steht in keiner Paketliste — die Paketliste bleibt in
`melos.yaml`.

Datei: `pubspec.yaml`

```yaml
# Wurzel-Paket des Monorepos. Enthaelt keinen Quelltext.
#
# Es existiert ausschliesslich, weil Melos ab Version 3.0.0 eine lokale
# Installation neben melos.yaml verlangt — ein global aktiviertes Melos
# bricht sonst mit "no local installation of Melos" ab.
#
# Die Paketliste steht weiterhin in melos.yaml, nicht hier.
name: app_fabrik
description: Wurzel-Paket der App-Fabrik. Traegt nur die Melos-Installation.
publish_to: none
version: 0.1.0

environment:
  sdk: ">=3.5.0 <4.0.0"

dev_dependencies:
  melos: ^6.3.2
```

Ab hier wird Melos **immer** über `dart run melos …` aufgerufen, nie über ein
global aktiviertes `melos`. Das gilt gleichermaßen für die drei
GitHub-Actions-Workflows in Schritt 8 bis 10.

### Schritt 5 — `pubspec.yaml` der Pakete

Datei: `packages/shared_base/pubspec.yaml`

```yaml
name: shared_base
description: Gemeinsamer Unterbau beider Kerne — Speicher, Suche, Export, Monetarisierung, Gestaltung, Schalter.
version: 0.1.0
publish_to: none

environment:
  sdk: ">=3.5.0 <4.0.0"
  flutter: ">=3.24.0"

dependencies:
  archive: ^3.6.1
  crypto: ^3.0.5
  csv: ^6.0.0
  drift: ^2.20.0
  flutter:
    sdk: flutter
  intl: ^0.19.0
  path: ^1.9.0
  path_provider: ^2.1.4
  pdf: ^3.11.1
  printing: ^5.13.2
  shared_preferences: ^2.3.2
  sqlite3_flutter_libs: ^0.5.24
  uuid: ^4.5.1

dev_dependencies:
  build_runner: ^2.4.12
  drift_dev: ^2.20.0
  flutter_lints: ^4.0.0
  flutter_test:
    sdk: flutter
```

Datei: `packages/capture_core/pubspec.yaml`

```yaml
name: capture_core
description: Sprach-Kern — Aufnahme, Wiedergabe, SttEngine mit drei Implementierungen, Eintrags-UI.
version: 0.1.0
publish_to: none

environment:
  sdk: ">=3.5.0 <4.0.0"
  flutter: ">=3.24.0"

dependencies:
  audioplayers: ^6.1.0
  flutter:
    sdk: flutter
  # path, path_provider und uuid werden ab capture-core-build Stufe B von
  # platform_recorder.dart direkt importiert. Ein Paket deklariert, was es
  # selbst importiert — transitiv ueber shared_base zu gehen bricht,
  # sobald shared_base eine dieser Abhaengigkeiten fallen laesst.
  path: ^1.9.0
  path_provider: ^2.1.4
  permission_handler: ^11.3.1
  record: ^5.1.2
  shared_base:
    path: ../shared_base
  speech_to_text: ^7.0.0
  uuid: ^4.5.1

dev_dependencies:
  flutter_lints: ^4.0.0
  flutter_test:
    sdk: flutter
```

Datei: `packages/lens_core/pubspec.yaml`

```yaml
name: lens_core
description: Kamera-Kern — Pipeline, Kantenerkennung, Entzerrung, ScanPipeline, PDF mit Textebene, Dokumentenbibliothek.
version: 0.1.0
publish_to: none

environment:
  sdk: ">=3.5.0 <4.0.0"
  flutter: ">=3.24.0"

dependencies:
  camera: ^0.11.0+2
  flutter:
    sdk: flutter
  google_mlkit_barcode_scanning: ^0.12.0
  google_mlkit_text_recognition: ^0.13.0
  image: ^4.2.0
  pdf: ^3.11.1
  shared_base:
    path: ../shared_base

dev_dependencies:
  flutter_lints: ^4.0.0
  flutter_test:
    sdk: flutter
```

### Schritt 6 — Die Schalter

Datei: `packages/shared_base/lib/src/config/features.dart`

```dart
/// Zentrale Schalter der App-Fabrik.
///
/// Regel aus ARCHITEKTUR.md Abschnitt 5: Kein Schalter darf im App-Code
/// abgefragt werden, nur in der Registrierung (`registry.dart`).
/// Apps sehen ausschließlich die Schnittstellen.
class Features {
  const Features._();

  /// Werbung. Bleibt aus, bis ein Play-Console-Konto existiert.
  static const bool adsEnabled = false;

  /// Käufe. Bleibt aus, bis ein Play-Console-Konto existiert.
  static const bool billingEnabled = false;

  /// Parakeet-Engine. Bleibt aus, bis die Kern-Integration steht und ein
  /// echtes Android-Gerät zum Messen von Ladezeit und Speicher da ist.
  static const bool parakeetEnabled = false;

  /// Welche SttEngine registriert wird: 'web' | 'platform' | 'parakeet'.
  /// Wird beim Web-Build durch die Plattformprüfung in registry.dart
  /// ohnehin auf 'web' gezwungen.
  static const String sttEngine =
      String.fromEnvironment('STT_ENGINE', defaultValue: 'platform');

  /// Dauerhaft aus. Kein Tracking, in keiner App, zu keinem Zeitpunkt.
  static const bool analyticsEnabled = false;

  /// True im Web-Build. Wird von registry.dart gesetzt, nicht von Hand.
  static const bool isWebStub = bool.fromEnvironment('dart.library.js_interop');
}
```

Datei: `packages/shared_base/lib/src/config/brand.dart`

```dart
/// Markenpräfix aller Paket-IDs. Muster aus ARCHITEKTUR.md Abschnitt 9:
/// de.<marke>.<flavor>  —  Beispiel: de.zeta.onira
const String kBrand = 'de.zeta';

/// Aktiver Flavor. Wird beim Build gesetzt:
/// flutter build web --dart-define=FLAVOR=vox
const String kFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'vox');

/// Vollständige Paket-ID des laufenden Builds.
String get kApplicationId => '$kBrand.$kFlavor';
```

Datei: `packages/shared_base/lib/src/config/registry.dart`

```dart
import 'package:flutter/foundation.dart';

import 'features.dart';

/// Zentrale Registrierung aller Schnittstellen-Implementierungen.
///
/// Einzige Stelle im gesamten Monorepo, an der `Features` gelesen wird.
/// Kerne und Apps beziehen Implementierungen ausschließlich über [get].
class Registry {
  Registry._();

  static final Registry instance = Registry._();

  final Map<Type, Object> _bindings = <Type, Object>{};

  /// Bindet eine Implementierung an ihre Schnittstelle.
  void bind<T extends Object>(T implementation) {
    _bindings[T] = implementation;
  }

  /// Liefert die gebundene Implementierung. Wirft, wenn nichts gebunden ist —
  /// das ist ein Programmierfehler, kein Laufzeitfall.
  T get<T extends Object>() {
    final Object? value = _bindings[T];
    if (value == null) {
      throw StateError(
        'Keine Implementierung für $T gebunden. '
        'Registrierung fehlt in configureRegistry().',
      );
    }
    return value as T;
  }

  /// True, wenn die Bindung existiert. Für Tests.
  bool has<T extends Object>() => _bindings.containsKey(T);

  /// Nur für Tests.
  @visibleForTesting
  void reset() => _bindings.clear();
}

/// Ergebnis der Plattform- und Schalterauswertung. Wird von den Kern-Skills
/// (`capture-core-build`, `lens-core-build`, `monetize-modul`) erweitert,
/// indem sie ihre Bindungen hier eintragen.
String resolveSttEngineId() {
  if (kIsWeb) {
    return 'web';
  }
  if (Features.sttEngine == 'parakeet' && !Features.parakeetEnabled) {
    return 'platform';
  }
  return Features.sttEngine;
}
```

Datei: `packages/shared_base/lib/shared_base.dart`

```dart
/// Gemeinsamer Unterbau der App-Fabrik.
///
/// Einzige öffentliche Tür des Pakets. Kern und Apps importieren
/// ausschließlich `package:shared_base/shared_base.dart` — niemals
/// `package:shared_base/src/...`.
///
/// Diese Datei wächst mit den Kern-Skills:
///   capture-core-build Stufe A ergänzt die storage-Exporte
///   monetize-modul     ergänzt die monetize-Exporte
library shared_base;

export 'src/config/brand.dart';
export 'src/config/features.dart';
export 'src/config/registry.dart';
```

### Schritt 7 — Flavor-Konfiguration

Datei: `tool/flavors.yaml` — einzige Wahrheit über alle Apps. `app-derive`
hängt hier je App eine Zeile an.

```yaml
# Muster: <flavor>: { label, core, applicationId }
# core: capture | lens | both
flavors:
  vox:
    label: Vox
    core: capture
    applicationId: de.zeta.vox
```

Datei: `tool/gen_flavors.dart` — erzeugt Gradle- und Xcode-Fragmente aus
`flavors.yaml`, damit niemand von Hand in Gradle-Dateien fasst.

```dart
// Erzeugt android/app/flavors.gradle und ios/Flutter/Flavors.xcconfig
// aus tool/flavors.yaml. Aufruf:  dart run tool/gen_flavors.dart
import 'dart:io';

void main() {
  final File source = File('tool/flavors.yaml');
  if (!source.existsSync()) {
    stderr.writeln('tool/flavors.yaml fehlt.');
    exit(1);
  }

  final List<String> lines = source.readAsLinesSync();
  final List<_Flavor> flavors = <_Flavor>[];
  String? current;
  String? label;
  String? core;
  String? appId;

  for (final String raw in lines) {
    final String line = raw.trimRight();
    if (line.startsWith('  ') && line.endsWith(':') && !line.startsWith('    ')) {
      if (current != null) {
        flavors.add(_Flavor(current, label ?? current, core ?? 'capture',
            appId ?? 'de.zeta.$current'));
      }
      current = line.trim().replaceAll(':', '');
      label = null;
      core = null;
      appId = null;
    } else if (line.trimLeft().startsWith('label:')) {
      label = line.split(':').last.trim();
    } else if (line.trimLeft().startsWith('core:')) {
      core = line.split(':').last.trim();
    } else if (line.trimLeft().startsWith('applicationId:')) {
      appId = line.split(':').last.trim();
    }
  }
  if (current != null) {
    flavors.add(_Flavor(current, label ?? current, core ?? 'capture',
        appId ?? 'de.zeta.$current'));
  }

  for (final _Flavor f in flavors) {
    final Directory android = Directory('apps/${f.name}/android/app');
    if (!android.existsSync()) {
      continue;
    }
    File('apps/${f.name}/android/app/flavors.gradle').writeAsStringSync('''
// ERZEUGT von tool/gen_flavors.dart — nicht von Hand ändern.
android {
    flavorDimensions "app"
    productFlavors {
        ${f.name} {
            dimension "app"
            applicationId "${f.applicationId}"
            resValue "string", "app_name", "${f.label}"
        }
    }
}
''');
    File('apps/${f.name}/ios/Flutter/Flavors.xcconfig').writeAsStringSync('''
// ERZEUGT von tool/gen_flavors.dart — nicht von Hand ändern.
FLAVOR=${f.name}
PRODUCT_BUNDLE_IDENTIFIER=${f.applicationId}
APP_DISPLAY_NAME=${f.label}
''');
  }

  stdout.writeln('Flavors erzeugt: ${flavors.map((_Flavor f) => f.name).join(", ")}');
}

class _Flavor {
  const _Flavor(this.name, this.label, this.core, this.applicationId);
  final String name;
  final String label;
  final String core;
  final String applicationId;
}
```

### Schritt 7b — Gerüst-App `apps/vox`

Ohne mindestens einen Flavor unter `apps/` hat `web.yml` nichts zu bauen, und
Tag 1 aus `WF-01-ERSTE-APP.md` endete mit einer leeren Seite. Deshalb legt das
Fundament **eine** Hülle an: Titel, leere Liste, Aufnahmeknopf-Attrappe. Keine
Fachlogik, kein Interpreter, kein Speicher — das füllt `app-derive` später in
genau dieses Verzeichnis.

```bash
flutter create \
  --project-name vox \
  --org de.zeta \
  --platforms=android,ios,web \
  --template=app \
  apps/vox

rm -rf apps/vox/test
mkdir -p apps/vox/lib/src apps/vox/store apps/vox/integration_test

# flutter create legt eine eigene analysis_options.yaml an. Sie liegt naeher
# an den Quelldateien als die des Wurzelverzeichnisses und wuerde damit die
# strengen Regeln aus Schritt 4 fuer genau diese App aushebeln. Ebenso weg:
# die Beispiel-README und die von flutter create erzeugte pubspec.lock, die
# `melos bootstrap` ohnehin neu schreibt.
rm -f apps/vox/analysis_options.yaml apps/vox/README.md apps/vox/pubspec.lock
```

Datei: `apps/vox/pubspec.yaml`

```yaml
name: vox
description: Vox — App-Fabrik. Gerüst, wird von app-derive gefüllt.
publish_to: none
version: 0.1.0+1

environment:
  sdk: ">=3.5.0 <4.0.0"
  flutter: ">=3.24.0"

dependencies:
  flutter:
    sdk: flutter
  shared_base:
    path: ../../packages/shared_base

dev_dependencies:
  flutter_lints: ^4.0.0
  flutter_test:
    sdk: flutter
```

Datei: `apps/vox/lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:shared_base/shared_base.dart';

/// Gerüst. Beweist an Tag 1, dass die Kette Push -> Build -> Deploy -> iPhone
/// steht. `app-derive` ersetzt Startbildschirm, Theme und Interpreter.
void main() {
  runApp(const VoxApp());
}

class VoxApp extends StatelessWidget {
  const VoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Liest den Flavor aus brand.dart — beweist an Tag 1 zugleich, dass
      // --dart-define=FLAVOR durch den ganzen Build durchkommt.
      title: kFlavor,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: const ScaffoldShell(),
    );
  }
}

class ScaffoldShell extends StatelessWidget {
  const ScaffoldShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // const, weil kFlavor eine Konstante ist. Ohne const meldet
      // prefer_const_constructors einen Hinweis, und --fatal-infos in
      // `melos run analyze` macht daraus einen Baustopp.
      appBar: AppBar(title: const Text(kFlavor)),
      body: Column(
        children: <Widget>[
          const Expanded(
            child: Center(child: Text('Noch nichts aufgenommen.')),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.mic_rounded),
                label: const Text('Aufnehmen'),
              ),
            ),
          ),
          // Reservierte Bannerfläche. monetize-modul ersetzt sie durch
          // AdSafeArea; die Höhe bleibt dieselbe.
          const SizedBox(height: 64),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}
```

Datenbank-Unterstützung für den Web-Build besorgen — sie wird gebraucht,
sobald `app-derive` den Speicher anschließt:

```bash
curl -L -o apps/vox/web/sqlite3.wasm \
  https://github.com/simolus3/sqlite3.dart/releases/latest/download/sqlite3.wasm
```

`drift_worker.js` erzeugt `app-derive`, sobald `drift_dev` im Paket verfügbar
ist. Bis dahin startet die Hülle ohne Datenbank.

`tool/flavors.yaml` enthält `vox` bereits aus Schritt 7. `app-derive` erkennt
diese eine Hülle und füllt sie, statt abzubrechen — die dokumentierte Ausnahme
von seinem Abbruchkriterium 3.

### Schritt 8 — CI: Analyse und Tests

Datei: `.github/workflows/ci.yml`

```yaml
name: ci

on:
  push:
    branches: ["**"]
  pull_request:

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    timeout-minutes: 25
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      # Melos ab 3.0.0 muss lokal neben melos.yaml installiert sein.
      # Die Wurzel-pubspec.yaml aus Schritt 4b traegt diese Installation.
      - name: Melos installieren
        run: dart pub get

      - name: Bootstrap
        run: dart run melos bootstrap

      - name: Formatierung prüfen
        run: dart run melos run format-check

      - name: Statische Analyse
        run: dart run melos run analyze

      - name: Werbe-IDs prüfen
        run: dart run melos run check-ad-ids

      - name: Tests inklusive Golden
        run: dart run melos run test

      - name: Golden-Abweichungen als Artefakt ablegen
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: golden-failures
          path: "**/test/**/failures/**"
          if-no-files-found: ignore
          retention-days: 14
```

Die Golden-Abweichungen landen als ZIP im Actions-Lauf. Auf dem iPhone in Safari
herunterladbar und ansehbar — das ist der Sichtkanal aus `TESTLEITER.md` Stufe 0.

### Schritt 9 — CI: Web-Deploy zu Cloudflare Pages

Datei: `.github/workflows/web.yml`

```yaml
name: web

on:
  push:
    branches: ["**"]

concurrency:
  group: web-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 25
    permissions:
      contents: read
      deployments: write
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      # Melos ab 3.0.0 muss lokal neben melos.yaml installiert sein.
      # Die Wurzel-pubspec.yaml aus Schritt 4b traegt diese Installation.
      - name: Melos installieren
        run: dart pub get

      - name: Bootstrap
        run: dart run melos bootstrap

      - name: Flavors aus tool/flavors.yaml ermitteln
        id: flavors
        run: |
          list=$(grep -E '^  [a-z0-9_]+:$' tool/flavors.yaml | tr -d ' :' | paste -sd, -)
          echo "list=$list" >> "$GITHUB_OUTPUT"
          echo "Gefundene Flavors: $list"

      - name: Alle Flavors bauen
        run: |
          mkdir -p build/web
          IFS=',' read -ra F <<< "${{ steps.flavors.outputs.list }}"
          for f in "${F[@]}"; do
            echo "::group::build $f"
            flutter build web --release \
              --dart-define=FLAVOR="$f" \
              --dart-define=STT_ENGINE=web \
              --base-href="/$f/" \
              --output="build/web/$f"
            echo "::endgroup::"
          done

      - name: Übersichtsseite erzeugen
        run: dart run tool/gen_web_index.dart

      - name: Cloudflare-Zugang vorhanden?
        id: cf
        run: |
          if [ -n "${{ secrets.CLOUDFLARE_API_TOKEN }}" ] && [ -n "${{ secrets.CLOUDFLARE_ACCOUNT_ID }}" ]; then
            echo "ready=true" >> "$GITHUB_OUTPUT"
          else
            echo "ready=false" >> "$GITHUB_OUTPUT"
            echo "Cloudflare-Secrets fehlen — Deploy wird übersprungen, Build bleibt grün."
          fi

      - name: Deploy zu Cloudflare Pages
        if: steps.cf.outputs.ready == 'true'
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: >-
            pages deploy build/web
            --project-name=app-fabrik
            --branch=${{ github.ref_name }}

      - name: Web-Build als Artefakt ablegen
        uses: actions/upload-artifact@v4
        with:
          name: web-${{ github.ref_name }}
          path: build/web
          retention-days: 7
```

**Warum der Build in GitHub Actions läuft und nicht in Cloudflare:** Cloudflare
Pages hat kein Flutter SDK. Der Weg ist deshalb: Actions baut, `wrangler pages
deploy` lädt das fertige Verzeichnis hoch. Cloudflare erzeugt je Branch eine
eigene Vorschau-URL nach dem Muster
`https://<branch>.app-fabrik.pages.dev/<flavor>/`.

Fehlen die Secrets, wird nur der Deploy übersprungen. Der Build bleibt grün, und
das Artefakt `web-<branch>` ist trotzdem herunterladbar. Damit läuft dieser Skill
auch dann durch, wenn der Nutzer Cloudflare noch nicht eingerichtet hat.

Datei: `tool/gen_web_index.dart`

```dart
// Erzeugt build/web/index.html — die Übersicht aller Flavor-Demos.
// app-derive muss diese Datei nicht ändern; sie liest das Verzeichnis.
import 'dart:io';

void main() {
  final Directory root = Directory('build/web');
  if (!root.existsSync()) {
    stderr.writeln('build/web fehlt — erst bauen.');
    exit(1);
  }

  final List<String> flavors = root
      .listSync()
      .whereType<Directory>()
      .map((Directory d) => d.path.split(Platform.pathSeparator).last)
      .toList()
    ..sort();

  final StringBuffer items = StringBuffer();
  for (final String f in flavors) {
    items.writeln('    <li><a href="/$f/">$f</a></li>');
  }

  File('build/web/index.html').writeAsStringSync('''
<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <title>App-Fabrik — Web-Demos</title>
  <style>
    :root { color-scheme: light dark; }
    body { font: 17px/1.5 -apple-system, system-ui, sans-serif; margin: 0; padding: 24px; }
    h1 { font-size: 22px; margin: 0 0 4px; }
    p { margin: 0 0 24px; opacity: .7; }
    ul { list-style: none; padding: 0; margin: 0; }
    li { margin: 0 0 12px; }
    a { display: block; padding: 16px; min-height: 56px; box-sizing: border-box;
        border: 1px solid currentColor; border-radius: 12px; text-decoration: none;
        color: inherit; }
  </style>
</head>
<body>
  <h1>App-Fabrik</h1>
  <p>${flavors.length} Demo(s) · Branch-Vorschau</p>
  <ul>
$items  </ul>
</body>
</html>
''');

  stdout.writeln('Übersicht erzeugt für: ${flavors.join(", ")}');
}
```

### Schritt 10 — CI: Firebase Test Lab

Datei: `.github/workflows/testlab.yml`

```yaml
name: testlab

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      flavor:
        description: Welcher Flavor getestet wird
        required: true
        default: vox

jobs:
  robo:
    runs-on: ubuntu-latest
    timeout-minutes: 40
    steps:
      - uses: actions/checkout@v4

      - name: Firebase-Zugang vorhanden?
        id: fb
        run: |
          if [ -n "${{ secrets.FIREBASE_SERVICE_ACCOUNT }}" ]; then
            echo "ready=true" >> "$GITHUB_OUTPUT"
          else
            echo "ready=false" >> "$GITHUB_OUTPUT"
            echo "FIREBASE_SERVICE_ACCOUNT fehlt — Test Lab wird übersprungen."
            echo "Anleitung: TESTLEITER.md, Abschnitt 'Einmalige Einrichtung'."
          fi

      - uses: subosito/flutter-action@v2
        if: steps.fb.outputs.ready == 'true'
        with:
          channel: stable
          cache: true

      - uses: actions/setup-java@v4
        if: steps.fb.outputs.ready == 'true'
        with:
          distribution: temurin
          java-version: "17"

      - name: Melos installieren
        if: steps.fb.outputs.ready == 'true'
        run: dart pub get

      - name: Bootstrap
        if: steps.fb.outputs.ready == 'true'
        run: dart run melos bootstrap

      - name: APK bauen
        if: steps.fb.outputs.ready == 'true'
        env:
          FLAVOR: ${{ github.event.inputs.flavor || 'vox' }}
        run: |
          cd "apps/$FLAVOR"
          flutter build apk --debug --flavor "$FLAVOR" --dart-define=FLAVOR="$FLAVOR"

      - uses: google-github-actions/auth@v2
        if: steps.fb.outputs.ready == 'true'
        with:
          credentials_json: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}

      - uses: google-github-actions/setup-gcloud@v2
        if: steps.fb.outputs.ready == 'true'

      - name: Robo-Test auf echter Hardware
        if: steps.fb.outputs.ready == 'true'
        env:
          FLAVOR: ${{ github.event.inputs.flavor || 'vox' }}
        run: |
          gcloud firebase test android run \
            --type robo \
            --app "apps/$FLAVOR/build/app/outputs/flutter-apk/app-$FLAVOR-debug.apk" \
            --device model=redfin,version=30,locale=de,orientation=portrait \
            --timeout 5m \
            --results-bucket "${{ secrets.FIREBASE_RESULTS_BUCKET }}" \
            --results-dir "robo-$FLAVOR-${{ github.run_number }}"

      - name: Hinweis, wenn übersprungen
        if: steps.fb.outputs.ready != 'true'
        run: echo "Test Lab übersprungen. Kein Fehler — Gratis-Kontingent nicht eingerichtet."
```

Das Ergebnis (Video, Screenshots, Absturzprotokolle) ist in der Firebase-Konsole
im Safari auf dem iPhone ansehbar.

### Schritt 11 — Werbe-ID-Prüfung

Datei: `tool/check_ad_ids.dart`

```dart
// Bricht den Build, wenn eine echte AdMob-ID im Quelltext auftaucht.
// Test-IDs von Google beginnen mit ca-app-pub-3940256099942544.
// Aufruf: dart run tool/check_ad_ids.dart
import 'dart:io';

const String _googleTestPrefix = 'ca-app-pub-3940256099942544';
final RegExp _adUnit = RegExp(r'ca-app-pub-\d{16}[/~]\d{10}');

void main() {
  final List<String> offenders = <String>[];

  for (final FileSystemEntity e in Directory('.').listSync(recursive: true)) {
    if (e is! File) {
      continue;
    }
    final String p = e.path;
    if (!p.endsWith('.dart') && !p.endsWith('.xml') && !p.endsWith('.plist')) {
      continue;
    }
    if (p.contains('/build/') || p.contains('/.dart_tool/') || p.endsWith('check_ad_ids.dart')) {
      continue;
    }
    for (final RegExpMatch m in _adUnit.allMatches(e.readAsStringSync())) {
      final String id = m.group(0)!;
      if (!id.startsWith(_googleTestPrefix)) {
        offenders.add('$p  ->  $id');
      }
    }
  }

  if (offenders.isEmpty) {
    stdout.writeln('OK: nur Test-Anzeigen-IDs im Quelltext.');
    return;
  }

  stderr.writeln('ABBRUCH: echte AdMob-IDs gefunden.');
  for (final String o in offenders) {
    stderr.writeln('  $o');
  }
  stderr.writeln('Echte IDs gehören ausschließlich in Release-Builds über '
      '--dart-define, niemals in den Quelltext.');
  exit(1);
}
```

### Schritt 12 — `.gitignore`

Datei: `.gitignore`

```gitignore
# Dart / Flutter
.dart_tool/
.packages
.pub-cache/
.pub/
build/
*.g.dart.lock
.flutter-plugins
.flutter-plugins-dependencies
pubspec_overrides.yaml

# Melos
.melos_tool/

# Android
apps/*/android/.gradle/
apps/*/android/local.properties
apps/*/android/key.properties
apps/*/android/app/*.keystore
apps/*/android/app/*.jks
apps/*/android/app/google-services.json

# iOS / macOS
apps/*/ios/Pods/
apps/*/ios/.symlinks/
apps/*/ios/Flutter/Flutter.framework
apps/*/ios/Flutter/Generated.xcconfig
apps/*/ios/Runner/GoogleService-Info.plist
**/*.mode1v3
**/*.pbxuser
**/xcuserdata/

# Test-Ausgaben
**/failures/
coverage/
integration_test/screenshots/

# Sprachmodelle — niemals ins Repo, niemals ins App-Paket
**/models/*.onnx
**/models/*.tar.bz2

# System
.DS_Store
*.log
```

### Schritt 12b — Fundament-Tests

Schritt 2 legt `packages/*/test/` an, füllt die Verzeichnisse aber nicht.
`melos run test` sucht mit `--dir-exists=test` genau dort und ruft
`flutter test` auf — und `flutter test` bricht in einem **leeren**
Testverzeichnis mit einem Fehler ab. Ohne diesen Schritt wäre der erste
`ci`-Lauf rot, und zwar in allen drei Paketen gleichzeitig.

Die Tests prüfen, was das Fundament zusichert: die Schalter stehen im
kostenlosen Zustand, die Marke stimmt, und die Registrierung verhält sich wie
in ARCHITEKTUR.md Abschnitt 4 und 5 beschrieben.

Datei: `packages/shared_base/test/config_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_base/shared_base.dart';

void main() {
  group('Features — kostenloser Zustand', () {
    test('alle kostenpflichtigen Schalter sind aus', () {
      expect(Features.adsEnabled, isFalse);
      expect(Features.billingEnabled, isFalse);
      expect(Features.parakeetEnabled, isFalse);
    });

    test('Analytics ist dauerhaft aus — kein Tracking, in keiner App', () {
      expect(Features.analyticsEnabled, isFalse);
    });

    test('sttEngine ist ohne --dart-define die Plattform-Engine', () {
      expect(Features.sttEngine, 'platform');
    });
  });

  group('Marke und Flavor', () {
    test('kBrand folgt dem Muster aus Abschnitt 9', () {
      expect(kBrand, 'de.zeta');
    });

    test('kApplicationId setzt sich aus Marke und Flavor zusammen', () {
      expect(kApplicationId, '$kBrand.$kFlavor');
    });
  });

  group('Registry', () {
    setUp(Registry.instance.reset);

    test('bind und get liefern dieselbe Instanz zurueck', () {
      const _Beispiel implementierung = _Beispiel();
      Registry.instance.bind<_Beispiel>(implementierung);

      expect(Registry.instance.has<_Beispiel>(), isTrue);
      expect(Registry.instance.get<_Beispiel>(), same(implementierung));
    });

    test('get wirft, wenn nichts gebunden ist — Programmierfehler', () {
      expect(Registry.instance.get<_Beispiel>, throwsStateError);
    });

    test('reset loest alle Bindungen', () {
      Registry.instance.bind<_Beispiel>(const _Beispiel());
      Registry.instance.reset();

      expect(Registry.instance.has<_Beispiel>(), isFalse);
    });
  });

  group('resolveSttEngineId', () {
    test('faellt ohne Web und ohne Parakeet auf die Plattform-Engine', () {
      expect(resolveSttEngineId(), 'platform');
    });
  });
}

class _Beispiel {
  const _Beispiel();
}
```

Datei: `packages/capture_core/test/fundament_test.dart` — und wortgleich
`packages/lens_core/test/fundament_test.dart` mit `lens_core` statt
`capture_core` im Testnamen:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_base/shared_base.dart';

/// Der Sprach-Kern ist an dieser Stelle noch leer — `capture-core-build`
/// fuellt ihn in vier Stufen. Dieser Test haelt nur fest, dass die
/// Abhaengigkeit auf `shared_base` steht und ausschliesslich ueber die
/// oeffentliche Tuer `package:shared_base/shared_base.dart` laeuft.
void main() {
  test('capture_core erreicht shared_base ueber die oeffentliche Tuer', () {
    expect(kBrand, isNotEmpty);
    expect(Features.analyticsEnabled, isFalse);
  });
}
```

`apps/vox` bekommt keinen Test — Schritt 7b löscht `apps/vox/test`, und
`--dir-exists=test` überspringt das Paket dadurch sauber. Die Widget- und
Golden-Tests der App legt `test-loop-free` an.

### Schritt 13 — Bootstrap ausführen und prüfen

```bash
dart pub get                    # installiert Melos aus der Wurzel-pubspec.yaml
dart run melos bootstrap
dart run melos run format-check
dart run melos run analyze
dart run melos run check-ad-ids
dart run melos run test
dart run tool/gen_flavors.dart
```

Alle sieben Befehle müssen ohne Befund durchlaufen. Läuft `analyze` mit Befund,
wird der Befund behoben, nicht die Regel gelockert.

Danach der Nachweis, dass Tag 1 sein Ziel erreicht — ein Web-Build, der sich
öffnen lässt:

```bash
cd apps/vox
flutter build web --release \
  --dart-define=FLAVOR=vox \
  --dart-define=STT_ENGINE=web \
  --base-href=/vox/ \
  --output=../../build/web/vox
cd ../..
dart run tool/gen_web_index.dart
```

### Schritt 14 — Erster Commit

```bash
git add -A
git commit -m "chore: Fundament der App-Fabrik (Melos, Pakete, CI, Schalter)"
git push -u origin main
```

### Schritt 15 — Einrichtungsanleitung für den Nutzer ausgeben

Der Skill gibt am Ende diesen Text aus — nicht als Datei, sondern in die
Unterhaltung, damit der Nutzer ihn auf dem iPhone abarbeiten kann:

```
Drei Dinge, alle vom iPhone aus, alle kostenlos:

1) Cloudflare Pages
   dash.cloudflare.com > Workers & Pages > Create > Pages >
   "Direct Upload" wählen, Projektname exakt: app-fabrik
   Danach: My Profile > API Tokens > Create Token >
   Vorlage "Edit Cloudflare Workers" oder eigenes Token mit
   Berechtigung "Account > Cloudflare Pages > Edit".
   Token und Account-ID (rechts im Dashboard) in GitHub eintragen:
   Repo > Settings > Secrets and variables > Actions > New secret
     CLOUDFLARE_API_TOKEN
     CLOUDFLARE_ACCOUNT_ID

2) Firebase (Gratis-Tarif, nur für Test Lab)
   console.firebase.google.com > Projekt anlegen, Analytics abwählen.
   Projekteinstellungen > Dienstkonten > Neuen privaten Schlüssel erzeugen.
   Den kompletten JSON-Inhalt als GitHub-Secret FIREBASE_SERVICE_ACCOUNT.
   Cloud-Storage-Bucket-Name als Secret FIREBASE_RESULTS_BUCKET.
   Ohne diese Secrets bleibt die CI grün, Test Lab wird übersprungen.

3) Nichts weiter. Kein Play-Konto, kein Apple-Konto, kein Gerät.
```

**Zweiter, klar markierter Pfad — GitHub Pages statt Cloudflare:**
Nur zulässig, wenn das Repository **öffentlich** sein darf. Bei privaten Repos
verlangt GitHub Pages ein bezahltes Konto; das ist der Grund für Cloudflare als
Standard. Wer den öffentlichen Weg will, ersetzt in `web.yml` die beiden
Cloudflare-Schritte durch:

```yaml
      - uses: actions/configure-pages@v5
      - uses: actions/upload-pages-artifact@v3
        with:
          path: build/web
      - id: deployment
        uses: actions/deploy-pages@v4
```

und ergänzt `permissions: pages: write` sowie `id-token: write`. Vorschau-URLs je
Branch entfallen dabei — GitHub Pages kennt nur eine Umgebung. Das ist der
Nachteil, der Cloudflare zum Standard macht.

## Abbruchkriterien

Der Skill stoppt und fragt, statt zu raten, wenn:

1. `melos.yaml` bereits existiert — das Fundament wurde schon gelegt.
2. `flutter --version` fehlschlägt — kein SDK in der Umgebung.
3. Das Arbeitsverzeichnis kein Git-Repository ist.
4. `ARCHITEKTUR.md` fehlt — dann fehlt die verbindliche Grundlage, und jede
   erzeugte Datei wäre geraten.
5. `melos run analyze` nach Schritt 13 Befunde meldet, die nicht durch Anpassung
   der erzeugten Dateien behebbar sind — dann liegt ein Versions-Konflikt vor,
   und der Nutzer entscheidet über das Anheben oder Festnageln von Versionen.
6. Der Nutzer bereits `apps/`-Verzeichnisse mit Inhalt hat — dann wurde außerhalb
   dieses Skills gearbeitet, und Überschreiben wäre Datenverlust.

## Fertig, wenn

- [ ] `melos.yaml` **und** `pubspec.yaml` liegen im Wurzelverzeichnis, und
      `dart pub get && dart run melos bootstrap` läuft ohne Fehler durch
- [ ] `packages/shared_base`, `packages/capture_core`, `packages/lens_core`
      existieren mit je einer gültigen `pubspec.yaml`
- [ ] `analysis_options.yaml` existiert und `melos run analyze` meldet keinen Befund
- [ ] `melos run format-check` meldet keine Abweichung
- [ ] `packages/shared_base/lib/src/config/features.dart` existiert und alle
      Schalter stehen auf dem kostenlosen Zustand (`adsEnabled=false`,
      `billingEnabled=false`, `parakeetEnabled=false`, `analyticsEnabled=false`,
      `sttEngine='platform'`)
- [ ] `packages/shared_base/lib/src/config/brand.dart` enthält `kBrand = 'de.zeta'`
- [ ] `packages/shared_base/lib/src/config/registry.dart` existiert und ist die
      einzige Datei außerhalb von `features.dart`, die `Features` importiert
- [ ] `apps/vox/` existiert als Gerüst und `flutter build web --dart-define=FLAVOR=vox`
      läuft durch
- [ ] `.github/workflows/ci.yml`, `web.yml`, `testlab.yml` existieren
- [ ] `tool/flavors.yaml`, `tool/gen_flavors.dart`, `tool/gen_web_index.dart`,
      `tool/check_ad_ids.dart` existieren
- [ ] `melos run check-ad-ids` meldet „OK"
- [ ] `melos run test` läuft grün — jedes der drei Pakete hat mindestens eine
      Testdatei, sonst bricht `flutter test` am leeren Verzeichnis ab
- [ ] `apps/vox/analysis_options.yaml` wurde entfernt, damit die strengen
      Regeln aus Schritt 4 auch für die Gerüst-App gelten
- [ ] `.gitignore` existiert und schließt `**/models/*.onnx` aus
- [ ] Der erste Push ist erfolgt und der `ci`-Lauf ist grün
- [ ] Der `web`-Lauf ist grün — entweder mit Deploy oder mit der Meldung
      „Cloudflare-Secrets fehlen"
- [ ] Die Einrichtungsanleitung wurde dem Nutzer ausgegeben

## Beispielaufruf

```
Leg das Fundament der App-Fabrik an. ARCHITEKTUR.md und TESTLEITER.md liegen
im Repo. Marke ist de.zeta, erste App wird vox auf dem capture-Kern.
```

Weitere Formulierungen, die diesen Skill auslösen:

```
Setz das Monorepo auf.
Bootstrap das Repo nach der Architektur-Referenz.
Fang an — ich hab ein leeres GitHub-Repo und sonst nichts.
```
