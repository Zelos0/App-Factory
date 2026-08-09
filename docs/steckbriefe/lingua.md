# LINGUA — Sprechen, sehen, korrigieren

| | |
|---|---|
| Flavor | `lingua` |
| Kern | `capture` |
| Paket-ID | `de.zeta.lingua` |
| Store-Titel | LINGUA — Sprachlern-Journal |
| Band | I |
| Umsetzungsstufe | 5 |
| Preisklasse | Consumer |

## Zielgruppe

Selbstlerner ab Niveau A2, die sprechen üben wollen, ohne Gesprächspartner und ohne Bewertung durch Dritte.

## Der Sprachmoment

Sprechpraxis scheitert an der Hemmung vor anderen. Allein sprechen bringt nichts, solange man nicht sieht, was tatsächlich angekommen ist.

## App-spezifische Funktionen

- **Das Alleinstellungsmerkmal des ganzen Portfolios:** mehrsprachige Spracherkennung, die vollständig ohne Netz läuft — technisch derzeit von keinem Wettbewerber offline angeboten
- Tagesthema als Sprechanlass, sechzig Sekunden frei sprechen
- Fortschritt sichtbar: aktiver Wortschatz über Wochen, Sprechdauer ohne Stocken
- Selbstvergleich: dieselbe Aufgabe nach vier Wochen erneut, beide Aufnahmen nebeneinander
- Schattensprechen: eigene Aufnahme direkt nach einer Vorlage abspielen
- Mehrere Sprachen gleichzeitig in getrennten Journalen

## Interpreter — die zwanzig Prozent

- Transkription in der gewählten Zielsprache — Parakeet v3 deckt fünfundzwanzig europäische Sprachen offline ab
- Abweichungsanalyse zwischen beabsichtigtem und erkanntem Text
- Wortschatz-Extraktion: welche Wörter tatsächlich aktiv verwendet werden
- Erkennung von Füllwörtern und Wiederholungen

## Export

PDF-Lernbericht, Anki-kompatible CSV für Vokabeln, Markdown

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,49 € |
| Pro — Einführung | 2,49 € |
| Pro — Zielpreis | 4,99 € |

## Konkurrenz

Sprachlern-Abos zwischen 10 und 15 € im Monat. Deren Aussprachebewertung läuft ausnahmslos über die Cloud.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Indigo | `#312E81` |
| Pergament | `#FEFCE8` |
| Safran | `#F59E0B` |
| Nacht | `#1E293B` |

**Typografie.** Zwei klar getrennte Schriftfamilien: eine für die Zielsprache, eine für die Muttersprache. Der Nutzer soll auf einen Blick sehen, welche Ebene er liest.

**Leitmotiv.** Vokabelheft und Bibliothek. Ruhig, textlastig, ohne Gamification-Elemente. Keine Punkte, keine Ligen, keine Herzchen.

**Startbildschirm.** Oben die aktuelle Sprache mit Flaggensymbol. Darunter die Tagesaufgabe als ein Satz. Der Aufnahmeknopf trägt die Beschriftung mit der Zielsprache.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
