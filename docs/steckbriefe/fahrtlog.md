# FAHRTLOG — Fahrten ansagen, während man fährt

| | |
|---|---|
| Flavor | `fahrtlog` |
| Kern | `capture` |
| Paket-ID | `de.zeta.fahrtlog` |
| Store-Titel | FAHRTLOG — Fahrtenprotokoll |
| Band | I |
| Umsetzungsstufe | 3 |
| Preisklasse | Semi-Pro |

## Zielgruppe

Selbständige, Außendienst, Handwerker, Pflegedienste, alle mit dienstlicher Nutzung eines Privatfahrzeugs.

## Der Sprachmoment

Am Steuer, Motor läuft, Hände am Lenkrad. Jede andere Erfassungsform ist entweder verboten oder wird verschoben.

## App-spezifische Funktionen

- Freihändiger Modus: Ansage startet und beendet die Fahrt, keine Bildschirmberührung
- Bluetooth-Kopplung ans Fahrzeug startet die Erfassung automatisch
- GPS-Streckenaufzeichnung mit Distanzberechnung als Kontrollwert
- Mehrere Fahrzeuge mit eigenen Kilometerständen
- Nachträgliche Zweckzuordnung gesammelt für die ganze Woche
- Lückenprüfung: erkennt fehlende Kilometer zwischen zwei Fahrten und weist darauf hin
- Änderungsprotokoll — jede spätere Korrektur bleibt nachvollziehbar

## Interpreter — die zwanzig Prozent

- Kilometerstand aus gesprochenen Zahlen, auch sechsstellig
- Zweck-Erkennung: geschäftlich, privat, Arbeitsweg
- Ziel aus Adressbuch und lernender Kundenliste
- Ergänzung fehlender Felder aus GPS und Zeitstempel

## Export

PDF-Fahrtenbuch pro Zeitraum, CSV, Excel

## Risiko / Auflage

Ein steuerlich anerkanntes Fahrtenbuch unterliegt strengen Formvorschriften zu Lückenlosigkeit und Änderungssicherheit. Die App wird als **Fahrtenprotokoll** vermarktet, nicht als finanzamtskonformes Fahrtenbuch. Andernfalls drohen Haftungsfragen und Ein-Stern-Rezensionen von Nutzern, deren Prüfung scheitert.

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,99 € |
| Pro — Einführung | 4,99 € |
| Pro — Zielpreis | 9,99 € |

## Konkurrenz

Etablierte deutsche Fahrtenbuch-Apps verlangen für Spracheingabe und Export gesonderte Käufe. Der Markt zahlt nachweislich — Abo-freie Positionierung wird dort bereits aktiv beworben.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Asphalt | `#18181B` |
| Signalgelb | `#FACC15` |
| Fahrbahn | `#FAFAF9` |
| Grau | `#52525B` |

**Typografie.** Sehr große Zahlen, sehr klare Kontraste. Im Fahrmodus nur zwei Schriftgrößen und keine dünnen Schnitte.

**Leitmotiv.** Instrumententafel. Reduziert, hoher Kontrast, dunkler Grund. Der Fahrmodus zeigt maximal drei Elemente gleichzeitig.

**Startbildschirm.** Ein einziger breiter Balken: Fahrt starten. Darunter der aktuelle Kilometerstand und die letzten drei Fahrten. Sonst nichts.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
