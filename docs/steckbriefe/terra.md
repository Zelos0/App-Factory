# TERRA — Aufzeichnen, wo kein Netz ist

| | |
|---|---|
| Flavor | `terra` |
| Kern | `capture` |
| Paket-ID | `de.zeta.terra` |
| Store-Titel | TERRA — Reise- & Outdoor-Log |
| Band | I |
| Umsetzungsstufe | 5 |
| Preisklasse | Consumer |

## Zielgruppe

Reisende, Wanderer, Radfahrer, Jäger, Angler. Zwei sehr unterschiedliche Gruppen mit derselben technischen Anforderung.

## Der Sprachmoment

Kein Empfang, teures Roaming, Regen auf dem Display, Rucksack auf. Cloud-Apps fallen hier vollständig aus.

## App-spezifische Funktionen

- Vollständige Offline-Karte des gewählten Gebiets, vorab geladen
- Sprachnotiz mit GPS-Punkt und Foto in einem Vorgang
- Höhenprofil und Strecke automatisch mitgezeichnet
- Reisetagebuch-Ansicht: Zeitachse mit Kartenausschnitt je Eintrag
- Logbuch-Ansicht für Jagd und Angel: Ort, Bedingungen, Ergebnis, wiederkehrende Muster
- Extrem sparsamer Aufnahmemodus für lange Touren ohne Ladegelegenheit
- Handschuhtauglich große Bedienelemente

## Interpreter — die zwanzig Prozent

- Ortszuordnung aus GPS, Ortsnamen nachträglich ergänzt sobald Netz besteht
- Erkennung von Art, Anzahl, Maß bei Beobachtungen und Fängen
- Wetter- und Bedingungsangaben aus dem gesprochenen Text
- Etappenzuordnung bei mehrtägigen Touren

## Export

PDF-Reisebuch mit Karten, GPX der Strecke, CSV des Logbuchs

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,49 € |
| Pro — Einführung | 2,49 € |
| Pro — Zielpreis | 4,99 € |

## Konkurrenz

Reisetagebuch- und Tourenportale mit Abo zwischen 3 und 8 € im Monat, alle mit Serverbindung. Im Offline-Fall schlicht nicht nutzbar.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Moos | `#14532D` |
| Kartenpapier | `#FEF3C7` |
| Erde | `#92400E` |
| Waldnacht | `#0F172A` |

**Typografie.** Robuste Grotesk mit hohem Kontrast. Kartenbeschriftungen in Versalien, Fließtext großzügig — gelesen wird im Gehen.

**Leitmotiv.** Topografische Karte. Höhenlinien als dezentes Muster, gedeckte Naturtöne, Papieranmutung. Nichts Glänzendes, nichts Verlaufendes.

**Startbildschirm.** Die Karte füllt den Bildschirm, eigene Position als Punkt. Ein einziger Knopf am unteren Rand setzt Marke und startet Aufnahme in einem Zug.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
