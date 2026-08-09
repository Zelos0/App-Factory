# ANAMNESE — Was man dem Arzt sagen wollte

| | |
|---|---|
| Flavor | `anamnese` |
| Kern | `capture` |
| Paket-ID | `de.zeta.anamnese` |
| Store-Titel | ANAMNESE — Symptomtagebuch |
| Band | I |
| Umsetzungsstufe | 3 |
| Preisklasse | Semi-Pro |

## Zielgruppe

Menschen mit wiederkehrenden oder unklaren Beschwerden, in Diagnostik, mit chronischem Verlauf oder in Therapiebegleitung.

## Der Sprachmoment

Die Beschwerde tritt auf, dauert zwanzig Minuten, verschwindet. Drei Wochen später in der Praxis fehlt jedes Detail.

## App-spezifische Funktionen

- **Arztbrief-Export:** ein zweiseitiges PDF, chronologisch, sachlich, ohne Interpretation — das eigentliche Verkaufsargument
- Körperkarte zum Antippen der Region statt Beschreiben
- Intensitätsskala von null bis zehn per Ansage oder Schieberegler
- Fotoverlauf für sichtbare Veränderungen
- Vorbereitungsliste: offene Fragen sammeln, die man in der Praxis stellen will
- Zeitachse mit Häufungen — sichtbare Muster ohne Deutung
- Biometriesperre standardmäßig aktiv

## Interpreter — die zwanzig Prozent

- Erkennung von Körperregion, Intensität und Dauer aus dem gesprochenen Text
- Zeitliche Einordnung: seit wann, wie oft, wie lange
- Erkennung von Begleitumständen: Nahrung, Schlaf, Belastung, Wetter
- Keinerlei Deutung, keine Verdachtsäußerung, keine Empfehlung

## Export

PDF-Arztbrief, PDF-Vollprotokoll, CSV

## Risiko / Auflage

Gesundheitskategorie mit verschärfter Prüfung bei Google Play. Keine diagnostische Aussage, keine Behandlungsempfehlung, kein Hinweis auf Krankheitsbilder. Der Datenschutzhinweis muss die reine Lokalspeicherung ausdrücklich benennen.

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,99 € |
| Pro — Einführung | 4,99 € |
| Pro — Zielpreis | 9,99 € |

## Konkurrenz

Symptom-Apps mit Abo zwischen 5 und 15 € im Monat, fast alle mit Cloud-Speicherung von Gesundheitsdaten. Der offene Winkel ist maximal: Gesundheitsdaten verlassen das Gerät nie.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Klinikweiß | `#F8FAFC` |
| Tiefblau | `#0C4A6E` |
| Signalblau | `#38BDF8` |
| Schiefer | `#334155` |

**Typografie.** Sachlich, ruhig, hoher Kontrast. Kein Rot außer bei tatsächlichen Warnungen. Das Dokument soll wie eine medizinische Notiz aussehen, nicht wie eine Lifestyle-App.

**Leitmotiv.** Karteikarte. Weißer Grund, blaue Struktur, sehr wenig Farbe. Keine Illustration, keine Maskottchen, keine Motivationssprache.

**Startbildschirm.** Die Frage „Wie geht es dir gerade?“ als einzige Überschrift, darunter der Aufnahmeknopf. Zeitachse der letzten vierzehn Tage als schmales Band am unteren Rand.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
