# Bauplan — Vox (`vox`)

Steckbrief: Band I, Nummer 1 — `docs/steckbriefe/vox.md`
Erstellt: 2026-08-11
Status: bereit für app-derive

> **Ein Widerspruch, vorab aufgelöst.** `WF-01-ERSTE-APP.md` nennt im
> Beispielaufruf für Tag 4 „Sprachnotizen mit Ausgabenerkennung" und den Satz
> „zweiundzwanzig fünfzig bei Rewe". Das ist der Interpreter von **KASSA**,
> nicht von VOX. Der Steckbrief ist die verbindliche Quelle und sagt
> ausdrücklich: *Kein Interpreter — Text bleibt Text.* Dieser Bauplan folgt dem
> Steckbrief. Der Betrags-Parser aus `app-derive` Schritt 5 ist Vorlagencode und
> wird hier nicht übernommen; er kommt bei KASSA zum Einsatz.

## 1 — Kern

```
core: capture
Startansicht: capture
```

Begründung: Rohaufnahme ist ausschließlich gesprochenes Wort, die Segmentkette
entsteht aus Audio.

## 2 — Interpreter-Regeln

VOX extrahiert keine Sachfelder. Sein Interpreter ordnet den Text, statt ihn zu
zerlegen: Titel und Schlagworte, sonst nichts.

| Feld | Typ | Pflicht | Regel | Mehrdeutigkeit |
|---|---|---|---|---|
| `title` | `String?` | ja | Erster Satz des Volltextes. Satzende ist `.`, `!`, `?` — die bleiben stehen — oder `:` und Zeilenumbruch, die fallen weg. Ein **erkannter Satz** ist eine Einheit und wird erst ab 120 Zeichen gekürzt. Ohne jedes Satzzeichen gilt die harte Grenze von 60 Zeichen, an der letzten Wortgrenze abgeschnitten, mit `…` beendet. Führende Füllwörter (`also`, `ähm`, `ähem`, `öhm`, `äh`, `hm`, `hmm`, `so`, `ja`, `okay`, `ok`) werden vorab entfernt — die Gratis-Engine schreibt sie mit. | erster Treffer |
| `keywords` | `List<String>` | nein | Häufigkeitsanalyse über den Volltext. Wörter ab 4 Zeichen, ohne Stoppwörter, Zählung auf kleingeschriebener Form. Aufgenommen wird, was **mindestens zweimal** vorkommt; höchstens fünf, absteigend nach Anzahl, bei Gleichstand alphabetisch (damit das Ergebnis reproduzierbar bleibt). Ausgabe in der Schreibweise des ersten Vorkommens. | alle sammeln |
| `wordCount` | `int` | ja | Anzahl der durch Leerraum getrennten Wortmarken im Volltext. | — |
| `charCount` | `int` | ja | Zeichenanzahl des Volltextes, ungetrimmt gemessen nach `trim()`. | — |

**Vertrauenswert.** Zwei Anteile, je 0,5:

```
title != null && title.isNotEmpty   -> +0.5
keywords.isNotEmpty                 -> +0.5
```

Ein Text ohne wiederkehrendes Wort ist kein Fehler, sondern ein kurzer Text.
Deshalb liegt `confidence` dort bei 0,5 und nicht bei 0. Erst der leere Text
ergibt 0.

**Bei Nichterkennung.** `raw` trägt in jedem Fall den vollständigen Text. Ein
Feld bleibt eher `null`, als dass es geraten wird — VOX zeigt Rohtext, nicht
Vermutungen. Unter `confidence < 0.5` blendet die Detailansicht den
Felderblock aus und zeigt nur das Transkript.

## 3 — Datenfelder in Entry.data

```json
{
  "_interpreter": "vox",
  "_schema": 1,
  "confidence": 0.0,
  "raw": "",
  "title": null,
  "keywords": [],
  "wordCount": 0,
  "charCount": 0
}
```

Segment-bezogene Zusatzdaten: keine. Die Engine je Segment steht in
`Segment.engine`, der Text in `Segment.transcript` — das Datenmodell trägt das
bereits, `Entry.data` muss es nicht doppeln.

## 4 — Bildschirme

| Bildschirm | Oben | Mitte | Primäraktion |
|---|---|---|---|
| Start | nichts — Leerfläche | die letzten Einträge als flache Zeilen ohne Rahmen | runder Aufnahmeknopf in Bernstein, unten mittig |
| Detail | Titel und Datum | Segmentkette: je Segment Transkript, Zeit, Engine | „Erweitern" — hängt ein Segment an |
| Auswertung | die eine große Zahl: **gesprochene Wörter gesamt** | Verlauf je Woche als Balken, darunter die häufigsten Schlagworte | keine |
| Einstellungen | Hell/Dunkel, Schriftgröße | Engine-Wahl, Werbeeinwilligung | **Fluchttür-Export** |

Kein fünfter Bildschirm. Suche sitzt als Feld im Startbildschirm, nicht als
eigene Seite — sie ist eine Filterung der Liste, kein Ort.

## 5 — Auswertung

```
Hauptform:            Verlauf über Zeit
Gruppierung:          Woche
Die eine große Zahl:  gesprochene Wörter gesamt
Nebenform:            Häufigkeitsliste der Schlagworte über alle Einträge
```

Begründung: VOX hat keine Beträge, die sich addieren. Was sich addiert, ist
gesprochener Umfang — und genau das ist der Beweis des Versprechens
„Sprechen ist schneller als Tippen". Die Zahl oben ist deshalb keine Statistik-
Spielerei, sondern das Verkaufsargument in Zahlenform.

## 6 — Export

| Empfänger | Format | Inhalt |
|---|---|---|
| Nutzer, später | Markdown + YAML | Frontmatter: `id`, `typ`, `erstellt`, `titel`, `schlagworte`, `woerter` · Verweise: jedes Schlagwort als `[[Schlagwort]]` |
| KI-Modell | Kontextbündel | Schema-Kopf: `title`, `keywords`, `wordCount`, `segments` · Auftrag: „Fasse die Notizen thematisch zusammen und nenne offene Punkte, die noch nicht zu Ende gedacht sind." |
| Mensch mit Autorität | PDF | Empfänger: **niemand mit Autorität** — VOX ist eine private Notiz-App. Das PDF ist ein Lesedokument für den Nutzer selbst: Titel, Datum, Transkript in Serifenschrift, keine Tabelle. `PdfRecipient(name: 'Eigenes Archiv', columns: [])`. |
| Andere Software | TXT und JSON | TXT: reiner Volltext, ein Eintrag je Datei. JSON: Zeitstempel je Segment — Spalten `id`, `erstellt`, `titel`, `woerter`, `schlagworte`, `text` |
| **Fluchttür** | JSON + ZIP | vollständig, kostenlos, in den Einstellungen |

Der Steckbrief nennt zusätzlich „ZIP mit Originalaudio" — das ist genau die
Fluchttür aus `shared_base/export/vault_export.dart`, kein eigener Export.

## 7 — Gestaltung

```
Primär: #D97706   Sekundär: #78716C   Fläche: #F5F2ED   Akzent: #1C1917
Überschrift: schmale Serifenschrift
Fließtext:   neutrale Grotesk
```

Rollenzuordnung gegen den Steckbrief: Bernstein `#D97706` ist Primär, weil der
Aufnahme-Knopf der einzige farbige Punkt ist. Graphit `#1C1917` ist Akzent und
zugleich Textfarbe, Papier `#F5F2ED` die Fläche, Stein `#78716C` das
Sekundäre für Datumszeilen und Beschriftungen.

**Startbildschirm-Aufbau.** Oben nichts als das Suchfeld, flach, ohne Rahmen.
Darunter Leerfläche. Die letzten Einträge stehen als flache Zeilen ohne Rahmen
und ohne Trennlinien, Titel in der Serifenschrift, Datum darunter in Stein.
Unten mittig der runde Aufnahmeknopf in Bernstein, mindestens 56 dp,
16 dp über der Bannerfläche. Kein Willkommenstext, keine Tour, keine
Kontoabfrage. Transkripte werden in 1,6-fachem Zeilenabstand gesetzt.

## 8 — Zwölf Testfälle

| # | Art | Eingabe | Erwartet |
|---|---|---|---|
| 1 | normal | „Ich muss morgen den Vertrag prüfen. Der Vertrag läuft im März aus." | title=„Ich muss morgen den Vertrag prüfen." · keywords enthält „vertrag" · confidence=1.0 |
| 2 | normal | „Idee für die App: Die App soll offline laufen. Offline ist das Argument." | title=„Idee für die App" · keywords enthält „offline" · confidence=1.0 |
| 3 | normal | „Einkaufen nicht vergessen. Einkaufen am Freitag." | title=„Einkaufen nicht vergessen." · keywords enthält „einkaufen" |
| 4 | normal | „Der Termin beim Steuerberater ist verschoben worden auf nächste Woche." | title = ganzer Satz · wordCount=10 |
| 5 | Engine-Fehler | „also ähm ich wollte sagen dass das Projekt Projekt fertig ist" | Füllwörter am Anfang entfernt, title beginnt mit „ich wollte" · keywords enthält „projekt" |
| 6 | Engine-Fehler | „hm die besprechung war gut die besprechung war lang" (keine Satzzeichen, klein) | title = erste 60 Zeichen ab „die besprechung" · keywords enthält „besprechung" |
| 7 | Engine-Fehler | „Muss noch die Rueckmeldung schreiben. Rueckmeldung bis Montag." | keywords enthält „rueckmeldung" (kein Umlaut, wird nicht korrigiert) |
| 8 | unvollständig | „Notiz" | title=„Notiz" · keywords leer · confidence=0.5 |
| 9 | unvollständig | „ähm" | Füllwort entfernt → title=null · confidence=0.0 |
| 10 | Grenzfall | 900 Wörter am Stück ohne Satzzeichen | title = 60 Zeichen + „…" · wordCount=900 · wirft nicht |
| 11 | Grenzfall | „§§ 1,2,3 — *** ###" | title = Rohtext · keywords leer · wirft nicht |
| 12 | leer | „" | title=null · keywords leer · wordCount=0 · confidence=0.0 |

## 9 — Abgrenzung

```
Was diese App NICHT tut:  Sie erkennt keine Beträge, keine Händler, keine
                          Termine, keine Symbole, keine Mengen. Sie ordnet
                          Text, sie deutet ihn nicht.
Wer das stattdessen tut:  KASSA (Beträge, Händler) · RITUS (Mengen, Zeiten)
                          ONIRA (Symbole) · ANAMNESE (Körper, Intensität)
Was in den Kern gehört:   Satzzerlegung, Füllwort-Filter, deutsche Stoppwort-
                          liste und Häufigkeitsanalyse werden von LITERA,
                          ARCHIV und ONIRA ebenfalls gebraucht. Sie stehen
                          heute bewusst in apps/vox/lib/src/vox_interpreter.dart
                          und wandern als TextStats nach shared_base/text/,
                          SOBALD die zweite App sie anfordert — nicht früher,
                          weil ein Kern mit einem Nutzer kein Kern ist.
```

## 10 — Offene Punkte

Der Steckbrief nennt drei. Vorschlag je Punkt eingetragen; der Nutzer bestätigt
oder ersetzt.

- [x] **Zwölf Beispielsätze** — in Abschnitt 8 geschrieben.
- [x] **Feldschema für `Entry.data`** — Abschnitt 3.
- [ ] **Gratis gegen Pro.** Vorschlag, an die Bände gebunden: Aufnehmen,
      Transkribieren, Suchen, alle vier Exporte und die Fluchttür bleiben
      **immer kostenlos**. Zur Pro-Stufe gehören ausschließlich
      Bequemlichkeitsfunktionen: „Präzision prüfen" (Zweit-Engine im
      Vergleich), Abspielgeschwindigkeit außerhalb 1,0×, Startbildschirm-
      Widget, Schnelleinstellungen-Kachel, automatische Stille-Erkennung.
      Ordner und Schlagworte bleiben gratis — sie sind Ordnung, kein Luxus.
      **Zu bestätigen, bevor `monetize-modul` Kaufpunkte setzt.**

## 11 — Vollständigkeitsprüfung

```
Frage 1 Kern         -> Abschnitt 1   ✓
Frage 2 Interpreter  -> Abschnitt 2+3 ✓
Frage 3 Auswertung   -> Abschnitt 5   ✓
Frage 4 Export       -> Abschnitt 6   ✓
Frage 5 Gestaltung   -> Abschnitt 7   ✓
```

Fünf Haken. Der Bauplan geht an `app-derive`. Der offene Punkt aus Abschnitt 10
betrifft die Monetarisierung, nicht den Bau — er blockiert `app-derive` nicht,
wohl aber das Setzen der Kaufpunkte.
