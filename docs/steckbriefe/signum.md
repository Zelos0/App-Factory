# SIGNUM — Ausfüllen und unterschreiben, ohne Drucker

| | |
|---|---|
| Flavor | `signum` |
| Kern | `lens` |
| Paket-ID | `de.zeta.signum` |
| Store-Titel | SIGNUM — PDF ausfüllen & signieren |
| Band | II |
| Umsetzungsstufe | 4 (Band II) |
| Preisklasse | Werkzeug |

## Zielgruppe

Alle mit gelegentlichem Formularverkehr. Besonders stark bei Menschen ohne Drucker zu Hause — also den meisten unter vierzig.

## Der auslösende Moment

Ein PDF kommt per Mail, muss unterschrieben zurück. Die übliche Kette ist drucken, unterschreiben, scannen, senden — und scheitert am fehlenden Drucker.

## App-spezifische Funktionen

- Textfelder, Kreuze, Datum und Initialen frei setzbar
- Unterschrift per Finger oder Stift zeichnen, Hintergrund automatisch entfernt
- Mehrere gespeicherte Unterschriften und Kürzel
- Gescanntes Papierformular wird zum ausfüllbaren Dokument
- **Alles bleibt auf dem Gerät** — kein Upload von Verträgen an Dritte
- Direkt aus der Mail-App öffnen und ausgefüllt zurückgeben
- Häufig genutzte Angaben als Bausteine gespeichert

## Pipeline — die zwanzig Prozent

- Erkennung vorhandener Formularfelder im PDF
- Erkennung von Linien und Kästchen in gescannten Formularen als Eingabepunkte
- Unterschrift einmal erfassen, freigestellt und wiederverwendbar
- Automatische Textgrößenanpassung an das Feld

## Export

PDF mit eingebetteten Eingaben, flaches PDF, PNG je Seite

## Risiko / Auflage

Keine Aussagen zu qualifizierten elektronischen Signaturen. Die App erzeugt eine einfache Unterschrift im Dokument — das ist für den Alltag ausreichend, aber rechtlich nicht dasselbe.

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,99 € |
| Pro — Einführung | 2,99 € |
| Pro — Zielpreis | 5,99 € |

## Konkurrenz

Die bekannten Anbieter verlangen Abos zwischen 12 und 25 € im Monat und laden das Dokument auf ihre Server. Für zwei Formulare im Jahr ist das absurd.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Tinte | `#1C1917` |
| Formular | `#FFFDF7` |
| Feld | `#2563EB` |
| Hilfslinie | `#78716C` |

**Typografie.** Die eingesetzte Schrift muss glaubwürdig wie eine Formulareintragung wirken — schmale Grotesk, keine Auffälligkeiten.

**Leitmotiv.** Schreibtisch. Das Dokument liegt flach, Werkzeuge am Rand. Keine Werkzeugleiste verdeckt das Blatt.

**Startbildschirm.** Zuletzt bearbeitete Dokumente als Liste. Ein Knopf zum Öffnen, einer zum Fotografieren eines Papierformulars.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
