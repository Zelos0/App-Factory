# KASSA — Ausgaben ansagen statt eintippen

| | |
|---|---|
| Flavor | `kassa` |
| Kern | `capture` |
| Paket-ID | `de.zeta.kassa` |
| Store-Titel | KASSA — Ausgaben per Sprache |
| Band | I |
| Umsetzungsstufe | 2 |
| Preisklasse | Consumer |

## Zielgruppe

Haushalte mit Budgetdisziplin, Selbständige mit Kleinbelegen, alle die Banking-Apps aus Datenschutzgründen meiden.

## Der Sprachmoment

An der Kasse, Tüte in der Hand, Schlange hinter einem. Der Beleg wandert in die Tasche und ist abends vergessen.

## App-spezifische Funktionen

- Belegfoto an den Sprach-Eintrag anhängen, Original bleibt lokal
- Monatsübersicht mit Kategorieanteilen, Vormonatsvergleich
- Budgets je Kategorie mit stiller Warnung, nicht mit Popup
- Wiederkehrende Posten erkennen und als Vorschlag anbieten
- Mehrere Konten oder Töpfe, frei benennbar
- Bargeld-Modus: nur Betrag und Kategorie, ohne weitere Felder
- Rückwirkende Erfassung: „gestern bei …“ wird korrekt datiert

## Interpreter — die zwanzig Prozent

- Betragserkennung aus deutschen Zahlwörtern: „zweiundzwanzig fünfzig“ wird zu 22,50 €
- Händlererkennung über eine lernende lokale Liste
- Kategorisierung über Regelwerk, jederzeit vom Nutzer korrigierbar — jede Korrektur verbessert die Regel
- Erkennung von Zahlungsart, Datum und Mehrfachposten in einem Satz

## Export

CSV für Tabellenkalkulation, PDF-Monatsbericht, DATEV-kompatibler Export als Ausbaustufe

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,49 € |
| Pro — Einführung | 2,49 € |
| Pro — Zielpreis | 4,99 € |

## Konkurrenz

Finanz-Apps mit Bankanbindung verlangen 3 bis 8 € im Monat und Zugriff auf Kontodaten. Der offene Winkel ist ausdrücklich: keine Bankverbindung, keine Übertragung.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Tiefgrün | `#0C1F1A` |
| Signalgrün | `#10B981` |
| Kalk | `#F5F5F4` |
| Warnrot | `#DC2626` |

**Typografie.** Zahlen in einer Schrift mit gleicher Ziffernbreite, damit Spalten stehen. Beträge deutlich größer als Beschriftungen — die Zahl ist der Inhalt.

**Leitmotiv.** Kassenbon-Ästhetik ohne Ironie: schmale Spalten, feine Trennlinien, viel Weißraum. Grün wird sparsam eingesetzt, nie flächig.

**Startbildschirm.** Oben der Monatsbetrag als große Zahl. Darunter die letzten Buchungen als einzeilige Bon-Zeilen. Unten rechts der Aufnahmeknopf.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
