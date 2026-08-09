# NIDO — Das erste Jahr mit einer freien Hand

| | |
|---|---|
| Flavor | `nido` |
| Kern | `capture` |
| Paket-ID | `de.zeta.nido` |
| Store-Titel | NIDO — Babytagebuch |
| Band | I |
| Umsetzungsstufe | 5 |
| Preisklasse | Consumer |

## Zielgruppe

Eltern im ersten bis zweiten Lebensjahr. Extrem hohe Nutzungsfrequenz über einen begrenzten, aber intensiven Zeitraum.

## Der Sprachmoment

Drei Uhr nachts, ein Arm hält das Kind, der andere die Flasche. Es gibt keine freie Hand und kein Licht.

## App-spezifische Funktionen

- Nachtmodus in gedämpftem Rot, Knopf über die halbe Bildschirmbreite
- Stillseiten-Wechsel wird mitgezählt und erinnert
- Schlafmuster als Tagesband über Wochen sichtbar
- Meilenstein-Buch: die Sprachaufnahme bleibt erhalten — die eigene Stimme aus dem ersten Jahr
- Zwei Geräte, ein Kind: Abgleich über Datei, ohne Cloud
- Wachstumskurven manuell eintragbar, ohne Bewertung
- Sprachaufnahmen des Kindes als eigene Kategorie

## Interpreter — die zwanzig Prozent

- Erkennung von Mahlzeit, Menge, Seite, Schlaf, Wickeln aus der Ansage
- Dauerangaben: „zwanzig Minuten links“
- Meilenstein-Erkennung: erstes Lachen, erster Zahn, erstes Wort
- Automatische Zuordnung zum richtigen Kind bei mehreren Profilen

## Export

PDF-Jahresbuch mit Zeitachse, CSV für die Vorsorgeuntersuchung, ZIP mit allen Audios

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,49 € |
| Pro — Einführung | 2,49 € |
| Pro — Zielpreis | 4,99 € |

## Konkurrenz

Baby-Tracker mit Abo zwischen 4 und 10 € im Monat, meist mit Cloud-Konto und Werbung für Babyprodukte.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Milchweiß | `#FFFBF5` |
| Altrosa | `#9D4E6C` |
| Dämmerblau | `#8DA9C4` |
| Tinte | `#44403C` |

**Typografie.** Weich, rund, sehr gut lesbar bei minimaler Helligkeit. Ziffern groß, weil im Halbschlaf gelesen.

**Leitmotiv.** Stoff und Papier, nicht Kunststoff. Gedämpfte Farben, keine grellen Pastelltöne, keine Comic-Figuren. Ein Tagebuch, kein Spielzeug.

**Startbildschirm.** Vier große Kacheln: Mahlzeit, Schlaf, Wickeln, Notiz. Jede startet direkt die Aufnahme mit vorbelegter Kategorie. Kein Menü davor.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
