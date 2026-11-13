---
name: review-agent
description: Holt täglich die Play-Store-Rezensionen über die Google-Play-Developer-API ab, führt ein eigenes Archiv unter ops/reviews/<flavor>.jsonl, weil die API nur etwa sieben Tage zurückreicht, und legt Antwortentwürfe zur Freigabe vor statt sie zu senden — prüft dabei zuerst PLAY_CONSOLE_READY und endet ohne Fehler, solange kein Play-Konto existiert; ausgelöst durch „Rezensionen abholen", „Bewertungen prüfen", „auf Reviews antworten", „was schreiben die Nutzer".
---

# Rezensions-Agent — stillgelegt, aber vollständig

Ohne Play-Konto gibt es keine Rezensionen. Trotzdem wird die Strecke jetzt gebaut,
weil sie eine Eigenschaft hat, die sich später nicht nachholen lässt: **Die API
zeigt Rezensionen nur rund sieben Tage lang.** Wer erst nach der Veröffentlichung
mit dem Archivieren anfängt, hat die erste Woche für immer verloren — genau die
Woche, in der die aussagekräftigsten Rezensionen entstehen.

## Wann dieser Skill greift

Auslöser: „hol die Rezensionen", „Bewertungen für onira prüfen",
„Antwortentwürfe schreiben", „was schreiben die Nutzer", „Reviews beantworten",
„Rezensionsarchiv aktualisieren".

Greift **nicht**:
- zum Hochladen einer App — das ist `release-gate`.
- für Store-Texte, mit denen man Erwartungen steuert — das ist `store-assets`.
- für Richtlinienänderungen, die aus Rezensionen abgeleitet würden — das ist
  `policy-watch`, und der läuft schon jetzt.
- für Absturzberichte. Die kommen aus Android Vitals, nicht aus dieser API.

## Voraussetzungen

**Zum Bauen (jetzt, kostenlos):**
- Repo nach `ARCHITEKTUR.md`, `packages/shared_base/lib/src/config/brand.dart` mit
  `kBrand` (`de.zeta`). Node kann Dart nicht importieren, deshalb spiegeln die
  Skripte den Wert als Konstante `MARKE`.
- `tool/release_gate.sh` aus `release-gate` — dieser Skill ruft es für die
  Schalterprüfung auf und definiert es nicht neu.
- Node 20 auf den GitHub-Runnern (vorinstalliert).
- `gh` authentifiziert.

**Zum Ausführen (später):**
- Repo-Variable `PLAY_CONSOLE_READY = true` (setzt `release-gate`).
- Repo-Secret `PLAY_SERVICE_ACCOUNT_JSON` mit dem Recht „Antworten auf
  Rezensionen verwalten".
- Mindestens eine App in der Produktionsspur veröffentlicht.

## Technische Randbedingungen — nicht verhandelbar

Diese fünf Punkte bestimmen den gesamten Entwurf. Wer einen davon ignoriert,
baut einen Agenten, der Daten verliert oder gesperrt wird.

1. **Nur Rezensionen mit Text.** `reviews.list` liefert ausschließlich
   Bewertungen, zu denen ein Kommentar geschrieben wurde. Reine Sternebewertungen
   erscheinen nie. Eine Antwort auf eine textlose Bewertung ist technisch
   unmöglich — der Agent zählt sie deshalb auch nicht.
2. **Nur die Produktionsspur.** Rezensionen aus interner, geschlossener oder
   offener Testspur tauchen in dieser API nicht auf. Solange nur getestet wird,
   ist das Ergebnis leer, und das ist korrekt, kein Fehler.
3. **Kontingente.** 200 Abrufe pro Stunde und 2000 Antworten pro Tag, je Paket.
   Der Agent zählt beides selbst mit und stoppt vor der Grenze, statt Fehler
   zu kassieren.
4. **Sichtbarkeitsfenster von etwa sieben Tagen.** Ältere Rezensionen sind über
   die API nicht mehr erreichbar. Daraus folgen zwei Pflichten: ein eigenes
   Archiv unter `ops/reviews/<flavor>.jsonl` und ein Lauf, der **mindestens
   täglich** stattfindet. Fällt der Lauf länger als sieben Tage aus, entsteht
   eine Lücke, die niemand mehr schließen kann.
5. **Eine Antwort je Rezension.** Eine zweite Antwort ersetzt die erste, sie
   ergänzt sie nicht. Antworten sind auf 350 Zeichen begrenzt.

## Ablauf

### Schritt 1 — Schalter prüfen

```bash
./tool/release_gate.sh || exit $?
```

Steht `PLAY_CONSOLE_READY` nicht auf `true`, meldet das Skript die vollständige
Fehlliste und endet mit Exit 0. Der Rezensions-Agent endet hier ebenfalls, ohne
Fehler und ohne angefangene Dateien.

Zusätzlich existiert ein eigener Schalter für das Senden:

```bash
gh variable set REVIEW_AUTOREPLY --body false
```

Solange `REVIEW_AUTOREPLY` aus ist, werden Antworten **ausschließlich als Entwurf
geschrieben und niemals gesendet.** Das ist der Vorgabezustand und bleibt es,
bis der Nutzer ihn ausdrücklich umlegt.

### Schritt 2 — Werkzeugpaket anlegen

```json
{
  "name": "fabrik-reviews",
  "private": true,
  "type": "module",
  "description": "Abruf und Archivierung der Play-Rezensionen. Kein App-Bestandteil.",
  "engines": { "node": ">=20" },
  "dependencies": {
    "googleapis": "^144.0.0"
  }
}
```

Pfad: `ops/reviews/package.json`

### Schritt 3 — Abrufskript

```javascript
// ops/reviews/fetch_reviews.mjs
// Holt die Rezensionen eines Pakets, hängt neue an das JSONL-Archiv an und
// legt für unbeantwortete Rezensionen einen Antwortentwurf ab.
//
// Aufruf:
//   node ops/reviews/fetch_reviews.mjs --flavor=onira
// Umgebung:
//   PLAY_SERVICE_ACCOUNT_JSON  vollständiger JSON-Inhalt des Dienstkontos
//   PLAY_CONSOLE_READY         "true" oder alles andere
import { google } from 'googleapis';
import { readFileSync, existsSync, mkdirSync, appendFileSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';

const MARKE = 'de.zeta';                 // Spiegel von kBrand aus lib/src/config/brand.dart
const MAX_ABRUFE_PRO_LAUF = 40;          // Kontingent 200/Stunde, bewusst weit darunter
const SEITENGROESSE = 100;               // Höchstwert der API
const SPRACHE = 'de';

const arg = Object.fromEntries(
  process.argv.slice(2)
    .filter((a) => a.startsWith('--'))
    .map((a) => a.slice(2).split('='))
);

const flavor = arg.flavor;
if (!flavor) {
  console.error('FEHLT: --flavor=<name>');
  process.exit(2);
}
const paketId = `${MARKE}.${flavor}`;

if (process.env.PLAY_CONSOLE_READY !== 'true') {
  console.log(
    'review-agent stillgelegt. PLAY_CONSOLE_READY ist nicht true.\n' +
    'Es fehlen: Play-Console-Konto (25 USD), eine in der Produktionsspur\n' +
    'veröffentlichte App und das Secret PLAY_SERVICE_ACCOUNT_JSON mit dem\n' +
    'Recht "Antworten auf Rezensionen verwalten".\n' +
    'Der Lauf endet ohne Fehler.'
  );
  process.exit(0);
}

const schluessel = process.env.PLAY_SERVICE_ACCOUNT_JSON;
if (!schluessel) {
  console.error('FEHLT: Secret PLAY_SERVICE_ACCOUNT_JSON');
  process.exit(1);
}

const auth = new google.auth.GoogleAuth({
  credentials: JSON.parse(schluessel),
  scopes: ['https://www.googleapis.com/auth/androidpublisher'],
});
const publisher = google.androidpublisher({ version: 'v3', auth });

const archivPfad = `ops/reviews/${flavor}.jsonl`;
mkdirSync(dirname(archivPfad), { recursive: true });

// Bekannte Rezensionen einlesen. Schlüssel ist reviewId, Wert der Zeitstempel
// der letzten bekannten Änderung — damit werden bearbeitete Rezensionen erkannt.
const bekannt = new Map();
if (existsSync(archivPfad)) {
  for (const zeile of readFileSync(archivPfad, 'utf8').split('\n')) {
    if (!zeile.trim()) continue;
    const e = JSON.parse(zeile);
    bekannt.set(e.reviewId, e.zuletztGeaendert ?? '');
  }
}

let token = undefined;
let abrufe = 0;
const neue = [];

do {
  if (abrufe >= MAX_ABRUFE_PRO_LAUF) {
    console.warn(`Kontingentbremse: ${MAX_ABRUFE_PRO_LAUF} Abrufe erreicht, Lauf beendet.`);
    break;
  }
  const antwort = await publisher.reviews.list({
    packageName: paketId,
    maxResults: SEITENGROESSE,
    translationLanguage: SPRACHE,
    token,
  });
  abrufe += 1;

  for (const r of antwort.data.reviews ?? []) {
    const k = r.comments?.[0]?.userComment;
    // Randbedingung 1: nur Rezensionen mit Text.
    if (!k?.text || !k.text.trim()) continue;

    const geaendert = k.lastModified
      ? new Date(Number(k.lastModified.seconds) * 1000).toISOString()
      : '';
    if (bekannt.get(r.reviewId) === geaendert) continue;

    const entwicklerAntwort = r.comments?.[1]?.developerComment?.text ?? null;

    neue.push({
      reviewId: r.reviewId,
      flavor,
      paketId,
      autor: r.authorName ?? null,
      sterne: k.starRating ?? null,
      text: k.text.trim(),
      sprache: k.reviewerLanguage ?? null,
      geraet: k.device ?? null,
      androidVersion: k.androidOsVersion ?? null,
      appVersionName: k.appVersionName ?? null,
      appVersionCode: k.appVersionCode ?? null,
      zuletztGeaendert: geaendert,
      beantwortet: entwicklerAntwort !== null,
      entwicklerAntwort,
      abgerufenAm: new Date().toISOString(),
    });
  }

  token = antwort.data.tokenPagination?.nextPageToken;
  if (token) await new Promise((r) => setTimeout(r, 1200)); // Kontingent schonen
} while (token);

for (const e of neue) {
  appendFileSync(archivPfad, JSON.stringify(e) + '\n');
}

// Entwürfe für alles, was Text hat und noch keine Antwort trägt.
mkdirSync(`ops/reviews/drafts/${flavor}`, { recursive: true });
let entwuerfe = 0;
for (const e of neue) {
  if (e.beantwortet) continue;
  const pfad = `ops/reviews/drafts/${flavor}/${e.reviewId}.md`;
  if (existsSync(pfad)) continue;
  writeFileSync(pfad, entwurfVorlage(e));
  entwuerfe += 1;
}

writeFileSync(`ops/reviews/${flavor}.status.json`, JSON.stringify({
  lauf: new Date().toISOString(),
  abrufe,
  neueRezensionen: neue.length,
  neueEntwuerfe: entwuerfe,
  archivGesamt: bekannt.size + neue.length,
  hinweis: 'Die API zeigt nur etwa 7 Tage. Fällt der Lauf länger aus, entsteht eine Lücke.',
}, null, 2) + '\n');

console.log(`OK  ${abrufe} Abrufe, ${neue.length} neue Rezensionen, ${entwuerfe} neue Entwürfe.`);

function entwurfVorlage(e) {
  return `---
reviewId: ${e.reviewId}
flavor: ${e.flavor}
sterne: ${e.sterne}
appVersion: ${e.appVersionName ?? 'unbekannt'}
geraet: ${e.geraet ?? 'unbekannt'}
freigegeben: false
---

## Rezension

> ${e.text.replace(/\n/g, '\n> ')}

## Antwortentwurf (höchstens 350 Zeichen)

<!-- Entwurf hier eintragen. Erst wenn freigegeben: true gesetzt ist UND die
     Repo-Variable REVIEW_AUTOREPLY auf true steht, wird gesendet.
     Eine zweite Antwort ersetzt die erste — es gibt nur einen Versuch. -->
`;
}
```

### Schritt 4 — Sendeskript, getrennt vom Abruf

Bewusst zwei Dateien: Abrufen ist harmlos, Senden ist öffentlich und
unwiderruflich. Das Sendeskript verlangt zwei unabhängige Freigaben.

```javascript
// ops/reviews/reply.mjs
// Sendet ausschließlich Entwürfe, die BEIDES erfüllen:
//   - freigegeben: true im Kopf der Entwurfsdatei
//   - Repo-Variable REVIEW_AUTOREPLY = true
// Aufruf: node ops/reviews/reply.mjs --flavor=onira
import { google } from 'googleapis';
import { readFileSync, readdirSync, existsSync, appendFileSync, unlinkSync } from 'node:fs';

const MARKE = 'de.zeta';
const MAX_ANTWORTEN_PRO_TAG = 2000;   // hartes Kontingent der API
const MAX_ANTWORTEN_PRO_LAUF = 50;    // eigene Bremse
const MAX_ZEICHEN = 350;

const arg = Object.fromEntries(
  process.argv.slice(2).filter((a) => a.startsWith('--')).map((a) => a.slice(2).split('='))
);
const flavor = arg.flavor;
if (!flavor) { console.error('FEHLT: --flavor=<name>'); process.exit(2); }

if (process.env.PLAY_CONSOLE_READY !== 'true') {
  console.log('review-agent stillgelegt: PLAY_CONSOLE_READY ist nicht true. Ende ohne Fehler.');
  process.exit(0);
}
if (process.env.REVIEW_AUTOREPLY !== 'true') {
  console.log('REVIEW_AUTOREPLY ist aus. Entwürfe bleiben liegen, es wird nichts gesendet.');
  process.exit(0);
}

const verzeichnis = `ops/reviews/drafts/${flavor}`;
if (!existsSync(verzeichnis)) { console.log('Keine Entwürfe.'); process.exit(0); }

const auth = new google.auth.GoogleAuth({
  credentials: JSON.parse(process.env.PLAY_SERVICE_ACCOUNT_JSON),
  scopes: ['https://www.googleapis.com/auth/androidpublisher'],
});
const publisher = google.androidpublisher({ version: 'v3', auth });

let gesendet = 0;
for (const datei of readdirSync(verzeichnis).filter((d) => d.endsWith('.md'))) {
  if (gesendet >= Math.min(MAX_ANTWORTEN_PRO_LAUF, MAX_ANTWORTEN_PRO_TAG)) break;

  const inhalt = readFileSync(`${verzeichnis}/${datei}`, 'utf8');
  if (!/^freigegeben:\s*true\s*$/m.test(inhalt)) continue;

  const reviewId = inhalt.match(/^reviewId:\s*(.+)$/m)?.[1]?.trim();
  const antwort = inhalt
    .split('## Antwortentwurf')[1]
    ?.replace(/\(höchstens 350 Zeichen\)/, '')
    .replace(/<!--[\s\S]*?-->/g, '')
    .trim();

  if (!reviewId || !antwort) { console.warn(`ÜBERSPRUNGEN: ${datei} unvollständig`); continue; }
  if (antwort.length > MAX_ZEICHEN) {
    console.error(`ABBRUCH: ${datei} hat ${antwort.length} Zeichen, erlaubt sind ${MAX_ZEICHEN}.`);
    process.exit(1);
  }

  await publisher.reviews.reply({
    packageName: `${MARKE}.${flavor}`,
    reviewId,
    requestBody: { replyText: antwort },
  });
  appendFileSync(`ops/reviews/${flavor}.replies.jsonl`,
    JSON.stringify({ reviewId, antwort, gesendetAm: new Date().toISOString() }) + '\n');
  unlinkSync(`${verzeichnis}/${datei}`);
  gesendet += 1;
  await new Promise((r) => setTimeout(r, 800));
}
console.log(`OK  ${gesendet} Antworten gesendet.`);
```

### Schritt 5 — Täglicher Lauf

```yaml
# .github/workflows/reviews.yml
name: reviews

on:
  schedule:
    - cron: '17 5 * * *'   # täglich 05:17 UTC — täglich ist Pflicht, siehe 7-Tage-Fenster
  workflow_dispatch:
    inputs:
      flavor:
        description: Flavor, leer lässt alle laufen
        required: false
        type: string

permissions:
  contents: write
  issues: write

jobs:
  abruf:
    name: Rezensionen abholen und archivieren
    runs-on: ubuntu-latest
    env:
      PLAY_CONSOLE_READY: ${{ vars.PLAY_CONSOLE_READY }}
      REVIEW_AUTOREPLY: ${{ vars.REVIEW_AUTOREPLY }}
      PLAY_SERVICE_ACCOUNT_JSON: ${{ secrets.PLAY_SERVICE_ACCOUNT_JSON }}
    steps:
      - uses: actions/checkout@v4

      - name: Schalter prüfen
        id: schalter
        run: |
          if [ "${{ vars.PLAY_CONSOLE_READY }}" != "true" ]; then
            echo "::notice title=review-agent stillgelegt::PLAY_CONSOLE_READY ist nicht true. Ohne Play-Konto gibt es keine Rezensionen. Lauf endet ohne Fehler."
            echo "weiter=false" >> "$GITHUB_OUTPUT"
          else
            echo "weiter=true" >> "$GITHUB_OUTPUT"
          fi

      - uses: actions/setup-node@v4
        if: steps.schalter.outputs.weiter == 'true'
        with: {node-version: '20'}

      - name: Abhängigkeiten
        if: steps.schalter.outputs.weiter == 'true'
        run: npm install --prefix ops/reviews

      - name: Abrufen
        if: steps.schalter.outputs.weiter == 'true'
        run: |
          set -e
          FLAVORS="${{ inputs.flavor }}"
          if [ -z "$FLAVORS" ]; then FLAVORS=$(ls apps); fi
          for f in $FLAVORS; do
            node ops/reviews/fetch_reviews.mjs --flavor="$f" || echo "Fehler bei $f, weiter"
          done

      - name: Antworten senden, falls freigegeben
        if: steps.schalter.outputs.weiter == 'true' && vars.REVIEW_AUTOREPLY == 'true'
        run: |
          FLAVORS="${{ inputs.flavor }}"
          if [ -z "$FLAVORS" ]; then FLAVORS=$(ls apps); fi
          for f in $FLAVORS; do node ops/reviews/reply.mjs --flavor="$f"; done

      - name: Archiv committen
        if: steps.schalter.outputs.weiter == 'true'
        run: |
          git config user.name "review-agent"
          git config user.email "actions@users.noreply.github.com"
          git add ops/reviews
          git diff --cached --quiet || git commit -m "chore(reviews): Archiv und Entwürfe aktualisiert"
          git push
```

### Schritt 6 — Entwürfe auf dem iPhone freigeben

Kein Sonderwerkzeug nötig. Die Entwürfe sind Markdown im Repo:

1. GitHub-App oder Safari öffnen, `ops/reviews/drafts/<flavor>/` ansehen.
2. Antworttext eintragen, `freigegeben: false` auf `true` ändern, committen.
3. Der nächste Lauf sendet — sofern `REVIEW_AUTOREPLY` auf `true` steht.

Solange `REVIEW_AUTOREPLY` aus ist, bleiben freigegebene Entwürfe liegen. Zwei
Schalter, zwei bewusste Entscheidungen.

### Schritt 7 — Archiv auswerten

```bash
# Verteilung der Sterne über das gesamte Archiv
jq -s 'group_by(.sterne) | map({sterne: .[0].sterne, anzahl: length})' ops/reviews/onira.jsonl

# Unbeantwortete Rezensionen mit einem oder zwei Sternen
jq -c 'select(.beantwortet == false and .sterne <= 2)' ops/reviews/onira.jsonl

# Welche App-Version welche Beschwerden erzeugt
jq -r 'select(.sterne <= 3) | "\(.appVersionName)\t\(.text[0:80])"' ops/reviews/onira.jsonl
```

## Abbruchkriterien

- `PLAY_CONSOLE_READY` ist nicht `true` → Meldung, Exit 0, Ende. Kein Fehler.
- `PLAY_SERVICE_ACCOUNT_JSON` fehlt, obwohl der Schalter an ist → Exit 1 mit
  Benennung des Secrets. Kein Ersatzweg, kein Abruf ohne Rechte.
- Der letzte erfolgreiche Lauf liegt mehr als sieben Tage zurück → melden, dass
  eine unwiederbringliche Archivlücke entstanden ist, und den Nutzer fragen, ob
  der Cron repariert werden soll. Nicht stillschweigend weitermachen.
- Ein Antwortentwurf überschreitet 350 Zeichen → Abbruch vor dem Senden. Kein
  automatisches Kürzen, weil eine Antwort nicht korrigierbar ist.
- Mehr als 40 Abrufe in einem Lauf nötig → abbrechen, Rest im nächsten Lauf.
  Das Kontingent von 200 Abrufen pro Stunde wird nie ausgereizt.
- Eine Rezension ist bereits beantwortet → kein neuer Entwurf. Eine zweite
  Antwort ersetzt die erste; das passiert nur auf ausdrückliche Anweisung.
- Der Entwurf enthält eine Zusage, die der Skill nicht prüfen kann („kommt im
  nächsten Update") → stoppen und den Nutzer entscheiden lassen.

## Fertig, wenn

- [ ] `ops/reviews/package.json` existiert und `npm install --prefix ops/reviews` läuft durch.
- [ ] `ops/reviews/fetch_reviews.mjs` existiert und endet bei ausgeschaltetem
      `PLAY_CONSOLE_READY` mit Exit 0 und der Stillgelegt-Meldung.
- [ ] `ops/reviews/reply.mjs` existiert und sendet nichts, solange `REVIEW_AUTOREPLY`
      aus ist oder `freigegeben: false` im Entwurf steht.
- [ ] `.github/workflows/reviews.yml` existiert mit täglichem Cron.
- [ ] Die Repo-Variable `REVIEW_AUTOREPLY` existiert und steht auf `false`.
- [ ] Im Skript stehen alle fünf Randbedingungen als Code, nicht nur als Kommentar:
      Textfilter, Produktionsspur, Abrufbremse, Antwortbremse, Archiv.
- [ ] Das Archivformat `ops/reviews/<flavor>.jsonl` ist eine Zeile je Rezension,
      dedupliziert über `reviewId` und `zuletztGeaendert`.
- [ ] Ein Probelauf `gh workflow run reviews.yml` ist grün und meldet
      „review-agent stillgelegt".
- [ ] Kein Dienstkonto-Schlüssel liegt im Repo.

## Beispielaufruf

```
Bau den Rezensions-Agenten für alle Apps. Täglicher Lauf, eigenes Archiv unter
ops/reviews, Antwortentwürfe nur vorlegen, nichts automatisch senden.
Wenn PLAY_CONSOLE_READY aus ist, brich sauber ab.
```

```
Hol die Rezensionen für onira und schreib mir Antwortentwürfe für alles unter
drei Sternen. Senden erst, wenn ich freigebe.
```
