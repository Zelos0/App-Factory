# LITERA — Text aus allem herausholen

| | |
|---|---|
| Flavor | `litera` |
| Kern | `lens` |
| Paket-ID | `de.zeta.litera` |
| Store-Titel | LITERA — Texterkennung offline |
| Band | II |
| Umsetzungsstufe | 3 (Band II) |
| Preisklasse | Werkzeug |

## Zielgruppe

Studierende, Büroarbeit, alle die Text aus Büchern, Schildern, Bildschirmen oder Formularen übernehmen wollen.

## Der auslösende Moment

Text existiert auf Papier oder auf einem fremden Bildschirm und soll in eine Datei. Abtippen ist die Alternative — und dauert zwanzigmal so lange.

## App-spezifische Funktionen

- Kein Zeichenlimit, kein Seitenkontingent, kein Serverupload
- Auswahlrahmen: nur den gewünschten Ausschnitt erkennen
- Direkt in die Zwischenablage, ein Tipp
- Stapelmodus für ganze Kapitel, Ergebnis als eine Textdatei
- Erkannter Text bleibt im Verlauf, durchsuchbar
- Vorlesefunktion des erkannten Textes
- Tabellen als CSV statt als Fließtext

## Pipeline — die zwanzig Prozent

- Texterkennung über ML Kit auf dem Gerät, lateinische und weitere Schriften
- Absatz- und Spaltenerkennung — mehrspaltiger Text bleibt lesbar
- Erkennung von Tabellenstruktur als eigener Modus
- Sprach- und Schriftrichtungserkennung automatisch

## Export

TXT, Markdown, CSV bei Tabellen, DOCX

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,49 € |
| Pro — Einführung | 1,99 € |
| Pro — Zielpreis | 3,99 € |

## Konkurrenz

OCR-Apps mit Zeichen- oder Seitenkontingenten und Abos zwischen 4 und 12 € im Monat. Fast alle laden das Bild auf einen Server hoch.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Tintenblau | `#2E2A8A` |
| Pergament | `#FEFCE8` |
| Auswahl | `#F59E0B` |
| Nacht | `#1E1B4B` |

**Typografie.** Der erkannte Text wird in einer sehr gut lesbaren Schrift gesetzt, deutlich größer als die Bedienelemente — er ist das Produkt.

**Leitmotiv.** Lesegerät. Kamerabild oben, erkannter Text unten, klare Teilung. Keine Verzierung.

**Startbildschirm.** Kamera oben, leeres Textfeld unten. Auslöser dazwischen. Der Verlauf ist ein Wisch nach oben entfernt.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
