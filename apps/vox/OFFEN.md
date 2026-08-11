# Offene Punkte — vox

Stand: Tag 4 abgeschlossen (`konzept-zu-bauplan`, `app-derive`).
Ein notierter offener Punkt ist verantwortbar, ein stiller nicht.

## Aus Tag 4 offen geblieben

- [x] **Gratis gegen Pro ist entschieden** (11.08.2026). Gratis: Aufnehmen,
      Transkribieren, Suchen, alle vier Exporte, Fluchttür, Ordner und
      Schlagworte. Pro: „Präzision prüfen", Abspielgeschwindigkeit, Widget,
      Schnelleinstellungen-Kachel, Stille-Erkennung. Bezahlt wird für
      Qualität, nie für Zugang. Steht in `docs/baupläne/vox.md` Abschnitt 10.

- [ ] **Der Export läuft über die Zwischenablage, nicht über Dateien.**
      Der Web-Build hat keinen Dateidialog. Statt einer halben Lösung landet
      der Export in der Zwischenablage. Der Datei-Export und das ZIP der
      Fluchttür (`VaultExport.toZip`) kommen mit `test-loop-free` Stufe 1.
      Der Inhalt ist bereits vollständig — nur der Weg nach draußen fehlt.

- [ ] **PDF-Export ist vorbereitet, aber nicht verdrahtet.**
      `VoxExport.pdfRecipient` liefert den Parametersatz, `PdfExport.build`
      erzeugt daraus die Datei. Der Knopf dafür wartet auf denselben
      Datei-Weg wie oben.

- [ ] **Golden-Tests fehlen noch.** Sechs Bilder (Start, Liste, Detail — je
      hell und dunkel) gehören zu Tag 5. `app-derive` legt nur das
      Verzeichnis an; die Referenzbilder und `test/support/fake_store.dart`
      erzeugt `test-loop-free` Stufe 0. **Absichtlich nicht vorab
      eingecheckt:** Golden-Tests ohne Referenzbilder brechen die CI.

- [ ] **Integrationstest fehlt noch.** `integration_test/` ist angelegt,
      der Hauptablauf kommt mit `test-loop-free` Stufe 1.

## Vom Steckbrief genannt, bewusst noch nicht gebaut

Diese Funktionen stehen im Steckbrief und gehören zu vox — sie hängen aber
an Fähigkeiten, die es an Tag 4 noch nicht gibt:

| Funktion | Wartet auf |
|---|---|
| „Präzision prüfen" — zwei Engines im Vergleich | `capture-core-build` Stufe D (Parakeet) |
| Abspielgeschwindigkeit 0,5× bis 2,5× | Wiedergabe je Segment im Kern |
| Segmente verschieben, löschen, neu transkribieren | `EntryStore.retranscribe` steht bereits; die Oberfläche dazu fehlt |
| Ordner und Schlagworte, frei kombinierbar | Schlagworte werden erkannt, aber noch nicht vergeben |
| Startbildschirm-Widget, Schnelleinstellungen-Kachel | Plattformkanäle, frühestens mit einem Android-Gerät |
| Automatische Stille-Erkennung | Amplitudenstrom steht; Schwelle und Pause fehlen |

## Im selben Zug in den Kern gewandert

- [x] **`SpokenNumbers` und `SpokenDates`** liegen jetzt in
      `packages/shared_base/lib/src/text/`, mit eigenen Tests. Deutsche
      Zahlwörter („zweiundzwanzig fünfzig" → 22,50), Euro-/Cent-Marker,
      Hunderter und Tausender, relative Zeitangaben („gestern", „letzten
      Freitag", „nächsten Montag") und explizite Daten.
      **VOX benutzt beides nicht** — dort bleibt Text Text. Sie stehen im
      Kern, weil KASSA, RITUS, FAHRTLOG, WERKBUCH und ANAMNESE sie sonst
      je einzeln nachbauen würden. `app-derive` weist ab sofort darauf hin,
      dass sein Betrags-Beispiel Vorlage ist und nicht Kopiervorlage.

## Nicht behoben, weil hier nicht behebbar

- [ ] **`melos run analyze`, `melos run test` und `dart format` liefen für
      diesen Stand NICHT lokal.** Die Sandbox dieser Sitzung erreicht weder
      `storage.googleapis.com` noch `dl.google.com` noch `pub.dev` — es gibt
      also kein Flutter und kein Dart. Die Interpreter-Regeln wurden
      stattdessen als 1:1-Portierung nachgerechnet (alle zwölf Testfälle
      grün). Der erste CI-Lauf nach dem Push ist damit der erste echte
      Analyse- und Formatlauf. **Erwartbar ist genau ein Befund: Formatierung.**
      Erste Gegenmaßnahme, falls `format-check` rot wird:

      ```
      dart format apps/vox lib docs
      git commit -am "style: dart format"
      ```
