# SCHWÄRZE — Weggeben, ohne alles preiszugeben

| | |
|---|---|
| Flavor | `schwaerze` |
| Kern | `lens` |
| Paket-ID | `de.zeta.schwaerze` |
| Store-Titel | SCHWÄRZE — Dokumente schwärzen |
| Band | II |
| Umsetzungsstufe | 4 (Band II) |
| Preisklasse | Werkzeug |

## Zielgruppe

Mieter, Bewerber, Antragsteller, Journalisten, alle die Kopien mit unnötigen Daten weitergeben müssen. Kleiner Markt, aber praktisch unbesetzt.

## Der auslösende Moment

Der Vermieter will die Gehaltsabrechnung, aber nicht die Kontonummer. Die Behörde den Ausweis, aber nicht die Ausweisnummer. Handschriftliche Schwärzung wirkt unprofessionell, digitale Überdeckung ist meist wirkungslos.

## App-spezifische Funktionen

- Vorschläge zum Schwärzen automatisch markiert, Nutzer bestätigt einzeln
- Wischen zum Schwärzen, Rückgängig möglich bis zum Export
- Vorlagen: Gehaltsabrechnung, Ausweis, Kontoauszug, Mietvertrag — je mit sinnvollen Vorgaben
- **Nachweisansicht** vor dem Export: die App zeigt, was nach dem Speichern noch auslesbar wäre
- Mehrseitige Dokumente in einem Durchgang
- Ausgabe als flaches PDF ohne Textebene, wenn gewünscht

## Pipeline — die zwanzig Prozent

- **Echte Entfernung:** geschwärzte Bereiche werden aus der Bilddatenebene gelöscht, nicht überdeckt
- Automatische Erkennung sensibler Muster: IBAN, Steuernummer, Ausweisnummer, Geburtsdatum, Anschrift
- Entfernung aller Metadaten aus dem Ergebnis, inklusive Standort und Gerätekennung
- Prüfansicht: was nach dem Export noch im Dokument steht

## Export

PDF flach, PDF mit bereinigter Textebene, PNG, JPG ohne Metadaten

## Risiko / Auflage

Die App darf keine Rechtssicherheit versprechen. Formulierung: technische Entfernung der Bilddaten und Metadaten — keine Aussage über rechtliche Anforderungen an Schwärzungen im jeweiligen Verfahren.

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,99 € |
| Pro — Einführung | 2,99 € |
| Pro — Zielpreis | 5,99 € |

## Konkurrenz

Nahezu keine spezialisierte Konkurrenz im Consumer-Bereich. Verbreitete Werkzeuge legen nur ein schwarzes Rechteck über den Text — der darunterliegende Text bleibt im PDF erhalten und ist auslesbar.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Schwarz | `#0A0A0A` |
| Blattweiß | `#FAFAFA` |
| Markierung | `#DC2626` |
| Grau | `#525252` |

**Typografie.** Sachlich und knapp. Warnhinweise in kurzen, eindeutigen Sätzen — die App wird in Situationen mit realem Risiko benutzt.

**Leitmotiv.** Aktendeckel. Schwarz, weiß, ein Rot. Keine Farbe, die vom Dokument ablenkt.

**Startbildschirm.** Ein Knopf: Dokument wählen oder fotografieren. Danach sofort das Dokument mit markierten Vorschlägen.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
