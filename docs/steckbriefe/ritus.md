# RITUS — Gewohnheiten und Medikamente per Zuruf

| | |
|---|---|
| Flavor | `ritus` |
| Kern | `capture` |
| Paket-ID | `de.zeta.ritus` |
| Store-Titel | RITUS — Routinen & Einnahme |
| Band | I |
| Umsetzungsstufe | 2 |
| Preisklasse | Consumer |

## Zielgruppe

Menschen mit festen Routinen, Nahrungsergänzung, Trainingsplänen oder regelmäßiger Medikamenteneinnahme.

## Der Sprachmoment

Beim Zähneputzen, beim Kaffeekochen, direkt nach dem Training. Die Hände sind belegt, das Abhaken wird verschoben und dann vergessen.

## App-spezifische Funktionen

- Streak-Anzeige ohne Bestrafungslogik — eine Lücke bricht die Kette nicht sichtbar ab
- Erinnerungen an feste Zeiten oder an Ereignisse gekoppelt
- Freitextnotiz zu jeder Einnahme: Wirkung, Nebenwirkung, Befinden
- Vorrat mitzählen und rechtzeitig an Nachbestellung erinnern
- Wochenraster als eine Bildschirmseite ohne Scrollen
- Mehrere Personen in einer Installation, streng getrennt

## Interpreter — die zwanzig Prozent

- Abgleich des Transkripts gegen die vom Nutzer angelegten Routinen
- Mengenerkennung: „zwei Kapseln“, „fünftausend Einheiten“, „halbe Tablette“
- Mehrfacherfassung in einem Satz: „Vitamin D genommen und zwanzig Minuten gelaufen“
- Zeitliche Zuordnung bei nachträglicher Meldung

## Export

PDF-Einnahmeprotokoll für die ärztliche Praxis, CSV, Markdown

## Risiko / Auflage

Sobald Medikamentennamen erfasst werden, gelten in Google Play strengere Regeln für Gesundheits-Apps. Keine Wirkungsaussagen, keine Dosierungsempfehlungen, klarer Hinweis auf reine Protokollfunktion.

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,49 € |
| Pro — Einführung | 2,49 € |
| Pro — Zielpreis | 4,99 € |

## Konkurrenz

Habit-Tracker mit Abo zwischen 3 und 10 € im Monat, fast alle mit Kontozwang und Cloud-Synchronisation.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Terrakotta | `#7C2D12` |
| Ocker | `#EA580C` |
| Sand | `#FEF3C7` |
| Kohle | `#292524` |

**Typografie.** Kräftige, kurze Überschriften. Beschriftungen groß genug für ältere Augen — Mindestgröße 17 Punkt in der Standardeinstellung.

**Leitmotiv.** Warm, handwerklich, tagebuchartig. Kein Fitness-Neon, keine Trophäen, keine Konfetti-Animation. Ruhe als Gestaltungsprinzip.

**Startbildschirm.** Die heutigen Punkte als große, gut treffbare Kacheln. Erledigtes wird gedämpft, nicht durchgestrichen. Aufnahmeknopf unten mittig.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
