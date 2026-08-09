# TOLK — Übersetzen ohne Netz

| | |
|---|---|
| Flavor | `tolk` |
| Kern | `lens` |
| Paket-ID | `de.zeta.tolk` |
| Store-Titel | TOLK — Kamera-Übersetzer offline |
| Band | II |
| Umsetzungsstufe | 3 (Band II) |
| Preisklasse | Werkzeug |

## Zielgruppe

Reisende, Pendler, alle mit fremdsprachigem Papierkram. Direkte Ergänzung zu TERRA und LINGUA aus Band I.

## Der auslösende Moment

Speisekarte auf Griechisch, kein Empfang, Roaming teuer. Genau dann fallen alle serverbasierten Übersetzer aus.

## App-spezifische Funktionen

- **Vollständig offline nach dem Laden der Sprachpakete** — kein einziger Serverzugriff
- Live-Sucher: Übersetzung erscheint direkt über dem Original
- Standbild-Modus für schwierige Vorlagen mit Zoom
- Gespeicherte Übersetzungen als eigene Sammlung
- Sprachpaket-Verwaltung mit sichtbarem Speicherbedarf
- Merkliste für wiederkehrende Begriffe, exportierbar nach LINGUA

## Pipeline — die zwanzig Prozent

- Texterkennung und Übersetzung vollständig auf dem Gerät über ML Kit
- Sprachpakete einzeln herunterladbar, je Sprache wenige Dutzend Megabyte
- Automatische Ausgangssprachenerkennung
- Zeilenzuordnung: Übersetzung erscheint an der Stelle des Originals

## Export

TXT, Markdown, CSV der Merkliste

## Risiko / Auflage

Der kostenlose Marktführer ist stark. Die Positionierung muss ausschließlich über kompromisslose Netzunabhängigkeit laufen, nicht über Übersetzungsqualität.

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,49 € |
| Pro — Einführung | 1,99 € |
| Pro — Zielpreis | 3,99 € |

## Konkurrenz

Der Marktführer ist kostenlos und gut — aber die Offline-Nutzung ist umständlich und die Kamerafunktion netzabhängig eingeschränkt. Die Lücke ist nicht Qualität, sondern kompromissloser Offline-Betrieb.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Tiefgrün | `#04513B` |
| Minze | `#ECFDF5` |
| Original | `#F97316` |
| Kontrast | `#0F172A` |

**Typografie.** Übersetzung immer größer als das Original. Zwei klar getrennte Schriften für Ausgangs- und Zielsprache.

**Leitmotiv.** Sucher mit Überlagerung. Die Übersetzung liegt als halbtransparente Fläche über dem Bild, nie daneben.

**Startbildschirm.** Kamera füllt den Bildschirm. Oben ein schmaler Balken mit Sprachpaar. Sonst nichts.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
