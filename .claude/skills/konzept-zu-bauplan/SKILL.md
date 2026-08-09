---
name: konzept-zu-bauplan
description: Übersetzt einen der 26 Steckbriefe aus den Portfolio-Dokumenten (Band I und II) in einen konkreten Bauplan — Interpreter-Regeln, Datenfelder, Bildschirme, Exportvorlage, zwölf Testfälle. Auslösen mit "mach aus dem Steckbrief einen Bauplan", "übersetz Konzept Nummer 12", "Bauplan für <Name>", "was muss ich für <App> bauen". Die Ausgabe ist die Eingabe für app-derive.
---

# Steckbrief zu Bauplan

Der Übersetzer zwischen Prosa und Architektur. Er produziert **keinen Code** —
er produziert das Dokument, aus dem `app-derive` in unter zwei Stunden Code
macht.

## Wann dieser Skill greift

**Greift**, wenn eine App als Idee, Steckbrief oder Absatz vorliegt und die
fünf Fragen von `app-derive` noch nicht beantwortbar sind.

Konkrete Auslöser: „Nimm Steckbrief 12", „Was muss ich für Onira bauen?",
„Übersetz das Konzept in einen Bauplan", „Bereite App 7 vor".

**Greift nicht** bei:

| Wunsch | Zuständiger Skill |
|---|---|
| Der Bauplan liegt schon vor | `app-derive` |
| Kernfähigkeit fehlt (Aufnahme, Scan, Export) | `capture-core-build` / `lens-core-build` |
| Repo existiert nicht | `monorepo-bootstrap` |
| Store-Texte schreiben | `store-assets` |

**Die Abgrenzung, die zählt:** Dieser Skill entscheidet *was* gebaut wird.
`app-derive` entscheidet *wie*. Wenn hier eine Frage nach Dateipfaden oder
Klassennamen auftaucht, gehört sie nach drüben. Wenn dort eine Frage nach
Fachlogik auftaucht, gehört sie hierher.

## Voraussetzungen

| Was | Woher | Prüfung |
|---|---|---|
| Der Steckbrief als Text | Portfolio-Dokument Band I oder II, vom Nutzer eingefügt oder als Datei im Repo unter `docs/portfolio/` | Text liegt vor |
| `ARCHITEKTUR.md` im Repo | `monorepo-bootstrap` bzw. das Paket | `test -f ARCHITEKTUR.md` |
| Kenntnis, welche Kerne stehen | Repo | `ls packages/` |

Der Skill braucht **kein** funktionierendes Repo. Er kann auch laufen, bevor
irgendetwas gebaut ist — dann liefert er den Bauplan, und `monorepo-bootstrap`
kommt danach.

Fehlt der Steckbrief vollständig: Der Skill erfindet keinen. Er fragt nach dem
Text.

## Ablauf

### Schritt 1 — Steckbrief einlesen und zerlegen

Der Steckbrief wird in genau sieben Bestandteile zerlegt. Was nicht darin steht,
wird als **Lücke** notiert, nicht ausgefüllt.

```
1. Was der Nutzer tut            (die eine Handlung, die 90 % ausmacht)
2. Was dabei entsteht            (die Rohaufnahme: Sprache? Bild? beides?)
3. Was daraus werden soll        (die strukturierten Felder)
4. Was der Nutzer danach sieht   (Liste, Summe, Verlauf, Karte)
5. Wohin es geht                 (Empfänger des Exports)
6. Wie es sich anfühlt           (Farbwelt, Ton, Tempo)
7. Was es ausdrücklich NICHT ist (Abgrenzung zu den anderen 25)
```

Punkt 7 ist der wichtigste und wird am häufigsten übersprungen. Ohne ihn
wandern Fähigkeiten in die App, die in den Kern gehören.

### Schritt 2 — Kern bestimmen

| Rohaufnahme | Kern | Begründung |
|---|---|---|
| gesprochenes Wort | `capture` | Segmentkette aus Audio |
| Papier, Etikett, Bildschirmfoto, Barcode | `lens` | Segmentkette aus Bildern |
| beides in einem Eintrag | `both` | ein Eintrag, gemischte Segmente |

Bei `both` wird zusätzlich festgelegt, welcher Kern die **Startansicht**
besetzt. Es gibt keine zwei gleichberechtigten Startknöpfe — die Primäraktion
ist eine.

**Prüfung, die hier gezogen wird:** Wenn eine App weder Sprache noch Bild als
Rohaufnahme hat, gehört sie nicht in dieses Portfolio. Der Skill sagt das und
bricht ab, statt einen dritten Kern zu erfinden.

### Schritt 3 — Interpreter-Regeln ableiten

Das ist der Teil, an dem der Bauplan seinen Wert hat. Für jedes Feld wird
festgelegt:

| Spalte | Bedeutung |
|---|---|
| Feldname | technisch, englisch, snake_case-frei (Dart: lowerCamelCase) |
| Typ | `double` · `int` · `String` · `DateTime` · `List<String>` · `bool` |
| Pflicht | ja / nein — bestimmt, ob `confidence` sinkt, wenn es fehlt |
| Erkennungsregel | in Worten, so präzise, dass sie ohne Rückfrage in Dart übersetzbar ist |
| Was passiert bei Mehrdeutigkeit | erster Treffer · letzter Treffer · beide sammeln · Rohtext behalten |

Beispiel für eine ausgefüllte Zeile:

| Feld | Typ | Pflicht | Regel | Mehrdeutigkeit |
|---|---|---|---|---|
| `amount` | `double` | ja | Ziffernform `\d+[,.]\d{1,2}`, oder „<Zahl> euro <Zahl>", oder deutsches Zahlwort-Kompositum („zweiundzwanzig fünfzig" = 22,50) | erster Treffer |
| `merchant` | `String?` | nein | Wort nach „bei", „von", „im", „beim", erstes Substantiv, max. 30 Zeichen | erster Treffer |
| `occurredAt` | `DateTime` | ja | „heute" · „gestern" · „letzten <Wochentag>" · explizites Datum; sonst Aufnahmezeitpunkt | letzter Treffer |

**Drei Regeln für gute Erkennungsregeln:**

1. Sie beschreiben, was gesprochen wird — nicht, was geschrieben würde.
   Niemand sagt „zweiundzwanzig Euro fünfzig Cent". Alle sagen
   „zweiundzwanzig fünfzig".
2. Sie rechnen mit den Fehlern der Gratis-Engine. „zwo" statt „zwei", „ein"
   statt „eins", fehlende Satzzeichen, kleingeschriebene Eigennamen.
3. Sie sagen, was bei Nichterkennung passiert. Ein Feld, das still `null`
   bleibt, ist schlechter als eines, das den Rohtext behält und `confidence`
   senkt.

### Schritt 4 — Datenfelder gegen `Entry.data` prüfen

Alle Felder landen in `Entry.data` als JSON. Der Bauplan legt fest:

```
_interpreter: <flavor>        Kennung, immer vorhanden
_schema: 1                    Schema-Version, immer vorhanden
confidence: 0.0–1.0           immer vorhanden
raw: <Volltext>               immer vorhanden — die Fluchttür im Kleinen
<feld1>: …                    app-spezifisch
```

**Nicht verhandelbar:** `Entry` und `Segment` selbst werden nicht erweitert.
Braucht eine App ein Feld auf Segment-Ebene, wird es in `Entry.data` unter
einem Schlüssel je Segment-ID abgelegt — so macht es `lens_core` mit den
Textblöcken. Wer das Datenmodell ändern will, ändert es für alle 26 Apps, und
das ist eine Kernänderung nach `WF-02-WEITERE-APP.md`.

### Schritt 5 — Bildschirme festlegen

Genau vier, mehr braucht keine App:

| Bildschirm | Inhalt | Pflicht |
|---|---|---|
| Start | Primäraktion + Liste der letzten Einträge | ja |
| Detail | Segmentkette, Rohtext je Segment, interpretierte Felder, „Erweitern" | ja |
| Auswertung | aus Schritt 6 | ja |
| Einstellungen | Hell/Dunkel, Schriftgröße, **Fluchttür-Export**, Engine-Wahl | ja |

Ein fünfter Bildschirm ist ein Warnsignal. Der Bauplan notiert ihn ausdrücklich
als Ausnahme mit Begründung, oder er entfällt.

### Schritt 6 — Auswertung festlegen

Genau eine Hauptform, höchstens eine Nebenform:

| Form | Passt, wenn | Gruppierung |
|---|---|---|
| Summe | Zahlen, die sich addieren lassen | Tag · Woche · Monat · Jahr |
| Verlauf | dieselbe Größe über Zeit | Tag · Woche · Monat |
| Häufigkeitsliste | Kategorien statt Zahlen | absteigend nach Anzahl |
| Zeitachse | Ereignisse ohne Größe | chronologisch |
| Karte | Einträge mit Ort | räumlich |

Der Bauplan nennt Hauptform, Gruppierung und die **eine Zahl, die oben groß
steht**. Ohne diese Zahl ist die Auswertung eine Liste, kein Überblick.

### Schritt 7 — Exportvorlage je Empfänger

Vier Empfänger nach `ARCHITEKTUR.md` Abschnitt 7. Der Bauplan füllt für jeden
eine Zeile aus:

| Empfänger | Format | Was konkret hineingehört |
|---|---|---|
| Der Nutzer selbst, später | Markdown + YAML-Frontmatter | welche Felder ins Frontmatter, welche Wörter werden `[[Verweise]]` |
| Ein KI-Modell | Kontextbündel | welcher Schema-Kopf, welcher vorformulierte Auftrag |
| Ein Mensch mit Autorität | PDF | **wer genau** — Finanzamt, Vermieter, Arzt, Versicherung, Arbeitgeber; danach richtet sich die Gestaltung |
| Andere Software | CSV / JSON / GPX | welche Spalten in welcher Reihenfolge |

Die Fluchttür (vollständiges JSON + ZIP der Originale) steht nicht zur
Abstimmung. Sie wird immer erzeugt, ist immer kostenlos und immer in den
Einstellungen sichtbar.

**Die Frage, an der dieser Schritt hängt:** „Wer genau bekommt das PDF?"
Ein PDF für das Finanzamt sieht anders aus als eines für einen Arzt. Bleibt
die Frage offen, bleibt das PDF beliebig, und beliebige PDFs erzeugen
Rückfragen statt Erledigung.

### Schritt 8 — Zwölf Testfälle schreiben

Pflicht nach `TESTLEITER.md` Stufe 0. Der Bauplan liefert sie fertig, damit
`app-derive` sie nur noch einsetzt.

Die Zusammensetzung ist vorgeschrieben:

| Anzahl | Art |
|---|---|
| 4 | Normalfall — so spricht der Nutzer an guten Tagen |
| 3 | Erkennungsfehler der Gratis-Engine — „zwo", zusammengeschriebene Zahlen, fehlende Umlaute |
| 2 | unvollständig — ein Pflichtfeld fehlt, `confidence` muss sinken |
| 2 | Grenzfall — sehr große Zahl, sehr langer Text, Sonderzeichen |
| 1 | leer — der Interpreter darf nicht werfen |

Format je Fall:

```
Eingabe:  "zweiundzwanzig fünfzig bei Rewe"
Erwartet: amount=22.50  merchant="Rewe"  confidence=1.0
```

### Schritt 9 — Abgrenzung notieren

Aus Punkt 7 von Schritt 1. Der Bauplan schließt mit drei Sätzen:

```
Was diese App NICHT tut:   …
Wer das stattdessen tut:   <anderer Flavor> oder <Kern>
Was in den Kern gehört:    <konkret, falls beim Zerlegen etwas aufgefallen ist>
```

Die dritte Zeile ist der Kanal, über den das Portfolio besser wird. Wenn beim
Bauplan für App 9 auffällt, dass Apps 3, 6 und 9 dieselbe Datumserkennung
brauchen, gehört sie in `shared_base` — und das steht hier, bevor `app-derive`
sie zum dritten Mal in eine App schreibt.

### Schritt 10 — Bauplan ablegen

Datei: `docs/baupläne/<flavor>.md`

```markdown
# Bauplan — <Label> (`<flavor>`)

Steckbrief: Band <I|II>, Nummer <n>
Erstellt: <Datum>
Status: bereit für app-derive

## 1 — Kern
core: <capture|lens|both>
Startansicht: <capture|lens>
Begründung: <ein Satz>

## 2 — Interpreter-Regeln

| Feld | Typ | Pflicht | Regel | Mehrdeutigkeit |
|---|---|---|---|---|
| … | … | … | … | … |

Vertrauenswert: <welche Felder zählen, wie er berechnet wird>
Bei Nichterkennung: <was passiert>

## 3 — Datenfelder in Entry.data

```json
{
  "_interpreter": "<flavor>",
  "_schema": 1,
  "confidence": 0.0,
  "raw": "",
  "<feld>": null
}
```

Segment-bezogene Zusatzdaten: <Schlüssel in Entry.data, oder "keine">

## 4 — Bildschirme

| Bildschirm | Oben | Mitte | Primäraktion |
|---|---|---|---|
| Start | … | … | … |
| Detail | … | … | … |
| Auswertung | … | … | … |
| Einstellungen | … | … | Fluchttür-Export |

## 5 — Auswertung
Hauptform: <…>
Gruppierung: <…>
Die eine große Zahl: <…>
Nebenform: <… oder "keine">

## 6 — Export

| Empfänger | Format | Inhalt |
|---|---|---|
| Nutzer, später | Markdown + YAML | Frontmatter: … · Verweise: … |
| KI-Modell | Kontextbündel | Schema-Kopf: … · Auftrag: „…" |
| Mensch mit Autorität | PDF | Empfänger: <konkret> · Gestaltung: … |
| Andere Software | <CSV/JSON/GPX> | Spalten: … |
| **Fluchttür** | JSON + ZIP | vollständig, kostenlos, in den Einstellungen |

## 7 — Gestaltung
Primär: #<hex>   Sekundär: #<hex>   Fläche: #<hex>   Akzent: #<hex>
Überschrift: <Schriftfamilie>   Fließtext: <Schriftfamilie>
Startbildschirm-Aufbau: <ein Absatz>

## 8 — Zwölf Testfälle

| # | Art | Eingabe | Erwartet |
|---|---|---|---|
| 1 | normal | „…" | … |
| … | | | |
| 12 | leer | „" | alle Felder null, confidence 0 |

## 9 — Abgrenzung
Was diese App NICHT tut: …
Wer das stattdessen tut: …
Was in den Kern gehört: …

## 10 — Offene Punkte
- [ ] <alles, was der Steckbrief nicht hergab — vom Nutzer zu entscheiden,
      BEVOR app-derive läuft>
```

### Schritt 11 — Vollständigkeit prüfen

Der Skill geht die fünf Fragen von `app-derive` durch und prüft, ob der Bauplan
sie beantwortet:

```
Frage 1 Kern              -> Abschnitt 1   ✓/✗
Frage 2 Interpreter       -> Abschnitt 2+3 ✓/✗
Frage 3 Auswertung        -> Abschnitt 5   ✓/✗
Frage 4 Export            -> Abschnitt 6   ✓/✗
Frage 5 Gestaltung        -> Abschnitt 7   ✓/✗
```

Fünf Haken: der Bauplan geht an `app-derive`.
Weniger als fünf: die offenen Punkte aus Abschnitt 10 werden dem Nutzer als
Fragen vorgelegt — nummeriert, mit einem Vorschlag je Frage, den er annehmen
oder ersetzen kann. **Der Skill entscheidet nicht selbst.**

## Abbruchkriterien

Der Skill stoppt und fragt, statt zu raten, wenn:

1. Der Steckbrief fehlt oder nur aus einem Namen besteht. Ein Bauplan aus einem
   Namen ist geraten, und `app-derive` würde ihn ungeprüft in Code gießen.
2. Die Rohaufnahme weder Sprache noch Bild ist. Dann passt die App nicht zu den
   beiden Kernen, und es ist eine Portfolio-Entscheidung, keine Bauplan-Frage.
3. Der Empfänger des PDF-Exports offen bleibt. Ohne Empfänger keine Gestaltung.
4. Mehr als vier Bildschirme nötig scheinen. Erst prüfen, ob zwei
   zusammengehören; wenn nicht, ausdrücklich begründen lassen.
5. Der Interpreter Fähigkeiten braucht, die kein Kern liefert — Übersetzung auf
   dem Gerät, Ortsbestimmung, Netzzugriff. Das ist eine **Kernänderung** und
   läuft nach `WF-02-WEITERE-APP.md`, nicht nebenbei im Bauplan.
6. Weniger als zwölf Testfälle zusammenkommen, weil der Steckbrief zu dünn ist.
   Der Skill schreibt keine Fälle, die er sich ausdenkt — er fragt nach
   Beispielsätzen aus dem echten Sprachgebrauch des Nutzers.
7. Der Bauplan Felder verlangt, die eine Erweiterung von `Entry` oder `Segment`
   nötig machen. Das widerspricht `ARCHITEKTUR.md` Abschnitt 3.
8. Ein Feld ohne Regel bei Nichterkennung bleibt. Stilles `null` ist keine
   Entscheidung, sondern eine ausgelassene.

## Fertig, wenn

- [ ] `docs/baupläne/<flavor>.md` existiert
- [ ] Abschnitt 1 nennt Kern und, bei `both`, die Startansicht mit Begründung
- [ ] Abschnitt 2 enthält für **jedes** Feld: Typ, Pflicht, Erkennungsregel und
      Verhalten bei Mehrdeutigkeit
- [ ] Abschnitt 2 nennt ausdrücklich, was bei Nichterkennung passiert
- [ ] Abschnitt 3 enthält `_interpreter`, `_schema`, `confidence`, `raw`
- [ ] Abschnitt 3 erweitert weder `Entry` noch `Segment`
- [ ] Abschnitt 4 listet genau vier Bildschirme, oder begründet den fünften
- [ ] Abschnitt 4 nennt für die Einstellungen ausdrücklich die Fluchttür
- [ ] Abschnitt 5 nennt Hauptform, Gruppierung und die eine große Zahl
- [ ] Abschnitt 6 nennt für das PDF einen **konkreten** Empfänger, keine Rolle
      im Allgemeinen
- [ ] Abschnitt 7 nennt genau vier Farben und genau zwei Schriftfamilien
- [ ] Abschnitt 8 enthält **zwölf** Fälle in der vorgeschriebenen Mischung
      (4 normal, 3 Engine-Fehler, 2 unvollständig, 2 Grenzfall, 1 leer)
- [ ] Abschnitt 9 beantwortet alle drei Zeilen
- [ ] Abschnitt 10 ist leer, oder jede offene Zeile wurde dem Nutzer vorgelegt
- [ ] Die Prüfung aus Schritt 11 zeigt fünf Haken

## Beispielaufruf

```
Nimm Steckbrief 12 aus Band II — hier ist der Text: <…>
Mach daraus einen Bauplan nach ARCHITEKTUR.md und leg ihn unter
docs/baupläne/ ab. Frag mich, was der Steckbrief offenlässt.
```

```
Bauplan für onira. Der Steckbrief steht in docs/portfolio/band-1.md,
Abschnitt "Onira". Kern ist vermutlich capture — prüf das.
```

```
Was muss ich für prisma bauen? Übersetz das Konzept in Interpreter-Regeln,
Datenfelder, Bildschirme, Export und zwölf Testfälle.
```

Weitere Formulierungen, die diesen Skill auslösen:

```
Mach aus dem Steckbrief einen Bauplan.
Bereite App 7 vor.
Übersetz das Konzept.
```
