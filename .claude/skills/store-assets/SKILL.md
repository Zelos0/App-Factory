---
name: store-assets
description: Erzeugt alle Play-Store-Materialien einer App vollständig vom iPhone aus — Titel, Kurz- und Langbeschreibung, Data-Safety-Angaben, Datenschutzerklärung und Screenshots aus den CI-Integrationstests — und legt sie unter apps/<flavor>/store/ ab; ausgelöst durch „Store-Material für onira erzeugen", „mach die Store-Texte", „Screenshots für den Play Store", „Datenschutzangaben für die App".
---

# Store-Material aus dem Repo statt aus dem Bildbearbeiter

Kein Bildbearbeiter, kein Desktop, kein Play-Konto. Die Screenshots entstehen dort,
wo die App ohnehin läuft: im Integrationslauf von `test-loop-free`. Dieser Skill
verbraucht sie und bringt sie in die Play-Formate. Die Texte stehen in genau einer
Quelle — `store/metadata.yaml` — und werden daraus in die Play-Ablage geschrieben
und auf Zeichenlängen geprüft. Alles wartet im Repo auf den Tag, an dem ein Konto
existiert.

## Wann dieser Skill greift

Auslöser: „Store-Material für <flavor> erzeugen", „mach die Store-Texte für <flavor>",
„Screenshots für den Play Store", „Datenschutzangaben", „Data Safety ausfüllen",
„Feature-Grafik bauen".

Greift **nicht**:
- beim Hochladen zu Google Play — das ist `release-gate` und der ist stillgelegt,
  bis `PLAY_CONSOLE_READY` an ist.
- beim Anlegen einer neuen App — das ist `app-derive`. Der legt das Gerüst
  `apps/<flavor>/store/metadata.yaml` an; dieser Skill füllt es und leitet daraus
  die Play-Ablage ab.
- bei Versionshinweisen (`whatsnew`) — die erzeugt `release-gate` aus den Commits.
- beim Einrichten oder Aufnehmen der Screenshots — das ist `test-loop-free`.
  Dessen Integrationslauf erzeugt die sechs PNGs; dieser Skill **verbraucht** sie.

## Voraussetzungen

- Repo nach `ARCHITEKTUR.md`, angelegt durch `monorepo-bootstrap`.
- Die App `apps/<flavor>/` existiert und startet im Web-Build (`app-derive`).
- `packages/shared_base/lib/src/config/brand.dart` existiert mit `kBrand`, `kFlavor`
  und `kApplicationId` (legt `monorepo-bootstrap` an). Dieser Skill **ergänzt** die
  Datei in Schritt 0 um eine Konstante, er ersetzt sie nicht.
- `apps/<flavor>/store/metadata.yaml` existiert als Gerüst mit den Feldern `titel`,
  `kurzbeschreibung`, `langbeschreibung`, `kategorie`, `schlagworte`, `datenschutz`,
  `screenshots` (legt `app-derive` an). Diese Datei ist die **Quelle**; alles unter
  `store/de-DE/` wird daraus erzeugt und nie direkt bearbeitet.
- `apps/<flavor>/integration_test/screenshots/` enthält die sechs PNGs des
  Hauptablaufs (erzeugt `test-loop-free`, Stufe 1). Fehlen sie, verweist dieser
  Skill dorthin und stoppt — er nimmt keine eigenen Screenshots auf.
- GitHub-Repo verbunden, `gh` authentifiziert (`gh auth status` antwortet ohne Fehler).

Alle folgenden Pfade und Inhalte sind für den Flavor `onira` vollständig ausformuliert.
Beim Lauf für einen anderen Flavor wird `onira` durchgängig ersetzt und die Texte
werden aus den Antworten in Schritt 1 neu formuliert — Struktur, Grenzen und
Prüfungen bleiben identisch.

## Ablauf

### Schritt 0 — Bestehende Marken-Datei ergänzen

`packages/shared_base/lib/src/config/brand.dart` existiert bereits und wird von
`monorepo-bootstrap` gepflegt. Sie wird **ergänzt, nicht ersetzt**: an das Ende
der Datei kommt genau eine Konstante, die dieser Skill für die Pflicht-URL der
Datenschutzerklärung braucht. `kBrand`, `kFlavor` und `kApplicationId` bleiben
unangetastet.

```dart
// packages/shared_base/lib/src/config/brand.dart — Anhang, kein Ersatz.
// Bestehend und unverändert: kBrand = 'de.zeta', kFlavor aus
// --dart-define=FLAVOR, kApplicationId => '$kBrand.$kFlavor'.

/// Öffentliche Basis-URL der Pflichtseiten (Datenschutz, Impressum).
/// Zeigt auf das Cloudflare-Pages-Projekt aus TESTLEITER.md, Stufe 1.
/// Die Seite selbst entsteht in Schritt 3 dieses Skills.
const String kPublicBaseUrl = 'https://app-fabrik.pages.dev';

/// Vollständige URL der Datenschutzerklärung dieses Flavors.
/// Genau diese Adresse wird im Play-Store-Eintrag hinterlegt.
String get kDatenschutzUrl => '$kPublicBaseUrl/$kFlavor/datenschutz.html';
```

Der öffentliche Import ist immer `package:shared_base/shared_base.dart`.
`package:shared_base/src/...` ist nicht auflösbar; falls `kPublicBaseUrl` und
`kDatenschutzUrl` dort noch nicht exportiert werden, wird die bestehende
`export`-Zeile für `src/config/brand.dart` in `lib/shared_base.dart` geprüft und
nichts Neues angelegt.

### Schritt 1 — Fünf Angaben abfragen und in metadata.yaml eintragen

Der Skill stellt genau diese fünf Fragen und rät bei keiner:

1. Flavor und Anzeigename der App.
2. Ein Satz: Was tut die App für wen? (Grundlage für Kurzbeschreibung)
3. Drei Funktionen, die den Unterschied machen (Grundlage für Langbeschreibung)
4. Welche Daten verlassen das Gerät jemals? (Grundlage für Data Safety)
5. Welche sechs Bildschirme aus dem Integrationslauf sollen in den Store?

Die Antworten wandern in das von `app-derive` angelegte Gerüst. **Diese Datei ist
die Quelle. Alles unter `store/de-DE/` ist ihr Erzeugnis und wird nie von Hand
bearbeitet** — wer den Titel ändern will, ändert `metadata.yaml` und führt
Schritt 2 erneut aus.

```yaml
# apps/onira/store/metadata.yaml — vom Gerüst zur gefüllten Quelle
titel: Onira — Traumtagebuch
kurzbeschreibung: Träume sofort einsprechen, strukturiert wiederfinden, offline behalten.
langbeschreibung: |
  Onira nimmt auf, was direkt nach dem Aufwachen noch da ist und zwei Minuten
  später verschwunden wäre. Knopf drücken, sprechen, fertig. Kein Konto, keine
  Anmeldung, kein Willkommensbildschirm.

  AUFNEHMEN
  Ein Traum ist selten ein Block Text. Er kommt in Bruchstücken. Onira legt jede
  Aufnahme als eigenes Segment ab und hängt spätere Bruchstücke an denselben
  Eintrag an. Die Reihenfolge bleibt erhalten, der Zeitstempel jedes Abschnitts
  ebenfalls, und das Original bleibt jederzeit einzeln nachhörbar.

  STRUKTURIEREN
  Aus dem gesprochenen Text zieht Onira heraus, was später zählt: Personen, Orte,
  wiederkehrende Motive, Stimmung, Klarheitsgrad. Diese Felder sind durchsuchbar
  und filterbar. Aus dreißig Einträgen wird damit eine Übersicht statt eines
  Stapels.

  WIEDERFINDEN
  Volltextsuche über alle Einträge und Segmente. Filter nach Motiv, Person, Ort
  und Zeitraum. Eine Zeitachse zeigt, welche Motive wann gehäuft auftreten.

  OFFLINE UND OHNE KONTO
  Die Spracherkennung des Betriebssystems arbeitet auf dem Gerät. Wer maximale
  Genauigkeit möchte, lädt einmalig das vollständige Sprachmodell nach — danach
  arbeitet die Erkennung ohne jede Netzverbindung. Kein Upload, kein Tracking,
  keine Analyse-Bibliothek.

  EXPORT MIT EMPFÄNGER
  Vier Formate, jedes für einen bestimmten Zweck:
  - Markdown mit Frontmatter und Verweisen für die eigene Notizsammlung
  - Kontextbündel für ein KI-Modell, mit Schema-Kopf und Token-Schätzung
  - PDF für Menschen, die es lesen sollen
  - CSV und JSON für andere Programme

  FLUCHTTÜR
  Der vollständige Export als JSON plus ZIP aller Originalaufnahmen ist dauerhaft
  kostenlos und steht sichtbar in den Einstellungen. Aufbereitete Formate können
  zur Kaufversion gehören, die Rohdaten niemals. Wer geht, nimmt alles mit.

  BEDIENUNG
  Helles und dunkles Design ab dem ersten Start. Schriftgröße einstellbar. Die
  Primäraktion liegt im Daumenbereich und ist mindestens 56 dp hoch.
kategorie: LIFESTYLE
schlagworte:
  - Traumtagebuch
  - Sprachnotizen
  - offline
  - ohne Konto
datenschutz:
  url: https://app-fabrik.pages.dev/onira/datenschutz.html
  quelle: store/datenschutz.md
  erhebt_daten: false
  gibt_daten_weiter: false
  hinweis: Verarbeitung ausschliesslich auf dem Gerät, kein Konto, kein Server.
screenshots:
  quelle: integration_test/screenshots
  # Exakt die sechs Dateien, die test-loop-free erzeugt. Der Integrationslauf
  # besucht Auswertung und Export nicht — was er nicht besucht, gibt es hier
  # auch nicht. app-derive legt das Gerüst bereits mit dieser Liste an.
  auswahl:
    - 01-start
    - 02-aufnahme-laeuft
    - 03-erster-eintrag
    - 04-erweitert
    - 05-liste
    - 06-detail
  hintergrund: '101018'
```

### Schritt 2 — Play-Ablage aus metadata.yaml erzeugen

`store/de-DE/` ist reines Erzeugnis. Es wird aus `metadata.yaml` geschrieben,
nicht getippt. Damit gibt es genau eine Stelle, an der ein Titel geändert wird,
und `release-gate` findet die Dateien immer dort, wo es sie erwartet.

```dart
// tool/store_metadata.dart
// Liest apps/<flavor>/store/metadata.yaml und erzeugt daraus die Play-Ablage
// apps/<flavor>/store/de-DE/ sowie die auslieferbare Datenschutzseite.
// Aufruf: dart run tool/store_metadata.dart --flavor=onira
import 'dart:io';
import 'package:yaml/yaml.dart';

const _grenzen = <String, int>{
  'titel': 30,
  'kurzbeschreibung': 80,
  'langbeschreibung': 4000,
};

int main(List<String> args) {
  final flavor = args
      .firstWhere((a) => a.startsWith('--flavor='), orElse: () => '')
      .replaceFirst('--flavor=', '');
  if (flavor.isEmpty) {
    stderr.writeln('FEHLT: --flavor=<name>');
    return 2;
  }

  final quelle = File('apps/$flavor/store/metadata.yaml');
  if (!quelle.existsSync()) {
    stderr.writeln('FEHLT: ${quelle.path} — app-derive legt das Gerüst an.');
    return 2;
  }
  final meta = loadYaml(quelle.readAsStringSync()) as YamlMap;

  final ziel = Directory('apps/$flavor/store/de-DE')..createSync(recursive: true);
  var fehler = 0;
  for (final feld in _grenzen.keys) {
    final wert = (meta[feld] as String?)?.trim() ?? '';
    if (wert.isEmpty) {
      stderr.writeln('FEHLT: metadata.yaml → $feld ist leer.');
      fehler += 1;
      continue;
    }
    if (wert.length > _grenzen[feld]!) {
      stderr.writeln('ZU LANG: $feld hat ${wert.length} Zeichen, '
          'Play erlaubt ${_grenzen[feld]}.');
      fehler += 1;
      continue;
    }
    File('${ziel.path}/$feld.txt').writeAsStringSync('$wert\n');
    stdout.writeln('OK  ${ziel.path}/$feld.txt (${wert.length} Zeichen)');
  }
  return fehler == 0 ? 0 : 3;
}
```

```bash
dart pub get --directory tool
dart run tool/store_metadata.dart --flavor=onira
```

Die Datenschutzerklärung wird als Markdown geschrieben, weil sie gelesen und
versioniert werden muss. Aus ihr entsteht in Schritt 3 die ausgelieferte Seite.

```markdown
# apps/onira/store/datenschutz.md
# Datenschutzerklärung — Onira

Stand: 2026-08-09
Anwendung: Onira (Paket-ID `de.zeta.onira`)
Öffentliche Adresse dieser Seite: https://app-fabrik.pages.dev/onira/datenschutz.html

## 1. Verantwortlich

Betreiber der Anwendung, erreichbar unter der im Play-Store-Eintrag genannten
E-Mail-Adresse.

## 2. Welche Daten die App verarbeitet

| Datenart | Wo sie liegt | Verlässt das Gerät |
|---|---|---|
| Audioaufnahmen | ausschließlich lokal, App-eigener Speicher | nein |
| Transkripte und Einträge | lokale, verschlüsselte SQLite-Datenbank | nein |
| Einstellungen | lokal | nein |
| Absturzberichte | werden nicht erhoben | nein |
| Nutzungsstatistiken | werden nicht erhoben | nein |

Es existiert kein Benutzerkonto. Es findet keine Registrierung statt.

## 3. Spracherkennung

Die App nutzt die Spracherkennung des Betriebssystems. Auf Android kann diese je
nach Geräteeinstellung Audiodaten an Google übertragen; das ist eine
Systemfunktion und unterliegt der Datenschutzerklärung von Google. Wird das
nachladbare Offline-Sprachmodell aktiviert, findet die Erkennung vollständig auf
dem Gerät statt und es werden keine Audiodaten übertragen.

## 4. Export

Ein Export wird von der Nutzerin oder dem Nutzer ausgelöst und erzeugt eine
Datei auf dem Gerät. Wohin diese Datei anschließend geht, entscheidet
ausschließlich die Person selbst. Beim Export in ein Kontextbündel für ein
KI-Modell weist die App vor dem Erzeugen ausdrücklich darauf hin, dass die Datei
ab diesem Punkt das Gerät verlassen kann.

## 5. Werbung und Käufe

In der aktuellen Fassung ist keine Werbung eingebunden und es findet keine
Kaufabwicklung statt. Werden diese Funktionen aktiviert, wird diese Erklärung
vorher ergänzt und die Data-Safety-Angaben im Play Store entsprechend angepasst.

## 6. Löschung

Löschen eines Eintrags entfernt Transkript, Struktur und Originalaufnahme
unwiderruflich vom Gerät. Deinstallation entfernt sämtliche Daten der App. Da
keine Daten auf Servern liegen, ist kein Löschantrag erforderlich.

## 7. Rechte

Auskunft, Berichtigung, Löschung und Datenübertragbarkeit werden technisch durch
den kostenlosen Vollexport erfüllt, der jederzeit in den Einstellungen erreichbar
ist.
```

```yaml
# apps/onira/store/data_safety.yaml
# Vorlage für das Play-Console-Formular „Datensicherheit".
# Jede Zeile entspricht einem Feld im Formular. Wird beim Ausfüllen abgelesen,
# nicht hochgeladen — Google bietet keinen API-Upload für dieses Formular.
paket_id: de.zeta.onira
stand: 2026-08-09

datenerhebung:
  erhebt_daten: false
  begruendung: >
    Sämtliche Verarbeitung findet auf dem Gerät statt. Es existiert kein Server,
    kein Konto und keine Analyse-Bibliothek.

datenweitergabe:
  gibt_daten_weiter: false

sicherheitspraktiken:
  verschluesselung_bei_uebertragung: true   # es findet keine Übertragung statt
  loeschung_anforderbar: false               # keine Serverdaten vorhanden
  unabhaengige_sicherheitspruefung: false
  familienrichtlinie_relevant: false

# Datentypen: Jede Zeile ist ein Formularfeld. false bedeutet: im Formular
# nicht ankreuzen. Bei einer Änderung des Codes MUSS diese Datei mitgeführt
# werden — falsche Angaben sind ein Sperrgrund, kein Formfehler.
datentypen:
  standort_grob:            {erhoben: false, geteilt: false}
  standort_genau:           {erhoben: false, geteilt: false}
  name:                     {erhoben: false, geteilt: false}
  email:                    {erhoben: false, geteilt: false}
  nutzer_id:                {erhoben: false, geteilt: false}
  zahlungsinformationen:    {erhoben: false, geteilt: false}
  kontakte:                 {erhoben: false, geteilt: false}
  fotos_videos:             {erhoben: false, geteilt: false}
  audiodateien:             {erhoben: false, geteilt: false, hinweis: "nur lokal gespeichert"}
  dateien_dokumente:        {erhoben: false, geteilt: false, hinweis: "nur lokal gespeichert"}
  app_aktivitaet:           {erhoben: false, geteilt: false}
  absturzprotokolle:        {erhoben: false, geteilt: false}
  diagnose:                 {erhoben: false, geteilt: false}
  geraete_id:               {erhoben: false, geteilt: false}
  werbe_id:                 {erhoben: false, geteilt: false}

# Schalter-Kopplung: Sobald die Registrierung eine echte AdSurface bzw.
# Purchases-Implementierung einhängt (AdSurface.isEnabled == true), MUSS
# werbe_id.erhoben auf true und der Zweck "Werbung oder Marketing" gesetzt
# werden. Der Test store_texte_test.dart prüft genau diese Kopplung — er fragt
# die Registrierung, nicht die Schalter, wie es ARCHITEKTUR.md §5 verlangt.
gekoppelt_an:
  ads_enabled: false
  billing_enabled: false
```

### Schritt 3 — Datenschutzseite für den Web-Build erzeugen

Die Play-Console verlangt eine erreichbare URL, keine Datei im Repo. Der
Web-Build ist ohnehin da — also liefert er die Seite mit aus. Alles unter
`apps/<flavor>/web/` landet unverändert im Build und damit unter der
Cloudflare-Pages-Adresse aus `TESTLEITER.md`, Stufe 1.

```dart
// tool/datenschutz_html.dart
// Erzeugt apps/<flavor>/web/datenschutz.html aus apps/<flavor>/store/datenschutz.md.
// Damit existiert die im Play-Eintrag hinterlegte URL wirklich.
// Aufruf: dart run tool/datenschutz_html.dart --flavor=onira
import 'dart:io';

int main(List<String> args) {
  final flavor = args
      .firstWhere((a) => a.startsWith('--flavor='), orElse: () => '')
      .replaceFirst('--flavor=', '');
  if (flavor.isEmpty) {
    stderr.writeln('FEHLT: --flavor=<name>');
    return 2;
  }
  final quelle = File('apps/$flavor/store/datenschutz.md');
  if (!quelle.existsSync()) {
    stderr.writeln('FEHLT: ${quelle.path}');
    return 2;
  }

  final koerper = _markdownZuHtml(quelle.readAsStringSync());
  final ziel = File('apps/$flavor/web/datenschutz.html');
  ziel.parent.createSync(recursive: true);
  ziel.writeAsStringSync('''
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Datenschutzerklärung — $flavor</title>
<style>
  :root { color-scheme: light dark; }
  body { font: 16px/1.6 system-ui, sans-serif; max-width: 42rem;
         margin: 0 auto; padding: 1.5rem; }
  table { border-collapse: collapse; width: 100%; }
  th, td { border: 1px solid currentColor; padding: .4rem .6rem; text-align: left; }
  code { font-family: ui-monospace, monospace; }
</style>
</head>
<body>
$koerper
</body>
</html>
''');
  stdout.writeln('OK  ${ziel.path}');
  return 0;
}

/// Übersetzt genau die Auszeichnungen, die in datenschutz.md vorkommen:
/// Überschriften, Tabellen, Absätze, Inline-Code.
String _markdownZuHtml(String md) {
  final aus = StringBuffer();
  var inTabelle = false;
  for (final roh in md.split('\n')) {
    final zeile = roh.trimRight();
    if (zeile.startsWith('|')) {
      final zellen = zeile.split('|').where((z) => z.trim().isNotEmpty).toList();
      if (zellen.every((z) => RegExp(r'^\s*-+\s*$').hasMatch(z))) continue;
      if (!inTabelle) {
        aus.writeln('<table>');
        inTabelle = true;
      }
      aus.writeln('<tr>${zellen.map((z) => '<td>${_inline(z.trim())}</td>').join()}</tr>');
      continue;
    }
    if (inTabelle) {
      aus.writeln('</table>');
      inTabelle = false;
    }
    if (zeile.isEmpty) continue;
    final ueberschrift = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(zeile);
    if (ueberschrift != null) {
      final stufe = ueberschrift.group(1)!.length;
      aus.writeln('<h$stufe>${_inline(ueberschrift.group(2)!)}</h$stufe>');
      continue;
    }
    aus.writeln('<p>${_inline(zeile)}</p>');
  }
  if (inTabelle) aus.writeln('</table>');
  return aus.toString();
}

String _inline(String t) => t
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => '<code>${m.group(1)}</code>');
```

```bash
dart run tool/datenschutz_html.dart --flavor=onira
```

Nach dem nächsten Web-Deploy ist die Seite unter
`https://app-fabrik.pages.dev/onira/datenschutz.html` erreichbar — exakt der Wert,
der in `metadata.yaml` unter `datenschutz.url` und im Play-Eintrag steht.

### Schritt 4 — Screenshots aus test-loop-free übernehmen

Dieser Skill nimmt **keine** Screenshots auf. Der Integrationslauf aus
`test-loop-free` erzeugt sie bereits: `apps/<flavor>/test_driver/integration_test.dart`
legt die sechs PNGs des Hauptablaufs unter `apps/<flavor>/integration_test/screenshots/`
ab. Genau diese sechs Dateien sind die Quelle. Ein zweiter Screenshot-Lauf mit
eigenen Widget-Keys wäre eine Kopie mit eigener Fehlerquelle.

```bash
# Vorhandensein prüfen — ohne Quelle bricht der Skill hier ab.
# Erwartet werden genau diese sechs Namen:
#   01-start.png  02-aufnahme-laeuft.png  03-erster-eintrag.png
#   04-erweitert.png  05-liste.png  06-detail.png
ls apps/onira/integration_test/screenshots/

# Fehlen die Bilder, erst test-loop-free Stufe 1 laufen lassen:
#   flutter drive --driver=test_driver/integration_test.dart \
#     --target=integration_test/app_test.dart -d web-server --release \
#     --dart-define=FLAVOR=onira --dart-define=STT_ENGINE=web
```

Aus `metadata.yaml → screenshots.auswahl` ergibt sich, welche der sechs Bilder in
den Store gehen und in welcher Reihenfolge. Play zeigt sie in Dateinamen-Ordnung,
deshalb bleibt das Präfix `01-` bis `06-` erhalten. Auswertung und Export kommen
im Integrationslauf nicht vor und tauchen deshalb auch im Store nicht auf — wer
sie zeigen will, erweitert zuerst den Lauf in `test-loop-free`.

### Schritt 5 — Skalierwerkzeug anlegen

```yaml
# tool/pubspec.yaml
name: fabrik_tools
description: Werkzeuge der App-Fabrik. Kein Bestandteil eines App-Builds.
publish_to: none
environment:
  sdk: ">=3.4.0 <4.0.0"
dependencies:
  image: ^4.2.0
  path: ^1.9.0
  yaml: ^3.1.2
```

```dart
// tool/store_images.dart
// Skaliert die von test-loop-free erzeugten Screenshots aus
// apps/<flavor>/integration_test/screenshots/ in die von Google Play
// geforderten Formate. Nimmt selbst keine Bilder auf. Aufruf:
//   dart pub get --directory tool
//   dart run tool/store_images.dart --flavor=onira --hintergrund=101018
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Die sechs Bilder, die der Integrationslauf von test-loop-free erzeugt.
/// Rückfallliste, falls metadata.yaml keine Auswahl nennt. Auswertung und
/// Export kommen im Lauf nicht vor und stehen deshalb auch hier nicht.
const standardAuswahl = <String>[
  '01-start',
  '02-aufnahme-laeuft',
  '03-erster-eintrag',
  '04-erweitert',
  '05-liste',
  '06-detail',
];

class Format {
  const Format(this.ordner, this.breite, this.hoehe);
  final String ordner;
  final int breite;
  final int hoehe;
}

const formate = <Format>[
  Format('telefon', 1080, 1920),
  Format('tablet-7', 1200, 1920),
  Format('tablet-10', 1600, 2560),
];

const featureBreite = 1024;
const featureHoehe = 500;

int main(List<String> args) {
  final arg = <String, String>{};
  for (final a in args) {
    final i = a.indexOf('=');
    if (a.startsWith('--') && i > 0) arg[a.substring(2, i)] = a.substring(i + 1);
  }
  final flavor = arg['flavor'];
  if (flavor == null) {
    stderr.writeln('FEHLT: --flavor=<name>');
    return 2;
  }
  final quelle =
      Directory(arg['quelle'] ?? 'apps/$flavor/integration_test/screenshots');
  final ziel = Directory(arg['ziel'] ?? 'apps/$flavor/store/screenshots');
  final hg = _farbe(arg['hintergrund'] ?? '101018');
  final titel = arg['titel'] ?? flavor;

  if (!quelle.existsSync()) {
    stderr.writeln('FEHLT: ${quelle.path} — erst test-loop-free Stufe 1 laufen lassen.');
    return 2;
  }

  // Reihenfolge und Auswahl stammen aus metadata.yaml, nicht aus der
  // Verzeichnisauflistung. Damit bestimmt die Quelle, was in den Store geht.
  final auswahl = _auswahl(flavor);
  final rohbilder = <File>[];
  for (final name in auswahl) {
    final f = File(p.join(quelle.path, '$name.png'));
    if (!f.existsSync()) {
      stderr.writeln('FEHLT: ${f.path} — metadata.yaml nennt "$name", '
          'der Integrationslauf hat es nicht erzeugt.');
      return 2;
    }
    rohbilder.add(f);
  }

  if (rohbilder.length < 2) {
    stderr.writeln('FEHLT: mindestens 2 Screenshots, gefunden ${rohbilder.length}. '
        'Play verlangt mindestens 2 Telefon-Screenshots.');
    return 2;
  }

  for (final f in formate) {
    final d = Directory(p.join(ziel.path, f.ordner))..createSync(recursive: true);
    for (final roh in rohbilder) {
      final quellBild = img.decodePng(roh.readAsBytesSync());
      if (quellBild == null) {
        stderr.writeln('FEHLER: ${roh.path} ist kein lesbares PNG.');
        return 3;
      }
      final leinwand = _leinwand(f.breite, f.hoehe, hg);
      _einpassen(leinwand, quellBild, rand: (f.breite * 0.04).round());
      final name = p.basenameWithoutExtension(roh.path);
      File(p.join(d.path, '$name.png'))
          .writeAsBytesSync(img.encodePng(leinwand.convert(numChannels: 3)));
    }
    stdout.writeln('OK  ${f.ordner}: ${rohbilder.length} Bilder ${f.breite}x${f.hoehe}');
  }

  // Feature-Grafik: exakt 1024x500, 24 Bit, ohne Alphakanal.
  final erstes = img.decodePng(rohbilder.first.readAsBytesSync())!;
  final feature = _leinwand(featureBreite, featureHoehe, hg);
  final schmal = img.copyResize(erstes,
      height: (featureHoehe * 0.86).round(), interpolation: img.Interpolation.cubic);
  img.compositeImage(feature, schmal,
      dstX: featureBreite - schmal.width - 64,
      dstY: (featureHoehe - schmal.height) ~/ 2);
  img.drawString(feature, titel,
      font: img.arial48, x: 64, y: featureHoehe ~/ 2 - 24, color: img.ColorRgb8(245, 245, 250));
  Directory(ziel.path).createSync(recursive: true);
  File(p.join(ziel.path, 'feature-grafik.png'))
      .writeAsBytesSync(img.encodePng(feature.convert(numChannels: 3)));
  stdout.writeln('OK  feature-grafik.png ${featureBreite}x$featureHoehe');
  return 0;
}

/// Liest metadata.yaml → screenshots.auswahl. Fehlt der Eintrag, gilt die
/// Standardliste — dieselben sechs Namen, die test-loop-free erzeugt.
List<String> _auswahl(String flavor) {
  final datei = File('apps/$flavor/store/metadata.yaml');
  if (!datei.existsSync()) return standardAuswahl;
  final meta = loadYaml(datei.readAsStringSync()) as YamlMap;
  final liste = (meta['screenshots'] as YamlMap?)?['auswahl'] as YamlList?;
  if (liste == null || liste.isEmpty) return standardAuswahl;
  return liste.map((e) => e.toString()).toList();
}

img.Image _leinwand(int b, int h, img.ColorRgb8 farbe) {
  final bild = img.Image(width: b, height: h, numChannels: 3);
  img.fill(bild, color: farbe);
  return bild;
}

void _einpassen(img.Image leinwand, img.Image quelle, {required int rand}) {
  final maxB = leinwand.width - 2 * rand;
  final maxH = leinwand.height - 2 * rand;
  final skala = (maxB / quelle.width) < (maxH / quelle.height)
      ? maxB / quelle.width
      : maxH / quelle.height;
  final neu = img.copyResize(quelle,
      width: (quelle.width * skala).round(),
      height: (quelle.height * skala).round(),
      interpolation: img.Interpolation.cubic);
  img.compositeImage(leinwand, neu,
      dstX: (leinwand.width - neu.width) ~/ 2,
      dstY: (leinwand.height - neu.height) ~/ 2);
}

img.ColorRgb8 _farbe(String hex) {
  final h = hex.replaceAll('#', '').padRight(6, '0');
  return img.ColorRgb8(
    int.parse(h.substring(0, 2), radix: 16),
    int.parse(h.substring(2, 4), radix: 16),
    int.parse(h.substring(4, 6), radix: 16),
  );
}
```

Ohne Dart geht dasselbe mit ImageMagick, das auf den GitHub-Runnern vorinstalliert ist:

```bash
for NAME in 01-start 02-aufnahme-laeuft 03-erster-eintrag 04-erweitert 05-liste 06-detail; do
  magick "apps/onira/integration_test/screenshots/$NAME.png" \
    -resize 1080x1920 -background '#101018' -gravity center -extent 1080x1920 \
    "apps/onira/store/screenshots/telefon/$NAME.png"
done
```

### Schritt 6 — Zeichenzähl-Prüfung als Test

```dart
// apps/onira/test/store_texte_test.dart
// Bricht, sobald ein Store-Text die Play-Grenze reißt oder die
// Data-Safety-Angaben nicht mehr zum tatsächlich eingehängten Monetarisierungs-
// Verhalten passen. Gefragt wird die Registrierung, nie ein Schalter —
// ARCHITEKTUR.md §5.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_base/shared_base.dart';
import 'package:yaml/yaml.dart';

const _flavor = 'onira';

String _lies(String pfad) {
  final f = File(pfad);
  expect(f.existsSync(), isTrue, reason: 'Datei fehlt: $pfad');
  return f.readAsStringSync().trim();
}

void main() {
  setUpAll(() async {
    // Registrierung hochfahren. Danach beantwortet die Schnittstelle selbst,
    // ob Werbung und Käufe tatsächlich eingehängt sind.
    await registerMonetize();
  });

  group('Store-Texte $_flavor', () {
    test('Titel höchstens 30 Zeichen und einzeilig', () {
      final t = _lies('store/de-DE/titel.txt');
      expect(t.length, lessThanOrEqualTo(30),
          reason: 'Titel hat ${t.length} Zeichen, Play erlaubt 30: "$t"');
      expect(t.contains('\n'), isFalse, reason: 'Titel muss einzeilig sein');
      expect(t.isNotEmpty, isTrue);
    });

    test('Kurzbeschreibung höchstens 80 Zeichen und einzeilig', () {
      final k = _lies('store/de-DE/kurzbeschreibung.txt');
      expect(k.length, lessThanOrEqualTo(80),
          reason: 'Kurzbeschreibung hat ${k.length} Zeichen, Play erlaubt 80');
      expect(k.contains('\n'), isFalse);
      expect(k.isNotEmpty, isTrue);
    });

    test('Langbeschreibung höchstens 4000 Zeichen', () {
      final l = _lies('store/de-DE/langbeschreibung.txt');
      expect(l.length, lessThanOrEqualTo(4000),
          reason: 'Langbeschreibung hat ${l.length} Zeichen, Play erlaubt 4000');
      expect(l.length, greaterThan(200), reason: 'Langbeschreibung ist ein Stumpf');
    });

    test('kein Platzhaltertext', () {
      for (final name in const ['titel', 'kurzbeschreibung', 'langbeschreibung']) {
        final t = _lies('store/de-DE/$name.txt').toLowerCase();
        for (final verboten in const ['lorem', 'tbd', 'todo', 'xxx', 'platzhalter']) {
          expect(t.contains(verboten), isFalse,
              reason: '$name.txt enthält Platzhalter "$verboten"');
        }
      }
    });

    test('Datenschutzerklärung vorhanden und nennt die Paket-ID', () {
      final d = _lies('store/datenschutz.md');
      expect(d.contains('$kBrand.$_flavor'), isTrue,
          reason: 'datenschutz.md muss $kBrand.$_flavor nennen');
      expect(d.length, greaterThan(500));
    });

    test('metadata.yaml ist die Quelle und deckt sich mit store/de-DE', () {
      final meta = loadYaml(_lies('store/metadata.yaml')) as YamlMap;
      expect((meta['titel'] as String).trim(), equals(_lies('store/de-DE/titel.txt')),
          reason: 'store/de-DE ist Erzeugnis — tool/store_metadata.dart erneut laufen lassen');
      expect((meta['kurzbeschreibung'] as String).trim(),
          equals(_lies('store/de-DE/kurzbeschreibung.txt')));
      expect(meta['datenschutz']['url'].toString().endsWith('/datenschutz.html'), isTrue,
          reason: 'Die Pflicht-URL muss auf die ausgelieferte HTML-Seite zeigen');
    });

    test('Datenschutzseite wird vom Web-Build ausgeliefert', () {
      expect(File('web/datenschutz.html').existsSync(), isTrue,
          reason: 'dart run tool/datenschutz_html.dart --flavor=$_flavor ausführen');
    });

    test('Data-Safety-Angaben passen zur Registrierung', () {
      final y = loadYaml(_lies('store/data_safety.yaml')) as YamlMap;
      expect(y['paket_id'], equals('$kBrand.$_flavor'));

      final werbungAktiv = Registry.instance.get<AdSurface>().isEnabled;
      final kaeufeAktiv = Registry.instance.get<Purchases>().isEnabled;

      expect(y['gekoppelt_an']['ads_enabled'], equals(werbungAktiv),
          reason: 'data_safety.yaml und die eingehängte AdSurface stehen auseinander');
      expect(y['gekoppelt_an']['billing_enabled'], equals(kaeufeAktiv),
          reason: 'data_safety.yaml und die eingehängte Purchases stehen auseinander');

      final werbeId = y['datentypen']['werbe_id']['erhoben'] as bool;
      expect(werbeId, equals(werbungAktiv),
          reason: 'Mit eingehängter Werbung MUSS die Werbe-ID als erhoben deklariert sein');
      final zahlung = y['datentypen']['zahlungsinformationen']['erhoben'] as bool;
      expect(zahlung, equals(kaeufeAktiv),
          reason: 'Mit eingehängter Kaufabwicklung MÜSSEN Zahlungsdaten deklariert sein');
    });

    test('Markenpräfix ist de.zeta', () {
      expect(kBrand, equals('de.zeta'));
    });
  });

  group('Screenshots $_flavor', () {
    // Genau die sechs Bilder, die der Integrationslauf von test-loop-free
    // erzeugt. Auswertung und Export besucht er nicht.
    const erwartet = <String>[
      '01-start',
      '02-aufnahme-laeuft',
      '03-erster-eintrag',
      '04-erweitert',
      '05-liste',
      '06-detail',
    ];

    test('metadata.yaml nennt nur Bilder, die der Lauf erzeugt', () {
      final meta = loadYaml(_lies('store/metadata.yaml')) as YamlMap;
      final auswahl = (meta['screenshots']['auswahl'] as YamlList)
          .map((e) => e.toString())
          .toList();
      for (final name in auswahl) {
        expect(erwartet.contains(name), isTrue,
            reason: '"$name" wird von test-loop-free nicht erzeugt — '
                'erst den Integrationslauf erweitern, dann hier eintragen');
      }
      expect(auswahl.length, greaterThanOrEqualTo(2));
    });

    test('mindestens zwei Telefon-Screenshots im Repo', () {
      final d = Directory('store/screenshots/telefon');
      if (!d.existsSync()) {
        markTestSkipped('Screenshots noch nicht aus der CI gezogen');
        return;
      }
      final png = d.listSync().where((f) => f.path.endsWith('.png')).length;
      expect(png, greaterThanOrEqualTo(2));
    });
  });
}
```

### Schritt 7 — CI-Workflow

```yaml
# .github/workflows/store-assets.yml
name: store-assets

on:
  workflow_dispatch:
    inputs:
      flavor:
        description: Flavor, z. B. onira
        required: true
        type: string
  push:
    paths:
      - 'apps/*/store/**'
      - 'apps/*/integration_test/**'

jobs:
  ablage:
    name: Play-Ablage erzeugen und prüfen
    runs-on: ubuntu-latest
    env:
      FLAVOR: ${{ inputs.flavor || 'onira' }}
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: {channel: stable}
      - run: dart pub global activate melos && melos bootstrap
      - name: store/de-DE aus metadata.yaml erzeugen
        run: |
          dart pub get --directory tool
          dart run tool/store_metadata.dart --flavor=$FLAVOR
          dart run tool/datenschutz_html.dart --flavor=$FLAVOR
      - name: Zeichenlängen prüfen
        run: flutter test test/store_texte_test.dart
        working-directory: apps/${{ env.FLAVOR }}

  bilder:
    name: Screenshots aus test-loop-free in Play-Formate bringen
    runs-on: ubuntu-latest
    env:
      FLAVOR: ${{ inputs.flavor || 'onira' }}
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: {channel: stable}
      - uses: nanasess/setup-chromedriver@v2
      - run: dart pub global activate melos && melos bootstrap
      - name: Screenshots erzeugen, falls noch keine im Repo liegen
        # Der Lauf gehört test-loop-free. Hier wird er nur ausgelöst, nicht
        # neu definiert — Treiber und Ziel stammen von dort.
        working-directory: apps/${{ env.FLAVOR }}
        run: |
          if [ ! -d integration_test/screenshots ]; then
            chromedriver --port=4444 &
            flutter drive \
              --driver=test_driver/integration_test.dart \
              --target=integration_test/app_test.dart \
              -d web-server --release \
              --dart-define=FLAVOR=${{ env.FLAVOR }} \
              --dart-define=STT_ENGINE=web \
              --browser-dimension=1080,1920 \
              --web-browser-flag=--headless=new \
              --web-browser-flag=--disable-gpu
          fi
      - name: In Play-Formate skalieren
        run: |
          dart pub get --directory tool
          dart run tool/store_images.dart \
            --flavor=${{ env.FLAVOR }} \
            --quelle=apps/${{ env.FLAVOR }}/integration_test/screenshots \
            --ziel=apps/${{ env.FLAVOR }}/store/screenshots \
            --titel=${{ env.FLAVOR }}
      - uses: actions/upload-artifact@v4
        with:
          name: store-screenshots-${{ env.FLAVOR }}
          path: apps/${{ env.FLAVOR }}/store/screenshots
          retention-days: 30
```

### Schritt 8 — Screenshots vom Handy ins Repo ziehen

```bash
gh run list --workflow=store-assets.yml --limit 1
gh run download --name store-screenshots-onira --dir apps/onira/store/screenshots
git add apps/onira/store && git commit -m "chore(onira): Store-Material aktualisiert" && git push
```

### Schritt 9 — Ansehen ohne Bildbetrachter

Die Bilder liegen jetzt im Repo und sind auf dem iPhone direkt in der
GitHub-Weboberfläche anzusehen. Zusätzlich landet die Artefakt-ZIP unter
`Actions → store-assets → Artifacts` und ist in Safari herunterladbar.

## Abbruchkriterien

Der Skill stoppt und fragt, statt zu raten, wenn:

- der Flavor nicht als Verzeichnis `apps/<flavor>/` existiert → Nutzer fragen,
  ob `app-derive` zuerst laufen soll.
- `apps/<flavor>/store/metadata.yaml` fehlt → `app-derive` legt es an. Dieser
  Skill erfindet die Quelle nicht, er füllt sie.
- eine der fünf Angaben aus Schritt 1 fehlt oder mehrdeutig ist.
- `apps/<flavor>/integration_test/screenshots/` ist leer oder fehlt → auf
  `test-loop-free`, Stufe 1 verweisen und stoppen. Dieser Skill nimmt keine
  eigenen Screenshots auf und erfindet keine Widget-Keys.
- weniger als zwei verwertbare Screenshots vorliegen — Play verlangt mindestens
  zwei Telefon-Screenshots.
- `metadata.yaml → screenshots.auswahl` nennt einen Namen, den der Lauf nicht
  erzeugt (etwa `05-auswertung` oder `06-export`) → stoppen. Erst wird der
  Integrationslauf in `test-loop-free` um den Bildschirm erweitert, dann die
  Auswahl ergänzt. Der Skill erfindet kein Bild.
- der Titel nach dreimaliger Kürzung nicht unter 30 Zeichen zu bringen ist, ohne
  den Namen zu verstümmeln → Nutzer entscheiden lassen.
- die Registrierung eine echte `AdSurface` oder `Purchases` einhängt: dann müssen
  Werbe-ID und Zahlungsangaben in `data_safety.yaml` deklariert werden. Falsche
  Data-Safety-Angaben sind ein Sperrgrund — hier wird nie geraten.

## Fertig, wenn

- [ ] `apps/<flavor>/store/metadata.yaml` ist vollständig gefüllt und trägt keine Gerüstwerte mehr.
- [ ] `apps/<flavor>/store/de-DE/titel.txt` ist aus `metadata.yaml` erzeugt und hat höchstens 30 Zeichen.
- [ ] `apps/<flavor>/store/de-DE/kurzbeschreibung.txt` ist erzeugt und hat höchstens 80 Zeichen.
- [ ] `apps/<flavor>/store/de-DE/langbeschreibung.txt` ist erzeugt und hat höchstens 4000 Zeichen.
- [ ] `apps/<flavor>/store/datenschutz.md` existiert und nennt `de.zeta.<flavor>`.
- [ ] `apps/<flavor>/web/datenschutz.html` existiert und die URL aus `metadata.yaml`
      ist nach dem Web-Deploy wirklich erreichbar.
- [ ] `apps/<flavor>/store/data_safety.yaml` deckt sich mit dem, was die Registrierung
      für `AdSurface` und `Purchases` einhängt.
- [ ] `flutter test test/store_texte_test.dart` läuft in `apps/<flavor>/` ohne Befund durch.
- [ ] `metadata.yaml → screenshots.auswahl` nennt ausschliesslich Namen aus
      `01-start`, `02-aufnahme-laeuft`, `03-erster-eintrag`, `04-erweitert`,
      `05-liste`, `06-detail`.
- [ ] `apps/<flavor>/store/screenshots/telefon/` enthält mindestens zwei PNG in 1080x1920.
- [ ] `apps/<flavor>/store/screenshots/tablet-7/` enthält dieselben Motive in 1200x1920.
- [ ] `apps/<flavor>/store/screenshots/tablet-10/` enthält dieselben Motive in 1600x2560.
- [ ] `apps/<flavor>/store/screenshots/feature-grafik.png` ist exakt 1024x500 und ohne Alphakanal.
- [ ] Der Workflow `store-assets.yml` ist grün gelaufen und hat das Artefakt abgelegt.
- [ ] Alles ist committet und gepusht.

## Beispielaufruf

```
Erzeuge das Store-Material für onira. Titel, Kurz- und Langbeschreibung auf
Deutsch, Datenschutzerklärung und Data-Safety-Angaben, und zieh die Screenshots
aus dem Integrationstest in allen Play-Formaten ins Repo.
```
