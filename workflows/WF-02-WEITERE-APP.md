# WF-02 — Die Schleife für App 2 bis 26

`vox` steht. Ab hier ist jede weitere App derselbe Ablauf, viermal wiederholt
pro Woche geht nicht, zweimal schon.

**Zielzeit: zwei bis vier Tage je App.** Zwei Tage bei einer reinen
capture-App mit einfachem Interpreter, vier bei einem Hybrid mit eigener
Auswertungsansicht. Wer über fünf Tage kommt, hat kein Zeitproblem, sondern
ein Architekturproblem — siehe Abschnitt „Abbruchregel".

## Die Reihenfolge, jedes Mal identisch

```
konzept-zu-bauplan  →  app-derive  →  test-loop-free 0/1  →  store-assets  →  DoD
```

Kein Schritt wird übersprungen, keiner wird getauscht. Wer ohne Bauplan
`app-derive` startet, führt einen Dialog mit fünf Fragen, deren Antworten er
sich in dem Moment ausdenkt — und bekommt eine App, die niemand geplant hat.

**`monetize-modul` steht nicht in dieser Kette.** Er läuft **einmal im Repo**,
an Tag 3 von `WF-01`, und liefert `AdSurface`, `Purchases` und die reservierte
Bannerfläche für alle 26 Apps. Eine neue App ruft ihn nie auf; sie erbt die
Fläche über `AdSafeArea` aus `shared_base`. Wer ihn je App aufruft, erzeugt
26 Bannerlayouts statt eines. Gleiches gilt für `lens-core-build`: einmal vor
der ersten lens-App, nicht je App.

## Tag 1 — Bauplan und Ableitung

**Zeitbudget: 4–5 Stunden.**

### Schritt 1 — `konzept-zu-bauplan` (60–90 Minuten)

```
Führe konzept-zu-bauplan für onira aus. Der Steckbrief steht in
portfolio/band-1.md unter „onira". Ergebnis nach docs/baupläne/onira.md:
Interpreter-Regeln, Datenfelder in Entry.data, Bildschirme, Exportvorlagen mit
Empfänger, zwölf Testsätze.
```

Der Bauplan ist fertig, wenn er diese fünf Angaben enthält — sonst startet
`app-derive` nicht:

| Angabe | Prüfbar durch |
|---|---|
| Kern | Steht dort `capture`, `lens` oder `beide`? |
| Interpreter-/Pipeline-Logik | Sind die Regeln als Wenn-Dann formuliert, nicht als Absicht? |
| Auswertungsansicht | Ist genannt, was summiert, verlaufen oder verortet wird? |
| Exportformate | Hat **jeder** Export einen benannten Empfänger nach `ARCHITEKTUR.md` §7? |
| Gestaltung | Vier Farben, zwei Schriftfamilien, Aufbau des Startbildschirms? |

### Schritt 2 — `app-derive` (unter 2 Stunden, hart)

```
Führe app-derive für onira aus. Kern: capture. Bauplan: docs/baupläne/onira.md.
Paket-ID de.zeta.onira.
```

Erzeugt: Flavor-Eintrag, `apps/onira/`, `OniraTheme`, `OniraInterpreter` mit
Tests, Startbildschirm, Store-Metadaten-Gerüst, Golden-Test-Grundstock, Eintrag
in der Web-Demo-Übersicht.

### Sichtprüfung am Ende von Tag 1

Vorschau-URL des Branches im Safari öffnen:
`https://<branch>.app-fabrik.pages.dev/` — die Übersichtsseite listet jetzt zwei
Apps. `https://<branch>.app-fabrik.pages.dev/onira/` öffnet die neue, zeigt
ihren Startbildschirm in ihrer eigenen Farbwelt, und der Aufnahme- bzw.
Sucherknopf reagiert.

### Abbruchbedingung

**`app-derive` über 2 Stunden** → siehe Abbruchregel unten. Nicht warten,
nicht durchziehen.

## Tag 2 — Interpreter scharf stellen

**Zeitbudget: 4 Stunden.**

Der Interpreter aus `app-derive` kennt die Regeln aus dem Bauplan, aber nicht
die Sprache echter Nutzer. Dieser Tag besteht aus: Testsatz schreiben, Test rot
sehen, Regel nachschärfen, Test grün.

```
Erweitere die Tests von OniraInterpreter auf mindestens zwölf realistische
Beispielsätze aus dem Bauplan. Jeder Testsatz prüft die vollständige
Entry.data-Struktur, nicht nur ein Feld. Danach flutter analyze.
```

**Regel für Testsätze:** Sie werden gesprochen, nicht getippt. Also keine
Satzzeichen, keine Großschreibung, Zahlwörter ausgeschrieben, Selbstkorrekturen
mitten im Satz („viertausend nein zweitausend vierhundert"). Ein Interpreter,
der nur saubere Eingaben versteht, ist im Web-Build grün und auf dem Gerät nutzlos.

### Sichtprüfung

Drei Einträge im Web-Build anlegen, Stub-Text jeweils auf einen der Testsätze
stellen, Detailansicht prüfen: Die Felder stimmen mit dem überein, was der Test
behauptet. Wenn Test und Anzeige auseinanderlaufen, liegt der Fehler in der
Darstellung, nicht im Interpreter — und der wäre im Unit-Test unsichtbar geblieben.

### Abbruchbedingung

**Wenn nach 90 Minuten weniger als acht Testsätze grün sind**, ist die
Interpreter-Regel im Bauplan zu unscharf. Zurück zu `konzept-zu-bauplan` für
genau diesen einen Aspekt, Bauplan nachschärfen, dann weiter. Nicht am Code
raten.

## Tag 3 — Auswertung, Export, Tests

**Zeitbudget: 4 Stunden.**

```
Führe test-loop-free für onira aus, Stufe 0 und Stufe 1. Golden Tests für
Startbildschirm, Liste, Detail — hell und dunkel. Integrationstest über den
Hauptablauf mit Screenshot-Ablage als CI-Artefakt.
```

Danach die vollständige Prüfliste aus `TESTLEITER.md` Stufe 1 auf dem iPhone,
alle acht Punkte. Sie ist nicht optional und wird auch bei App 19 nicht
abgekürzt — sie dauert acht Minuten.

### Abbruchbedingung

**Golden Tests brechen in fremden Apps** → siehe Tabelle „Signal → Diagnose →
Maßnahme". Das ist fast immer eine Kernänderung, die durchgeschlagen ist, kein
Fehler der neuen App.

## Tag 4 — Store-Material und Definition of Done

**Zeitbudget: 2–3 Stunden.** Bei einfachen Apps fällt dieser Tag mit Tag 3
zusammen.

```
Führe store-assets für onira aus. Screenshots aus den Integrationstests.
Titel 30 Zeichen, Kurzbeschreibung 80 Zeichen, Langbeschreibung,
Datenschutzangaben. Ablage unter apps/onira/store/.
```

Dann die zehn Punkte aus `ARCHITEKTUR.md` §10 abhaken. Erst wenn alle zehn
stehen, wird nach `main` gemerged. Ein Merge stößt Firebase Test Lab an
(Stufe 2, Gratis-Kontingent); der Robo-Test läuft rund zehn Minuten, das
Ergebnis ist im Browser auf dem iPhone ansehbar.

## Abbruchregel — Kernänderung geht immer vor App

**Die wichtigste Regel dieses Workflows.**

Wenn eine App etwas braucht, das der Kern nicht kann, wird **der Kern geändert.
Niemals die App-Kopie.** `ARCHITEKTUR.md` §2 sagt es als Regel; hier steht das
Verfahren.

### Erkennungsmerkmale

Eine dieser drei Beobachtungen bedeutet: Kernänderung, sofort.

1. `app-derive` will Code nach `apps/<flavor>/` schreiben, der in einer zweiten
   App nützlich wäre.
2. Beim Schreiben eines Interpreters entsteht der Gedanke „das habe ich bei der
   letzten App schon einmal gebaut".
3. Eine Datei in `apps/<flavor>/` überschreitet 400 Zeilen. Eine App ist rund
   200 Zeilen plus Theme plus Interpreter. Alles darüber ist verschobener Kern.

### Verfahren

**Schritt 1 — Neue App anhalten.** Der Branch der neuen App bleibt liegen,
unfertig, ungemerged. Nichts daran wird gerettet, umgangen oder dupliziert.

**Schritt 2 — Kernbranch aufmachen.**

```
Lege einen Branch core/<kurzbeschreibung> an und ändere ausschließlich
packages/shared_base, packages/capture_core oder packages/lens_core.
Kein Code in apps/. Erweitere die Kern-Tests um den neuen Fall.
```

Namensmuster: `core/zahlwort-parser`, `core/gpx-export`,
`core/segment-neu-transkribieren`.

**Schritt 3 — Alle bestehenden Apps müssen grün sein.**

```
Führe test-loop-free Stufe 0 über das gesamte Monorepo aus:
melos exec -- flutter analyze
melos exec -- flutter test
Golden Tests aller bestehenden Apps eingeschlossen.
```

Grün heißt: **alle** bereits fertigen Apps, nicht nur die zuletzt gebaute.
Bei App 14 sind das dreizehn Apps mit je sechs Golden-Bildern. Das ist der
Preis für achtzig Prozent geteilten Code, und er ist es wert.

**Schritt 4 — Kernbranch nach `main` mergen.** Erst wenn Schritt 3 grün ist.

**Schritt 5 — Neue App fortsetzen**, auf `main` rebased.

### Was ausdrücklich verboten ist

- Die Hilfsfunktion in der neuen App bauen und „später in den Kern schieben".
  Sie wandert nie.
- Den Kern ändern und die Golden Tests der anderen Apps „erst mal rot lassen".
  Rote Tests werden nach drei Tagen ignoriert und nach zehn gelöscht.
- Eine Kernänderung im selben Branch wie die neue App. Dann ist nicht mehr
  trennbar, welche Regression woher kommt.

## Signal → Diagnose → Maßnahme

| Signal | Diagnose | Maßnahme |
|---|---|---|
| `app-derive` läuft über 2 Stunden | Zu viel App, zu wenig Kern. Der Skill schreibt Code, den es schon geben müsste. | Lauf abbrechen. Erzeugte Dateien in `apps/<flavor>/` durchgehen: Was wäre in einer zweiten App nützlich? Diese Teile per Kernbranch nach `shared_base` bzw. Kern verschieben, Kern-Tests ergänzen, alle Apps grün stellen, dann `app-derive` neu starten. |
| Zweite App braucht dieselbe Hilfsfunktion | Bestätigte Kernzugehörigkeit. Zweimal gebraucht ist die Schwelle aus `ARCHITEKTUR.md` §2. | Kernbranch. Funktion aus der **ersten** App entfernen und in den Kern heben, erste App auf den Kern umstellen, beide Apps grün, dann weiter. Nicht kopieren. |
| Golden Tests brechen in fremden Apps | Kernänderung hat durchgeschlagen — meist `shared_base/design/`. | Diff-PNGs aus dem CI-Artefakt auf dem iPhone ansehen. **Beabsichtigte** Änderung: Goldens aller betroffenen Apps neu erzeugen, aber erst nach Sichtprüfung jedes einzelnen Bildes. **Unbeabsichtigte** Änderung: Kernänderung zurücknehmen, Design-Token statt globaler Wertänderung einführen. |
| Golden Tests brechen nur bei einer App | Themefehler dieser App, nicht des Kerns. | `<Flavor>Theme` prüfen: hartkodierte Größen statt Skalen aus `shared_base/design/`. Skalen verwenden, Golden neu erzeugen. |
| Interpreter grün, Web-Build zeigt falsche Werte | Formatierung in der Darstellung, nicht Extraktion. | Formatierer (`22.5` → `22,50 €`) gehört nach `shared_base`, nicht in die App. Kernbranch. |
| Bannerfläche kollidiert nach Themewechsel | App setzt eigene Abstände statt der Kernkomponente. | Bannerfläche kommt ausschließlich aus `packages/shared_base/lib/src/monetize/` (`AdSafeArea`, `NoOpAdSurface.bannerHeight = 64`, `gap = 16`) und wird nicht in der App überschrieben. |
| Firebase-Test-Lab-Kontingent aufgebraucht | Mehr als ein Merge pro Tag nach `main`. | Merges bündeln: eine App pro Tag nach `main`. Zwischenstände bleiben auf Branches, dort läuft Stufe 0 und 1, was für Entwicklung genügt. |
| `flutter pub get` bricht nach Kernänderung in einer alten App | Versionsbereich im `pubspec.yaml` der App weicht vom Kern ab. | Abhängigkeiten ausschließlich in den Kernpaketen versionieren, Apps hängen nur an den Kernpaketen. Prüfen mit `melos list --graph`. |

## Reihenfolge der 26 Apps — nach Risiko, nicht nach Lust

Sortiert wird nach Integrationsrisiko, nicht nach Attraktivität des Konzepts.
Die attraktivste App ist regelmäßig die riskanteste, und sie zuerst zu bauen
kostet die Fabrik.

### Die drei Risikobänder

| Band | Kern | Warum in dieser Position | Zeit je App |
|---|---|---|---|
| A — capture-only | `capture_core` | Vollständig im Web-Build testbar. `WebStubSttEngine` deckt den gesamten Ablauf ab. Kein natives Plugin im kritischen Pfad. | 2–3 Tage |
| B — lens-only | `lens_core` | Kamera und Erkennung sind im Web nur als Stub prüfbar; Bildqualität bleibt offen bis Firebase Test Lab. Erkennungslogik ist testbar, Bildgüte nicht. | 3–4 Tage |
| C — Hybrid | beide | Zwei Kerne in einem Eintrag, gemeinsame Segmentkette aus Audio **und** Bild. Erst sinnvoll, wenn beide Kerne durch je fünf Apps gehärtet sind. | 4 Tage |

### Positionsplan

| Nr. | Band | Kern | Flavor | Bemerkung |
|---|---|---|---|---|
| 01 | A | capture | `vox` | fertig nach WF-01 |
| 02 | A | capture | `onira` | zweite capture-App, prüft die Kerntauglichkeit |
| 03 | A | capture | | erste App ohne neue Kernfunktion — die Messlatte |
| 04 | A | capture | | |
| 05 | A | capture | | ab hier sollte `app-derive` unter 60 Minuten liegen |
| 06 | A | capture | | |
| 07 | A | capture | | |
| 08 | A | capture | | |
| 09 | A | capture | | |
| 10 | A | capture | | letzte reine capture-App vor dem Kernwechsel |
| 11 | B | lens | `prisma` | erste lens-App — `lens-core-build` läuft vorher einmal |
| 12 | B | lens | | |
| 13 | B | lens | | |
| 14 | B | lens | | |
| 15 | B | lens | | |
| 16 | B | lens | | |
| 17 | B | lens | | |
| 18 | B | lens | | |
| 19 | B | lens | | |
| 20 | B | lens | | letzte reine lens-App |
| 21 | C | beide | | erster Hybrid — Segmentkette mischt Audio und Bild |
| 22 | C | beide | | |
| 23 | C | beide | | |
| 24 | C | beide | | |
| 25 | C | beide | | |
| 26 | C | beide | | |

**Zuordnungsregel:** Jeder Steckbrief aus Band I und II wird beim ersten
`konzept-zu-bauplan`-Lauf einem Band zugeordnet — nach der Frage, welchen Kern
sein Hauptablauf braucht. Braucht er beide, ist er Band C, auch wenn einer der
beiden nur eine Nebenrolle spielt. Die Flavor-Spalte wird bei der Zuordnung
gefüllt, die Positionsnummer bleibt.

**Vor Position 11** läuft einmalig:

```
Führe lens-core-build aus. Web-Stub zuerst: WebStubScanPipeline mit
Browser-Kamera. MlKitScanPipeline danach als Gerüst. PDF-Erzeugung mit
durchsuchbarer Textebene.
```

**Vor Position 21** läuft einmalig eine Kernänderung: Die Segmentkette muss
Audio- und Bildsegmente in einer Reihenfolge tragen. `Segment.mediaPath` kann
das bereits, `Segment.engine` unterscheidet die Herkunft — geändert wird nur
die Darstellung in `capture_core/ui/EntryDetail`, und zwar als Kernbranch nach
dem Verfahren oben.

## Fortschrittstabelle — Vorlage

Liegt unter `FORTSCHRITT.md` im Repo-Wurzelverzeichnis und wird nach jedem
Merge nach `main` fortgeschrieben. Sie ist die einzige Stelle, an der der
Gesamtstand steht.

```markdown
# Fortschritt — 26 Apps

Stand: <Datum>   Fertig: <n>/26   Ø Bauzeit letzte fünf: <n,n> Tage

| Nr | Flavor | Band | Kern | Bauplan | derive | Tests 0/1 | Store | DoD | Merge | Tage | Bemerkung |
|----|--------|------|------|---------|--------|-----------|-------|-----|-------|------|-----------|
| 01 | vox    | A    | capture | x | x | x | x | x | 2026-08-14 | 5 | Fabrik-Aufbau inbegriffen |
| 02 | onira  | A    | capture | x | x | x | – | – | –          | –  | Tag 3 |
| 03 |        | A    | capture | – | – | – | – | – | –          | –  | |

Legende: x = erledigt, – = offen, ! = blockiert (Grund in Bemerkung)

## Offene Kernbranches

| Branch | Grund | Ausgelöst durch App | Alle Apps grün? |
|--------|-------|---------------------|-----------------|
| core/zahlwort-parser | Zahlwörter zweimal gebraucht | 02 onira | nein |

## Offene Punkte der Definition of Done

| App | Offener Punkt | Seit | Warum vertretbar |
|-----|---------------|------|------------------|
| vox | Golden Test Detailansicht dunkel | 2026-08-14 | Schriftrendering instabil, Startbildschirm grün |
```

**Zwei Kennzahlen entscheiden, ob die Fabrik funktioniert:**

1. **Ø Bauzeit der letzten fünf Apps.** Steigt sie, wandert Kernarbeit in die
   Apps. Fällt sie unter zwei Tage, ist der Kern gut.
2. **Zahl offener Kernbranches.** Mehr als einer gleichzeitig bedeutet, dass
   Schritt 3 des Verfahrens (alle Apps grün) übersprungen wurde. Dann wird
   keine neue App begonnen, bis die Zahl wieder bei null oder eins steht.
