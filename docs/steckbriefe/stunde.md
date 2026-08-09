# STUNDE — Zeiterfassung im Vorbeigehen

| | |
|---|---|
| Flavor | `stunde` |
| Kern | `capture` |
| Paket-ID | `de.zeta.stunde` |
| Store-Titel | STUNDE — Zeiterfassung per Sprache |
| Band | II |
| Umsetzungsstufe | einschiebbar |
| Preisklasse | Semi-Pro |

## Zielgruppe

Selbständige, Freiberufler, kleine Agenturen, alle die nach Stunden abrechnen und die Erfassung regelmäßig aufschieben.

## Der auslösende Moment

Beim Aufstehen vom Schreibtisch, beim Wechsel zwischen Kunden. Wer die Zeiterfassung auf den Abend verschiebt, schätzt — und schätzt systematisch zu niedrig.

## App-spezifische Funktionen

- Laufende Uhr oder nachträgliche Ansage — beide Wege gleichwertig
- Stundensätze je Kunde und je Tätigkeit
- Monatsauswertung nach Kunde, Projekt und abrechenbarem Anteil
- **Rechnungsanhang als PDF** mit Einzelnachweis — die Position, über die Kunden sonst diskutieren
- Nicht abrechenbare Zeit getrennt erfasst und sichtbar gemacht
- Budgetwarnung bei Festpreisprojekten
- Pausen automatisch abgezogen, konfigurierbar

## Interpreter — die zwanzig Prozent

- Dauer aus gesprochener Angabe: „zwei Stunden zwanzig“, „von neun bis halb zwölf“
- Kunden- und Projektzuordnung über lernende Liste
- Tätigkeitsart aus dem Satz, frei konfigurierbar
- Nachträgliche Erfassung mit korrekter Datierung

## Export

PDF-Stundennachweis, CSV für die Buchhaltung, JSON für Rechnungsprogramme

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,99 € |
| Pro — Einführung | 4,99 € |
| Pro — Zielpreis | 9,99 € |

## Konkurrenz

Zeiterfassungs-Werkzeuge mit Abo zwischen 8 und 20 € pro Nutzer und Monat. Für Einzelkämpfer ist das teurer als der Nutzen.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Tiefblau | `#152D4A` |
| Papier | `#FAFAF9` |
| Abrechenbar | `#22C55E` |
| Neutral | `#94A3B8` |

**Typografie.** Zahlen dominieren. Stunden und Beträge in gleicher Ziffernbreite, Beschriftungen deutlich zurückgenommen.

**Leitmotiv.** Kontoauszug. Nüchtern, spaltenorientiert, hohe Informationsdichte ohne Gedränge.

**Startbildschirm.** Die heutige Summe als große Zahl. Darunter die Einträge des Tages als Zeilen. Ein Knopf für laufende Uhr, einer für Ansage.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
