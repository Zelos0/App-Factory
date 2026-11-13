# HERD — Rezepte, wie sie erzählt werden

| | |
|---|---|
| Flavor | `herd` |
| Kern | `capture` |
| Paket-ID | `de.zeta.herd` |
| Store-Titel | HERD — Rezeptbuch per Sprache |
| Band | II |
| Umsetzungsstufe | einschiebbar |
| Preisklasse | Consumer |

## Zielgruppe

Alle, die Familienrezepte sammeln oder eigene Abwandlungen festhalten. Emotional stark aufgeladen, dadurch sehr hohe Bindung.

## Der auslösende Moment

Zwei Situationen: Hände im Teig beim Abwandeln — und die Großmutter, die es erzählt statt aufschreibt. Die zweite ist der eigentliche Grund, warum diese App gekauft wird.

## App-spezifische Funktionen

- **Erzählmodus:** jemand erzählt frei, die App gliedert daraus Zutaten und Schritte — nachträglich korrigierbar
- Die Originalstimme bleibt erhalten, dauerhaft, neben dem Text
- Kochmodus: Bildschirm bleibt an, Schritt für Schritt, Weiterschalten per Zuruf
- Portionen hochrechnen mit automatisch angepassten Mengen
- Eigene Abwandlungen als zusätzliche Segmente am selben Rezept
- Einkaufsliste aus einem oder mehreren Rezepten
- Fotos je Schritt und vom Ergebnis

## Interpreter — die zwanzig Prozent

- Trennung von Zutaten und Arbeitsschritten aus fortlaufender Rede
- Mengen und Einheiten aus gesprochener Sprache, inklusive Prisen und Handvoll
- Zeit- und Temperaturangaben als eigene Felder
- Portionsangabe erkannt und später hochrechenbar

## Export

PDF-Rezeptbuch im Buchsatz, Markdown, ZIP mit den Originalaufnahmen

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,49 € |
| Pro — Einführung | 2,49 € |
| Pro — Zielpreis | 4,99 € |

## Konkurrenz

Rezept-Apps mit Abo zwischen 3 und 6 € im Monat, alle auf Rezeptdatenbanken ausgerichtet. Keine ist darauf ausgelegt, ein *erzähltes* Rezept aufzunehmen.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Röstbraun | `#6B2C13` |
| Mehl | `#FEF6E4` |
| Butter | `#CA8A04` |
| Guss | `#3F3F46` |

**Typografie.** Buchsatz. Serife für die Schritte, klare Grotesk für Mengen. Das erzeugte PDF soll wie ein gedrucktes Kochbuch wirken, nicht wie ein Ausdruck.

**Leitmotiv.** Handgeschriebenes Familienrezeptbuch. Warme Papiertöne, Fleckenanmutung, aber sauber gesetzt.

**Startbildschirm.** Die zuletzt gekochten Rezepte als Kacheln mit Foto. Ein Knopf für neues Rezept, einer für Erzählmodus.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
