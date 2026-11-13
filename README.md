# App-Fabrik — Skill- und Workflow-Paket

Sechsundzwanzig Apps sind nicht sechsundzwanzig Projekte. Sie sind zwei Kerne,
ein gemeinsamer Unterbau und sechsundzwanzig dünne Hüllen. Dieses Paket enthält
die elf Skills und vier Workflows, mit denen Claude Code diese Fabrik baut —
von einem iPhone 14 aus, mit einem Budget von null Euro.

[![ci](https://github.com/Zelos0/App-Factory/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Zelos0/App-Factory/actions/workflows/ci.yml)
[![web](https://github.com/Zelos0/App-Factory/actions/workflows/web.yml/badge.svg?branch=main)](https://github.com/Zelos0/App-Factory/actions/workflows/web.yml)

## Ausprobieren — auf dem iPhone, jetzt

**https://zelos0.github.io/App-Factory/**

Dort liegen alle fertigen Apps als Web-App. Jeder Push auf `main` baut sie neu
und veröffentlicht sie automatisch (`.github/workflows/web.yml`). Tipp: In
Safari über *Teilen → Zum Home-Bildschirm* sieht Vox aus wie eine echte App.

> **Einmalig nötig, falls die Adresse 404 meldet:** Repository →
> *Settings* → *Pages* → bei *Build and deployment* unter *Source*
> „Deploy from a branch" wählen → Branch **`gh-pages`**, Ordner **`/ (root)`**
> → *Save*. Nach ein bis zwei Minuten ist die Seite da. Danach nie wieder.

## Stand

| | |
|---|---|
| **Fundament** | Melos-Monorepo, `shared_base`, `capture_core`, `lens_core` (Gerüst), CI, Web-Deploy |
| **Apps** | 1 von 26: **Vox** — Sprachnotizen, die sich selbst ordnen |
| **Prüfungen** | Analyse ohne Befund, 130 Tests grün, Werbe-ID-Wächter — lokal und in der CI identisch (Flutter 3.24.5) |
| **Nächster Schritt** | `apps/vox/OFFEN.md` — dann WF-02 für App 2 |

### Was Vox heute im Browser kann

- **Aufnehmen und mitschreiben.** Die Spracherkennung des Browsers hört
  während der Aufnahme mit (Safari ab iOS 14.5, Chrome, Edge). Pausen beim
  Sprechen sind kein Problem. Scheitert die Erkennung, bleibt die Aufnahme
  trotzdem gespeichert.
- **Einträge erweitern** — das ➕ neben einem Eintrag hängt eine Aufnahme an.
- **Suchen** über alle Transkripte, **Auswertung** über alle Einträge.
- **Exportieren** als Markdown, PDF, KI-Kontextbündel, JSON oder Text —
  auf dem Telefon über das Teilen-Menü (In Dateien sichern, AirDrop …),
  am Rechner als Download. Jedes Textformat auch per Kopier-Symbol.
- **Fluchttür:** alles als ZIP, dauerhaft kostenlos.
- Kein Konto, kein Server, kein Tracking. Alles bleibt im Browser.

### Lokal bauen

```bash
# Flutter 3.24.5 — dieselbe Version wie die CI
export PATH=/pfad/zu/flutter/bin:$PATH
dart pub get && dart run melos bootstrap
dart run melos run analyze
dart run melos run test
dart run melos run build-web -- vox    # Ergebnis in build/web/vox
```

Melos immer über `dart run melos …`, nie global installiert.

## Was hier drin ist

```
app-fabrik/
├── README.md                          diese Datei
├── ARCHITEKTUR.md                     die technische Wahrheit — Widersprüche sind Fehler
├── TESTLEITER.md                      Verifikation ohne Geld, ohne PC, ohne Android-Gerät
├── docs/steckbriefe/                  die 26 Apps aus Band I und II
├── .claude/skills/
│   ├── monorepo-bootstrap/            Fundament: Melos, Pakete, CI, Schalter
│   ├── capture-core-build/            Sprach-Kern, vier Stufen
│   ├── lens-core-build/               Kamera-Kern, vier Stufen
│   ├── app-derive/                    eine App ableiten — läuft 26-mal
│   ├── konzept-zu-bauplan/            Steckbrief → Bauplan (Eingabe für app-derive)
│   ├── test-loop-free/                vier Teststufen, jede einzeln aufrufbar
│   ├── monetize-modul/                AdSurface + Purchases, gebaut und stillgelegt
│   ├── store-assets/                  Store-Texte und Screenshots aus der CI
│   ├── release-gate/                  Veröffentlichung — stillgelegt
│   ├── review-agent/                  Rezensionsantworten — stillgelegt
│   └── policy-watch/                  Richtlinien und SDK-Fristen — läuft ab Tag 1
└── workflows/
    ├── WF-01-ERSTE-APP.md             Tag 1 bis 5: von null zur bedienbaren Web-App
    ├── WF-02-WEITERE-APP.md           die Schleife für App 2 bis 26
    ├── WF-03-BETRIEB.md               der monatliche Bestandslauf
    └── WF-04-GELD-DA.md               die Aufwachliste in drei Wellen
```

Die Skills liegen unter `.claude/skills/`, weil Claude Code sie nur dort
selbst findet und anbietet. Der Aufruf bleibt derselbe wie unten beschrieben —
wörtlich, auf Deutsch.

## Die Regel, die alles bestimmt

**Budget = 0 €.** Kein Play-Console-Konto, kein Apple Developer Program, kein
Android-Testgerät, kein Mac, kein bezahlter Dienst.

Daraus folgt: **Alles, was Geld kostet, wird jetzt vollständig gebaut, aber
hinter einem Schalter stillgelegt.** Kein Skill setzt ein bezahltes Konto
voraus, um zu laufen. Jeder Skill, der später eines braucht, prüft eine
Konfigurationsvariable und überspringt sich selbst mit einer klaren Meldung,
statt zu scheitern.

| Bereich | Jetzt | Später |
|---|---|---|
| Werbung | `AdSurface` + `NoOpAdSurface`, Layout reserviert 64 dp + 16 dp Abstand | `AdMobAdSurface` einhängen, `adsEnabled` umlegen |
| Käufe | `Purchases` + `AlwaysProPurchases` | `PlayBillingPurchases` einhängen |
| Veröffentlichung | Store-Texte, Screenshots, Datenschutzangaben liegen im Repo | Hochladen über `release-gate` |
| Natives Testen | Web-Build + CI + Firebase Test Lab (Gratis-Kontingent) | TestFlight, echtes Android-Gerät |

Das ist keine Notlösung. Die Schnittstellenschicht, die daraus entsteht, ist die
Architektur, die das Portfolio ohnehin braucht — der Geldmangel erzwingt nur,
sie sofort richtig zu machen.

## Wo du anfängst

**Zuerst laufen muss `monorepo-bootstrap`.** Er legt das gesamte Fundament an
und läuft genau einmal. Alles andere setzt ihn voraus.

Danach folgt `WF-01-ERSTE-APP.md` Schritt für Schritt. Tag 1 endet damit, dass
du auf deinem iPhone eine URL öffnest und etwas siehst. Erst danach beginnt
Fachlogik.

### Reihenfolge im Überblick

```
monorepo-bootstrap          einmal
  └─ capture-core-build     Stufen A → B → C  (D erst mit Android-Gerät)
  └─ lens-core-build        Stufen A → B → C  (D erst mit Android-Gerät)
  └─ monetize-modul         einmal, vor der ersten App
       └─ konzept-zu-bauplan  ┐
       └─ app-derive          ├─ je App, 26-mal
       └─ test-loop-free      │
       └─ store-assets        ┘
policy-watch                monatlich, ab sofort
release-gate                schläft — wacht bei 25 $
review-agent                schläft — wacht mit der Produktionsspur
```

## Was du selbst tun musst, bevor irgendetwas läuft

Drei Dinge, alle vom iPhone aus, alle kostenlos:

**1 — GitHub-Repository anlegen (privat) und Claude Code damit verbinden.**
Ohne Repo kein Fundament. Privat ist die Vorgabe; öffentlich ginge auch, dann
wird in `monorepo-bootstrap` der zweite, klar markierte Pfad über GitHub Pages
statt Cloudflare gewählt.

**2 — Cloudflare-Pages-Projekt verbinden.**
`dash.cloudflare.com` → Workers & Pages → Create → Pages → Direct Upload,
Projektname exakt `app-fabrik`. Dann unter My Profile → API Tokens ein Token
mit der Berechtigung *Account → Cloudflare Pages → Edit* erzeugen. Token und
Account-ID als GitHub-Secrets hinterlegen:

```
CLOUDFLARE_API_TOKEN
CLOUDFLARE_ACCOUNT_ID
```

Cloudflare Pages ist der Standard, weil GitHub Pages bei privaten Repositories
ein bezahltes Konto verlangt. Cloudflare ist kostenlos, kommt mit privaten
Repos zurecht und erzeugt je Branch eine eigene Vorschau-URL.

**3 — Firebase-Projekt auf dem Gratis-Tarif anlegen.**
`console.firebase.google.com` → Projekt anlegen, Analytics abwählen. Unter
Projekteinstellungen → Dienstkonten einen privaten Schlüssel erzeugen und den
kompletten JSON-Inhalt als GitHub-Secret hinterlegen:

```
FIREBASE_SERVICE_ACCOUNT
FIREBASE_RESULTS_BUCKET
```

Damit läuft Firebase Test Lab mit echter Android-Hardware in Googles
Rechenzentrum — ohne ein Gerät zu besitzen.

**Fehlen Secrets aus 2 oder 3, bleibt die CI grün.** Der jeweilige Schritt wird
übersprungen und meldet, was fehlt. Nichts blockiert.

## Die Dateien, die im Repo entstehen

`ARCHITEKTUR.md` Abschnitt 2 zeigt die Struktur zum Zeitpunkt des Fundaments —
drei Workflow-Dateien. Die stillgelegten Skills bringen ihre eigenen mit, sobald
sie laufen. Vollständige Liste, damit später niemand rätselt, wer was angelegt
hat:

| Datei | Erzeugt von | Aktiv ab |
|---|---|---|
| `.github/workflows/ci.yml` | `monorepo-bootstrap` | sofort |
| `.github/workflows/web.yml` | `monorepo-bootstrap` | sofort |
| `.github/workflows/testlab.yml` | `monorepo-bootstrap` | sobald Firebase-Secret da ist |
| `.github/workflows/policy-watch.yml` | `policy-watch` | sofort |
| `.github/workflows/store-assets.yml` | `store-assets` | sofort |
| `.github/dependabot.yml` | `WF-03-BETRIEB` | sofort |
| `.github/workflows/release.yml` | `release-gate` | mit `PLAY_CONSOLE_READY` |
| `.github/workflows/reviews.yml` | `review-agent` | mit `PLAY_CONSOLE_READY` |
| `.github/workflows/distribute.yml` | `WF-04-GELD-DA`, Welle 2 | mit `APP_DISTRIBUTION_READY` |
| `codemagic.yaml` | `test-loop-free` Stufe 3 | mit Apple-Konto |

Ablage außerhalb des Quelltexts, durchgängig unter `ops/`:
`ops/policy/<JJJJ-MM>.md`, `ops/reviews/<flavor>.jsonl`,
`ops/testers/<flavor>.md`. Baupläne unter `docs/baupläne/<flavor>.md`.

## Die 26 Steckbriefe

`docs/steckbriefe/` enthält je App eine Datei, aus den beiden Bänden
übernommen: Zielgruppe, auslösender Moment, Funktionen, Interpreter bzw.
Pipeline, Export, Auflagen, Preisgestaltung, Konkurrenz und Gestaltung.
`docs/steckbriefe/README.md` trägt die Gesamtübersicht, die Preisarchitektur
und beide Umsetzungsreihenfolgen.

Das ist die **Eingabe für `konzept-zu-bauplan`** — nicht für `app-derive`.
Der Weg ist immer:

```
docs/steckbriefe/<flavor>.md   konzept-zu-bauplan   docs/baupläne/<flavor>.md   app-derive
```

Jeder Steckbrief schließt mit dem Abschnitt „Offen", der benennt, was die
Bände nicht festlegen — allen voran die zwölf Beispielsätze je Interpreter.
Diese Punkte klärt `konzept-zu-bauplan` beim Lauf, statt sie zu raten.

Sechzehn Apps laufen auf `capture_core`, acht auf `lens_core`, zwei auf
beiden. Zwei Flavor-Namen sind gegenüber den Bänden entumlautet, weil
ARCHITEKTUR.md Abschnitt 9 Kleinbuchstaben ohne Umlaute verlangt: ÜBERGABE →
`uebergabe`, SCHWÄRZE → `schwaerze`.

## Wie du einen Skill aufrufst

Wörtlich, auf Deutsch, so wie du sprichst. Jede `SKILL.md` schließt mit einem
Abschnitt „Beispielaufruf". Beispiele:

```
Leg das Fundament der App-Fabrik an.
```

```
Bau Stufe A des Sprach-Kerns: Datenmodell und Speicher nach ARCHITEKTUR.md.
```

```
Leite die App onira ab. Kern: capture. Bauplan liegt in docs/baupläne/onira.md.
```

```
Stufe 1 der Testleiter: Web-Build und Prüfliste fürs iPhone.
```

## Die drei Zahlen, die zählen

| Zahl | Bedeutung | Steht in |
|---|---|---|
| **2 Stunden** | Zielzeit für eine abgeleitete App. Wird sie gerissen, steckt zu viel in der App und zu wenig im Kern. | `app-derive`, Abbruchkriterium 1 |
| **12 Beispielsätze** | Pflicht je Interpreter, nicht Kür. Vier normal, drei Engine-Fehler, zwei unvollständig, zwei Grenzfall, einer leer. | `konzept-zu-bauplan` Schritt 8 |
| **16 dp** | Mindestabstand zwischen jedem Bedienelement und der Bannerfläche. Fehlklicks sind ein Sperrgrund im Store. | `ARCHITEKTUR.md` Abschnitt 8 |

## Was dieses Paket bewusst nicht tut

- Es baut keine Apps. Es baut die Werkzeuge, mit denen Apps gebaut werden.
- Es entscheidet nichts, was der Bauplan offenlässt. Jeder Skill fragt, statt
  zu raten — die Abbruchkriterien sind Teil der Spezifikation, kein Beiwerk.
- Es schaltet nichts ein, was Geld kostet. `adsEnabled`, `billingEnabled`,
  `parakeetEnabled` bleiben `false`, bis `WF-04-GELD-DA.md` sie Welle für Welle
  aufweckt. `analyticsEnabled` bleibt dauerhaft `false` — kein Tracking, in
  keiner App.
