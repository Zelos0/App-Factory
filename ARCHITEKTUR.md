# Architektur-Referenz — App-Fabrik

Verbindliche technische Grundlage. Jeder Skill und jede App richtet sich danach.
Widersprüche sind Fehler, keine Varianten.

---

## 1. Leitidee

Sechsundzwanzig Apps sind nicht sechsundzwanzig Projekte. Sie sind **zwei Kerne,
ein gemeinsamer Unterbau und sechsundzwanzig dünne Hüllen.** Jede App besteht zu
etwa achtzig Prozent aus geteiltem Code. Was variiert, sind genau vier Dinge:

1. **Interpreter / Pipeline** — was aus der Rohaufnahme strukturiert extrahiert wird
2. **Auswertung** — Summen, Verläufe, Karten, Zeitachsen
3. **Export** — Format und Empfänger
4. **Gestaltung** — Farbwelt, Typografie, Startbildschirm

Alles andere ist geteilt. Wenn eine App etwas Fünftes braucht, gehört es in den
Kern, nicht in die App.

---

## 2. Verzeichnisstruktur

```
app-fabrik/
├── melos.yaml
├── analysis_options.yaml
├── ARCHITEKTUR.md
├── TESTLEITER.md
├── .github/workflows/
│   ├── ci.yml                  Analyse, Unit, Widget, Golden
│   ├── web.yml                 Web-Build + Cloudflare-Pages-Deploy
│   └── testlab.yml             Firebase Test Lab, Robo + Integration
├── packages/
│   ├── shared_base/            Unterbau — von BEIDEN Kernen genutzt
│   │   ├── storage/            SQLite (drift), Verschlüsselung, Migration
│   │   ├── search/             Volltextsuche über alle Einträge
│   │   ├── export/             Markdown, JSON, CSV, PDF, KI-Kontextbündel
│   │   ├── monetize/           AdSurface, Purchases, UMP-Gerüst
│   │   ├── design/             Theme-System, Typografie-Skalen, Komponenten
│   │   └── config/             features.dart — alle Schalter
│   ├── capture_core/           Sprach-Kern
│   │   ├── audio/              Recorder, Wellenform, Wiedergabe
│   │   ├── stt/                SttEngine + drei Implementierungen
│   │   └── ui/                 RecordButton, EntryList, EntryDetail
│   └── lens_core/              Kamera-Kern
│       ├── camera/             Pipeline, Kantenerkennung, Entzerrung
│       ├── recognize/          ScanPipeline: Barcode, OCR, Übersetzung
│       ├── pdf/                Erzeugung mit durchsuchbarer Textebene
│       └── ui/                 Sucher, Dokumentenbibliothek
└── apps/
    ├── vox/                    ~200 Zeilen + Theme + Interpreter
    ├── onira/
    ├── prisma/
    └── …
```

**Regel:** In `apps/*` steht kein Code, der in einer zweiten App nützlich wäre.
Sobald etwas zweimal gebraucht wird, wandert es in `shared_base` oder den Kern.

---

## 3. Das Datenmodell

Trägt die Kernanforderung „ein Eintrag ist jederzeit erweiterbar". Nicht verhandelbar.

```dart
class Entry {
  String id;
  String type;              // App-Kennung
  String? title;
  DateTime createdAt;
  DateTime updatedAt;
  List<String> tags;
  Map<String, dynamic> data;   // Ergebnis des Interpreters
}

class Segment {
  String id;
  String entryId;
  int order;                // Reihenfolge innerhalb des Eintrags
  String? mediaPath;        // Audio oder Bild
  String? transcript;       // erkannter Text
  String engine;            // welche Engine erzeugt hat — für Re-Transkription
  DateTime createdAt;
}
```

Ein Eintrag ist eine **geordnete Kette von Segmenten**, kein Textblock.
Daraus folgt kostenlos: Erweitern durch Anhängen, Original je Abschnitt
nachhörbar, Zeitstempel je Gedanke, einzelne Segmente später mit besserer
Engine neu transkribierbar.

---

## 4. Die Schnittstellenschicht

**Das Herzstück der gesamten Strategie.** Jede plattformabhängige oder
kostenpflichtige Fähigkeit liegt hinter einer Schnittstelle mit mindestens
einer kostenlosen Web-Implementierung. Nur so ist der Web-Build ein
vollwertiger Testkanal — und nur so bleibt das Portfolio plattformbeweglich.

```dart
abstract class SttEngine {
  Future<Transcript> transcribe(String path, {String lang});
  bool get isAvailable;
  String get id;
}
// WebStubSttEngine     hinterlegter Beispieltext — Web-Build
// PlatformSttEngine    Android SpeechRecognizer / iOS Speech — Gratis-Stufe
// ParakeetSttEngine    sherpa-onnx, Modell ~640 MB, Nachladen — Pro-Stufe

abstract class ScanPipeline {
  Future<ScanResult> process(Uint8List image, ScanMode mode);
}
// WebStubScanPipeline  Browser-Kamera + einfache JS-Erkennung
// MlKitScanPipeline    ML Kit auf dem Gerät

abstract class FileVault  { }   // NativeVault  | IndexedDbVault
abstract class AdSurface  { }   // AdMobSurface | NoOpSurface
abstract class Purchases  { }   // PlayBilling  | AlwaysProPurchases
```

Registrierung zentral in `shared_base/config/`, abhängig von Plattform und
Schaltern. **Kein Geschäftslogik-Code kennt eine konkrete Implementierung.**

---

## 5. Schalter — `shared_base/config/features.dart`

```dart
class Features {
  static const adsEnabled      = false;  // bis Play-Konto existiert
  static const billingEnabled  = false;  // bis Play-Konto existiert
  static const parakeetEnabled = false;  // bis Kern-Integration steht
  static const sttEngine       = 'platform';   // web | platform | parakeet
  static const analyticsEnabled = false; // dauerhaft — kein Tracking
}
```

Kein Schalter darf im App-Code abgefragt werden, nur in der Registrierung.
Apps sehen ausschließlich die Schnittstellen.

---

## 6. Zwei-Stufen-STT

| Stufe | Engine | Größe | Wo verfügbar |
|---|---|---|---|
| Web | `WebStubSttEngine` | 0 | nur Testkanal |
| Gratis | Plattform-Engine des Betriebssystems | 0 | Android, iOS |
| Pro | Parakeet TDT 0.6B v3 int8 via sherpa-onnx | ~640 MB | nach Nachladen |

Das Modell wird **niemals** ins App-Paket gelegt, sondern bei Aktivierung
geladen. Der Nachladedialog formuliert die Größe als Beweis, nicht als Kosten:
das vollständige Sprachmodell wandert auf das Gerät, danach arbeitet die App
ohne jede Netzverbindung.

**Der Verkaufsmechanismus:** „Präzision prüfen" transkribiert dasselbe Segment
mit der Pro-Engine und zeigt den Unterschied farbig markiert. Drei kostenlose
Läufe, nicht zehn. Das ist der einzige Weg, Qualität zu beweisen, ohne
Marketingmaterial.

---

## 7. Export — jeder Export hat einen Empfänger

| Empfänger | Format |
|---|---|
| Der Nutzer selbst, später | Markdown mit YAML-Frontmatter, `[[Verweise]]` |
| Ein KI-Modell | Kontextbündel: Schema-Kopf, Einträge, vorformulierter Auftrag, Token-Schätzung |
| Ein Mensch mit Autorität | PDF, gestaltet nach Empfänger |
| Andere Software | CSV, JSON, GPX |

**Fluchttür, immer kostenlos und prominent:** vollständiges JSON plus ZIP aller
Originaldateien. Aufbereitete Formate dürfen zur Kaufversion gehören, die
Rohdaten nie. Beim KI-Export erscheint ein ausdrücklicher Hinweis, dass die
Datei ab hier das Gerät verlässt und der Nutzer entscheidet, wohin.

---

## 8. Gestaltungssystem

`shared_base/design/` liefert Skalen, Abstände, Komponenten. Jede App liefert
nur ein `AppTheme` mit vier Farben, zwei Schriftfamilien und einem
Startbildschirm-Aufbau.

Feste Regeln über alle Apps:
- Bannerfläche unten verankert, **mindestens 16 dp Abstand** zu jedem
  Bedienelement, besonders zum Aufnahmeknopf — Fehlklicks sind ein Sperrgrund
- Primäraktion im Daumenbereich, mindestens 56 dp hoch
- Startbildschirm ohne Willkommenstext, ohne Tour, ohne Kontoabfrage
- Helles und dunkles Design ab dem ersten Tag, Schriftgröße einstellbar

---

## 9. Namenskonventionen

| Gegenstand | Muster | Beispiel |
|---|---|---|
| Flavor | Kleinbuchstaben | `onira` |
| Paket-ID | `de.<marke>.<flavor>` | `de.zeta.onira` |
| App-Verzeichnis | `apps/<flavor>/` | `apps/onira/` |
| Interpreter | `<Flavor>Interpreter` | `OniraInterpreter` |
| Theme | `<Flavor>Theme` | `OniraTheme` |
| Store-Material | `apps/<flavor>/store/` | |

---

## 10. Definition of Done je App

Eine App gilt als fertig, wenn **alle** Punkte erfüllt sind:

- [ ] Läuft im Web-Build vollständig bedienbar, alle Bildschirme erreichbar
- [ ] Interpreter hat Tests mit mindestens zwölf realistischen Beispielsätzen
- [ ] Golden Tests für Startbildschirm, Liste, Detail — hell und dunkel
- [ ] Ein Integrationstest spielt den Hauptablauf von Anfang bis Ende durch
- [ ] Alle vier Exportformate erzeugen gültige Dateien
- [ ] Fluchttür-Export vorhanden, kostenlos, in den Einstellungen sichtbar
- [ ] Bannerfläche reserviert, Abstand geprüft
- [ ] Store-Texte und Screenshots liegen unter `apps/<flavor>/store/`
- [ ] `flutter analyze` ohne Befund
- [ ] Kein Code in `apps/<flavor>/`, der in eine zweite App gehören würde
