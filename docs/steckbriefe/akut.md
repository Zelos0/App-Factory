# AKUT — Der Vertrauensanker

| | |
|---|---|
| Flavor | `akut` |
| Kern | `capture` |
| Paket-ID | `de.zeta.akut` |
| Store-Titel | AKUT — Unfallprotokoll |
| Band | I |
| Umsetzungsstufe | 6 |
| Preisklasse | Vertrauensanker |

## Zielgruppe

Alle Autofahrer und Radfahrer. Wird selten geöffnet und im Ernstfall dringend gebraucht.

## Der Sprachmoment

Nach einem Unfall zittern die Hände, der Puls ist hoch, die Gegenseite drängt. Ein Formular auszufüllen ist in dieser Lage unrealistisch.

## App-spezifische Funktionen

- Geführter Ablauf in acht Schritten, jeder Schritt eine Frage und ein Aufnahmeknopf
- Fotoleitfaden: welche sechs Aufnahmen tatsächlich gebraucht werden, mit Rahmenhilfe
- GPS, Zeit und Wetter automatisch protokolliert
- Zeugenkontakt über Sprachaufnahme statt Tippen
- Alles bleibt lokal — nichts geht an einen Versicherer, solange der Nutzer es nicht selbst versendet
- Fertiges PDF-Protokoll in unter fünf Minuten

## Interpreter — die zwanzig Prozent

- Geführte Erfassung entlang der rechtlich relevanten Punkte, jeweils per Ansage
- Kennzeichen-, Zeit- und Ortserkennung
- Personenrollen: Beteiligte, Zeugen, Polizei
- Automatische Vollständigkeitsprüfung am Ende

## Export

PDF-Unfallprotokoll mit Bildanhang, ZIP mit Originalaufnahmen

## Risiko / Auflage

**Diese App wird nie verkauft und trägt keine Werbung.** Sie ist Reputationsträger und Verteilkanal: Sie wird weiterempfohlen, sammelt Fünf-Sterne-Rezensionen aus Dankbarkeit und trägt den Verweis auf die übrigen Apps. Ihr Ertrag liegt vollständig in der Reichweite, die sie den anderen zehn verschafft.

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | gratis |
| Pro — Einführung | gratis |
| Pro — Zielpreis | gratis |

## Konkurrenz

Formularbasierte Apps der Versicherer, allesamt mit Kontozwang und Datenübertragung an den Versicherer noch vor jeder Beratung.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Signalrot | `#7F1D1D` |
| Weiß | `#FAFAFA` |
| Alarm | `#DC2626` |
| Schwarz | `#171717` |

**Typografie.** Größtmögliche Schrift, härtester Kontrast. Eine Anweisung je Bildschirm, nichts daneben. Die Gestaltung geht davon aus, dass der Nutzer unter Schock steht.

**Leitmotiv.** Notfallkarte. Kein Design im gestalterischen Sinn — nur Klarheit. Ein Element je Bildschirm, ein Knopf, eine Frage.

**Startbildschirm.** Ein einziger roter Knopf über die volle Breite: Protokoll starten. Nichts anderes ist sichtbar.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
