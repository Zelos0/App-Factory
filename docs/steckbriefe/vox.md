# VOX — Sprachnotizen ohne Umwege

| | |
|---|---|
| Flavor | `vox` |
| Kern | `capture` |
| Paket-ID | `de.zeta.vox` |
| Store-Titel | VOX — Sprachnotizen offline |
| Band | I |
| Umsetzungsstufe | 1 |
| Preisklasse | Consumer |

## Zielgruppe

Alle, die Gedanken schneller festhalten wollen, als sie tippen können — Selbständige, Studierende, Kreative, Vielredner.

## Der Sprachmoment

Der Gedanke ist da und verschwindet in zwanzig Sekunden wieder. Tippen dauert länger als der Gedanke lebt.

## App-spezifische Funktionen

- **Präzision prüfen:** dasselbe Audio mit beiden Engines transkribieren, Unterschiede farbig markiert im Vergleich
- Ordner und Schlagworte, frei kombinierbar
- Segmente einzeln verschieben, löschen, neu transkribieren
- Abspielgeschwindigkeit 0,5× bis 2,5×
- Widget auf dem Startbildschirm: ein Tipp startet die Aufnahme
- Schnellaufnahme über die Schnelleinstellungen-Kachel, auch bei gesperrtem Bildschirm
- Automatische Stille-Erkennung beendet die Aufnahme nach frei wählbarer Pause

## Interpreter — die zwanzig Prozent

- Kein Interpreter — Text bleibt Text
- Automatische Titelbildung aus dem ersten Satz
- Schlagwort-Erkennung über Häufigkeitsanalyse

## Export

Markdown, TXT, PDF, JSON mit Zeitstempeln je Segment, ZIP mit Originalaudio

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,49 € |
| Pro — Einführung | 2,49 € |
| Pro — Zielpreis | 4,99 € |

## Konkurrenz

Otter (~17 €/Monat), Notta, Rev, HappyScribe — alle Cloud, alle Abo. Kostenlose Diktiergeräte ohne brauchbare Transkription.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Graphit | `#1C1917` |
| Papier | `#F5F2ED` |
| Bernstein | `#D97706` |
| Stein | `#78716C` |

**Typografie.** Überschriften in einer schmalen Serifenschrift, Fließtext in einer neutralen Grotesk. Transkripte in einer Schrift mit hoher x-Höhe, Zeilenabstand 1,6.

**Leitmotiv.** Papier und Tinte. Ruhig, dokumentarisch, kein Verspieltes. Der Aufnahme-Knopf ist der einzige farbige Punkt auf dem Startbildschirm.

**Startbildschirm.** Leere Fläche, unten mittig ein großer runder Knopf in Bernstein. Darüber die letzten drei Einträge als flache Zeilen ohne Rahmen. Kein Willkommenstext, keine Tour.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
