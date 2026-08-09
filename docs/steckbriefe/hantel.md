# HANTEL — Zwischen den Sätzen ansagen

| | |
|---|---|
| Flavor | `hantel` |
| Kern | `capture` |
| Paket-ID | `de.zeta.hantel` |
| Store-Titel | HANTEL — Trainingslog per Sprache |
| Band | II |
| Umsetzungsstufe | zuletzt oder gar nicht |
| Preisklasse | Consumer |

## Zielgruppe

Kraftsportler mit festem Plan. Große Zielgruppe, aber auch der am stärksten besetzte Markt in diesem Band.

## Der auslösende Moment

Verschwitzte Hände, neunzig Sekunden Satzpause, Handschuhe an. Tippen kostet die halbe Pause und unterbricht den Rhythmus.

## App-spezifische Funktionen

- Freihändiger Trainingsmodus: Ansage nach jedem Satz, kein Bildschirmkontakt
- Eigene Pläne, keine vorgegebenen Programme
- Verlauf je Übung als Kurve, persönliche Bestwerte automatisch erkannt
- Volumenberechnung je Muskelgruppe und Woche
- Pausenuhr startet automatisch nach der Ansage
- Ausschließlich lokal — Trainingsdaten sind Gesundheitsdaten

## Interpreter — die zwanzig Prozent

- Übung, Gewicht, Wiederholungen aus einem Satz: „Bankdrücken achtzig acht“
- Einheitenerkennung und Umrechnung
- Satzzuordnung zum laufenden Training ohne Auswahl
- Erkennung von Abbruch, Teilwiederholung und Hilfestellung

## Export

CSV je Übung, PDF-Trainingsbuch, JSON für Auswertung in anderen Werkzeugen

## Risiko / Auflage

Am stärksten besetzter Markt des Portfolios. Realistische Erwartung: solide Mitte statt Durchbruch. Wird gebaut, weil er aus dem Kern billig ist — nicht weil er gewonnen wird.

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,49 € |
| Pro — Einführung | 2,49 € |
| Pro — Zielpreis | 4,99 € |

## Konkurrenz

Marktführer mit Abo zwischen 5 und 12 € im Monat und sehr ausgereiften Funktionen. Der einzige belastbare Winkel ist die **Spracheingabe** — funktional aufholen wird nicht gelingen.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Gusseisen | `#18181B` |
| Signal | `#EF4444` |
| Kreide | `#FAFAFA` |
| Stahl | `#52525B` |

**Typografie.** Sehr große Zahlen, sehr kurze Beschriftungen. Im Trainingsmodus nur zwei Schriftgrößen.

**Leitmotiv.** Kraftraum, nicht Studio. Dunkler Grund, harte Kanten, ein einziger Akzent. Keine Erfolgsanimationen, keine Abzeichen.

**Startbildschirm.** Der heutige Plan als Übungsliste. Die aktive Übung hervorgehoben mit letztem Gewicht. Aufnahmeknopf über die halbe Breite.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
