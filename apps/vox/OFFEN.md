# Offene Punkte — vox

Stand: 13.11.2026 — Tag 4 abgeschlossen, Tag 5 zum größeren Teil.
Ein notierter offener Punkt ist verantwortbar, ein stiller nicht.

## Zuerst: einmal auf dem iPhone prüfen

Alles unten ist im Browser automatisiert geprüft — aber mit einer
*simulierten* Spracherkennung. Was nur ein echtes iPhone zeigt:

1. https://zelos0.github.io/App-Factory/ öffnen (falls 404: README,
   Abschnitt „Ausprobieren", einmal GitHub Pages einschalten).
2. Vox → Aufnehmen → Mikrofon erlauben → einen Satz sprechen, zwei Sekunden
   Pause, noch einen Satz → Fertig. **Erwartet:** beide Sätze im Eintrag.
3. Falls stattdessen „Das Mikrofon war für die Erkennung belegt" erscheint:
   Safari gibt das Mikrofon nicht gleichzeitig an Aufnahme UND Erkennung.
   Dann bitte melden — die Lösung wäre, im Browser nur die Erkennung laufen
   zu lassen (ohne Audiodatei), siehe unten „Audio im Browser".
4. Einstellungen → PDF → das Teilen-Menü muss aufgehen.
5. Teilen → Zum Home-Bildschirm → orangefarbenes Icon mit Schallwelle.

## Am 13.11.2026 erledigt

- [x] **CI läuft und ist grün** — zum ersten Mal überhaupt. Analyse,
      Format, Werbe-ID-Wächter und 127 Tests lokal und auf GitHub mit
      derselben Flutter-Version (3.24.5, in allen Workflows festgenagelt).
- [x] **Echte Spracherkennung.** Vorher erzeugte Vox nirgends Text: im
      Browser lief zwangsweise der Stub, auf dem Gerät warf die
      Plattform-Engine immer einen Fehler. Jetzt hört `PlatformSttEngine`
      während der Aufnahme mit — im Browser über die Web Speech API.
- [x] **Export als Datei** — Teilen-Menü auf dem Telefon, Download am
      Rechner. Kopieren bleibt als Zweitweg.
- [x] **PDF verdrahtet**, mit eingebetteter Unicode-Schrift (€ „ “ —
      fielen vorher still heraus).
- [x] **Fluchttür als ZIP** angeschlossen.
- [x] **Icons im Build** (fehlten komplett), CanvasKit ohne Google-CDN,
      eigenes App-Icon und Manifest statt Flutter-Vorlage.

## Aus Tag 4 offen geblieben

- [x] **Gratis gegen Pro ist entschieden** (11.08.2026). Die Trennlinie
      liegt zwischen Funktion und Komfort. Gratis ist alles, was eine Notiz
      erzeugt, findet oder wieder hinausträgt — **alle vier Exporte
      eingeschlossen, PDF und Fluchttür ebenso**. Pro sind: „Präzision
      prüfen", Abspielgeschwindigkeit außer 1,0×, Startbildschirm-Widget,
      Schnelleinstellungen-Kachel, automatische Stille-Erkennung.
      Kaufargument ist „nimm die Präzisions-Engine dazu", nicht „schalt die
      App frei". Tabelle in `docs/baupläne/vox.md` Abschnitt 10.

- [x] **Audio im Browser bleibt erhalten** (13.11.2026). Die Aufnahme
      wandert beim Stopp aus der flüchtigen Blob-Adresse in IndexedDB
      (`IndexedDbVault` speichert jetzt wirklich). Jedes Segment hat einen
      Abspielknopf — auch nach Neuladen. Das Fluchttür-ZIP enthält die
      Originale. Dabei behoben: Die Aufnahme war fest auf Opus/WebM
      eingestellt; Safari vor iOS 18.4 kann das nicht und hätte den Start
      mit „opus not supported" verweigert. Jetzt Opus → AAC → WAV, je nachdem,
      was der Browser kann. (AAC ließ sich hier nicht prüfen — Chromium kann
      kein AAC aufnehmen; der WAV-Rückfall ist geprüft.)

- [x] **Überschriften in schmaler Serifenschrift** (13.11.2026), wie der
      Steckbrief verlangt: Crimson Pro (SIL OFL 1.1) liegt unter
      `apps/vox/assets/fonts/`. Vorher stand im Theme 'Serif' — eine Schrift
      dieses Namens gibt es nicht, Flutter fiel still auf die Standardschrift
      zurück. Titelgrößen um 2 pt angehoben (kleinere x-Höhe).

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
| Abspielgeschwindigkeit 0,5× bis 2,5× | Wiedergabe je Segment steht (`SegmentPlayButton`); Geschwindigkeit fehlt noch |
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
