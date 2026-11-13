# ONIRA — Träume festhalten, bevor sie verblassen

| | |
|---|---|
| Flavor | `onira` |
| Kern | `capture` |
| Paket-ID | `de.zeta.onira` |
| Store-Titel | ONIRA — Traumtagebuch offline |
| Band | I |
| Umsetzungsstufe | 2 |
| Preisklasse | Consumer |

## Zielgruppe

Menschen mit Interesse an luzidem Träumen, Traumdeutung, Selbstbeobachtung. Überwiegend 20 bis 40, hohe emotionale Bindung.

## Der Sprachmoment

Sechs Uhr morgens, Augen halb zu, der Traum zerfällt beim Aufsetzen. Tippen ist in diesem Zustand ausgeschlossen.

## App-spezifische Funktionen

- **Weckerkopplung:** Der Alarm endet nicht mit Stopp, sondern mit direkt startbereiter Aufnahme
- Nachtmodus mit rotem Licht und maximaler Knopfgröße — bedienbar mit geschlossenen Augen
- Erweitern über den Tag: fällt später etwas ein, hängt es als neues Segment an denselben Traum
- Symbolkarte: welche Motive über Wochen wiederkehren, als Häufigkeitsgraph
- Serienerkennung: wiederkehrende Träume automatisch verknüpft
- Mondphase und Schlafdauer optional je Eintrag
- Realitätsprüfungs-Erinnerungen für luzides Träumen, frei terminierbar

## Interpreter — die zwanzig Prozent

- Symbolerkennung gegen eine lokale Wortliste (Wasser, Fallen, Verfolgung, Fliegen, Zähne …)
- Stimmungserkennung über Wortfeldanalyse, vom Nutzer korrigierbar
- Personen- und Ortsmarkierungen aus dem Transkript vorgeschlagen

## Export

PDF-Traumbuch mit Zeitachse, Markdown, CSV der Symbolhäufigkeiten

## Risiko / Auflage

Direkte Konkurrenz existiert bereits im deutschen Store. Die Abgrenzung muss in den ersten beiden Screenshots sichtbar sein, nicht im Fließtext.

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,49 € |
| Pro — Einführung | 2,49 € |
| Pro — Zielpreis | 4,99 € |

## Konkurrenz

Dreamiary und ähnliche Apps bieten Sprachaufnahme mit Transkription bereits an — durchweg über die Cloud und meist mit Abo. Der offene Winkel ist Offline-Betrieb plus Einmalkauf.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Tiefnacht | `#0B0A1F` |
| Indigo | `#2E2A6B` |
| Amethyst | `#A78BFA` |
| Nebel | `#E0E7FF` |

**Typografie.** Weiche, humanistische Serife für Überschriften. Transkripte in großzügigem Zeilenabstand, leicht reduzierter Kontrast — der Bildschirm wird bei Dunkelheit gelesen.

**Leitmotiv.** Verlaufende Übergänge statt harter Kanten, Sternenfeld-Andeutung im Hintergrund, aber sehr zurückhaltend. Nichts Esoterisch-Kitschiges.

**Startbildschirm.** Der Bildschirm ist fast schwarz. In der Mitte ein pulsierender violetter Ring als Aufnahmeknopf. Am oberen Rand nur Datum und Uhrzeit. Alles andere erst nach dem Wischen.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
