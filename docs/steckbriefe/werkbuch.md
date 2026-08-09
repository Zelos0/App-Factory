# WERKBUCH — Baustellendokumentation mit Handschuhen

| | |
|---|---|
| Flavor | `werkbuch` |
| Kern | `capture` |
| Paket-ID | `de.zeta.werkbuch` |
| Store-Titel | WERKBUCH — Bautagebuch |
| Band | I |
| Umsetzungsstufe | 4 |
| Preisklasse | Beruflich |

## Zielgruppe

Handwerksbetriebe, Bauleitung, Sachverständige, Montage und Wartung. Kleinste Zielgruppe, höchste Zahlungsbereitschaft.

## Der Sprachmoment

Handschuhe an, Hände schmutzig, Lärm, kein Netz im Rohbau. Dokumentiert wird sonst abends aus dem Gedächtnis — oder gar nicht.

## App-spezifische Funktionen

- Projekte mit Bauabschnitten, jeder Eintrag automatisch zugeordnet
- Fotos und Videos direkt an das Sprachsegment, mit Zeitstempel und Standort
- Wetter und Temperatur automatisch je Tag protokolliert
- Anwesenheitserfassung per Ansage: wer war wann auf der Baustelle
- Mängelliste als eigener Auszug mit Frist und Status
- Übergabeprotokoll auf Knopfdruck aus den Einträgen eines Zeitraums
- Sehr großer Aufnahmeknopf, bedienbar mit Arbeitshandschuhen

## Interpreter — die zwanzig Prozent

- Gewerk- und Bauteilerkennung gegen eine anpassbare Betriebsliste
- Mengen und Maße: „drei Meter vierzig“, „zwölf Quadratmeter“
- Mangel-Erkennung: Formulierungen wie „Riss“, „fehlt“, „nicht ausgeführt“ werden als Mangel markiert
- Zuordnung zu Projekt, Bauabschnitt und beteiligter Firma

## Export

PDF-Bautagebuch mit Bildanhang, Mängelliste als eigenes PDF, ZIP-Archiv des Projekts

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | — |
| Pro — Einführung | 9,99 € |
| Pro — Zielpreis | 19,99 € |

## Konkurrenz

Bau-Software mit Nutzerlizenzen ab 20 € pro Monat und Person. Für Ein- bis Fünf-Mann-Betriebe deutlich überdimensioniert und zu teuer.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Beton | `#27272A` |
| Warnorange | `#F97316` |
| Kalkweiß | `#FAFAF9` |
| Staub | `#A8A29E` |

**Typografie.** Breite, sehr gut lesbare Grotesk. Keine feinen Linien — das Display wird bei Sonnenlicht und mit nassen Fingern gelesen.

**Leitmotiv.** Werkzeugkasten, nicht Büro. Kräftige Flächen, dicke Trennlinien, Warnfarbe als Funktionsträger. Bedienelemente mindestens 56 Punkt hoch.

**Startbildschirm.** Das aktive Projekt als breite Kachel oben. Darunter zwei Knöpfe: Eintrag und Mangel. Die Trennung dieser beiden ist die wichtigste Bedienentscheidung der App.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
