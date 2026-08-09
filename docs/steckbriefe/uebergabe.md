# ÜBERGABE — Die Kaution retten

| | |
|---|---|
| Flavor | `uebergabe` |
| Kern | `capture` |
| Paket-ID | `de.zeta.uebergabe` |
| Store-Titel | ÜBERGABE — Wohnungsprotokoll |
| Band | II |
| Umsetzungsstufe | 2 (Band II) |
| Preisklasse | Semi-Pro |

## Zielgruppe

Mieter bei Ein- und Auszug. In Deutschland jährlich mehrere Millionen Umzüge — und fast jeder Streit um die Kaution scheitert an fehlender Dokumentation.

## Der auslösende Moment

Leere Wohnung, Vermieter wartet, Schlüsselübergabe in zwanzig Minuten. Ein handschriftliches Protokoll wird unter Zeitdruck lückenhaft — und die Lücke kostet später vierstellig.

## App-spezifische Funktionen

- Geführter Rundgang Raum für Raum — die App vergisst keinen Raum, der Mensch schon
- Foto und Sprachnotiz in einem Vorgang, Zeitstempel und Standort fest verankert
- Zählerstände mit Foto als Beweis
- **Beidseitige Unterschrift auf dem Bildschirm** — beide Parteien bekommen dasselbe PDF
- Vergleichsmodus: Einzugsprotokoll neben Auszugsprotokoll, Unterschiede markiert
- Vorlagen für Wohnung, Haus, Gewerbe, Ferienobjekt
- Alles bleibt lokal, bis der Nutzer das PDF selbst versendet

## Interpreter — die zwanzig Prozent

- Raumzuordnung: „Küche, Fensterbank, Kratzer links unten“ wird strukturiert abgelegt
- Mangelschwere aus der Wortwahl vorgeschlagen, vom Nutzer bestätigt
- Zählerstände aus gesprochenen Zahlen, auch mit Nachkommastellen
- Erkennung von Schlüsselanzahl und Schlüsselart

## Export

PDF-Übergabeprotokoll mit Bildanhang und Unterschriften, ZIP mit Originalfotos

## Risiko / Auflage

Die App darf kein rechtsverbindliches Protokoll versprechen. Formulierung: Dokumentationshilfe, nicht Rechtsdokument. Keine Aussagen zur Rechtslage bei Mängeln.

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,99 € |
| Pro — Einführung | 4,99 € |
| Pro — Zielpreis | 9,99 € |

## Konkurrenz

Kaum spezialisierte Konkurrenz, überwiegend PDF-Vorlagen zum Ausdrucken. Der Markt ist praktisch unbesetzt, obwohl der finanzielle Einsatz je Nutzung sehr hoch ist.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Petrol | `#0F3D40` |
| Rauputz | `#F5F5F4` |
| Markierung | `#F59E0B` |
| Schiefer | `#1E293B` |

**Typografie.** Formularhaft, klar gegliedert, hoher Kontrast. Das erzeugte PDF muss aussehen wie ein Dokument, das vor Gericht Bestand hat.

**Leitmotiv.** Amtliches Formular, aber freundlich. Klare Abschnitte, sichtbarer Fortschritt, keine Verspieltheit — der Nutzer steht unter Zeitdruck.

**Startbildschirm.** Zwei Knöpfe: Einzug oder Auszug. Danach sofort die Raumliste. Kein Konto, keine Einführung, keine Umwege.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
