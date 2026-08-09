---
name: policy-watch
description: Überwacht monatlich die Play-Programmrichtlinien, die App-Store-Review-Guidelines und die Ziel-SDK-Fristen, liest die tatsächlichen compileSdk- und targetSdk-Werte aller Apps aus den Gradle-Dateien, schreibt einen Bericht nach ops/policy/<JJJJ-MM>.md und öffnet bei Handlungsbedarf ein GitHub-Issue; ausgelöst durch „Richtlinien prüfen", „targetSdk-Frist checken", „was ändert sich bei Google Play", „Policy-Bericht für diesen Monat".
---

# Richtlinienwache — der einzige Agent, der ab Tag eins läuft

Dieser Skill kostet nichts. Kein Konto, kein Secret, keine API mit Kontingent.
Deshalb ist er der einzige der Betriebs-Skills, der nicht stillgelegt ist,
sondern vom ersten Tag an sinnvoll arbeitet — lange bevor eine App
veröffentlicht wird.

Der Grund ist zeitlicher Natur: Google verlangt jedes Jahr ein neues Mindest-Ziel-SDK
für neue Apps und für Updates bestehender Apps. Wer die Frist verpasst, kann
kein Update mehr einreichen. Eine App, die sechsundzwanzigmal existiert, verpasst
diese Frist sechsundzwanzigmal gleichzeitig.

## Wann dieser Skill greift

Auslöser: „prüf die Richtlinien", „targetSdk-Frist", „was ändert sich bei Google
Play", „Policy-Bericht", „sind meine Apps noch konform", „App-Store-Guidelines
geändert", „monatlicher Bestandslauf".

Greift **nicht**:
- für Abhängigkeits-Aktualisierungen (`flutter pub upgrade`) — das gehört in den
  Betriebs-Workflow `WF-03-BETRIEB.md`, nicht hierher.
- für Rezensionen und Nutzerbeschwerden — das ist `review-agent`.
- für das Hochladen einer angepassten Version — das ist `release-gate`.
- für Data-Safety-Angaben im Store-Eintrag — die pflegt `store-assets`. Dieser
  Skill meldet nur, wenn eine Richtlinienänderung sie betrifft.

## Voraussetzungen

- Repo nach `ARCHITEKTUR.md` mit mindestens einer App unter `apps/`.
- `packages/shared_base/lib/src/config/brand.dart` mit `kBrand` (`de.zeta`),
  öffentlich über `package:shared_base/shared_base.dart`.
- Dart-SDK in der CI (`subosito/flutter-action`), `gh` authentifiziert.
- Werkzeugpaket `tool/pubspec.yaml` (legt `store-assets` an; fehlt es, legt
  Schritt 2 es selbst an).
- Kein Konto, kein Secret, kein Geld. Vorsätzlich.

## Was aus dem Netz geholt wird — und was ausdrücklich nicht

Der Skill nutzt WebFetch und WebSearch auf genau diesen Seiten:

| Zweck | URL |
|---|---|
| Ziel-SDK-Pflicht Android, Stichtage und API-Level | `https://developer.android.com/google/play/requirements/target-sdk` |
| Play-Programmrichtlinien, Änderungsankündigungen | `https://support.google.com/googleplay/android-developer` |
| App-Store-Review-Guidelines | `https://developer.apple.com/app-store/review/guidelines/` |
| Apple-SDK-Pflicht für Einreichungen | `https://developer.apple.com/news/upcoming-requirements/` |

**Es werden ausschließlich Rohdaten und Fristen extrahiert:** API-Level als Zahl,
Stichtag als Datum, Abschnittsnummer als Kennung, Datum der letzten Änderung.
Kein Fließtext wird übernommen, kein Richtlinientext wird ins Repo kopiert, keine
juristische Auslegung wird erzeugt. Der Bericht enthält Zahlen, Daten und Links —
sonst nichts. Wer die Formulierung braucht, öffnet den Link.

## Ablauf

### Schritt 1 — Fristen holen und als Rohdaten ablegen

Claude Code ruft die vier URLs mit WebFetch ab und schreibt daraus **nur** die
folgenden Felder. Steht ein Wert nicht eindeutig auf der Seite, bleibt er `null`
und wird im Bericht als „nicht ermittelt" ausgewiesen — nie geschätzt.

```json
{
  "stand": "2026-08-09",
  "android": {
    "min_target_sdk_updates": null,
    "min_target_sdk_neue_apps": null,
    "stichtag_updates": null,
    "stichtag_neue_apps": null,
    "fristverlaengerung_moeglich_bis": null,
    "quelle": "https://developer.android.com/google/play/requirements/target-sdk",
    "abgerufen_am": null,
    "hinweis": "Google hebt das Mindest-Ziel-SDK jährlich an. Der Stichtag für Updates liegt üblicherweise Ende August; eine Fristverlängerung ist auf Antrag bis in den November möglich. Verbindlich ist ausschliesslich der Wert auf der Quellseite."
  },
  "apple": {
    "min_sdk_xcode": null,
    "stichtag": null,
    "quelle": "https://developer.apple.com/news/upcoming-requirements/",
    "abgerufen_am": null,
    "hinweis": "Apple verlangt, dass Einreichungen mit einer aktuellen Xcode- bzw. SDK-Version gebaut werden. Ohne Apple-Developer-Konto rein informativ."
  },
  "richtlinien": {
    "play_zuletzt_geprueft": null,
    "apple_guidelines_zuletzt_geprueft": null,
    "beobachtete_themen": [
      "Data Safety und Datenschutzerklärung",
      "Berechtigungen fuer Audioaufnahme",
      "Werbe-ID und UMP-Einwilligung",
      "Abonnements und Preisangaben",
      "Konto- und Datenloeschung"
    ]
  }
}
```

Pfad: `ops/policy/fristen.json`

Diese Datei ist der einzige Ort, an dem Netzinhalte landen. Sie wird bei jedem
Lauf überschrieben und im Git-Verlauf mitgeführt — damit ist jederzeit
nachvollziehbar, wann sich eine Frist geändert hat.

### Schritt 2 — Werkzeugpaket sicherstellen

```yaml
# tool/pubspec.yaml
name: fabrik_tools
description: Werkzeuge der App-Fabrik. Kein Bestandteil eines App-Builds.
publish_to: none
environment:
  sdk: ">=3.4.0 <4.0.0"
dependencies:
  image: ^4.2.0
  path: ^1.9.0
  yaml: ^3.1.2
```

```bash
dart pub get --directory tool
```

### Schritt 3 — Gradle-Werte auslesen und Bericht schreiben

```dart
// tool/policy_watch.dart
// Liest die tatsächlichen SDK-Werte aller Apps, vergleicht sie mit den Fristen
// aus ops/policy/fristen.json und schreibt den Monatsbericht.
//
// Aufruf: dart run tool/policy_watch.dart
// Exit 0 = alles konform, Exit 3 = Handlungsbedarf, Exit 2 = Eingabe fehlt.
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class AppSdk {
  AppSdk(this.flavor, this.compileSdk, this.targetSdk, this.minSdk, this.quelle);
  final String flavor;
  final int? compileSdk;
  final int? targetSdk;
  final int? minSdk;
  final String quelle;
}

int main(List<String> args) {
  final fristenDatei = File('ops/policy/fristen.json');
  if (!fristenDatei.existsSync()) {
    stderr.writeln('FEHLT: ops/policy/fristen.json — erst Schritt 1 des Skills ausführen.');
    return 2;
  }
  final fristen = jsonDecode(fristenDatei.readAsStringSync()) as Map<String, dynamic>;
  final android = fristen['android'] as Map<String, dynamic>;
  final minTarget = android['min_target_sdk_updates'] as int?;
  final stichtag = android['stichtag_updates'] as String?;

  final apps = _appsLesen();
  if (apps.isEmpty) {
    stderr.writeln('FEHLT: keine Gradle-Konfiguration unter '
        'apps/*/android/app/build.gradle[.kts] gefunden.');
    return 2;
  }

  final betroffen = <AppSdk>[];
  final unbekannt = <AppSdk>[];
  for (final a in apps) {
    if (a.targetSdk == null) {
      unbekannt.add(a);
    } else if (minTarget != null && a.targetSdk! < minTarget) {
      betroffen.add(a);
    }
  }

  final jetzt = DateTime.now();
  final monat = '${jetzt.year}-${jetzt.month.toString().padLeft(2, '0')}';
  final bericht = StringBuffer()
    ..writeln('# Richtlinienbericht $monat')
    ..writeln()
    ..writeln('Erzeugt am ${jetzt.toIso8601String().substring(0, 10)} durch `policy-watch`.')
    ..writeln('Enthält ausschliesslich Rohdaten und Fristen. Der Wortlaut der Richtlinien')
    ..writeln('steht auf den verlinkten Seiten und wird hier nicht wiedergegeben.')
    ..writeln()
    ..writeln('## Fristen')
    ..writeln()
    ..writeln('| Gegenstand | Wert | Stichtag | Quelle |')
    ..writeln('|---|---|---|---|')
    ..writeln('| Android, Mindest-targetSdk für Updates | ${minTarget ?? 'nicht ermittelt'} | '
        '${stichtag ?? 'nicht ermittelt'} | ${android['quelle']} |')
    ..writeln('| Android, Mindest-targetSdk für neue Apps | '
        '${android['min_target_sdk_neue_apps'] ?? 'nicht ermittelt'} | '
        '${android['stichtag_neue_apps'] ?? 'nicht ermittelt'} | ${android['quelle']} |')
    ..writeln('| Apple, Mindest-SDK für Einreichungen | '
        '${(fristen['apple'] as Map)['min_sdk_xcode'] ?? 'nicht ermittelt'} | '
        '${(fristen['apple'] as Map)['stichtag'] ?? 'nicht ermittelt'} | '
        '${(fristen['apple'] as Map)['quelle']} |')
    ..writeln()
    ..writeln('## Ist-Stand der Apps')
    ..writeln()
    ..writeln('| App | compileSdk | targetSdk | minSdk | Quelle | Status |')
    ..writeln('|---|---|---|---|---|---|');

  for (final a in apps) {
    final status = a.targetSdk == null
        ? 'unlesbar'
        : (minTarget == null
            ? 'Frist unbekannt'
            : (a.targetSdk! < minTarget ? 'ANHEBEN' : 'konform'));
    bericht.writeln('| ${a.flavor} | ${a.compileSdk ?? '?'} | ${a.targetSdk ?? '?'} | '
        '${a.minSdk ?? '?'} | `${a.quelle}` | $status |');
  }

  bericht
    ..writeln()
    ..writeln('## Handlungsbedarf')
    ..writeln();
  if (betroffen.isEmpty && unbekannt.isEmpty) {
    bericht.writeln('Keiner. Alle ${apps.length} Apps liegen auf oder über dem geforderten Ziel-SDK.');
  } else {
    if (betroffen.isNotEmpty) {
      bericht.writeln('${betroffen.length} von ${apps.length} Apps liegen unter dem '
          'geforderten targetSdk $minTarget:');
      bericht.writeln();
      for (final a in betroffen) {
        bericht.writeln('- **${a.flavor}** — targetSdk ${a.targetSdk}, gefordert $minTarget');
      }
      bericht
        ..writeln()
        ..writeln('Vorgehen: compileSdkVersion und targetSdkVersion in der '
            'jeweiligen apps/<flavor>/android/app/build.gradle anheben, '
            '`melos run analyze` und die Golden-Tests laufen lassen, '
            'anschliessend Firebase Test Lab nach `TESTLEITER.md` Stufe 2.')
        ..writeln('Frist: ${stichtag ?? 'nicht ermittelt'}.');
    }
    if (unbekannt.isNotEmpty) {
      bericht
        ..writeln()
        ..writeln('Nicht auslesbar und deshalb manuell zu prüfen:')
        ..writeln();
      for (final a in unbekannt) {
        bericht.writeln('- ${a.flavor} — `${a.quelle}`');
      }
    }
  }

  bericht
    ..writeln()
    ..writeln('## Beobachtete Richtlinienthemen')
    ..writeln();
  for (final t in ((fristen['richtlinien'] as Map)['beobachtete_themen'] as List)) {
    bericht.writeln('- $t');
  }

  final ziel = File('ops/policy/$monat.md');
  ziel.parent.createSync(recursive: true);
  ziel.writeAsStringSync(bericht.toString());
  stdout.writeln('OK  ${ziel.path} geschrieben. '
      '${betroffen.length} Apps mit Handlungsbedarf, ${unbekannt.length} unlesbar.');

  return (betroffen.isEmpty && unbekannt.isEmpty) ? 0 : 3;
}

/// Liest die tatsächlich vorhandenen Gradle-Dateien jeder App.
/// Vorausgesetzt wird nur, was `flutter create` und `monorepo-bootstrap`
/// wirklich anlegen: `android/app/build.gradle` oder `build.gradle.kts`,
/// dazu die von `tool/gen_flavors.dart` erzeugte Groovy-Datei
/// `android/app/flavors.gradle`. Es wird keine Wurzel-`gradle.properties`
/// und keine `fabrik.*`-Property vorausgesetzt — legt kein Skill an.
List<AppSdk> _appsLesen() {
  final apps = <AppSdk>[];
  final wurzel = Directory('apps');
  if (!wurzel.existsSync()) return apps;

  for (final eintrag in wurzel.listSync().whereType<Directory>()) {
    final flavor = p.basename(eintrag.path);
    final app = p.join(eintrag.path, 'android', 'app');

    final kandidaten = <File>[
      File(p.join(app, 'build.gradle')),
      File(p.join(app, 'build.gradle.kts')),
      File(p.join(app, 'flavors.gradle')),
      File(p.join(eintrag.path, 'android', 'build.gradle')),
      File(p.join(eintrag.path, 'android', 'build.gradle.kts')),
      File(p.join(eintrag.path, 'android', 'gradle.properties')),
    ].where((f) => f.existsSync()).toList();

    if (kandidaten.isEmpty) continue;

    // Alle vorhandenen Dateien zusammen betrachten: der SDK-Block steht je
    // nach Flutter-Version in build.gradle oder build.gradle.kts, eine
    // Überschreibung je Flavor in flavors.gradle.
    final inhalt = kandidaten.map((f) => f.readAsStringSync()).join('\n');
    final quelle = kandidaten.map((f) => p.relative(f.path)).join(', ');

    apps.add(AppSdk(
      flavor,
      _wert(inhalt, 'compileSdk'),
      _wert(inhalt, 'targetSdk'),
      _wert(inhalt, 'minSdk'),
      quelle,
    ));
  }
  apps.sort((a, b) => a.flavor.compareTo(b.flavor));
  return apps;
}

/// Erkennt die Schreibweisen, die in echten Flutter-Projekten vorkommen:
///   targetSdkVersion 36            (Groovy, ältere Vorlage)
///   targetSdk = 36                 (Kotlin DSL)
///   targetSdkVersion = 36          (Groovy mit Zuweisung)
///   targetSdkVersion flutter.targetSdkVersion   → symbolisch, nicht auswertbar
/// Symbolische Werte liefern null. Das ist Absicht: der Bericht meldet die App
/// dann als „unlesbar" und nimmt Handlungsbedarf an, statt eine Zahl zu erfinden.
int? _wert(String inhalt, String feld) {
  final direkt =
      RegExp('$feld(?:Version)?\\s*=?\\s*(\\d+)\\b').firstMatch(inhalt);
  if (direkt != null) return int.parse(direkt.group(1)!);
  return null;
}
```

### Schritt 4 — Wo die Werte tatsächlich stehen

Es gibt keine zentrale `gradle.properties` mit `fabrik.*`-Einträgen; kein Skill
legt so etwas an. Der Scanner liest deshalb die Dateien, die wirklich existieren:

| Datei | Was drinsteht |
|---|---|
| `apps/<flavor>/android/app/build.gradle` bzw. `.kts` | `compileSdk`, `minSdk`, `targetSdk` aus der `flutter create`-Vorlage |
| `apps/<flavor>/android/app/flavors.gradle` | Flavor-Block mit `applicationId`, erzeugt von `tool/gen_flavors.dart` (`monorepo-bootstrap`) |
| `apps/<flavor>/android/gradle.properties` | app-eigene Gradle-Einstellungen, falls vorhanden |

Steht dort ein symbolischer Wert wie `targetSdkVersion flutter.targetSdkVersion`,
ist die Stufe nicht aus dem Repo ablesbar — sie stammt aus der installierten
Flutter-Version und ändert sich beim nächsten SDK-Wechsel unbemerkt. Genau dann
meldet der Bericht die App als „unlesbar" und der Skill verlangt eine
ausgeschriebene Zahl:

```groovy
// apps/onira/android/app/build.gradle — ausgeschrieben statt symbolisch,
// damit die Stufe im Repo steht und policy-watch sie prüfen kann.
android {
    namespace "de.zeta.onira"
    compileSdkVersion 36

    defaultConfig {
        minSdkVersion 24
        targetSdkVersion 36
    }
}
```

Beim Anheben werden alle Apps gleich behandelt: dieselbe Zahl in jeder
`build.gradle`. Der Bericht listet jede App einzeln auf, damit sofort sichtbar
ist, wenn eine zurückbleibt.

### Schritt 5 — Issue bei Handlungsbedarf

```bash
dart run tool/policy_watch.dart
CODE=$?
MONAT=$(date +%Y-%m)

if [ "$CODE" -eq 3 ]; then
  gh issue create \
    --title "policy-watch $MONAT: Ziel-SDK oder Richtlinie erfordert Handlung" \
    --label "policy,wartung" \
    --body-file "ops/policy/$MONAT.md"
elif [ "$CODE" -ne 0 ]; then
  echo "policy_watch.dart konnte nicht auswerten, Exit $CODE"
  exit "$CODE"
fi
```

### Schritt 6 — Monatlicher Lauf

```yaml
# .github/workflows/policy-watch.yml
name: policy-watch

on:
  schedule:
    - cron: '0 6 1 * *'   # am Ersten jedes Monats, 06:00 UTC
  workflow_dispatch:

permissions:
  contents: write
  issues: write

jobs:
  wache:
    name: Richtlinien und Ziel-SDK prüfen
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: {channel: stable}

      - name: Rohdaten der Quellseiten sichern
        # Nur Rohabzug fuer den naechsten Claude-Lauf. Es wird nichts
        # interpretiert und nichts in den Bericht uebernommen.
        run: |
          MONAT=$(date +%Y-%m)
          mkdir -p ops/policy
          {
            echo "# Rohabzug $MONAT — nur Zahlen und Datumsangaben relevant"
            for URL in \
              "https://developer.android.com/google/play/requirements/target-sdk" \
              "https://developer.apple.com/news/upcoming-requirements/"; do
              echo "## $URL"
              curl -sSL --max-time 30 "$URL" \
                | sed -e 's/<[^>]*>/ /g' \
                | tr -s ' \n' ' \n' \
                | grep -Eo '(API level [0-9]+|Android [0-9.]+|[0-9]{1,2} (January|February|March|April|May|June|July|August|September|October|November|December) [0-9]{4}|(August|November|April) [0-9]{1,2}, [0-9]{4}|Xcode [0-9.]+)' \
                | sort -u || echo "nicht erreichbar"
            done
          } > "ops/policy/rohdaten-$MONAT.txt"
          cat "ops/policy/rohdaten-$MONAT.txt"

      - name: Auswerten
        id: auswertung
        run: |
          dart pub get --directory tool
          set +e
          dart run tool/policy_watch.dart
          echo "code=$?" >> "$GITHUB_OUTPUT"

      - name: Bericht committen
        run: |
          git config user.name "policy-watch"
          git config user.email "actions@users.noreply.github.com"
          git add ops/policy
          git diff --cached --quiet || git commit -m "chore(policy): Bericht $(date +%Y-%m)"
          git push

      - name: Issue öffnen
        if: steps.auswertung.outputs.code == '3'
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          MONAT=$(date +%Y-%m)
          gh issue create \
            --title "policy-watch $MONAT: Ziel-SDK oder Richtlinie erfordert Handlung" \
            --label "policy,wartung" \
            --body-file "ops/policy/$MONAT.md"

      - name: Erinnerung an den Live-Abgleich
        if: steps.auswertung.outputs.code != '0'
        run: |
          echo "::notice title=Live-Abgleich nötig::ops/policy/fristen.json ist möglicherweise veraltet. In Claude Code 'prüf die Richtlinien' aufrufen — dort werden die Quellseiten mit WebFetch gelesen."
```

### Schritt 7 — Wenn eine Frist zuschlägt

1. In jeder `apps/<flavor>/android/app/build.gradle` `compileSdkVersion` und
   `targetSdkVersion` auf die geforderte Stufe setzen — ausgeschrieben als Zahl,
   nicht symbolisch.
2. `melos run analyze` und die Golden-Tests — `TESTLEITER.md`, Stufe 0.
3. Web-Build bedienen — Stufe 1. Ein SDK-Sprung bricht dort nichts, das ist der Punkt.
4. Firebase Test Lab, Robo-Test auf einem Gerät mit der neuen API-Stufe — Stufe 2.
5. Bei Verhaltensänderungen: Betroffenes gehört in `packages/` oder den Kern,
   nie in `apps/<flavor>/`. Sechsundzwanzig Einzelkorrekturen sind ein Architekturfehler.
6. Erst danach `release-gate` — sofern `PLAY_CONSOLE_READY` an ist.

## Abbruchkriterien

- Eine Quellseite ist nicht erreichbar oder hat ihre Struktur geändert → den
  betroffenen Wert auf `null` lassen, im Bericht als „nicht ermittelt" ausweisen
  und den Nutzer fragen. Niemals eine Frist schätzen oder aus dem Vorjahr fortschreiben.
- `ops/policy/fristen.json` fehlt → Exit 2 mit dem Hinweis auf Schritt 1. Der
  Scanner erfindet keine Sollwerte.
- Der `targetSdk`-Wert einer App ist aus der Gradle-Datei nicht auslesbar, etwa
  weil dort `flutter.targetSdkVersion` steht → als „unlesbar" melden, nicht raten.
  Handlungsbedarf annehmen, nicht ausschliessen, und den Nutzer fragen, ob die
  Stufe ausgeschrieben werden soll.
- Eine App hat gar keine Android-Konfiguration unter `apps/<flavor>/android/app/`
  → überspringen und im Bericht benennen, nicht auf eine Struktur schliessen,
  die kein Skill anlegt.
- Eine Richtlinienänderung berührt Data Safety, Berechtigungen oder Abrechnung →
  stoppen und den Nutzer fragen. Data-Safety-Angaben werden nie automatisch
  geändert; falsche Angaben sind ein Sperrgrund.
- `gh issue create` scheitert (fehlendes Label, fehlende Rechte) → Bericht
  trotzdem committen und den Fehler melden. Der Bericht ist wichtiger als das Issue.
- Mehr als die Hälfte der Apps ist betroffen → nicht app-weise korrigieren,
  sondern in einem Durchgang alle `build.gradle` auf dieselbe Stufe setzen und
  den Nutzer darauf hinweisen, dass es ein gemeinsamer Vorgang ist.

## Fertig, wenn

- [ ] `ops/policy/fristen.json` existiert und trägt ein Abrufdatum.
- [ ] `tool/policy_watch.dart` existiert und läuft mit `dart run tool/policy_watch.dart`.
- [ ] Der Scanner findet für jede App unter `apps/*/android/app/` mindestens eine
      auswertbare Gradle-Datei (`build.gradle`, `build.gradle.kts` oder `flavors.gradle`).
- [ ] Jede App liefert eine ausgeschriebene Zahl für `targetSdk`; keine App steht
      im Bericht als „unlesbar".
- [ ] `ops/policy/<JJJJ-MM>.md` existiert für den laufenden Monat und listet
      jede App mit compileSdk, targetSdk, minSdk und Status.
- [ ] `.github/workflows/policy-watch.yml` existiert mit monatlichem Cron.
- [ ] Ein Probelauf `gh workflow run policy-watch.yml` ist grün und hat den
      Bericht committet.
- [ ] Bei Handlungsbedarf existiert ein GitHub-Issue mit dem Bericht als Text.
- [ ] Der Bericht enthält keinen kopierten Richtlinientext, nur Zahlen, Daten
      und Links.

## Beispielaufruf

```
Prüf die Richtlinien. Hol die aktuelle targetSdk-Frist von Google, lies die
Werte aus allen Apps und sag mir, welche betroffen wären. Bericht nach
ops/policy ablegen und bei Handlungsbedarf ein Issue aufmachen.
```

```
Richt policy-watch ein, monatlicher Lauf. Der soll ab sofort laufen, ich habe
noch kein Play-Konto — das ist der Punkt.
```
