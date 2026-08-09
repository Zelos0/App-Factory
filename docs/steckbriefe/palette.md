# PALETTE — Farben aus der Welt holen

| | |
|---|---|
| Flavor | `palette` |
| Kern | `lens` |
| Paket-ID | `de.zeta.palette` |
| Store-Titel | PALETTE — Farben erfassen |
| Band | II |
| Umsetzungsstufe | 3 (Band II) |
| Preisklasse | Werkzeug |

## Zielgruppe

Gestalter, Handwerker, Renovierer, Bastler. Kleiner, aber sehr treuer und gut vernetzter Nutzerkreis.

## Der auslösende Moment

Eine Wandfarbe, ein Stoff, ein Sonnenuntergang — der Farbwert soll in ein Projekt. Ohne Werkzeug bleibt nur Schätzen.

## App-spezifische Funktionen

- Farbe live im Sucher aufnehmen oder aus vorhandenem Foto ziehen
- Paletten benennen, ordnen, um harmonische Ergänzungen erweitern
- **Kontrastprüfung** mit Bewertung — für Gestalter der eigentliche Grund
- Vergleich zweier Farben nebeneinander in voller Fläche
- Farbenfehlsichtigkeits-Simulation der Palette
- Export in Formate für Gestaltungs- und Entwicklungswerkzeuge

## Pipeline — die zwanzig Prozent

- Farbwertermittlung im Sucher mit Weißabgleichkorrektur
- Automatische Palettenbildung aus einem Bild über Häufung im Farbraum
- Umrechnung in HEX, RGB, HSL, CMYK und die gängigen Lacksysteme
- Kontrastprüfung zweier Farben nach Barrierefreiheitsstufen

## Export

PNG-Palettenblatt, CSS, JSON, ASE, PDF-Übersicht

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,49 € |
| Pro — Einführung | 1,99 € |
| Pro — Zielpreis | 3,99 € |

## Konkurrenz

Farbwerkzeuge mit Abo zwischen 3 und 8 € im Monat, oft mit Kontozwang für das Speichern eigener Paletten.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Beere | `#701038` |
| Rosé | `#FFF1F5` |
| Kontrast | `#FBBF24` |
| Neutral | `#18181B` |

**Typografie.** Sehr zurückhaltend, damit sie nicht mit den Farben konkurriert. Farbwerte in gleicher Ziffernbreite.

**Leitmotiv.** Farbfächer. Große, satte Flächen, Beschriftung klein am Rand. Die Farbe darf nie von einer Oberfläche gerahmt werden, die selbst Farbe hat.

**Startbildschirm.** Der Sucher mit einem Fadenkreuz, darunter der aktuelle Farbwert als breite Fläche. Gespeicherte Paletten als Streifen am unteren Rand.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
