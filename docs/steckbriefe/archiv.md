# ARCHIV — Papier, das sich selbst meldet

| | |
|---|---|
| Flavor | `archiv` |
| Kern | `both` |
| Paket-ID | `de.zeta.archiv` |
| Store-Titel | ARCHIV — Verträge & Fristen |
| Band | II |
| Umsetzungsstufe | 2 (Band II) |
| Preisklasse | Semi-Pro |

## Zielgruppe

Haushalte mit laufenden Verträgen: Versicherungen, Mobilfunk, Strom, Abonnements, Garantien. Also praktisch alle.

## Der auslösende Moment

Der Vertrag verlängert sich automatisch, weil die Kündigungsfrist im Ordner verschwunden ist. Der Schaden ist konkret und bezifferbar — meist dreistellig pro Jahr.

## App-spezifische Funktionen

- Vertrag scannen, Frist wird vorgeschlagen, Nutzer bestätigt — mehr braucht es nicht
- Erinnerung gestaffelt: drei Monate, ein Monat, eine Woche vor Fristablauf
- Garantien mit Kaufbeleg und Ablaufdatum
- **Kündigungsschreiben als PDF** aus den erfassten Daten erzeugt
- Jahresübersicht aller laufenden Kosten
- Volltextsuche über alle Vertragsinhalte, weil die PDFs eine Textebene haben
- **Keine Wechselempfehlungen, keine Provisionen** — der Unterschied zu allen Wettbewerbern

## Interpreter & Pipeline — die zwanzig Prozent

- Laufzeit, Kündigungsfrist und Verlängerung per Texterkennung aus dem Vertrag gezogen
- Vertragspartner, Vertragsnummer und Beitrag automatisch erfasst
- Sprachnotiz je Dokument für den Zusammenhang, den kein Text hergibt
- Kategorisierung nach Vertragsart mit passenden Standardfristen

## Export

PDF-Vertragsübersicht, PDF-Kündigungsschreiben, CSV der Kosten, ZIP des Archivs

## Risiko / Auflage

Keine Rechtsberatung zu Kündigungsfristen. Die erkannte Frist ist ein Vorschlag aus dem Dokument, den der Nutzer bestätigt — nicht eine geprüfte Rechtsauskunft.

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,99 € |
| Pro — Einführung | 4,99 € |
| Pro — Zielpreis | 9,99 € |

## Konkurrenz

Vertragsverwalter mit Abo zwischen 3 und 10 € im Monat, viele finanzieren sich über Wechselprovisionen und haben damit ein Interesse an bestimmten Empfehlungen.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Kraftpapier | `#3B3835` |
| Ablage | `#FAF9F7` |
| Frist | `#DC2626` |
| Erledigt | `#0F766E` |

**Typografie.** Ordnerregister. Klare Hierarchie, Fristen deutlich hervorgehoben, alles andere ruhig.

**Leitmotiv.** Hängeregistratur. Reiter, Register, gedecktes Papier. Nur die nächste Frist ist farbig.

**Startbildschirm.** Die nächsten drei Fristen als Zeilen mit Countdown, farbig nach Dringlichkeit. Darunter das Archiv als Ordnerliste.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
