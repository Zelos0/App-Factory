# FOLIO — Dokumente scannen, ohne zu zahlen

| | |
|---|---|
| Flavor | `folio` |
| Kern | `lens` |
| Paket-ID | `de.zeta.folio` |
| Store-Titel | FOLIO — Dokumentenscanner |
| Band | II |
| Umsetzungsstufe | 1 (Band II) |
| Preisklasse | Consumer |

## Zielgruppe

Alle mit gelegentlichem Papierkram — Bewerbungen, Belege, Verträge, Formulare, Bescheinigungen.

## Der auslösende Moment

Ein Dokument muss digital werden, jetzt. Die verbreiteten Scanner setzen Wasserzeichen, begrenzen Seiten oder verlangen ein Abo für den Export.

## App-spezifische Funktionen

- Kein Wasserzeichen, keine Seitenbegrenzung in der Gratisversion
- Durchsuchbares PDF mit echter Textebene, nicht nur Bild
- Seiten sortieren, drehen, ersetzen, nachträglich einfügen
- Kompressionsstufen mit sichtbarer Dateigröße vor dem Speichern
- Ordner, Schlagworte, Volltextsuche über alle Dokumente
- Direkt in eine beliebige Cloud des Nutzers speichern — ohne eigene Cloud
- Stapelscan für viele Belege in einem Durchgang

## Pipeline — die zwanzig Prozent

- Kantenerkennung und perspektivische Entzerrung auf dem Gerät
- Automatische Modi: Text, Farbfoto, Graustufe, Weißabgleich
- Texterkennung über ML Kit erzeugt eine durchsuchbare Textebene im PDF
- Mehrseitenerkennung mit automatischem Auslöser beim Umblättern

## Export

PDF mit Textebene, PDF/A, einzelne Bilddateien, ZIP

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,49 € |
| Pro — Einführung | 2,49 € |
| Pro — Zielpreis | 4,99 € |

## Konkurrenz

Marktführer mit Abo zwischen 5 und 10 € im Monat. Kostenlose Versionen setzen Wasserzeichen oder begrenzen auf wenige Seiten. Serverseitige Verarbeitung ist die Regel.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Tinte | `#1E293B` |
| Blattweiß | `#F8FAFC` |
| Kante | `#3B82F6` |
| Grau | `#94A3B8` |

**Typografie.** Zurückhaltend. Das Dokument ist der Inhalt, die Oberfläche tritt zurück. Dateinamen und Ordner gut lesbar.

**Leitmotiv.** Aktenschrank. Ruhig, geordnet, viel Weißraum. Die Vorschau eines Scans ist immer das größte Element auf dem Bildschirm.

**Startbildschirm.** Zuletzt gescannte Dokumente als Kachelraster mit Vorschaubild. Aufnahmeknopf unten mittig, groß.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
