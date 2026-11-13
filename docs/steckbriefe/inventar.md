# INVENTAR — Hausrat, bevor etwas passiert

| | |
|---|---|
| Flavor | `inventar` |
| Kern | `both` |
| Paket-ID | `de.zeta.inventar` |
| Store-Titel | INVENTAR — Hausratverzeichnis |
| Band | II |
| Umsetzungsstufe | einschiebbar |
| Preisklasse | Semi-Pro |

## Zielgruppe

Hausrat- und Wohngebäudeversicherte, Wohnungsbesitzer, Wohngemeinschaften. Wird einmal angelegt und im Ernstfall dringend gebraucht.

## Der auslösende Moment

Nach Einbruch, Brand oder Wasserschaden verlangt die Versicherung eine Aufstellung. Aus dem Gedächtnis fehlt regelmäßig ein Drittel — und das ist bares Geld.

## App-spezifische Funktionen

- Geführter Rundgang Raum für Raum, wie bei ÜBERGABE
- Kaufbeleg als zusätzliche Aufnahme direkt am Gegenstand
- Gesamtwert je Raum und gesamt, mit Abschreibung nach Alter
- **Schadensmappe:** ausgewählte Positionen als PDF für die Versicherung
- Erinnerung zur jährlichen Aktualisierung
- Sicherungskopie auf ein zweites Gerät oder eine Nutzer-Cloud — denn die Daten müssen den Schaden überleben
- Nichts geht an einen Versicherer, solange der Nutzer nicht selbst versendet

## Interpreter & Pipeline — die zwanzig Prozent

- **Foto und Ansage in einem Vorgang:** Gerät fotografieren, Beschreibung einsprechen
- Seriennummer und Typbezeichnung per Texterkennung aus dem Bild gezogen
- Kaufpreis und Kaufdatum aus dem gesprochenen Satz
- Raumzuordnung und Kategorie automatisch vorgeschlagen

## Export

PDF-Verzeichnis mit Bildern, PDF-Schadensmappe je Auswahl, CSV, ZIP

## Risiko / Auflage

Keine Aussagen zur Deckung oder zur Regulierungspraxis. Die App erstellt ein Verzeichnis, sie ersetzt keine Versicherungsberatung.

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,99 € |
| Pro — Einführung | 4,99 € |
| Pro — Zielpreis | 9,99 € |

## Konkurrenz

Verzeichnis-Apps der Versicherer mit Kontozwang und Datenübertragung an den Versicherer noch vor jedem Schaden. Genau das wollen viele nicht.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Tiefblau | `#0A3A56` |
| Weiß | `#F8FAFC` |
| Wert | `#F59E0B` |
| Schiefer | `#334155` |

**Typografie.** Sachlich, tabellarisch. Werte in gleicher Ziffernbreite. Das PDF muss wie ein Verzeichnis wirken, nicht wie eine Fotosammlung.

**Leitmotiv.** Bestandsbuch. Nüchtern, geordnet, jedes Objekt eine Zeile mit Vorschaubild.

**Startbildschirm.** Der Gesamtwert als große Zahl, darunter die Räume als Kacheln mit Anzahl. Ein Knopf: Gegenstand hinzufügen.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
