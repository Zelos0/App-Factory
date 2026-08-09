# WF-03 — Bestandslauf, monatlich

Was mit einem Portfolio geschieht, an dem gerade nicht gebaut wird.

Solange kein Play-Console-Konto existiert, ist der Bestandslauf kurz: **zwei
aktive Aufgaben**, `policy-watch` und Abhängigkeits-Aktualisierung. Die übrigen
Agenten sind gebaut, stillgelegt und warten auf einen Schalter. Sie stehen hier
mit ihrem Weckmechanismus, damit später niemand suchen muss.

**Termin: erster Montag im Monat.** Kein „wenn Zeit ist". Zeitbudget 60–90
Minuten. Wer den Termin dreimal verschiebt, hat ein Portfolio mit
Abhängigkeiten von vor einem halben Jahr und einen Ziel-SDK-Verstoß, den er
unter Zeitdruck reparieren muss.

## Monatscheckliste — erster Montag

Abzuarbeiten in dieser Reihenfolge. Jede Zeile ist mit ja oder nein
beantwortbar.

| # | Aufgabe | Zeit | Fertig, wenn |
|---|---|---|---|
| 1 | `policy-watch` laufen lassen | 15 min | `ops/policy/<JJJJ-MM>.md` liegt im Repo, betroffene Apps sind benannt |
| 2 | Dependabot-PRs sichten | 15 min | Kein offener Dependabot-PR älter als 30 Tage |
| 3 | `flutter pub upgrade --major-versions` auf einem Branch | 20 min | Branch `wartung/<jahr>-<monat>` existiert, CI-Ergebnis liegt vor |
| 4 | Flutter-Kanal prüfen | 5 min | In `ci.yml`, `web.yml` und `testlab.yml` steht derselbe `channel`-Wert |
| 5 | Golden-Diffs prüfen, falls rot | 20 min | Jedes Diff-PNG auf dem iPhone angesehen und entschieden |
| 6 | `FORTSCHRITT.md` fortschreiben | 5 min | Stand, Anzahl fertiger Apps, offene Kernbranches aktuell |
| 7 | Quartalsaufgabe, falls Quartalsmonat | 60 min | siehe Abschnitt „Quartal" |

## Aufgabe 1 — `policy-watch`

Der einzige Agent, der jetzt schon vollständig sinnvoll läuft, weil er nichts
kostet und kein Konto braucht.

```
Führe policy-watch aus. Prüfzeitraum: seit dem letzten Bericht unter ops/policy/.
Berichte Play-Richtlinienänderungen, App-Store-Richtlinienänderungen und
Ziel-SDK-Fristen. Nenne für jede Änderung die betroffenen Apps aus apps/*
und die konkrete Datei, die geändert werden müsste.
```

### Was der Bericht enthalten muss

- Datum der Richtlinienänderung und Datum ihrer Durchsetzung — beide, sie
  liegen oft ein halbes Jahr auseinander
- betroffene Apps namentlich, nicht „alle Apps mit Mikrofonzugriff"
- die Datei, die geändert wird — vollständiger Pfad, nicht Kurzform:
  `apps/<flavor>/android/app/src/main/AndroidManifest.xml`,
  `apps/<flavor>/ios/Runner/Info.plist`,
  `apps/<flavor>/store/datenschutz.md`,
  `packages/shared_base/lib/src/config/features.dart`
- Einstufung: **jetzt**, **vor Veröffentlichung**, **beobachten**

Nur „jetzt" wird im selben Bestandslauf abgearbeitet. „Vor Veröffentlichung"
wandert in eine Liste, die `release-gate` beim Aufwachen liest — siehe
`WF-04-GELD-DA.md`.

### Ablage

`ops/policy/2026-08.md`, ein Bericht je Monat, nie überschrieben. Die
Historie ist der Beweis, dass eine Richtlinie zum Zeitpunkt der Umsetzung
tatsächlich so lautete.

## Aufgabe 2 und 3 — Abhängigkeiten

### Dependabot

Automatische PRs, kostenlos, funktioniert auch bei privaten Repos. Die Datei
liegt vollständig hier und wird genau so angelegt.

**Datei: `.github/dependabot.yml`**

```yaml
version: 2

updates:
  # ---- Dart/Flutter: die drei Kernpakete ----
  - package-ecosystem: "pub"
    directory: "/packages/shared_base"
    schedule:
      interval: "monthly"
      day: "monday"
      time: "06:00"
      timezone: "Europe/Berlin"
    open-pull-requests-limit: 5
    commit-message:
      prefix: "deps(shared_base)"
    labels:
      - "abhaengigkeiten"
      - "kern"
    groups:
      kern-patch-minor:
        update-types:
          - "minor"
          - "patch"

  - package-ecosystem: "pub"
    directory: "/packages/capture_core"
    schedule:
      interval: "monthly"
      day: "monday"
      time: "06:10"
      timezone: "Europe/Berlin"
    open-pull-requests-limit: 5
    commit-message:
      prefix: "deps(capture_core)"
    labels:
      - "abhaengigkeiten"
      - "kern"
    groups:
      kern-patch-minor:
        update-types:
          - "minor"
          - "patch"

  - package-ecosystem: "pub"
    directory: "/packages/lens_core"
    schedule:
      interval: "monthly"
      day: "monday"
      time: "06:20"
      timezone: "Europe/Berlin"
    open-pull-requests-limit: 5
    commit-message:
      prefix: "deps(lens_core)"
    labels:
      - "abhaengigkeiten"
      - "kern"
    groups:
      kern-patch-minor:
        update-types:
          - "minor"
          - "patch"

  # ---- Apps: hängen nur an den Kernpaketen, deshalb enges Limit ----
  - package-ecosystem: "pub"
    directory: "/apps/vox"
    schedule:
      interval: "monthly"
      day: "monday"
      time: "06:30"
      timezone: "Europe/Berlin"
    open-pull-requests-limit: 2
    commit-message:
      prefix: "deps(vox)"
    labels:
      - "abhaengigkeiten"
      - "app"

  # ---- GitHub Actions: die Auslieferungskette ----
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "monthly"
      day: "monday"
      time: "06:40"
      timezone: "Europe/Berlin"
    open-pull-requests-limit: 5
    commit-message:
      prefix: "ci"
    labels:
      - "abhaengigkeiten"
      - "ci"
    groups:
      actions:
        patterns:
          - "*"

  # ---- Android-Build der Kernpakete ----
  - package-ecosystem: "gradle"
    directory: "/packages/capture_core/android"
    schedule:
      interval: "monthly"
      day: "monday"
      time: "06:50"
      timezone: "Europe/Berlin"
    open-pull-requests-limit: 3
    commit-message:
      prefix: "deps(android)"
    labels:
      - "abhaengigkeiten"
      - "android"
```

**Regel für neue Apps:** Jede App, die nach `WF-02` entsteht, bekommt beim
Merge nach `main` ihren eigenen `pub`-Block nach dem Muster von `vox`. Das ist
ein Punkt in der Definition of Done, kein Zusatz.

**Warum `monthly` und nicht `weekly`:** Wöchentliche PRs an einem Handy
gesichtet zu bekommen, führt nach sechs Wochen dazu, dass niemand mehr
hinsieht. Ein Termin, ein Stapel.

### Manueller Durchlauf

Dependabot erhöht keine Major-Versionen quer über das Monorepo. Das macht der
Bestandslauf einmal im Monat, auf einem eigenen Branch:

```
Lege den Branch wartung/2026-08 an und führe darauf aus:
melos exec -- flutter pub upgrade --major-versions
melos exec -- flutter analyze
melos exec -- flutter test
Berichte danach, welche Pakete eine Major-Version gesprungen sind und welche
Tests rot sind — getrennt nach Kernpaketen und Apps.
```

Der Branch heißt immer `wartung/<jahr>-<monat>` und wird nach dem Merge
gelöscht. Er wird nie länger als eine Woche offen gehalten.

### Flutter-Kanal

Es wird ausschließlich `stable` verwendet. `beta` und `master` haben in einem
Portfolio mit sechsundzwanzig Apps nichts zu suchen — ein Regressionsfehler im
Framework kostet dann sechsundzwanzigmal Zeit.

Die Version steht an genau einer Stelle, damit sie an genau einer Stelle
geändert wird:

```
Prüfe, ob subosito/flutter-action in .github/workflows/ci.yml, web.yml und
testlab.yml denselben channel-Wert hat und ob dieser Wert stable ist. Prüfe
ausserdem, welche Flutter-Version der letzte grüne Lauf tatsächlich benutzt hat
(Schritt-Log "Flutter ... channel stable"). Weicht etwas ab: gemeinsam auf einem
Branch wartung/<jahr>-<monat> angleichen und Stufe 0 über das Monorepo laufen
lassen.
```

Eine Flutter-Anhebung wird **nie** zusammen mit einer Abhängigkeits-Anhebung
gemerged. Sonst ist bei roten Goldens nicht unterscheidbar, ob das Framework
oder ein Paket die Ursache ist.

## Umgang mit brechenden Abhängigkeiten

Die Reihenfolge ist nicht verhandelbar, sie folgt derselben Logik wie die
Abbruchregel in `WF-02`.

### Schritt 1 — Kern zuerst

```
Repariere ausschließlich packages/shared_base, packages/capture_core und
packages/lens_core gegen die neuen Paketversionen. Kein Code in apps/.
Danach: melos exec --scope="*_core,shared_base" -- flutter test
```

Solange die Kernpakete rot sind, wird keine App angefasst. Fast jeder Bruch in
den Apps ist eine Folgeerscheinung und verschwindet mit der Kernreparatur von
selbst.

### Schritt 2 — Apps danach, in der Reihenfolge des Positionsplans

```
Führe melos exec -- flutter test aus und berichte pro App, welche Tests rot
sind. Repariere in der Reihenfolge der Nummern aus FORTSCHRITT.md.
```

Die Reihenfolge ist Absicht: Die früheren Apps sind die einfacheren. Wenn App 02
und App 03 mit derselben Anpassung grün werden, ist die Anpassung ein
Kernkandidat und Schritt 1 war unvollständig — zurück zu Schritt 1.

### Schritt 3 — Golden Tests, und hier wird nicht abgekürzt

Neue Golden-Bilder werden **niemals** ungesehen erzeugt. `--update-goldens`
ohne vorherige Sichtprüfung ist die einzige Methode, mit der ein
Layout-Regressionsfehler dauerhaft im Repo verschwindet.

**Verfahren:**

1. CI-Lauf öffnen → **Artifacts** → `golden-failures` herunterladen. Das
   Archiv enthält je gebrochenem Test **vier** PNG: `*_testImage`,
   `*_masterImage`, `*_isolatedDiff`, `*_maskedDiff`.
2. Auf dem iPhone in der Fotos-App **jedes** `*_maskedDiff` ansehen — das ist
   nach `test-loop-free` das Bild, das entscheidet. Nicht
   überfliegen — bei sechsundzwanzig Apps sind das im Ernstfall über
   hundertfünfzig Bilder, und genau deshalb steht dieser Termin monatlich im
   Kalender statt vierteljährlich.
3. Entscheiden, je Bild:
   - **Beabsichtigt** (z. B. neue Material-Version zeichnet Schaltflächen
     minimal anders): notieren.
   - **Unbeabsichtigt** (Text abgeschnitten, Abstand zum Aufnahmeknopf unter
     16 dp, Bannerfläche verschoben): das ist ein Fehler, kein neues Soll.
     Reparieren, nicht abnicken.
4. Erst wenn **alle** Diffs als beabsichtigt eingestuft sind:

```
Erzeuge die Golden-Bilder neu:
melos exec -- flutter test --update-goldens
Danach: Neue Bilder als CI-Artefakt ablegen und mir die Liste der geänderten
Dateien nennen.
```

5. Der PR, der neue Goldens enthält, trägt im Text die Zahl der geprüften
   Diffs und die Begründung. Ein Golden-PR ohne Begründung wird nicht gemerged.

**Wenn ein einziges Diff unbeabsichtigt ist**, wird der gesamte
Aktualisierungsbranch angehalten, der Fehler behoben, und der Durchgang beginnt
bei Schritt 3 von vorn.

## Stillgelegte Agenten — Beschreibung und Weckschalter

Beide sind vollständig gebaut. Sie laufen nicht, weil ihre Voraussetzung Geld
kostet. Sie scheitern nicht, sie überspringen sich mit klarer Meldung.

### `release-gate` — stillgelegt

**Was er tut:** Veröffentlichung in die geschlossene Testspur, Durchsetzung der
Zwölf-Tester-Regel (12 Tester, 14 Tage ununterbrochen), Stufenfreigabe in die
Produktionsspur, Versionshinweise aus den Commits seit dem letzten Tag.

**Warum stillgelegt:** Braucht ein Play-Console-Konto, 25 $ einmalig.

**Weckschalter:** `PLAY_CONSOLE_READY` — eine **GitHub-Repo-Variable**, kein
`env:`-Eintrag in der Workflow-Datei. `.github/workflows/release.yml` liest sie
als `vars.PLAY_CONSOLE_READY`, alle Upload-Schritte hängen an
`if: vars.PLAY_CONSOLE_READY == 'true'`.

| Ort | Wie | Jetzt | Beim Aufwachen |
|---|---|---|---|
| Repo-Variable | `gh variable set PLAY_CONSOLE_READY --body true` | nicht gesetzt (gilt als `false`) | `true` |
| GitHub → Settings → Secrets → Actions | `PLAY_SERVICE_ACCOUNT_JSON` | fehlt | JSON des Play-Dienstkontos |
| GitHub → Settings → Secrets → Actions | `ANDROID_KEYSTORE_BASE64` | fehlt | Upload-Key |

**Verhalten jetzt:** Bei jedem Aufruf meldet der Skill, welche der drei
Voraussetzungen fehlt — Konto, Dienstkonto-Schlüssel, hochgeladenes
Signaturzertifikat — und endet mit Status 0. Kein roter CI-Lauf.

**Was der Bestandslauf für ihn tut:** Die Einstufung „vor Veröffentlichung"
aus dem `policy-watch`-Bericht wird in `ops/policy/vor-release.md` gesammelt.
Diese Liste ist das Erste, was `release-gate` beim Aufwachen abarbeitet.

### `review-agent` — stillgelegt

**Was er tut:** Täglicher Lauf über die Reply-to-Reviews-API. Nur Rezensionen
**mit Text**, nur aus der **Produktionsspur**. Kontingente: 200 Abrufe pro
Stunde, 2000 Antworten pro Tag, und die API reicht nur rund sieben Tage zurück —
deshalb führt er ein eigenes Archiv unter `ops/reviews/<flavor>.jsonl` und läuft
täglich statt nachzuholen.

**Warum stillgelegt:** Es gibt keine Produktionsspur, weil es keine
veröffentlichte App gibt. Die API liefert für nicht veröffentlichte Apps nichts.

**Weckschalter:** ebenfalls die Repo-Variable `PLAY_CONSOLE_READY` — der Agent
hat keinen eigenen. `.github/workflows/reviews.yml` läuft bereits täglich
(`cron: '17 5 * * *'`) und beendet sich ohne Fehler, solange die Variable nicht
`true` ist. Ein **zweiter** Schalter steuert nur das Senden.

| Ort | Wie | Jetzt | Beim Aufwachen |
|---|---|---|---|
| Repo-Variable | `gh variable set PLAY_CONSOLE_READY --body true` | nicht gesetzt | `true` — Abruf und Archiv laufen |
| Repo-Variable | `gh variable set REVIEW_AUTOREPLY --body false` | `false` | bleibt zunächst `false` — Antworten nur als Entwurf |

**Verhalten jetzt:** `.github/workflows/reviews.yml` meldet „PLAY_CONSOLE_READY
ist nicht true" und endet mit Status 0. Das Archivverzeichnis `ops/reviews/`
existiert bereits leer, damit der erste echte Lauf keinen Sonderfall hat.
`REVIEW_AUTOREPLY` bleibt auch nach dem Aufwachen zunächst `false`: Entwürfe
landen unter `ops/reviews/drafts/<flavor>/`, gesendet wird erst nach Sichtung.

## Quartalsaufgabe — Ziel-SDK-Anhebung

**Termine: erster Montag im Februar, Mai, August, November.** Zeitbudget
60 Minuten zusätzlich.

Google setzt jährlich ein Mindest-Ziel-SDK durch. Wer die Frist verpasst, kann
keine Aktualisierung mehr einreichen — und bei sechsundzwanzig Apps trifft das
sechsundzwanzigmal gleichzeitig.

```
Führe policy-watch mit Schwerpunkt Ziel-SDK aus. Nenne:
1. das aktuell in den Apps gesetzte targetSdk und compileSdk
2. das von Google für neue Einreichungen geforderte Mindest-targetSdk und ab
   welchem Datum
3. das für Aktualisierungen bestehender Apps geforderte und ab wann
4. die Verhaltensänderungen zwischen unserem targetSdk und dem geforderten,
   die unsere Kerne betreffen: Mikrofon, Kamera, Speicherzugriff,
   Vordergrunddienste, Benachrichtigungen
```

### Ablauf der Anhebung

1. Branch `wartung/sdk-<zielversion>`.
2. `targetSdk` und `compileSdk` an **einer** Stelle ändern: in der
   gemeinsamen Gradle-Konfiguration der Kernpakete. Wenn dieser Wert in
   sechsundzwanzig App-Verzeichnissen steht, ist das der eigentliche Fehler —
   dann zuerst zentralisieren, dann anheben.
3. Verhaltensänderungen der Punkte aus dem Bericht in den Kernen umsetzen,
   nicht in den Apps.
4. Stufe 0 über das gesamte Monorepo.
5. **Stufe 2 ist hier Pflicht, nicht Kür:** Ziel-SDK-Änderungen wirken sich auf
   Berechtigungsdialoge aus, und die sieht der Web-Build nicht.

```
Führe test-loop-free Stufe 2 aus: Firebase Test Lab, Robo-Test auf zwei
Geräten, davon eines mit der neuen Android-Version. Berichte
Berechtigungsdialoge, Abstürze und Speicherverhalten.
```

6. Merge nach `main`, Eintrag in `FORTSCHRITT.md`.

**Regel:** Die Anhebung geschieht im Quartal **vor** der Frist, nicht im
Quartal der Frist. Wenn `policy-watch` eine Frist meldet, die im laufenden
Quartal liegt, wird die Anhebung im selben Bestandslauf begonnen und alles
andere zurückgestellt.

## Wenn ein Bestandslauf ausfällt

Ein ausgefallener Monat ist verkraftbar, zwei nicht. Nach zwei ausgefallenen
Läufen gilt:

1. Kein Beginn einer neuen App nach `WF-02`, bis der Bestandslauf nachgeholt ist.
2. Der Nachholtermin arbeitet **beide** ausgefallenen Monate ab, mit zwei
   getrennten `policy-watch`-Berichten. Ein zusammengefasster Bericht verliert
   die Datumszuordnung, und die ist bei Richtlinienfristen der ganze Punkt.
