---
name: release-gate
description: Baut die vollständige Veröffentlichungsstrecke nach Google Play — geschlossene Testspur, Zwölf-Tester-Regel, Stufenfreigabe und Versionshinweise aus Commits — prüft dabei zuerst den Schalter PLAY_CONSOLE_READY und beendet sich ohne Fehler, solange kein Play-Konto existiert; ausgelöst durch „App veröffentlichen", „Release bauen", „auf Play hochladen", „geschlossenen Test starten", „Rollout erhöhen".
---

# Veröffentlichungsschleuse — vollständig gebaut, stillgelegt

Dieser Skill ist fertig. Er läuft nur nicht, weil kein Play-Console-Konto existiert.
Das ist kein Mangel, sondern der Entwurf: Alles Kostenpflichtige wird jetzt gebaut
und hinter einem Schalter geparkt. Der Schalter heißt `PLAY_CONSOLE_READY`.
Ist er aus, meldet der Skill präzise, was fehlt, und endet mit Exit 0.

## Wann dieser Skill greift

Auslöser: „veröffentliche onira", „Release bauen", „lade auf Play hoch",
„geschlossenen Test starten", „Rollout auf 20 Prozent", „Versionshinweise erzeugen",
„was fehlt mir noch zum Release".

Greift **nicht**:
- solange nur getestet wird — das ist `test-loop-free` (Web-Build, Golden, Test Lab).
- für Store-Texte, Screenshots und Datenschutzangaben — das ist `store-assets`.
  Dieser Skill liest sie nur, er erzeugt sie nicht.
- für Rezensionen und Antworten nach der Veröffentlichung — das ist `review-agent`.
- für Richtlinien- und Ziel-SDK-Fristen — das ist `policy-watch`, und der läuft
  schon jetzt.

## Voraussetzungen

**Zum Bauen der Strecke (jetzt, kostenlos):**
- Repo nach `ARCHITEKTUR.md`, `packages/shared_base/lib/src/config/brand.dart` mit
  `kBrand`, `kFlavor` und `kApplicationId`.
- `apps/<flavor>/store/` gefüllt durch `store-assets`, und zwar genau in dieser Ablage:
  `store/metadata.yaml` als Quelle, daraus erzeugt `store/de-DE/titel.txt`,
  `store/de-DE/kurzbeschreibung.txt`, `store/de-DE/langbeschreibung.txt`,
  dazu `store/datenschutz.md`, `store/data_safety.yaml` und
  `store/screenshots/{telefon,tablet-7,tablet-10}` samt `feature-grafik.png`.
  Dieser Skill liest diese Ablage und ergänzt nur `store/whatsnew/`.
- `gh` authentifiziert.

**Zum Ausführen der Strecke (später, kostenpflichtig):**
- Play-Console-Entwicklerkonto, einmalig 25 US-Dollar.
- Upload-Key (Keystore) als Base64 in den Repo-Secrets.
- Dienstkonto-JSON aus der Google Cloud Console mit Zugriff auf die Play Console.
- Repo-Variable `PLAY_CONSOLE_READY = true`.

## Ablauf

### Schritt 1 — Schalter prüfen, bevor irgendetwas passiert

`PLAY_CONSOLE_READY` wird an genau zwei Stellen gelesen: in der CI als
`vars.PLAY_CONSOLE_READY` und in der Registrierung von `shared_base`, die
entscheidet, welche `Purchases`- und `AdSurface`-Implementierung eingehängt wird.
**Im App-Code wird der Schalter nie abgefragt** — Apps sehen ausschliesslich die
Schnittstellen, ARCHITEKTUR.md §5. Die Dart-Konstante ist deshalb kein zweiter
Schalter, sondern die Spiegelung, aus der die Registrierung liest; `release_gate.sh`
prüft nur, dass Spiegel und Repo-Variable nicht auseinanderlaufen.

```dart
// packages/shared_base/lib/src/config/release.dart
/// Spiegelung der GitHub-Repo-Variable PLAY_CONSOLE_READY.
/// Gelesen wird dieser Wert ausschliesslich in der Registrierung
/// (registerMonetize / registerPlatform), niemals in App-Code.
/// Solange false: keine Veröffentlichung, keine echte Kaufabwicklung,
/// keine Werbeeinbindung. tool/release_gate.sh prüft die Übereinstimmung
/// mit der Repo-Variable.
const bool kPlayConsoleReady = false;

/// Stufen der Freigabe in Prozent. Reihenfolge ist verbindlich.
const List<double> kRolloutStufen = <double>[0.05, 0.20, 0.50, 1.0];

/// Zwölf-Tester-Regel: Anzahl und Mindestdauer des geschlossenen Tests,
/// bevor ein neues Privatentwickler-Konto Produktionszugang erhält.
const int kMindestTester = 12;
const int kMindestTageDurchgehend = 14;
```

```bash
# tool/release_gate.sh
#!/usr/bin/env bash
# Prüft den Schalter PLAY_CONSOLE_READY. Ist er aus, nennt das Skript exakt,
# was fehlt, und beendet sich mit 0 — ein fehlendes Konto ist kein Fehler.
set -euo pipefail

REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
READY="$(gh api "repos/$REPO/actions/variables/PLAY_CONSOLE_READY" --jq .value 2>/dev/null || echo "false")"
SPIEGEL="$(grep -o 'kPlayConsoleReady = [a-z]*' packages/shared_base/lib/src/config/release.dart | awk '{print $3}')"

if [ "$READY" != "$SPIEGEL" ]; then
  echo "WIDERSPRUCH: Repo-Variable=$READY, release.dart=$SPIEGEL."
  echo "Beide auf denselben Wert setzen, dann erneut starten."
  exit 1
fi

if [ "$READY" != "true" ]; then
  cat <<'MELDUNG'
release-gate ist stillgelegt. PLAY_CONSOLE_READY steht auf false.

Was fehlt, vollständig und in dieser Reihenfolge:

  1. Play-Console-Entwicklerkonto
     Einmalig 25 US-Dollar. Registrierung unter play.google.com/console.
     Für Privatpersonen: Identitätsprüfung, danach Wartezeit bis zur Freischaltung.

  2. Upload-Key (Keystore)
     Wird einmal erzeugt und nie verloren. Ohne ihn ist kein Update mehr möglich.
     Erzeugung siehe Schritt 2 dieses Skills.
     Danach als Repo-Secrets hinterlegen:
       ANDROID_KEYSTORE_BASE64      Keystore, base64-kodiert
       ANDROID_KEYSTORE_PASSWORD    Passwort des Keystores
       ANDROID_KEY_ALIAS            Alias des Schlüssels
       ANDROID_KEY_PASSWORD         Passwort des Schlüssels

  3. App-Signatur durch Google Play
     In der Play Console aktivieren. Google verwaltet dann den Signaturschlüssel,
     hochgeladen wird ausschliesslich mit dem Upload-Key aus Punkt 2.

  4. Dienstkonto-JSON
     Google Cloud Console: Dienstkonto anlegen, JSON-Schlüssel erzeugen,
     in der Play Console unter Nutzer und Rechte einladen und für
     "Releases in Testspuren verwalten" sowie "Produktions-Releases" freigeben.
     Danach als Repo-Secret hinterlegen:
       PLAY_SERVICE_ACCOUNT_JSON    vollständiger JSON-Inhalt

  5. Schalter umlegen
       gh variable set PLAY_CONSOLE_READY --body true
     und in packages/shared_base/lib/src/config/release.dart
       const bool kPlayConsoleReady = true;

Alles bis hierhin ist bereits gebaut: Workflow, Signaturkonfiguration,
Versionshinweise, Testerliste, Stufenfreigabe. Es fehlt nur das Konto.
MELDUNG
  exit 0
fi

echo "PLAY_CONSOLE_READY=true — Veröffentlichungsstrecke ist scharf."
```

```bash
chmod +x tool/release_gate.sh && ./tool/release_gate.sh
```

Ist der Schalter aus, endet der Skill hier. Ohne Fehler, ohne Warnung, ohne
angefangene Arbeit. Alle folgenden Schritte laufen nur bei `true`.

### Schritt 2 — Upload-Key erzeugen und hinterlegen

Einmal je Marke, nicht je App. Der Befehl läuft in der CI, weil kein Desktop
existiert; das Ergebnis wird sofort als Secret gesetzt und nirgends abgelegt.

```bash
keytool -genkeypair -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -alias zeta-upload \
  -dname "CN=de.zeta, O=de.zeta, C=DE" \
  -storepass "$KS_PASS" -keypass "$KEY_PASS"

base64 -w0 upload-keystore.jks | gh secret set ANDROID_KEYSTORE_BASE64
printf '%s' "$KS_PASS"  | gh secret set ANDROID_KEYSTORE_PASSWORD
printf '%s' "zeta-upload" | gh secret set ANDROID_KEY_ALIAS
printf '%s' "$KEY_PASS" | gh secret set ANDROID_KEY_PASSWORD
shred -u upload-keystore.jks
```

Zusätzlich muss die Datei selbst gesichert werden — geht sie verloren, ist die
App nicht mehr aktualisierbar. Die base64-Zeichenkette wandert in den
Passwortspeicher des Nutzers, nicht ins Repo.

### Schritt 3 — Signaturkonfiguration in Gradle

```kotlin
// apps/onira/android/app/build.gradle.kts — Ergänzung, kein Ersatz
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(FileInputStream(f))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
    buildTypes {
        getByName("release") {
            // Fällt auf Debug-Signatur zurück, solange kein Keystore da ist —
            // damit bleibt der Release-Build lokal und in der CI baubar.
            signingConfig = if (keystoreProperties.isEmpty)
                signingConfigs.getByName("debug")
            else
                signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}
```

### Schritt 4 — Versionshinweise aus Conventional Commits

```dart
// tool/whatsnew.dart
// Erzeugt die Versionshinweise aus den Commits seit dem letzten Tag.
// Aufruf: dart run tool/whatsnew.dart --flavor=onira
// Ergebnis: apps/<flavor>/store/whatsnew/whatsnew-de-DE (max. 500 Zeichen)
import 'dart:io';

const _maxZeichen = 500;

const _rubriken = <String, String>{
  'feat': 'Neu',
  'fix': 'Behoben',
  'perf': 'Schneller',
};

int main(List<String> args) {
  final flavor = args
      .firstWhere((a) => a.startsWith('--flavor='), orElse: () => '')
      .replaceFirst('--flavor=', '');
  if (flavor.isEmpty) {
    stderr.writeln('FEHLT: --flavor=<name>');
    return 2;
  }

  final letzterTag = Process.runSync(
    'git',
    ['describe', '--tags', '--abbrev=0', '--match', '$flavor-v*'],
  );
  final bereich = letzterTag.exitCode == 0
      ? '${(letzterTag.stdout as String).trim()}..HEAD'
      : 'HEAD';

  final log = Process.runSync('git', ['log', bereich, '--pretty=format:%s']);
  final zeilen = (log.stdout as String).split('\n').where((z) => z.trim().isNotEmpty);

  final gesammelt = <String, List<String>>{for (final r in _rubriken.values) r: <String>[]};
  final muster = RegExp(r'^(feat|fix|perf)(\(([^)]+)\))?!?:\s*(.+)$');

  for (final z in zeilen) {
    final m = muster.firstMatch(z.trim());
    if (m == null) continue;
    final bereichName = m.group(3);
    // Commits anderer Apps ignorieren; Commits ohne Bereich gelten für alle.
    if (bereichName != null && bereichName != flavor && bereichName != 'core') continue;
    final rubrik = _rubriken[m.group(1)!]!;
    final text = m.group(4)!.trim();
    gesammelt[rubrik]!.add(text[0].toUpperCase() + text.substring(1));
  }

  final puffer = StringBuffer();
  for (final rubrik in _rubriken.values) {
    final punkte = gesammelt[rubrik]!;
    if (punkte.isEmpty) continue;
    puffer.writeln('$rubrik:');
    for (final p in punkte) {
      puffer.writeln('- $p');
    }
    puffer.writeln();
  }

  var text = puffer.toString().trim();
  if (text.isEmpty) {
    text = 'Kleinere Verbesserungen und Fehlerbehebungen.';
  }
  if (text.length > _maxZeichen) {
    text = '${text.substring(0, _maxZeichen - 1).trimRight()}…';
  }

  final ziel = File('apps/$flavor/store/whatsnew/whatsnew-de-DE');
  ziel.parent.createSync(recursive: true);
  ziel.writeAsStringSync('$text\n');
  stdout.writeln('OK  ${ziel.path} (${text.length} Zeichen)');
  return 0;
}
```

### Schritt 5 — Geschlossene Testspur und die Zwölf-Tester-Regel

Für neu angelegte Privatentwickler-Konten verlangt Google vor dem Zugang zur
Produktionsspur einen geschlossenen Test: **mindestens zwölf Tester, die
durchgehend vierzehn Tage lang teilnehmen (opt-in)**. Springt ein Tester
zwischendurch ab, beginnt die Frist für die Gruppe neu. Deshalb wird die Liste
im Repo geführt und mitgezählt.

```markdown
# ops/testers/onira.md
# Geschlossener Test — onira

Spur: closed testing, Track-Name `alpha`
Verteilung: Google-Gruppe `zeta-tester@googlegroups.com`

## Regel
- Mindestens 12 Tester, die dem Test aktiv beigetreten sind (opt-in).
- 14 Tage ununterbrochen. Austritt eines Testers setzt die Frist für die
  Gruppe zurück.
- Erst danach lässt sich der Produktionszugang beantragen.

## Zählung
| Feld | Wert |
|---|---|
| Startdatum des laufenden Fensters | — wird beim ersten Rollout gesetzt |
| Teilnehmer aktuell | — aus der Play Console ablesen |
| Frühestens Produktionsantrag | Startdatum + 14 Tage |

## Testerliste
Eine E-Mail-Adresse je Zeile in `ops/testers/testers.txt`. Diese Datei wird in
die Google-Gruppe übernommen, nicht direkt in die Play Console — so lässt sich
die Liste ändern, ohne einen neuen Release zu erzeugen.

## Aufgabe je Tester
1. Einladungslink öffnen, Test beitreten.
2. App installieren und in den 14 Tagen mindestens einmal öffnen.
3. Nicht austreten, nicht deinstallieren.
```

```text
# ops/testers/testers.txt
# Eine Adresse je Zeile. Mindestens 12. Kommentarzeilen beginnen mit #.
# Nach jeder Änderung: Google-Gruppe aktualisieren, nicht die Play Console.
```

### Schritt 6 — Der Workflow

```yaml
# .github/workflows/release.yml
name: release

on:
  workflow_dispatch:
    inputs:
      flavor:
        description: Flavor, z. B. onira
        required: true
        type: string
      track:
        description: Play-Spur
        required: true
        default: internal
        type: choice
        options: [internal, alpha, beta, production]
      rollout:
        description: Anteil der Stufenfreigabe
        required: true
        default: '0.05'
        type: choice
        options: ['0.05', '0.20', '0.50', '1.0']

permissions:
  contents: read

jobs:
  schleuse:
    name: Schalter prüfen
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: PLAY_CONSOLE_READY
        run: |
          if [ "${{ vars.PLAY_CONSOLE_READY }}" != "true" ]; then
            echo "::notice title=release-gate stillgelegt::PLAY_CONSOLE_READY ist nicht true. Es fehlen: Play-Console-Konto (25 USD), Upload-Key als ANDROID_KEYSTORE_BASE64, Dienstkonto-JSON als PLAY_SERVICE_ACCOUNT_JSON. Der Lauf endet ohne Fehler."
            exit 0
          fi
          echo "Schalter an."

  release:
    name: Bauen und hochladen
    needs: schleuse
    if: vars.PLAY_CONSOLE_READY == 'true'
    runs-on: ubuntu-latest
    env:
      FLAVOR: ${{ inputs.flavor }}
    steps:
      - uses: actions/checkout@v4
        with: {fetch-depth: 0}   # für git describe in whatsnew.dart

      - uses: actions/setup-java@v4
        with: {distribution: temurin, java-version: '17'}
      - uses: subosito/flutter-action@v2
        with: {channel: stable}

      - name: Abhängigkeiten
        run: dart pub global activate melos && melos bootstrap

      - name: Store-Material vorhanden
        # Exakt die Ablage, die store-assets erzeugt. metadata.yaml ist die
        # Quelle, de-DE das Erzeugnis — beides muss da sein.
        run: |
          set -e
          for d in metadata.yaml de-DE/titel.txt de-DE/kurzbeschreibung.txt \
                   de-DE/langbeschreibung.txt datenschutz.md data_safety.yaml; do
            test -s "apps/$FLAVOR/store/$d" || { echo "FEHLT: apps/$FLAVOR/store/$d — store-assets ausführen"; exit 1; }
          done
          test -s "apps/$FLAVOR/web/datenschutz.html" || { echo "FEHLT: apps/$FLAVOR/web/datenschutz.html — die Pflicht-URL existiert sonst nicht"; exit 1; }
          for f in telefon tablet-7 tablet-10; do
            test -d "apps/$FLAVOR/store/screenshots/$f" || { echo "FEHLT: Screenshots $f"; exit 1; }
          done
          test -s "apps/$FLAVOR/store/screenshots/feature-grafik.png" || { echo "FEHLT: Feature-Grafik"; exit 1; }

      - name: Zeichenlängen prüfen
        working-directory: apps/${{ env.FLAVOR }}
        run: flutter test test/store_texte_test.dart

      - name: Versionshinweise erzeugen
        run: |
          dart pub get --directory tool
          dart run tool/whatsnew.dart --flavor=$FLAVOR
          cat apps/$FLAVOR/store/whatsnew/whatsnew-de-DE

      - name: Keystore herstellen
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > apps/$FLAVOR/android/upload-keystore.jks
          cat > apps/$FLAVOR/android/key.properties <<EOF
          storeFile=upload-keystore.jks
          storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
          keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
          EOF

      - name: App Bundle bauen
        working-directory: apps/${{ env.FLAVOR }}
        # --dart-define=FLAVOR ist Pflicht, nicht Kosmetik: kFlavor in
        # packages/shared_base/lib/src/config/brand.dart fällt sonst auf 'vox'
        # zurück. Die Folge wäre eine ausgelieferte App mit falschem
        # Entry.type, falschem Datenbanknamen und falscher Ablage.
        # Gleiche Definitionen wie in web.yml und testlab.yml.
        run: |
          flutter build appbundle --release \
            --flavor $FLAVOR \
            -t lib/main.dart \
            --dart-define=FLAVOR=$FLAVOR \
            --dart-define=STT_ENGINE=platform

      - name: Hochladen zu Google Play
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_SERVICE_ACCOUNT_JSON }}
          packageName: de.zeta.${{ env.FLAVOR }}
          releaseFiles: apps/${{ env.FLAVOR }}/build/app/outputs/bundle/${{ env.FLAVOR }}Release/app-${{ env.FLAVOR }}-release.aab
          track: ${{ inputs.track }}
          status: ${{ inputs.rollout == '1.0' && 'completed' || 'inProgress' }}
          userFraction: ${{ inputs.rollout != '1.0' && inputs.rollout || '' }}
          whatsNewDirectory: apps/${{ env.FLAVOR }}/store/whatsnew
          mappingFile: apps/${{ env.FLAVOR }}/build/app/outputs/mapping/${{ env.FLAVOR }}Release/mapping.txt

      - name: Aufräumen
        if: always()
        run: rm -f apps/$FLAVOR/android/upload-keystore.jks apps/$FLAVOR/android/key.properties

      - name: Tag setzen
        run: |
          VERSION=$(grep '^version:' apps/$FLAVOR/pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
          git tag "$FLAVOR-v$VERSION" && git push origin "$FLAVOR-v$VERSION"
```

Alternative mit fastlane, falls mehrere Spuren gleichzeitig bedient werden:

```ruby
# apps/onira/android/fastlane/Fastfile
default_platform(:android)
platform :android do
  desc "Bundle in eine Spur hochladen, Stufenfreigabe steuerbar"
  lane :deploy do |options|
    supply(
      package_name: "de.zeta.onira",
      aab: "../build/app/outputs/bundle/oniraRelease/app-onira-release.aab",
      track: options[:track] || "internal",
      rollout: options[:rollout] || "0.05",
      release_status: options[:rollout].to_f >= 1.0 ? "completed" : "inProgress",
      metadata_path: "../../store",
      json_key_data: ENV["PLAY_SERVICE_ACCOUNT_JSON"],
      skip_upload_images: false,
      skip_upload_screenshots: false
    )
  end
end
```

### Schritt 7 — Stufenfreigabe fahren

Reihenfolge ist verbindlich: 5, 20, 50, 100. Zwischen zwei Stufen liegen
mindestens 24 Stunden, in denen Abstürze und Rezensionen beobachtet werden.

```bash
gh workflow run release.yml -f flavor=onira -f track=production -f rollout=0.05
# 24 Stunden warten, Absturzrate in der Play Console prüfen
gh workflow run release.yml -f flavor=onira -f track=production -f rollout=0.20
gh workflow run release.yml -f flavor=onira -f track=production -f rollout=0.50
gh workflow run release.yml -f flavor=onira -f track=production -f rollout=1.0
```

Bricht eine Stufe: Rollout in der Play Console anhalten, Fehler beheben, neue
Versionsnummer, wieder bei 0.05 anfangen. Ein angehaltener Rollout wird nie
fortgesetzt, sondern ersetzt.

## Abbruchkriterien

- `PLAY_CONSOLE_READY` ist nicht `true` → Meldung aus Schritt 1, Exit 0, Ende.
- Repo-Variable und `kPlayConsoleReady` stehen auseinander → Exit 1, Nutzer fragen,
  welcher Wert gilt. Nie selbst entscheiden.
- Ein Secret fehlt → benennen, welches, und Ende. Keine Ersatzwerte, keine
  Debug-Signatur für einen echten Upload.
- Store-Material unvollständig → auf `store-assets` verweisen und stoppen.
- Track ist `production`, das Konto ist neu und die Zwölf-Tester-Regel ist noch
  nicht erfüllt → stoppen und den Stand aus `ops/testers/<flavor>.md` melden.
- Rollout soll direkt auf 1.0 gehen, ohne dass 0.05 gelaufen ist → nachfragen.
- Die Versionsnummer in `pubspec.yaml` ist gegenüber dem letzten Tag unverändert
  → stoppen, Play nimmt denselben Versionscode kein zweites Mal an.

## Fertig, wenn

- [ ] `tool/release_gate.sh` existiert, ist ausführbar und endet bei ausgeschaltetem
      Schalter mit Exit 0 und der vollständigen Fehlliste.
- [ ] `packages/shared_base/lib/src/config/release.dart` existiert mit `kPlayConsoleReady`,
      `kRolloutStufen`, `kMindestTester`, `kMindestTageDurchgehend`.
- [ ] `.github/workflows/release.yml` existiert und alle Upload-Schritte hängen an
      `if: vars.PLAY_CONSOLE_READY == 'true'`.
- [ ] Jeder `flutter build`-Aufruf übergibt `--dart-define=FLAVOR=$FLAVOR`;
      kein Build verlässt sich auf den Standardwert von `kFlavor`.
- [ ] `tool/whatsnew.dart` erzeugt `apps/<flavor>/store/whatsnew/whatsnew-de-DE`
      mit höchstens 500 Zeichen.
- [ ] Die Signaturkonfiguration in `apps/<flavor>/android/app/build.gradle.kts`
      fällt ohne Keystore auf die Debug-Signatur zurück, der Release-Build bricht nicht.
- [ ] `ops/testers/<flavor>.md` und `ops/testers/testers.txt` existieren.
- [ ] Ein Probelauf `gh workflow run release.yml -f flavor=onira -f track=internal
      -f rollout=0.05` läuft grün durch und endet mit der Stillgelegt-Meldung.
- [ ] Kein Keystore, kein Passwort und kein Dienstkonto-JSON liegt im Repo.

## Beispielaufruf

```
Bau die Veröffentlichungsstrecke für onira fertig und sag mir, was mir noch fehlt.
Wenn PLAY_CONSOLE_READY aus ist, brich sauber ab, ich habe noch kein Play-Konto.
```

```
PLAY_CONSOLE_READY steht jetzt auf true. Starte den geschlossenen Test für onira
in der Alpha-Spur und erzeug die Versionshinweise aus den Commits.
```
