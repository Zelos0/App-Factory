# GARAGE — Werkstattbuch fürs eigene Fahrzeug

| | |
|---|---|
| Flavor | `garage` |
| Kern | `capture` |
| Paket-ID | `de.zeta.garage` |
| Store-Titel | GARAGE — Werkstattbuch |
| Band | II |
| Umsetzungsstufe | einschiebbar |
| Preisklasse | Consumer |

## Zielgruppe

Selbstschrauber, Oldtimer-Halter, Motorradfahrer, Wohnmobilbesitzer. Kleine, sehr treue Zielgruppe mit hoher Zahlungsbereitschaft für Nischen-Werkzeug.

## Der auslösende Moment

Hände ölig, unter dem Wagen, Werkzeug in der Hand. Das Wartungsheft liegt im Handschuhfach und bleibt leer — bis zum Verkauf, wo die Lücke bares Geld kostet.

## App-spezifische Funktionen

- Mehrere Fahrzeuge mit eigenem Verlauf und eigenem Kilometerstand
- Fällige Arbeiten aus dem Intervall vorhergesagt, mit Vorlauf-Erinnerung
- Belegfoto und Teilenummer je Eintrag
- Kostenübersicht je Fahrzeug und Jahr
- **Verkaufsmappe:** PDF-Scheckheft aus dem gesamten Verlauf — das eigentliche Kaufargument
- TÜV- und Versicherungstermine mitgeführt
- Verbrauchsberechnung aus getankten Mengen

## Interpreter — die zwanzig Prozent

- Kilometerstand, Bauteil und Kosten aus dem gesprochenen Satz
- Erkennung wiederkehrender Arbeiten und automatische Intervallberechnung
- Teile- und Werkstattnamen über eine lernende lokale Liste
- Trennung von Wartung, Reparatur und Umbau

## Export

PDF-Scheckheft für den Verkauf, CSV der Kosten, ZIP mit allen Belegfotos

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,49 € |
| Pro — Einführung | 2,49 € |
| Pro — Zielpreis | 4,99 € |

## Konkurrenz

Wartungs-Apps mit Abo zwischen 3 und 8 € im Monat, meist mit Kontozwang. Der Verkaufswert eines lückenlosen Scheckhefts liegt bei mehreren hundert Euro — das Missverhältnis ist absurd.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Motorenöl | `#231F1D` |
| Rost | `#B45309` |
| Werkbank | `#E7E5E4` |
| Prüfblau | `#0EA5E9` |

**Typografie.** Technische Grotesk, Zahlen in gleicher Ziffernbreite. Kilometerstände sind die wichtigste Zahl der App und werden entsprechend groß gesetzt.

**Leitmotiv.** Werkstatthandbuch der siebziger Jahre. Gedeckte Töne, technische Zeichnung als Andeutung, keine Hochglanz-Optik.

**Startbildschirm.** Das aktive Fahrzeug als breite Kachel mit Kilometerstand. Darunter die nächste fällige Arbeit. Aufnahmeknopf unten rechts.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
