# WF-01 — Von null zur ersten bedienbaren App

Fünf Tage. Ziel: `vox` auf dem capture-Kern, im Safari des iPhones vollständig
bedienbar, unter einer Cloudflare-Pages-URL.

**Die Regel dieses Workflows:** Tag 1 endet nicht mit Code, sondern mit einer
URL, die auf dem iPhone etwas anzeigt. Vorher wird keine Fachlogik geschrieben.
Wer diese Reihenfolge umdreht, baut fünf Tage blind und erfährt am Ende, dass
die Auslieferungskette nicht funktioniert. Zeitbudgets sind Nettozeit am Handy,
inklusive Wartezeit auf CI-Läufe.

## Übersicht

| Tag | Ergebnis | Zeit | Skills |
|---|---|---|---|
| 1 | Monorepo + Gerüst-App online | 4–5 h | `monorepo-bootstrap` |
| 2 | Datenmodell + Segmentkette, im Browser sichtbar | 4 h | `capture-core-build` Stufe A |
| 3 | Aufnahme + `WebStubSttEngine` + Bannerfläche | 4 h | `capture-core-build` Stufe B/C, `monetize-modul` |
| 4 | `VoxInterpreter` + Auswertung | 4–5 h | `konzept-zu-bauplan`, `app-derive` |
| 5 | Export + Golden Tests + Definition of Done | 4 h | `test-loop-free`, `store-assets` |

## Was der Nutzer vorher selbst erledigt

Drei Konten, alle kostenlos, alle vom iPhone aus. Ohne diese drei läuft nichts.
Zeitaufwand zusammen etwa 40 Minuten.

### A) GitHub-Repository

1. Safari → `github.com` → einloggen → oben rechts `+` → **New repository**.
2. Name: `app-fabrik`. Sichtbarkeit: **Private**. Kein README, kein .gitignore,
   keine Lizenz ankreuzen — das legt `monorepo-bootstrap` an. → **Create**.
3. Claude Code mit dem Repo verbinden (in der Claude-App: Repository auswählen).

### B) Cloudflare-Pages-Projekt

Cloudflare Pages hat **kein Flutter vorinstalliert**. Die Git-Anbindung von
Cloudflare würde versuchen, `flutter build web` auf einem Node-Image auszuführen,
und scheitern. Deshalb: **Der Build läuft in GitHub Actions, Cloudflare bekommt
nur das fertige Verzeichnis `build/web` per Direct Upload.**

1. `dash.cloudflare.com` → Konto anlegen (E-Mail + Passwort, keine Kreditkarte).
2. Linke Spalte → **Workers & Pages** → **Create** → Reiter **Pages** →
   **Upload assets** (nicht „Connect to Git").
3. Projektname: `app-fabrik` — **ein Projekt für alle 26 Flavors**, jede App
   bekommt ein Unterverzeichnis. → **Create project**.
4. Cloudflare verlangt einen ersten Upload. Eine `index.html` mit dem Inhalt
   `ok` in der Dateien-App anlegen, als ZIP hochladen. Danach existiert das
   Projekt unter `https://app-fabrik.pages.dev`.
5. **Account ID** notieren: steht in der Adresszeile hinter
   `dash.cloudflare.com/` — eine 32-stellige Hex-Zeichenkette.
6. API-Token: Profilbild → **My Profile** → **API Tokens** → **Create Token** →
   **Create Custom Token**. Name `github-actions-pages`, Permissions
   `Account` → `Cloudflare Pages` → `Edit`, Account Resources: eigenes Konto.
   → **Continue to summary** → **Create Token** → Token **sofort kopieren**,
   er wird nie wieder angezeigt.
7. GitHub → Repo → **Settings** → **Secrets and variables** → **Actions** →
   **New repository secret**: `CLOUDFLARE_API_TOKEN` = der Token,
   `CLOUDFLARE_ACCOUNT_ID` = die Account ID.

**Falls das Repo öffentlich sein darf**, ist GitHub Pages der zweite mögliche
Weg. Bei privatem Repo verlangt GitHub Pages ein bezahltes Konto — deshalb ist
Cloudflare der Hauptpfad und bleibt es.

**Die Werte, die zusammengehören** — sie stehen im Actions-Workflow, nicht in
der Cloudflare-Oberfläche:

| Feld | Wert |
|---|---|
| Build-Befehl | `flutter build web --release --no-web-resources-cdn --dart-define=FLAVOR=vox --dart-define=STT_ENGINE=web --base-href=/vox/ --output=build/web/vox` |
| Ausgabeverzeichnis | `build/web` (je Flavor ein Unterordner) |
| Deploy-Schritt | `cloudflare/wrangler-action` mit `command: pages deploy build/web --project-name=app-fabrik --branch=<ref>` |

### C) Firebase-Projekt (Gratis-Tarif)

Wird erst ab Tag 5 gebraucht, kann aber jetzt miterledigt werden.

1. `console.firebase.google.com` → **Projekt hinzufügen** → Name `app-fabrik`.
   Google Analytics **abwählen** — `analyticsEnabled` ist dauerhaft `false`.
2. Zahnrad → **Projekteinstellungen** → **Dienstkonten** → **Neuen privaten
   Schlüssel generieren** → JSON-Inhalt als GitHub-Secret
   `FIREBASE_SERVICE_ACCOUNT` ablegen.
3. **Cloud Storage** → Bucket-Namen kopieren, als Secret
   `FIREBASE_RESULTS_BUCKET` ablegen. Ohne diesen Bucket legt Test Lab die
   Videos und Protokolle nirgends ab.

## Tag 1 — Fundament und Gerüst-App online

**Zeitbudget: 4–5 Stunden.** Davon etwa 90 Minuten Skill-Laufzeit, der Rest
Kontoeinrichtung und CI-Wartezeit.

**Skill:** `monorepo-bootstrap`, läuft genau einmal in der Lebenszeit des Repos.

### Aufruf

```
Führe monorepo-bootstrap aus. Marke ist de.zeta, erste App ist vox auf dem
capture-Kern. Cloudflare-Pages-Projekt heißt app-fabrik, die Secrets
CLOUDFLARE_API_TOKEN und CLOUDFLARE_ACCOUNT_ID liegen im Repo. Schritt 7b legt
die Gerüst-App unter apps/vox an.
```

### Was entsteht

- `melos.yaml`, `analysis_options.yaml` mit strengen Regeln
- `packages/shared_base/`, `packages/capture_core/`, `packages/lens_core/`
- `packages/shared_base/lib/src/config/features.dart` mit allen Schaltern auf
  dem kostenlosen Zustand: `adsEnabled=false`, `billingEnabled=false`,
  `parakeetEnabled=false`, `sttEngine='platform'`, `analyticsEnabled=false`,
  `isWebStub` aus `dart.library.js_interop`. **`sttEngine` bleibt auf
  `'platform'`** — der Web-Build erzwingt die Stub-Engine zur Bauzeit über
  `--dart-define=STT_ENGINE=web`, und `resolveSttEngineId()` in
  `registry.dart` gibt unter `kIsWeb` ohnehin `'web'` zurück.
- `apps/vox/` als **Gerüst-App** (`monorepo-bootstrap` Schritt 7b): Titel,
  Platzhalter-Liste, Aufnahmeknopf-Attrappe. Keine Fachlogik, kein Interpreter,
  kein Speicher. Sie existiert, damit `web.yml` an Tag 1 etwas zu bauen hat;
  `app-derive` füllt diese Hülle an Tag 4.
- `.github/workflows/ci.yml`, `web.yml`, `testlab.yml`
- Android- und iOS-Flavor-Konfiguration, Paket-ID `de.zeta.vox`

### Der Deploy-Weg im Klartext

`web.yml` macht drei Dinge, und nur diese drei: `subosito/flutter-action`
installiert Flutter (`channel: stable`), `flutter build web --release
--dart-define=FLAVOR=vox --dart-define=STT_ENGINE=web --base-href=/vox/` baut
nach `build/web/vox`, `cloudflare/wrangler-action` lädt `build/web` per
`pages deploy build/web --project-name=app-fabrik` hoch. Cloudflare baut nichts,
Cloudflare hostet. Diese Trennung ist der Grund, warum der Weg mit Gratis-Konto
und ohne Terminal funktioniert. Je Branch entsteht eine Vorschau-URL nach dem
Muster `https://<branch>.app-fabrik.pages.dev/<flavor>/`; `main` bedient
`https://app-fabrik.pages.dev/<flavor>/`.

### Sichtprüfung auf dem iPhone

Safari öffnen, `https://app-fabrik.pages.dev/` aufrufen — die Übersichtsseite
aus `tool/gen_web_index.dart` listet die Demos. `vox` antippen, Ziel ist
`https://app-fabrik.pages.dev/vox/`.

- Es erscheint die Gerüst-App mit dem Titel `vox` und einer Platzhalter-Liste.
- Der Aufnahmeknopf ist sichtbar und ohne Funktion — eine Attrappe.
- Unten sind 64 dp fest reserviert — ein `SizedBox(height: 64)` in
  `apps/vox/lib/main.dart`. An Tag 3 löst `AdSafeArea` aus `monetize-modul`
  diesen festen Kasten ab; gleiche Höhe, deshalb ändert sich das Layout nicht.
- Hell/Dunkel folgt der iOS-Einstellung: iPhone-Einstellungen → Anzeige &
  Helligkeit umschalten, Seite neu laden, das Design wechselt.

Wenn diese vier Punkte stimmen, ist Tag 1 erfüllt. Kein Punkt davon betrifft
Fachlogik. Das ist Absicht.

### Abbruchbedingung

**Wenn nach 90 Minuten kein grüner `web.yml`-Lauf existiert**, wird nicht weiter
am Build geschraubt. Stattdessen:

1. In GitHub: **Actions** → fehlgeschlagenen Lauf → letzten roten Schritt lesen.
   Drei häufige Ursachen: Secret-Name falsch geschrieben, Account ID mit
   Leerzeichen kopiert, Projektname in `wrangler` weicht vom
   Cloudflare-Projektnamen ab.
2. Sonst `web.yml` auf reines `wrangler pages deploy` eines Ordners mit
   statischer `index.html` reduzieren, ohne Flutter. Grün heißt: Fehler im
   Flutter-Schritt. Rot heißt: Fehler bei den Zugangsdaten.
3. Tag 2 beginnt trotzdem nicht. Ein Repository ohne funktionierenden
   Auslieferungskanal ist ein Repository ohne Testkanal — und der Web-Build ist
   nach `TESTLEITER.md` zwei Drittel der Arbeit.

## Tag 2 — Datenmodell und Segmentkette

**Zeitbudget: 4 Stunden.**

**Skill:** `capture-core-build`, **Stufe A** (Datenmodell und Speicher).

### Aufruf

```
Führe capture-core-build aus, aber nur Stufe A: Datenmodell und Speicher.
Entry und Segment exakt nach ARCHITEKTUR.md, drift als SQLite-Schicht,
FileVault mit IndexedDbVault für Web. Keine Aufnahme, keine STT-Engine.
```

### Was entsteht

- `packages/shared_base/lib/src/storage/` — drift-Datenbank (`models.dart`,
  `database.dart`, `entry_store.dart`), Migration auf Version 1
- `Entry` und `Segment` mit exakt den Feldern aus `ARCHITEKTUR.md` §3.
  `Segment.order` trägt die Reihenfolge, `Segment.engine` die erzeugende Engine
  für spätere Re-Transkription. Beide werden heute schon geschrieben, obwohl
  noch keine Engine existiert.
- `packages/shared_base/lib/src/storage/file_vault.dart` — `FileVault` mit
  `IndexedDbVault` für Web und `NativeVault` für die Plattformen
- `packages/shared_base/lib/src/search/` — Volltextsuche über `title`, `tags`,
  `Segment.transcript`
- `packages/shared_base/test/entry_store_test.dart` — die vier Tests, an denen
  Stufe A gemessen wird

**In `apps/vox/` entsteht heute nichts.** `capture-core-build` baut
ausschließlich Paketcode und verweist für App-Code ausdrücklich auf
`app-derive`. Die Gerüst-App bleibt unverändert, bis sie an Tag 4 ersetzt wird.
Wer heute Liste und Detailansicht in `apps/vox` erwartet, sucht am falschen Ort.

### Nachweis am Ende von Tag 2

Der Kern ist heute nur über Tests bedienbar. Das ist kein Mangel, sondern die
Reihenfolge: Erst steht das Datenmodell, dann bekommt es eine Oberfläche.

```
Führe melos exec --scope=shared_base -- flutter test aus und zeig mir das
Ergebnis Test für Test. Danach flutter analyze über das Monorepo.
```

Vier Tests aus `entry_store_test.dart` müssen grün sein, und zwar diese:
`appendSegment` vergibt lückenlose `order`-Werte ab 0, `retranscribe` ersetzt
Text **und** Engine eines Segments, die Volltextsuche findet über
Segmentgrenzen hinweg, `FileVault` ist über `registerFileVault()` gebunden.

**Sichtprüfung auf dem iPhone:**

1. GitHub-App → **Actions** → letzter Lauf von `ci.yml` ist grün. Test- und
   Analyse-Schritt einzeln aufklappen und die Zeile mit der Testanzahl lesen.
2. `https://app-fabrik.pages.dev/vox/` öffnen: die Gerüst-App sieht aus wie an
   Tag 1 — Titel, Platzhalter-Liste, Knopf-Attrappe, 64 dp unten. **Unverändert
   ist hier das richtige Ergebnis.** Verändert wäre es ein Zeichen dafür, dass
   Paketcode in die App gewandert ist.

**Was der Nutzer selbst tut:** nichts an Konten. Nur den Actions-Lauf ansehen
und die Gerüst-App gegenprüfen.

### Abbruchbedingung

**Wenn drift nach 90 Minuten nicht auf Web läuft** (häufigster Fall: fehlende
`drift_worker.js` oder `sqlite3.wasm` in `web/`), wird nicht weiter an drift
gearbeitet. Stattdessen `StorageAdapter` als Schnittstelle einziehen,
`InMemoryStorage` für Web registrieren, weiterbauen. drift kommt an Tag 5 als
eigener Branch zurück; das Datenmodell bleibt unverändert, nur die Schicht
darunter wird getauscht. Genau dafür existiert `ARCHITEKTUR.md` §4.

## Tag 3 — Aufnahme und WebStubSttEngine

**Zeitbudget: 4 Stunden.**

**Skills:** `capture-core-build` **Stufe B und C**, danach `monetize-modul`.

### Aufruf 1

```
Führe capture-core-build Stufe B und C aus: Recorder mit Wellenform und
Wiedergabe, danach die SttEngine-Schnittstelle mit WebStubSttEngine und
PlatformSttEngine. Stufe D (ParakeetSttEngine) wird NICHT gebaut,
parakeetEnabled bleibt false. Die WebStubSttEngine bekommt eine einstellbare
Verzögerung und einen Fehlerfall.
```

### Aufruf 2

```
Bau das Monetarisierungs-Modul: AdSurface und Purchases als Schnittstellen,
NoOpAdSurface und AlwaysProPurchases gebunden, Bannerfläche reserviert mit
16 dp Abstand, UMP-Gerüst, CI-Prüfung auf Test-IDs. Nichts einschalten.
```

`monetize-modul` läuft **einmal im Repo**, nicht je App. Er gehört hierher,
weil die Definition of Done „Bannerfläche reserviert, Abstand geprüft" verlangt
und weil der Aufnahmeknopf aus Stufe B genau jetzt seinen endgültigen Platz
bekommt. Später eingezogen, wird jedes Layout ein zweites Mal angefasst.

### Was entsteht

- `packages/capture_core/lib/src/audio/` — Aufnahme über `MediaRecorder` im
  Web, Wellenformanzeige, Wiedergabe je Segment
- `packages/capture_core/lib/src/stt/stt_engine.dart` — die Schnittstelle aus
  `ARCHITEKTUR.md` §4, wortgleich
- `WebStubSttEngine` (`id == 'web'`) — hinterlegter Beispieltext nach
  einstellbarer Verzögerung, mit Fehlermodus
- `PlatformSttEngine` — Gerüst gegen Android `SpeechRecognizer` und iOS
  `Speech`, auf Web `isAvailable == false`
- Registrierung über `resolveSttEngineId()` in
  `packages/shared_base/lib/src/config/registry.dart`
- `packages/shared_base/lib/src/monetize/` — `AdSurface` mit `NoOpAdSurface`
  (`bannerHeight = 64`, `gap = 16`), `Purchases` mit `AlwaysProPurchases`,
  UMP-Gerüst, CI-Prüfung auf Test-Anzeigen-IDs

**Nicht gebaut wird Stufe D (`ParakeetSttEngine`):** riskanteste Integration,
640 MB Modell, gehört nicht in den kritischen Pfad des ersten Ergebnisses.

**Auch heute entsteht kein Code in `apps/vox/`.** Recorder, Wellenform,
`RecordButton` und die Engines liegen in `capture_core`, die Bannerfläche in
`shared_base`. Zusammengesetzt wird das an Tag 4 von `app-derive`. Eine im
Browser bedienbare Aufnahme gibt es deshalb heute noch nicht.

### Nachweis am Ende von Tag 3

```
Führe melos exec --scope=capture_core -- flutter test und
melos exec --scope=shared_base -- flutter test aus. Nenn mir jeden roten Test
einzeln, nicht nur die Gesamtzahl.
```

Grün sein müssen:

| Testdatei | Was sie festhält |
|---|---|
| `packages/capture_core/test/record_button_test.dart` | `RecordButton` ist mindestens 56 dp hoch und hält 16 dp Abstand nach unten |
| `packages/capture_core/test/stt_engine_test.dart` | vier Tests: Stub liefert Text nach eingestellter Verzögerung, Stub bricht bei eingestellter Fehlerquote, `PlatformSttEngine` meldet `isAvailable` ehrlich, `registerSttEngine()` wählt nach `resolveSttEngineId()` |
| `packages/shared_base/test/monetize_test.dart` | `NoOpAdSurface.bannerHeight == 64`, Mindestabstand ≥ 16, `AdSafeArea.scrollPadding == 88`, keine echte Anzeigen-ID im Debug-Build |

**Sichtprüfung auf dem iPhone:**

1. GitHub-App → **Actions** → `ci.yml` grün. Die Golden-Bilder des Kerns liegen
   als Artefakt bereit; bei Rot enthält `golden-failures` die Diff-PNGs.
2. Der Werbe-ID-Prüfschritt aus `monetize-modul` steht im Lauf und ist grün —
   er ist der einzige Schritt, der einen Build absichtlich brechen darf.
3. `https://app-fabrik.pages.dev/vox/` öffnen: die Gerüst-App ist weiterhin
   unverändert. Der Aufnahmeknopf bleibt eine Attrappe.

Der Fehlerfall der `WebStubSttEngine` ist der wichtige Test der drei Tabellen —
der Erfolgsfall ist trivial, die Frage ist, ob eine fehlgeschlagene
Transkription die Aufnahme mitnimmt. Bedient wird beides an Tag 4.

### Abbruchbedingung

**Wenn `PlatformAudioRecorder` nach 90 Minuten nicht durch seine Tests kommt**
— iOS-Safari ist bei `MediaRecorder` eigenwillig, die Codec-Auswahl
eingeschränkt, und das schlägt bis in den Web-Zweig durch —, dann:
Aufnahme überspringen, `Segment.mediaPath` bleibt `null`, die
`WebStubSttEngine` liefert ihren Text ohne Audioquelle. Segmentkette,
Interpreter und Exporte sind ohne echtes Audio vollständig testbar. Die
Aufnahme kommt an Tag 5 als eigener Branch zurück, spätestens auf echter
Hardware in Firebase Test Lab.

## Tag 4 — Interpreter und Auswertung

**Zeitbudget: 4–5 Stunden.**

**Skills:** `konzept-zu-bauplan`, danach `app-derive`.

### Aufruf 1

```
Führe konzept-zu-bauplan für vox aus. Steckbrief steht in
docs/steckbriefe/vox.md — halt dich daran, auch wenn dieser Workflow
etwas anderes nahelegt. Ergebnis nach docs/baupläne/vox.md:
Interpreter-Regeln, Datenfelder, Bildschirme, Exportvorlage, zwölf
Testsätze.
```

> **Korrektur, 11.08.2026.** Frühere Fassungen nannten hier „Sprachnotizen
> mit Ausgabenerkennung" und den Satz „zweiundzwanzig fünfzig bei Rewe".
> Das ist der Interpreter von **KASSA**, nicht von VOX. Der Steckbrief von
> VOX sagt ausdrücklich *„Kein Interpreter — Text bleibt Text"*. Bei einem
> Widerspruch zwischen Workflow und Steckbrief gewinnt der Steckbrief: der
> Workflow beschreibt den Ablauf, der Steckbrief das Erzeugnis.

### Aufruf 2

```
Führe app-derive für vox aus. Kern: capture. Bauplan liegt unter
docs/baupläne/vox.md. Erzeuge VoxInterpreter mit Tests, die Auswertungsansicht,
VoxTheme und den Store-Metadaten-Rahmen.
```

### Was entsteht

- `apps/vox/lib/src/vox_interpreter.dart` — schreibt strukturierte Felder nach
  `Entry.data`
- `apps/vox/test/vox_interpreter_test.dart` — mindestens **zwölf**
  realistische Beispielsätze nach der Mischung aus `TESTLEITER.md` Stufe 0:
  vier normal, drei Erkennungsfehler der Gratis-Engine, zwei unvollständig,
  zwei Grenzfall, einer leer.
- **Deutsche Zahlwörter und Zeitangaben gehören nicht in die App.** Sie
  stehen seit Tag 4 in `shared_base/src/text/` als `SpokenNumbers` und
  `SpokenDates`, mit eigenen Tests — benutzt von KASSA, RITUS, FAHRTLOG,
  WERKBUCH und ANAMNESE. Dass `"zweiundzwanzig fünfzig bei Rewe"` zu
  `22.50` wird, prüft `packages/shared_base/test/text_test.dart`, nicht
  `vox`.
- `apps/vox/lib/src/insights_screen.dart` — die eine große Zahl
  (gesprochene Minuten), Häufigkeitsliste der Schlagworte, Verlauf je Woche
- `apps/vox/lib/src/home_screen.dart` und `apps/vox/lib/main.dart` — die
  Gerüst-App aus Tag 1 wird ersetzt, nicht ergänzt
- `apps/vox/lib/src/vox_theme.dart` — vier Farben, zwei Schriftfamilien,
  Startbildschirmaufbau. Sonst nichts.

### Sichtprüfung auf dem iPhone

1. Drei Einträge über den Aufnahmeknopf anlegen, Stub-Text jeweils anders
   einstellen.
2. Detailansicht: die vom Interpreter erkannten Felder stehen sichtbar unter
   dem Transkript, nicht statt seiner.
3. Auswertungsansicht: die große Zahl und die Wortzahl stimmen
   rechnerisch mit den drei Einträgen.
4. Ein Segment nachträglich anhängen → die Auswertung aktualisiert sich, ohne
   dass die App neu geladen wird.
5. Schriftgröße in iOS auf die größte Stufe → keine abgeschnittenen Zahlen,
   kein Überlauf in der Auswertung.

### Abbruchbedingung

**Wenn `app-derive` nach 2 Stunden Laufzeit nicht fertig ist**, ist das ein
Architekturfehler, kein Zeitproblem: zu viel App, zu wenig Kern. Lauf
abbrechen, prüfen, welche Dateien in `apps/vox/` in einer zweiten App nützlich
wären (Zahlwort-Parser, Datumserkennung, Währungsformatierung gehören nach
`shared_base`), diese in den Kern verschieben, dann `app-derive` neu starten.
Das ist keine Nacharbeit, sondern der Zweck der Fabrik.

**Wenn weniger als zwölf Testsätze grün sind**, geht Tag 5 nicht los. Der
Interpreter ist nach `TESTLEITER.md` der Teil mit der höchsten Fehlerdichte und
dem geringsten Testaufwand.

## Tag 5 — Export, Golden Tests, Definition of Done

**Zeitbudget: 4 Stunden.**

**Skills:** `test-loop-free`, dann `store-assets`.

### Aufruf 1

```
Führe test-loop-free für vox aus, Stufe 0 und Stufe 1. Golden Tests für
Startbildschirm, Liste und Detail, je hell und dunkel. Integrationstest für
den Hauptablauf mit Screenshot-Ablage als CI-Artefakt.
```

### Aufruf 2

```
Führe store-assets für vox aus. Screenshots aus den Integrationstests, keine
Bildbearbeitung. Ablage unter apps/vox/store/.
```

### Was entsteht

- Alle vier Exportformate aus `ARCHITEKTUR.md` §7: Markdown mit
  YAML-Frontmatter und `[[Verweisen]]`, KI-Kontextbündel mit Schema-Kopf und
  Token-Schätzung, gestaltetes PDF, CSV
- **Fluchttür-Export**: vollständiges JSON plus ZIP aller Originaldateien,
  kostenlos, in den Einstellungen prominent
- Sechs Golden-Test-PNGs als CI-Artefakt, `integration_test/` mit dem
  Hauptablauf, `apps/vox/store/` mit Titel (30 Z.), Kurzbeschreibung (80 Z.),
  Langbeschreibung, Datenschutzangaben, Screenshots

### Sichtprüfung auf dem iPhone

Die vollständige Prüfliste aus `TESTLEITER.md`, Stufe 1, alle acht Punkte:

1. Neuen Eintrag anlegen, Stub-Transkript erscheint
2. Denselben Eintrag um ein zweites Segment erweitern, Reihenfolge stimmt
3. Interpreter-Ergebnis prüfen — Felder korrekt gefüllt
4. Eintrag suchen, finden, öffnen
5. Alle vier Exporte auslösen, Dateien öffnen sich und sind vollständig
6. Fluchttür-Export prüfen: enthält er wirklich alles?
7. Hell und dunkel umschalten, Schriftgröße hoch, nichts bricht
8. Auf schmalem Fenster: Bannerfläche kollidiert mit nichts — **mindestens
   16 dp Abstand zum Aufnahmeknopf.** Fehlklicks neben dem Aufnahmeknopf sind
   ein Sperrgrund im Store, nicht eine Unschönheit.

Zusätzlich: In GitHub → **Actions** → letzter Lauf → **Artifacts** → die
Golden-PNGs herunterladen und in der Fotos-App ansehen. Sechs Bilder, drei
Bildschirme, hell und dunkel.

### Definition of Done — abhaken

Aus `ARCHITEKTUR.md` §10. Alle zehn Punkte, sonst ist `vox` nicht fertig:

- [ ] Läuft im Web-Build vollständig bedienbar, alle Bildschirme erreichbar
- [ ] Interpreter hat Tests mit mindestens zwölf realistischen Beispielsätzen
- [ ] Golden Tests für Startbildschirm, Liste, Detail — hell und dunkel
- [ ] Ein Integrationstest spielt den Hauptablauf von Anfang bis Ende durch
- [ ] Alle vier Exportformate erzeugen gültige Dateien
- [ ] Fluchttür-Export vorhanden, kostenlos, in den Einstellungen sichtbar
- [ ] Bannerfläche reserviert, Abstand geprüft
- [ ] Store-Texte und Screenshots liegen unter `apps/vox/store/`
- [ ] `flutter analyze` ohne Befund
- [ ] Kein Code in `apps/vox/`, der in eine zweite App gehören würde

### Abbruchbedingung

**Wenn Golden Tests nach 90 Minuten nicht stabil sind** — üblicher Grund ist
Schriftrendering, das zwischen Runner-Versionen abweicht —, dann: Schriftart
über `loadFontFromList` fest im Test laden statt die Systemschrift zu nutzen,
`matchesGoldenFile` mit festgelegtem `TestWidgetsFlutterBinding` und fixer
`devicePixelRatio`. Führt auch das nicht zum Ziel: Golden Tests auf den
Startbildschirm reduzieren, Rest auf einen eigenen Branch, `vox` gilt trotzdem
als fertig — mit einem offenen Punkt in `apps/vox/OFFEN.md`. Ein notierter
offener Punkt ist verantwortbar, ein stiller nicht.

## Nach Tag 5

`vox` läuft. Die Fabrik steht. Ab App 2 gilt `WF-02-WEITERE-APP.md`, Zielzeit
zwei bis vier Tage je App. Firebase Test Lab (Stufe 2) läuft beim ersten Merge
nach `main` automatisch an, sobald `FIREBASE_SERVICE_ACCOUNT` gesetzt ist — der
Robo-Test liefert Video und Absturzprotokolle, im Browser auf dem iPhone
ansehbar. Erster Blick auf echte Android-Hardware, kostenlos.
