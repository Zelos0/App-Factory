# PRISMA — Scannen ohne Gegenleistung

| | |
|---|---|
| Flavor | `prisma` |
| Kern | `lens` |
| Paket-ID | `de.zeta.prisma` |
| Store-Titel | PRISMA — QR- & Barcode-Scanner |
| Band | II |
| Umsetzungsstufe | 1 (Band II) |
| Preisklasse | Werkzeug |

## Zielgruppe

Alle. Der größte Einzelmarkt in beiden Bänden und zugleich der mit der schlechtesten Konkurrenz.

## Der auslösende Moment

Kein Sprachmoment, sondern ein Frustmoment: Die verbreiteten Scanner zeigen vor dem Ergebnis Vollbildwerbung. Der Nutzer will drei Sekunden, bekommt fünfzehn.

## App-spezifische Funktionen

- **Ergebnis in unter einer Sekunde, ohne jede Zwischenanzeige** — das gesamte Verkaufsargument
- Verlauf aller Scans, durchsuchbar, lokal
- Eigene Codes erzeugen: WLAN-Zugang, Kontakt, Text, Adresse
- Stapelmodus für Inventuren
- Aus Bildern der Galerie scannen
- Taschenlampe und Zoom direkt im Sucher
- Widget und Schnelleinstellungs-Kachel

## Pipeline — die zwanzig Prozent

- Erkennung aller gängigen Formate über ML Kit, vollständig auf dem Gerät
- Typerkennung: URL, WLAN, Kontakt, Kalender, IBAN, Produkt
- Warnung bei verdächtigen Zieladressen vor dem Öffnen
- Mehrfacherkennung mehrerer Codes in einem Bild

## Export

CSV des Verlaufs, PNG und SVG der erzeugten Codes

## Risiko / Auflage

Reines Volumenspiel mit sehr niedriger Zahlungsbereitschaft. Der Beitrag liegt in Werbevolumen und Quergewinnung, nicht im Kaufumsatz.

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,49 € |
| Pro — Einführung | 1,99 € |
| Pro — Zielpreis | 2,99 € |

## Konkurrenz

Marktführer mit hunderten Millionen Installationen, durchweg mit Interstitials vor dem Ergebnis und Bewertungen zwischen 3,2 und 3,9 Sternen. Die Ein-Stern-Rezensionen nennen fast alle denselben Grund.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Tiefzyan | `#0E3A47` |
| Scanlinie | `#22D3EE` |
| Weiß | `#FAFAFA` |
| Rahmen | `#1E293B` |

**Typografie.** Minimal. Das Ergebnis ist groß, alles andere klein. Kein Text im Sucher außer der Zielhilfe.

**Leitmotiv.** Sucher. Der Bildschirm gehört der Kamera, die Oberfläche verschwindet fast vollständig.

**Startbildschirm.** Die Kamera startet sofort mit dem App-Start. Kein Startbildschirm, kein Logo, keine Berechtigungsabfrage außer der ersten.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
