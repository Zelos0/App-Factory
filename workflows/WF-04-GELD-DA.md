# WF-04 — Die Aufwachliste

Alles, was Geld kostet, ist gebaut und stillgelegt. Dieses Dokument sagt, in
welcher Reihenfolge es aufgeweckt wird, sobald Geld da ist — und in welcher
Reihenfolge ausdrücklich **nicht**.

Drei Wellen in dieser Folge, nach `TESTLEITER.md` Stufe 3: erst 25 $ Play
Console, dann 60–120 € gebrauchtes Android-Gerät, zuletzt 99 $ Apple. Android
ist die Auslieferungsplattform, iOS zunächst nur Testkanal. Eine Welle wird
vollständig abgeschlossen, bevor die nächste beginnt — bei zwei offenen Wellen
ist nach einem Bruch nicht mehr feststellbar, welcher Schalter es war.

## Die Schalterdatei

Alle Verhaltensschalter stehen an einer Stelle:
`packages/shared_base/lib/src/config/features.dart`. Ausgangszustand, auf die
Schalter reduziert — **alle Verweise in diesem Dokument nennen Schalternamen,
nie Zeilennummern**, weil die echte Datei Dokumentationskommentare trägt und
jede Zeilenangabe beim nächsten Kommentar ins Leere geht.

```dart
class Features {
  static const bool   adsEnabled       = false;  // Welle 1, Schritt 7
  static const bool   billingEnabled   = false;  // Welle 1, Schritt 6
  static const bool   parakeetEnabled  = false;  // Welle 2, Schritt 4
  static const String sttEngine        =
      String.fromEnvironment('STT_ENGINE', defaultValue: 'platform');
  static const bool   analyticsEnabled = false;  // dauerhaft aus
  static const bool   isWebStub =
      bool.fromEnvironment('dart.library.js_interop');
}
```

`analyticsEnabled` wird **in keiner Welle** angefasst. Kein Tracking ist eine
Produktentscheidung, keine Kostenfrage. `isWebStub` und `sttEngine` werden
ebenfalls nie von Hand gesetzt: Beide kommen zur Bauzeit aus der Umgebung, der
Web-Build erzwingt `STT_ENGINE=web`.

# Welle 1 — 25 $ Play Console

Der größte Sprung: schaltet Veröffentlichung, Kauf und Werbung frei.

## Vorbedingungen — alle sechs, bevor der erste Schalter umgelegt wird

| # | Vorbedingung | Prüfbar durch |
|---|---|---|
| 1 | Play-Console-Konto angelegt, 25 $ bezahlt, Identität geprüft | Konto zeigt Status „Verifiziert" |
| 2 | Mindestens eine App erfüllt die Definition of Done vollständig | `ARCHITEKTUR.md` §10, alle zehn Punkte |
| 3 | `apps/<flavor>/store/` vollständig | Titel 30 Z., Kurzbeschreibung 80 Z., Langbeschreibung, Datenschutzangaben, Screenshots |
| 4 | `ops/policy/vor-release.md` abgearbeitet | Einstufung „vor Veröffentlichung" aus `WF-03` erledigt |
| 5 | Upload-Signaturschlüssel als GitHub-Secret hinterlegt | `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_PASSWORD` existieren |
| 6 | Play-Dienstkonto erzeugt, JSON als Secret hinterlegt | `PLAY_SERVICE_ACCOUNT_JSON` existiert |

Vorbedingung 2 heißt **eine** App. Die erste Veröffentlichung ist ein
Lernvorgang; sie mit sechsundzwanzig Apps zu machen, multipliziert jeden Fehler.

## Schalterliste, in dieser Reihenfolge

| Schritt | Ort | Schalter | Von | Auf |
|---|---|---|---|---|
| 1 | GitHub-Repo-Variable, gelesen als `vars.PLAY_CONSOLE_READY` in `.github/workflows/release.yml` | `PLAY_CONSOLE_READY` | nicht gesetzt | `true` |
| 6 | `packages/shared_base/lib/src/config/features.dart` | `billingEnabled` | `false` | `true` |
| 7 | `packages/shared_base/lib/src/config/features.dart` | `adsEnabled` | `false` | `true` |
| 9 | GitHub-Repo-Variable, gelesen als `vars.PLAY_CONSOLE_READY` in `.github/workflows/reviews.yml` | `PLAY_CONSOLE_READY` | siehe Schritt 1 | `true` |
| 9 | GitHub-Repo-Variable, gelesen als `vars.REVIEW_AUTOREPLY` in `.github/workflows/reviews.yml` | `REVIEW_AUTOREPLY` | `false` | bleibt `false`, bis Entwürfe geprüft sind |

Zwischen Schritt 1 und Schritt 6 liegen vierzehn Tage. Das ist kein Versehen.

### Schritt 1 — `release-gate` aufwecken
```
Setze die Repo-Variable mit gh variable set PLAY_CONSOLE_READY --body true und
führe release-gate im Prüfmodus aus. release.yml liest sie als
vars.PLAY_CONSOLE_READY. Berichte, welche Voraussetzungen erfüllt und welche
fehlend sind. Noch nichts hochladen.
```

Geprüft werden Konto, Dienstkonto-Schlüssel, Signaturzertifikat, Store-Material, Datenschutzerklärung, Paket-ID `de.zeta.<flavor>`, Zielgruppe, Inhaltsbewertung.

### Schritt 2 — Store-Material hochladen
```
Führe store-assets für vox im Upload-Modus aus. Lade Titel, Kurzbeschreibung,
Langbeschreibung, Datenschutzangaben und Screenshots aus apps/vox/store/ in die
Play Console. Danach: Liste, was die Console zusätzlich verlangt und im Repo
nicht vorhanden ist.
```

Screenshots kommen aus den CI-Integrationstests. Verlangt die Console ein Format,
das die Tests nicht liefern (Feature-Grafik 1024×500), wird es als Test erzeugt —
handgebasteltes Material ist bei App 14 nicht reproduzierbar.

### Schritt 3 — Geschlossene Testspur anlegen
```
Führe release-gate aus, Ziel: geschlossene Testspur. Erzeuge das signierte
App-Bundle mit dem Flavor vox, lade es in die geschlossene Spur, erzeuge die
Versionshinweise aus den Commits seit dem letzten Tag.
```

**In diesem Bundle sind `billingEnabled` und `adsEnabled` noch `false`.** Der erste Lauf prüft nur, ob die App auf echten Geräten startet und nicht abstürzt.

### Schritt 4 — Zwölf-Tester-Lauf starten

Google verlangt für neue Entwicklerkonten **12 Tester, die 14 Tage ununterbrochen**
teilnehmen. Wer die App entfernt oder die Gruppe verlässt, unterbricht die
Zählung für alle. Zwölf ist Minimum, also **fünfzehn** einladen.
```
Führe release-gate aus, Ziel: Tester-Lauf verwalten. Lege die Testerliste unter
ops/testers/vox.md an, erzeuge den Einladungslink der geschlossenen Spur, notiere
das Startdatum. Berichte täglich die Zahl aktiver Tester und die Resttage.
```

**Datei: `ops/testers/vox.md`** — die Adressen selbst stehen in
`ops/testers/testers.txt`, eine je Zeile.
```markdown
# Zwölf-Tester-Lauf
App: vox (de.zeta.vox) · Spur: geschlossen
Startdatum: <erster aktiver Tester> · Zieldatum: Startdatum + 14 Tage
Mindestzahl: 12 · Eingeladen: 15 · Aktiv: <n>

| # | Name | Google-Konto | Eingeladen | Installiert | Aktiv seit | Bemerkung |
|---|------|--------------|------------|-------------|------------|-----------|
| 1 |      |              |            |             |            |           |
```

**Während dieser vierzehn Tage wird kein Schalter umgelegt.** Kein Billing, keine
Werbung, nur weiterbauen — an den vierzehn Tagen ist nichts zu beschleunigen.

### Schritt 5 — AdMob-Konto anlegen, Test-ID-Zwang schärfen

Parallel zum Tester-Lauf, kostenlos, ohne Auswirkung auf die Apps.
1. `admob.google.com` → mit demselben Google-Konto anmelden.
2. **Apps** → **App hinzufügen** → Android → „Ja, im Play Store" →
   `de.zeta.vox`. Es entsteht eine **App-ID**.
3. **Anzeigenblöcke** → **Banner** anlegen → **Anzeigenblock-ID**. Beide IDs als
   GitHub-Secrets `ADMOB_APP_ID` und `ADMOB_BANNER_UNIT_ID` ablegen.
4. **Datenschutz und Meldung** → **DSGVO** → UMP-Nachricht für den EWR
   erstellen und **veröffentlichen**.

Die CI-Prüfung, die den Build bei einer echten Anzeigen-ID im Debug-Build
bricht, wird **nicht** entfernt, sondern schärfer:
```
Führe monetize-modul im Nachrüstmodus aus. Echte AdMob-IDs kommen
ausschliesslich aus den Secrets ADMOB_APP_ID und ADMOB_BANNER_UNIT_ID und
werden ausschliesslich in Release-Builds eingesetzt. Debug- und Profile-Builds
verwenden weiterhin die Google-Test-IDs. Die CI-Pruefung bricht den Build, wenn
in einem Debug-Build eine ID auftaucht, die nicht mit
ca-app-pub-3940256099942544 beginnt.
```

Ein Debug-Build mit echten Anzeigen erzeugt ungültige Klickzahlen. Google sperrt
dafür Konten — das trifft alle 26 Apps.

### Schritt 6 — `billingEnabled` auf `true` — **zuerst**

Nach Ablauf der vierzehn Tage und erfolgreicher Prüfung.
```
Setze den Schalter billingEnabled in
packages/shared_base/lib/src/config/features.dart auf true. Registriere PlayBillingPurchases statt AlwaysProPurchases. Führe
test-loop-free Stufe 0 über das gesamte Monorepo aus, danach eine neue Version
in die geschlossene Spur.
```

Zusätzlich in der Play Console: **Monetarisierung** → **Produkte** →
**In-App-Produkte** → Pro-Produkt anlegen, Preis setzen, aktivieren.

### Schritt 7 — `adsEnabled` auf `true` — **danach**
```
Setze den Schalter adsEnabled in
packages/shared_base/lib/src/config/features.dart auf true. Registriere AdMobAdSurface statt NoOpAdSurface. Der UMP-Dialog läuft vor
der ersten Anzeigenanforderung. Die Kaufversion liefert weiterhin
NoOpAdSurface. Danach Stufe 0 und eine neue Version in die geschlossene Spur.
```

### Warum Kauf vor Werbung — nicht verhandelbar

Die Kaufversion **entfernt** die Werbung. Die Anzeige hängt also vom Kaufzustand
ab, nicht umgekehrt. Wer `adsEnabled` zuerst einschaltet, testet vierzehn Tage
lang mit fünfzehn echten Menschen eine Version, in der Werbung erscheint und
**kein Weg existiert, sie loszuwerden**. Drei Folgen:

1. Der Pfad „gekauft → keine Werbung" wird nie durchlaufen, obwohl er der einzige
   ist, in dem Geld fließt — er geht ungetestet produktiv.
2. Die Tester bewerten ein Produkt, das es so nie geben wird.
3. „Kauf während laufender Anzeigenanforderung", die häufigste Absturzstelle der
   Kombination, entsteht erst beim Einschalten von Billing und wird dann in
   einer bereits veröffentlichten Version geprüft.

Umgekehrt ist es sauber: Beim Einschalten von `adsEnabled` existiert der
Kaufzustand bereits, `AdMobAdSurface` wird gegen einen echten
`Purchases`-Zustand registriert, der Übergang fällt im geschlossenen Test auf.

### Schritt 8 — Stufenfreigabe in die Produktionsspur
```
Führe release-gate aus, Ziel: Produktionsspur. Stufenfreigabe beginnend bei
5 Prozent, Erhöhung auf 20, 50, 100 Prozent nur, wenn die Absturzrate unter dem
Schwellwert bleibt. Berichte nach jeder Stufe.
```

### Schritt 9 — `review-agent` aufwecken

Erst wenn die Produktionsspur existiert — vorher liefert die API nichts.
```
PLAY_CONSOLE_READY steht seit Schritt 1 auf true, damit läuft
.github/workflows/reviews.yml (cron 17 5 * * *) ab jetzt nicht mehr leer. Setze
zusätzlich gh variable set REVIEW_AUTOREPLY --body false und führe review-agent
einmal manuell aus. Nur Rezensionen mit Text, nur aus der Produktionsspur,
Archiv unter ops/reviews/<flavor>.jsonl, Entwürfe unter
ops/reviews/drafts/<flavor>/. Kontingente: 200 Abrufe pro Stunde, 2000
Antworten pro Tag.
```

## Rücknahme-Plan Welle 1

| Was schiefgeht | Sofortmaßnahme | Rücknahme |
|---|---|---|
| Tester-Lauf reißt ab (unter 12 aktiv) | Nachrücker aus der Reserveliste einladen | Zählung beginnt neu, kein Schalter wird vorgezogen. `ops/testers/vox.md` bekommt ein neues Startdatum, das alte bleibt stehen. |
| Kauf schlägt bei Testern fehl | `billingEnabled` zurück auf `false`, neue Version in die geschlossene Spur | `AlwaysProPurchases` greift wieder, App bleibt bedienbar. Kein Datenverlust, weil der Kaufzustand nicht in `Entry` liegt. |
| Werbung kollidiert mit dem Aufnahmeknopf | `adsEnabled` zurück auf `false` | `NoOpAdSurface` greift, Fläche bleibt reserviert (64 dp). Layout als Kernänderung in `packages/shared_base/lib/src/monetize/` reparieren, ≥16 dp erneut prüfen. |
| AdMob meldet ungültige Aktivität | `adsEnabled` sofort auf `false`, neue Version hochladen | CI-Test-ID-Prüfung auswerten: Welcher Build hat echte IDs angefordert? Ursache beheben, bevor wieder eingeschaltet wird. |
| Absturzrate steigt bei Stufenfreigabe | Freigabe anhalten, nicht erhöhen | Vorherige Version als Ziel setzen. Der Anteil bereits aktualisierter Nutzer bleibt — deshalb bei 5 Prozent beginnen. |
| Play lehnt die App ab | Ablehnungsgrund in `ops/policy/vor-release.md` eintragen | `PLAY_CONSOLE_READY` bleibt `true`, `release-gate` läuft im Prüfmodus weiter. Der Grund geht an `policy-watch`, damit er bei App 2 bis 26 nicht wiederkehrt. |

# Welle 2 — 60–120 € gebrauchtes Android-Gerät

Kein Konto, kein Abonnement, ein Gerät. Es beantwortet die vier Fragen, die
`TESTLEITER.md` unter „Was diese Leiter nicht kann" offen lässt.

## Vorbedingungen

| # | Vorbedingung | Prüfbar durch |
|---|---|---|
| 1 | Welle 1 abgeschlossen, mindestens eine App in der Produktionsspur | Play Console zeigt Produktionsspur |
| 2 | Android 12 oder neuer, mindestens 4 GB RAM, mindestens 8 GB frei | Geräteeinstellungen |
| 3 | Firebase-Projekt existiert (aus WF-01) | `FIREBASE_SERVICE_ACCOUNT` und `FIREBASE_RESULTS_BUCKET` als Secrets vorhanden |
| 4 | USB-Debugging **nicht** nötig — Verteilung über App Distribution | — |

Die Speicheranforderung ist wörtlich zu nehmen: Das Modell belegt rund 640 MB, das
Nachladen bei knappem Speicher ist genau der zu prüfende Fall.

## Schalterliste

| Schritt | Ort | Schalter | Von | Auf |
|---|---|---|---|---|
| 1 | GitHub-Repo-Variable, gelesen als `vars.APP_DISTRIBUTION_READY` in `.github/workflows/distribute.yml` | `APP_DISTRIBUTION_READY` | nicht gesetzt | `true` |
| 4 | `packages/shared_base/lib/src/config/features.dart` | `parakeetEnabled` | `false` | `true` |
| 5 | Release-Build in `.github/workflows/release.yml` | `--dart-define=STT_ENGINE` | Define fehlt (Vorgabewert `platform`) | `--dart-define=STT_ENGINE=parakeet` |

`sttEngine` wird **nicht** in `features.dart` umgeschrieben — er kommt aus
`String.fromEnvironment('STT_ENGINE', defaultValue: 'platform')`. Der einzige
Schalterort ist der Release-Build in `.github/workflows/release.yml`, und dort
wird das Define in **diesem** Schritt zum ersten Mal überhaupt gesetzt: Bisher
übergibt `release.yml` nur `--dart-define=FLAVOR=$FLAVOR`, das `release-gate`
in derselben Runde eingeführt hat. `STT_ENGINE` kommt daneben.

**`web.yml` bleibt unangetastet.** Dort steht `--dart-define=STT_ENGINE=web`
fest, und das ändert sich nie: Der Web-Build ist Testkanal, dort läuft immer die
Stub-Engine. Wer den Wert dort anfasst, nimmt sich den Testkanal.

Umgestellt wird **erst**, wenn `parakeetEnabled` auf echter Hardware bestanden
hat. `parakeetEnabled = true` macht die Pro-Engine verfügbar, `STT_ENGINE` legt
fest, welche standardmäßig läuft — zwei Entscheidungen, zwei Schritte. Solange
`parakeetEnabled` `false` ist, fängt `resolveSttEngineId()` den Fall ohnehin ab
und gibt `'platform'` zurück.

### Schritt 1 — Firebase App Distribution einschalten

Erst jetzt sinnvoll: Ohne Android-Gerät ist App Distribution nach
`TESTLEITER.md` Stufe 3 wörtlich „nutzlos".
```
Lege .github/workflows/distribute.yml mit dem unten abgedruckten Inhalt an und
setze gh variable set APP_DISTRIBUTION_READY --body true. Bei jedem Merge nach
main wird das Debug-APK an die Testergruppe "eigenes-geraet" in Firebase App
Distribution verteilt.
```

In der Firebase-Konsole: **App Distribution** → **Tester und Gruppen** → Gruppe
`eigenes-geraet` → eigene E-Mail eintragen. Dann **Projekteinstellungen** →
**Meine Apps** → Android-App `de.zeta.vox` hinzufügen; die dort angezeigte
App-ID (Muster `1:123…:android:abc…`) als GitHub-Secret `FIREBASE_APP_ID_VOX`
ablegen. Auf dem Android-Gerät die Einladungs-E-Mail öffnen, App Tester
installieren. Ab jetzt liegt jeder Merge zwei Minuten später auf dem Gerät.

**Datei: `.github/workflows/distribute.yml`** — wird von keinem Skill erzeugt,
sie entsteht hier. Ohne die Repo-Variable läuft sie leer durch, ohne rot zu
werden.

```yaml
name: distribute

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      flavor:
        description: Flavor, der verteilt wird
        required: true
        default: vox
        type: string

concurrency:
  group: distribute-${{ github.ref }}
  cancel-in-progress: true

jobs:
  verteilen:
    name: Debug-APK an das eigene Gerät
    runs-on: ubuntu-latest
    timeout-minutes: 30
    if: vars.APP_DISTRIBUTION_READY == 'true'
    env:
      FLAVOR: ${{ inputs.flavor || 'vox' }}
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: Melos installieren
        run: dart pub global activate melos

      - name: Bootstrap
        run: melos bootstrap

      - name: Debug-APK bauen
        working-directory: apps/${{ env.FLAVOR }}
        run: |
          flutter build apk --debug \
            --dart-define=FLAVOR=${{ env.FLAVOR }} \
            --dart-define=STT_ENGINE=platform

      - name: Versionshinweise aus den letzten Commits
        run: |
          git log -10 --pretty='- %s' > /tmp/notes.txt
          cat /tmp/notes.txt

      - name: An Firebase App Distribution verteilen
        uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: ${{ secrets.FIREBASE_APP_ID_VOX }}
          serviceCredentialsFileContent: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          groups: eigenes-geraet
          releaseNotesFile: /tmp/notes.txt
          file: apps/${{ env.FLAVOR }}/build/app/outputs/flutter-apk/app-debug.apk

  stillgelegt:
    name: Hinweis, solange kein Gerät da ist
    runs-on: ubuntu-latest
    if: vars.APP_DISTRIBUTION_READY != 'true'
    steps:
      - run: |
          echo "::notice title=App Distribution stillgelegt::APP_DISTRIBUTION_READY ist nicht true. Ohne Android-Gerät ist die Verteilung nutzlos. Lauf endet ohne Fehler."
```

**Der zweite Job ist kein Beiwerk.** Ohne ihn hätte `distribute.yml` bei
ausgeschalteter Variable null Jobs, und GitHub meldet den gesamten Lauf als
übersprungen — das ist in der Actions-Übersicht nicht von einem Fehler zu
unterscheiden. Der Hinweis-Job macht sichtbar, dass die Stilllegung gewollt ist.

### Schritt 2 — Echte Mikrofonqualität prüfen
```
Führe test-loop-free Stufe 3 aus, Ziel: eigenes Gerät. Prüfliste
Mikrofonqualität: Aufnahme in ruhiger Umgebung, mit Hintergrundgeräusch, aus
zwei Metern Abstand, im Freien mit Wind. PlatformSttEngine, deutsche Sprache.
Ergebnis nach ops/geraet/stt-platform.md.
```

### Schritt 3 — Werbung und Kauf real prüfen
```
Prüfliste Monetarisierung auf dem Gerät:
1. UMP-Dialog erscheint beim ersten Start, Ablehnung wird respektiert
2. Banner erscheint, Abstand zum Aufnahmeknopf mindestens 16 dp — nachmessen
3. Kauf im Testkonto durchführen, Werbung verschwindet ohne Neustart
4. App entfernen und neu installieren, Kauf wird wiederhergestellt
5. Kauf während laufender Anzeigenanforderung — kein Absturz
6. Flugmodus: Kaufzustand bleibt, Werbeplatz bleibt leer statt zu kollabieren
Ergebnis nach ops/geraet/monetize.md.
```

Punkt 3 und 5 sind nach `TESTLEITER.md` nicht simulierbar. Punkt 6 ist der, der
in Rezensionen auftaucht.

### Schritt 4 — `parakeetEnabled` auf `true`

**Nicht früher.** Ladezeit und Speicherverhalten des 640-MB-Modells sind nach
`TESTLEITER.md` ausschließlich auf echter Hardware beurteilbar; im Web-Build
oder im Test Lab erzeugt es Zahlen, die nichts bedeuten.
```
Setze den Schalter parakeetEnabled in
packages/shared_base/lib/src/config/features.dart auf true. Registriere ParakeetSttEngine zusätzlich zu PlatformSttEngine.
sttEngine bleibt auf 'platform'. Verteile über App Distribution.
```

Auf dem Gerät zu prüfen, festzuhalten in `ops/geraet/parakeet.md`:

| Messpunkt | Erwartung | Gemessen |
|---|---|---|
| Ladezeit über WLAN | unter 5 Minuten | |
| Verbindungsabbruch beim Laden | fortsetzbar, kein halber Zustand | |
| Belegter Speicher danach | ~640 MB, in den Einstellungen sichtbar und löschbar | |
| Arbeitsspeicher beim Transkribieren | App wird vom System nicht beendet | |
| Dauer für 60 Sekunden Audio | gemessen, nicht geschätzt | |
| „Präzision prüfen" gegen `PlatformSttEngine` | Unterschied farbig markiert, drei Gratis-Läufe | |
| Voller Gerätespeicher | klare Meldung, kein Absturz | |

### Schritt 5 — `STT_ENGINE=parakeet` in `release.yml`, nur wenn Schritt 4 bestanden hat
```
Ergänze im Build-Schritt von .github/workflows/release.yml neben dem
vorhandenen --dart-define=FLAVOR=$FLAVOR ein --dart-define=STT_ENGINE=parakeet.
Nur dort. web.yml bleibt auf STT_ENGINE=web und wird nicht angefasst,
features.dart ebenfalls nicht. Danach eine neue Version in die geschlossene
Spur und gegen das eigene Gerät prüfen.
```

## Rücknahme-Plan Welle 2

| Was schiefgeht | Sofortmaßnahme | Rücknahme |
|---|---|---|
| Modell lädt nicht zu Ende | Nachladen abbrechbar machen, Teilstand verwerfen | `parakeetEnabled` auf `false`. `PlatformSttEngine` greift, alle Einträge bleiben lesbar, weil `Segment.engine` die Herkunft trägt. |
| App wird beim Transkribieren beendet | Segmentweise statt am Stück transkribieren | `STT_ENGINE` zurück auf `platform`, `parakeetEnabled` bleibt `true` — die Engine bleibt wählbar, ist aber nicht Standard. |
| Speicher voll, Gerät träge | Modell in den Einstellungen löschbar machen | Kernfehler, kein Gerätefehler: Kernbranch nach dem Verfahren aus `WF-02`. |
| Kauf stellt sich nach Neuinstallation nicht wieder her | Wiederherstellung reparieren, `billingEnabled` bleibt zunächst `true` | Nicht binnen eines Tages behoben: `billingEnabled` auf `false`, Version zurückziehen. Ein nicht wiederherstellbarer Kauf ist ein Erstattungsfall. |
| Banner kollidiert trotz grüner Golden Tests | `adsEnabled` auf `false` | Golden Tests decken die Geräteauflösung nicht ab — neue Auflösung in `shared_base` ergänzen, damit der Fall künftig in Stufe 0 auffällt. |

# Welle 3 — 99 $ Apple Developer

Zuletzt, weil iOS nur Testkanal ist und die Stufen 0 bis 2 dafür genügen.

## Vorbedingungen

| # | Vorbedingung | Prüfbar durch |
|---|---|---|
| 1 | Welle 1 und 2 abgeschlossen | Produktionsspur läuft, Gerätetests dokumentiert |
| 2 | Apple Developer Program bezahlt | Konto zeigt Status „Active" |
| 3 | Codemagic-Konto auf dem Gratis-Tarif | 500 Build-Minuten pro Monat, macOS-Runner |
| 4 | iOS-Flavors aus `monorepo-bootstrap` vorhanden | `apps/<flavor>/ios/` mit Schema je Flavor |

Kein Mac nötig: Codemagic stellt den macOS-Runner, Signierung und
TestFlight-Upload laufen dort. Einrichtung vom iPhone über `codemagic.io`.

## Schalterliste

`codemagic.yaml` liegt bereits im Repo — `test-loop-free` hat sie stillgelegt
angelegt, nach demselben Muster wie `release-gate` es mit `PLAY_CONSOLE_READY`
tut: ein einziger Schalter `IOS_READY: "false"` unter `environment: vars:`, ein
erster Skript-Schritt, der bei `false` eine Meldung ausgibt und ohne Fehler
endet, und jeder Schritt, der ein Apple-Konto braucht, unter
`when: condition: env.IOS_READY == 'true'`. Umgelegt wird genau diese Variable.

| Schritt | Datei | Ort | Von | Auf |
|---|---|---|---|---|
| 1 | `codemagic.yaml` | `environment: vars: IOS_READY` | `"false"` | `"true"` |
| 1 | `codemagic.yaml` | `environment: ios_signing:` | auskommentiert | aktiv, `bundle_identifier: de.zeta.<flavor>` |
| 1 | `codemagic.yaml` | `triggering: events: [tag]` | auskommentiert | aktiv |
| 3 | `codemagic.yaml` | `publishing: app_store_connect:` | auskommentiert | aktiv, `submit_to_testflight: true` |

Die Schritte unter `when: condition: env.IOS_READY == 'true'` werden **nicht**
angefasst — sie laufen von allein an, sobald die Variable steht. Wer stattdessen
die Bedingungen entfernt, verliert die Rücknahme aus dem Rücknahme-Plan.

`features.dart` wird in Welle 3 **nicht** angefasst — iOS ändert keine
Produktschalter, nur den Auslieferungsweg.

### Schritt 1 — Codemagic verbinden

1. `codemagic.io` → mit GitHub anmelden → Repo `app-fabrik` auswählen.
2. **Teams** → **Integrations** → **Apple Developer Portal** →
   App-Store-Connect-API-Schlüssel (Issuer ID, Key ID, `.p8`) hinterlegen.
3. `IOS_READY` in `codemagic.yaml` unter `environment: vars:` auf `"true"` —
   der einzige Schalter dieses Workflows, gesetzt von `test-loop-free`.
4. **Automatic code signing** — Codemagic erzeugt Profile je Bundle-ID, Muster
   identisch zu Android: `de.zeta.<flavor>`.

### Schritt 2 — iOS-Flavors bauen
```
Führe test-loop-free Stufe 3 aus, Ziel: iOS über Codemagic. Baue den Flavor vox
mit --dart-define=FLAVOR=vox gegen das iOS-Schema vox. Berichte, welche Plugins
auf iOS keine Entsprechung haben und welche Berechtigungen in Info.plist fehlen.
```

Zu erwarten sind `Info.plist`-Einträge, die auf Android im Manifest stehen:
`NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`,
`NSCameraUsageDescription`, `NSPhotoLibraryAddUsageDescription`. Die Texte sind
deutsch und konkret — „für Sprachnotizen" ist ein Ablehnungsgrund.

### Schritt 3 — TestFlight
```
Aktiviere den publishing-Abschnitt in codemagic.yaml: app_store_connect mit
submit_to_testflight: true. Baue vox und lade nach TestFlight. Danach:
Installiere über die TestFlight-App auf dem iPhone 14 und berichte, welche
Plugins nativ arbeiten und welche auf einen Stub fallen.
```

Ab hier ist das eigene iPhone Testgerät statt Anzeigegerät: `PlatformSttEngine`
über die iOS-Speech-API, `FileVault` über das echte Dateisystem, Kamera nativ.

### Schritt 4 — App-Store-Connect-Metadaten
```
Führe store-assets für vox im iOS-Modus aus. Erzeuge aus apps/vox/store/:
Name (30 Zeichen), Untertitel (30 Zeichen), Beschreibung, Keywords (100 Zeichen,
kommagetrennt), Support-URL, Datenschutz-URL und die App-Datenschutz-Angaben.
Screenshots in den von Apple verlangten Größen aus den Integrationstests.
Ablage unter apps/vox/store/ios/.
```

Der iOS-Untertitel (30 Zeichen) hat keine Entsprechung bei Play, dessen
Kurzbeschreibung 80 Zeichen hat. Beide werden getrennt geführt, nie ineinander
überführt. Bei den Datenschutz-Angaben gilt dieselbe Wahrheit wie bei Play: Es
wird nichts erhoben, `analyticsEnabled` bleibt `false`. Sobald `adsEnabled` auf
`true` steht, wird AdMob als Datenverarbeiter angegeben — vollständig. Eine
falsche Angabe ist ein Entfernungsgrund.

## Rücknahme-Plan Welle 3

| Was schiefgeht | Sofortmaßnahme | Rücknahme |
|---|---|---|
| Signierung schlägt in Codemagic fehl | Auf manuelles Signieren umstellen, Profile im Apple-Portal erzeugen | `IOS_READY` auf `"false"`. Android bleibt unberührt — dafür sind die Wellen getrennt. |
| Ein Plugin hat keine iOS-Entsprechung | Web-Stub oder eigene Implementierung hinter der bestehenden Schnittstelle registrieren | Nichts zurückzunehmen. Genau dafür existiert die Schnittstellenschicht aus `ARCHITEKTUR.md` §4. |
| Gratis-Kontingent bei Codemagic aufgebraucht | Nur noch bei Tags bauen statt bei jedem Merge | `on: push: tags:` statt `branches:`. iOS-Builds sind Testkanal, keine Auslieferung. |
| Apple lehnt wegen unklarer Berechtigungstexte ab | Texte in `Info.plist` konkretisieren | Ablehnungsgrund nach `ops/policy/vor-release.md`, damit App 2 bis 26 ihn nicht wiederholen. |
| 99 $ laufen aus, keine Verlängerung | TestFlight-Builds verfallen | `IOS_READY` auf `"false"`. Android und Web laufen unverändert weiter, kein Datenverlust, keine Codeänderung. |
