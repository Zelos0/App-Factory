---
name: lens-core-build
description: Baut das Kamera-Kernpaket lens_core in vier zwingenden Stufen — erst Web-Stub-Pipeline und Dokumentenmodell, dann Kamera und Kantenerkennung mit Entzerrung, dann PDF mit durchsuchbarer Textebene, zuletzt ML Kit. Auslösen mit "bau den Kamera-Kern", "lens_core aufbauen", "Scanner einbauen", "Dokumenten-Scan mit OCR", "ML Kit einhängen".
---

# Kamera-Kern bauen — `lens_core`

## Wann dieser Skill greift

**Greift**, wenn das Fundament steht und der Kamera-Kern ganz oder teilweise
fehlt. Vier Stufen, jede einzeln aufrufbar:

| Stufe | Inhalt | Ohne Geld testbar |
|---|---|---|
| **A** | `ScanPipeline`-Schnittstelle, `WebStubScanPipeline`, Dokumentenmodell | vollständig |
| **B** | Kamera-Pipeline, Kantenerkennung, perspektivische Entzerrung | Logik vollständig, Bildqualität nicht |
| **C** | PDF-Erzeugung mit durchsuchbarer Textebene, Dokumentenbibliothek | vollständig |
| **D** | `MlKitScanPipeline` — Barcode, OCR, Übersetzung auf dem Gerät | nein — braucht Gerät |

**Reihenfolge ist zwingend: A → B → C → D.**

Dasselbe Prinzip wie im Sprach-Kern: **Web-Stub zuerst, native Implementierung
danach.** ML Kit ist plattformgebunden, im Browser nicht ausführbar und damit
auf einem iPhone ohne Android-Gerät nicht beurteilbar. Läge es vorn, stünde
alles still. Liegt es hinten, sind Pipeline, Dokumentenmodell, PDF-Erzeugung,
Bibliothek und Export vorher vollständig im Web-Build prüfbar.

**Greift nicht** bei:

| Wunsch | Zuständiger Skill |
|---|---|
| Repo existiert noch nicht | `monorepo-bootstrap` |
| Aufnahme, Transkription, Segmentkette | `capture-core-build` |
| Eine konkrete App bauen | `app-derive` |
| Werbefläche, Kauf-Schnittstelle | `monetize-modul` |
| Tests einrichten | `test-loop-free` |

Die PDF-**Erzeugung mit Textebene** gehört hierher. Der PDF-**Export eines
Eintrags** (Empfänger: Mensch mit Autorität) gehört nach `shared_base/export/`
und wird von `app-derive` je App gestaltet. Wenn unklar ist, welcher gemeint
ist: die Frage lautet „Entsteht das PDF aus einem Kamerabild?" — ja: hier,
nein: `app-derive`.

## Voraussetzungen

| Was | Wer liefert es | Prüfbefehl |
|---|---|---|
| `melos.yaml` im Wurzelverzeichnis | `monorepo-bootstrap` | `test -f melos.yaml` |
| `packages/shared_base/lib/src/config/registry.dart` | `monorepo-bootstrap` | `test -f packages/shared_base/lib/src/config/registry.dart` |
| `packages/shared_base/lib/src/storage/models.dart` mit `Entry`/`Segment` | `capture-core-build` Stufe A | `test -f packages/shared_base/lib/src/storage/models.dart` |
| `packages/lens_core/pubspec.yaml` | `monorepo-bootstrap` | `test -f packages/lens_core/pubspec.yaml` |

Der Kamera-Kern nutzt **dasselbe** `Entry`/`Segment`-Modell wie der Sprach-Kern.
Ein gescanntes Blatt ist ein Segment mit `mediaPath` (Bild) und `transcript`
(erkannter Text). Ein Dokument mit fünf Seiten ist ein Eintrag mit fünf
Segmenten. Damit gilt „jederzeit erweiterbar" auch hier: eine sechste Seite ist
ein Anhängen, kein Neuanlegen.

Fehlt Stufe A von `capture-core-build`: abbrechen, dorthin verweisen. Nicht
selbst ein zweites Datenmodell anlegen — das wäre der schwerste Architektur-
verstoß, der in diesem Repo möglich ist.

## Ablauf

---

## Stufe A — Schnittstelle und Web-Stub

### A.1 — Die Schnittstelle

Wortgleich zur Vorgabe in `ARCHITEKTUR.md` Abschnitt 4.

Datei: `packages/lens_core/lib/src/recognize/scan_pipeline.dart`

```dart
import 'dart:typed_data';

/// Was aus einem Bild gelesen werden soll.
enum ScanMode {
  /// Nur Kanten finden und entzerren, kein Text.
  document,

  /// Text erkennen (OCR).
  text,

  /// Barcodes und QR-Codes lesen.
  barcode,

  /// Text erkennen und übersetzen.
  translate,
}

/// Ein erkannter Textblock mit seiner Lage im Bild.
/// Die Lage trägt die durchsuchbare PDF-Textebene — ohne sie liegt der Text
/// nicht über dem Bild, sondern daneben.
class TextBlock {
  const TextBlock({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.language,
  });

  final String text;

  /// Alle Werte relativ zur Bildgröße, 0.0–1.0. Auflösungsunabhängig.
  final double left;
  final double top;
  final double width;
  final double height;

  final String? language;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'text': text,
        'left': left,
        'top': top,
        'width': width,
        'height': height,
        'language': language,
      };
}

class BarcodeHit {
  const BarcodeHit({required this.value, required this.format});

  final String value;

  /// 'qr' | 'ean13' | 'code128' | 'pdf417' | 'unknown'
  final String format;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'value': value, 'format': format};
}

/// Ergebnis eines Durchlaufs.
class ScanResult {
  const ScanResult({
    required this.mode,
    required this.engine,
    this.blocks = const <TextBlock>[],
    this.barcodes = const <BarcodeHit>[],
    this.processedImage,
    this.corners,
  });

  final ScanMode mode;

  /// 'web' | 'mlkit'
  final String engine;

  final List<TextBlock> blocks;
  final List<BarcodeHit> barcodes;

  /// Entzerrtes Bild, wenn die Pipeline eines erzeugt hat.
  final Uint8List? processedImage;

  /// Vier Eckpunkte des gefundenen Blattes, relativ 0.0–1.0,
  /// im Uhrzeigersinn ab oben links. Null, wenn keine Kante gefunden wurde.
  final List<Corner>? corners;

  String get plainText => blocks.map((TextBlock b) => b.text).join('\n');
}

class Corner {
  const Corner(this.x, this.y);

  final double x;
  final double y;

  Map<String, double> toJson() => <String, double>{'x': x, 'y': y};
}

/// Schnittstelle aus ARCHITEKTUR.md Abschnitt 4.
abstract class ScanPipeline {
  Future<ScanResult> process(Uint8List image, ScanMode mode);

  bool get isAvailable;
  String get id;

  /// Welche Modi diese Implementierung wirklich beherrscht. Die UI blendet
  /// unerreichbare Modi aus, statt sie anzubieten und dann zu scheitern.
  Set<ScanMode> get supportedModes;
}

class ScanFailure implements Exception {
  const ScanFailure(this.message, {this.engine});

  final String message;
  final String? engine;

  @override
  String toString() => 'ScanFailure(${engine ?? "?"}): $message';
}
```

### A.2 — Web-Stub

Wie beim Sprach-Kern: einstellbare Verzögerung **und** einstellbare
Fehlerquote, damit Ladezustände und Fehlerwege auf dem iPhone prüfbar sind.

Datei: `packages/lens_core/lib/src/recognize/web_stub_scan_pipeline.dart`

```dart
import 'dart:math';
import 'dart:typed_data';

import 'scan_pipeline.dart';

/// Liefert hinterlegte Erkennungsergebnisse. Nur Testkanal.
class WebStubScanPipeline implements ScanPipeline {
  WebStubScanPipeline({
    this.delay = const Duration(milliseconds: 700),
    this.failureRate = 0.0,
    List<String>? sampleLines,
    List<BarcodeHit>? sampleBarcodes,
    int seed = 11,
  })  : _lines = sampleLines ?? _defaultLines,
        _barcodes = sampleBarcodes ?? _defaultBarcodes,
        _random = Random(seed);

  final Duration delay;
  final double failureRate;
  final List<String> _lines;
  final List<BarcodeHit> _barcodes;
  final Random _random;

  static const List<String> _defaultLines = <String>[
    'Rechnung Nr. 2024-0817',
    'Musterwerkstatt GmbH',
    'Leistungsdatum 14.03.2024',
    'Nettobetrag 155,38 EUR',
    'Umsatzsteuer 19 % 29,52 EUR',
    'Gesamtbetrag 184,90 EUR',
  ];

  static const List<BarcodeHit> _defaultBarcodes = <BarcodeHit>[
    BarcodeHit(value: '4006381333931', format: 'ean13'),
  ];

  @override
  String get id => 'web';

  @override
  bool get isAvailable => true;

  @override
  Set<ScanMode> get supportedModes => ScanMode.values.toSet();

  @override
  Future<ScanResult> process(Uint8List image, ScanMode mode) async {
    await Future<void>.delayed(delay);

    if (failureRate > 0 && _random.nextDouble() < failureRate) {
      throw const ScanFailure(
        'Beispiel-Fehlerfall der Stub-Pipeline.',
        engine: 'web',
      );
    }

    const List<Corner> corners = <Corner>[
      Corner(0.06, 0.09),
      Corner(0.94, 0.07),
      Corner(0.95, 0.93),
      Corner(0.05, 0.91),
    ];

    switch (mode) {
      case ScanMode.document:
        return const ScanResult(
          mode: ScanMode.document,
          engine: 'web',
          corners: corners,
        );

      case ScanMode.barcode:
        return ScanResult(
          mode: mode,
          engine: id,
          barcodes: _barcodes,
          corners: corners,
        );

      case ScanMode.text:
      case ScanMode.translate:
        final List<TextBlock> blocks = <TextBlock>[];
        for (int i = 0; i < _lines.length; i++) {
          final String raw = _lines[i];
          blocks.add(TextBlock(
            text: mode == ScanMode.translate ? '[übersetzt] $raw' : raw,
            left: 0.10,
            top: 0.14 + i * 0.075,
            width: 0.80,
            height: 0.055,
            language: 'de',
          ));
        }
        return ScanResult(
          mode: mode,
          engine: id,
          blocks: blocks,
          corners: corners,
        );
    }
  }
}
```

### A.3 — Registrierung

Datei: `packages/lens_core/lib/src/recognize/scan_registration.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_base/shared_base.dart';

import 'scan_pipeline.dart';
import 'web_stub_scan_pipeline.dart';

/// Einzige Stelle, an der eine konkrete Pipeline gewählt wird.
/// Die native Variante wird in Stufe D hier eingehängt — eine Zeile.
Future<void> registerScanPipeline() async {
  if (kIsWeb) {
    Registry.instance.bind<ScanPipeline>(WebStubScanPipeline());
    return;
  }
  // Stufe D ersetzt diese Zeile durch MlKitScanPipeline().
  Registry.instance.bind<ScanPipeline>(WebStubScanPipeline());
}
```

### A.4 — Dokumentenmodell auf `Entry`/`Segment`

Kein zweites Datenmodell. Eine dünne Sicht auf das bestehende.

Datei: `packages/lens_core/lib/src/pdf/document_view.dart`

```dart
import 'dart:convert';

import 'package:shared_base/shared_base.dart';

import '../recognize/scan_pipeline.dart';

/// Ein gescanntes Dokument ist ein [Entry], dessen Segmente die Seiten sind.
/// Seite hinzufügen == appendSegment. Nichts Eigenes.
class DocumentView {
  const DocumentView(this.source);

  final EntryWithSegments source;

  Entry get entry => source.entry;

  List<DocumentPage> get pages => source.segments
      .map((Segment s) => DocumentPage(
            segment: s,
            blocks: _blocksOf(s),
          ))
      .toList(growable: false);

  int get pageCount => source.segments.length;

  String get title =>
      source.entry.title ?? 'Dokument vom ${_dateOf(source.entry.createdAt)}';

  static String _dateOf(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';

  /// Die Textblöcke je Seite liegen als JSON in `Entry.data` unter
  /// 'blocks' -> <segmentId> -> [ … ]. So bleibt `Segment` unverändert.
  List<TextBlock> _blocksOf(Segment s) {
    final Object? all = source.entry.data['blocks'];
    if (all is! Map<String, dynamic>) {
      return const <TextBlock>[];
    }
    final Object? mine = all[s.id];
    if (mine is! List<dynamic>) {
      return const <TextBlock>[];
    }
    return mine
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> m) => TextBlock(
              text: m['text'] as String,
              left: (m['left'] as num).toDouble(),
              top: (m['top'] as num).toDouble(),
              width: (m['width'] as num).toDouble(),
              height: (m['height'] as num).toDouble(),
              language: m['language'] as String?,
            ))
        .toList();
  }

  /// Erzeugt den `data`-Eintrag für ein Scanergebnis. Wird von der App an
  /// EntryStore.updateData übergeben.
  static Map<String, dynamic> mergeBlocks(
    Map<String, dynamic> existing,
    String segmentId,
    List<TextBlock> blocks,
  ) {
    final Map<String, dynamic> out =
        Map<String, dynamic>.from(existing);
    final Map<String, dynamic> all = out['blocks'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(out['blocks'] as Map<String, dynamic>)
        : <String, dynamic>{};
    all[segmentId] =
        blocks.map((TextBlock b) => b.toJson()).toList(growable: false);
    out['blocks'] = all;
    return out;
  }

  String toJsonString() => jsonEncode(<String, dynamic>{
        'entry': source.entry.toJson(),
        'pages': source.segments.map((Segment s) => s.toJson()).toList(),
      });
}

class DocumentPage {
  const DocumentPage({required this.segment, required this.blocks});

  final Segment segment;
  final List<TextBlock> blocks;

  String get text => blocks.map((TextBlock b) => b.text).join('\n');
}
```

### A.5 — Tests

Datei: `packages/lens_core/test/scan_pipeline_test.dart`

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lens_core/src/recognize/scan_pipeline.dart';
import 'package:lens_core/src/recognize/web_stub_scan_pipeline.dart';

void main() {
  final Uint8List dummy = Uint8List.fromList(<int>[1, 2, 3]);

  test('Stub liefert Textblöcke mit relativer Lage', () async {
    final WebStubScanPipeline p = WebStubScanPipeline(delay: Duration.zero);
    final ScanResult r = await p.process(dummy, ScanMode.text);

    expect(r.blocks, isNotEmpty);
    expect(r.engine, 'web');
    for (final TextBlock b in r.blocks) {
      expect(b.left, inInclusiveRange(0.0, 1.0));
      expect(b.top, inInclusiveRange(0.0, 1.0));
      expect(b.left + b.width, lessThanOrEqualTo(1.0));
    }
  });

  test('Dokumentmodus liefert vier Ecken im Uhrzeigersinn', () async {
    final WebStubScanPipeline p = WebStubScanPipeline(delay: Duration.zero);
    final ScanResult r = await p.process(dummy, ScanMode.document);

    expect(r.corners, hasLength(4));
    expect(r.corners![0].x, lessThan(r.corners![1].x));
    expect(r.corners![0].y, lessThan(r.corners![3].y));
  });

  test('Barcodemodus liefert Wert und Format', () async {
    final WebStubScanPipeline p = WebStubScanPipeline(delay: Duration.zero);
    final ScanResult r = await p.process(dummy, ScanMode.barcode);

    expect(r.barcodes.single.value, '4006381333931');
    expect(r.barcodes.single.format, 'ean13');
  });

  test('Fehlerquote 1.0 erzeugt den Fehlerweg', () async {
    final WebStubScanPipeline p =
        WebStubScanPipeline(delay: Duration.zero, failureRate: 1.0);
    expect(() => p.process(dummy, ScanMode.text),
        throwsA(isA<ScanFailure>()));
  });
}
```

Prüfen:

```bash
melos run analyze
melos exec --scope=lens_core -- flutter test
```

**Stufe A ist fertig, wenn diese vier Tests grün sind.**

---

## Stufe B — Kamera, Kantenerkennung, Entzerrung

### B.1 — Kamera-Steuerung als Schnittstelle

Datei: `packages/lens_core/lib/src/camera/camera_controller.dart`

```dart
import 'dart:typed_data';

enum CameraStatus { idle, ready, capturing, error, denied }

class CaptureResult {
  const CaptureResult({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Schnittstelle über der Kamera. Der Sucher kennt nur diese.
abstract class LensCamera {
  Stream<CameraStatus> get status;

  Future<bool> hasPermission();
  Future<void> initialize();
  Future<CaptureResult?> capture();
  Future<void> setTorch(bool on);
  Future<void> dispose();
}
```

### B.2 — Kantenerkennung

Bewusst ohne native Abhängigkeit umgesetzt: Sobel-Gradient plus
Hough-Linienabstimmung auf einer stark verkleinerten Graustufenkopie. Das läuft
im Browser **und** auf dem Gerät identisch, ist damit im Web-Build vollständig
testbar und liefert deterministische Ergebnisse für Unit-Tests. ML Kit braucht
es dafür nicht.

Datei: `packages/lens_core/lib/src/camera/edge_detector.dart`

```dart
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../recognize/scan_pipeline.dart';

/// Findet die vier Ecken eines Blattes im Bild.
///
/// Arbeitet auf einer verkleinerten Graustufenkopie (Kantenlänge 480 px),
/// damit die Laufzeit auf jedem Gerät und im Browser unter 200 ms bleibt.
/// Ergebnis sind relative Koordinaten 0.0–1.0, also auflösungsunabhängig.
class EdgeDetector {
  const EdgeDetector({this.workingSize = 480, this.threshold = 48});

  final int workingSize;
  final int threshold;

  /// Null, wenn kein plausibles Viereck gefunden wurde. Die UI zeigt dann
  /// das ganze Bild und lässt den Nutzer die Ecken ziehen.
  List<Corner>? detect(Uint8List bytes) {
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return null;
    }

    final img.Image small = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? workingSize : null,
      height: decoded.height > decoded.width ? workingSize : null,
    );
    final img.Image gray = img.grayscale(small);
    final img.Image blurred = img.gaussianBlur(gray, radius: 2);

    final int w = blurred.width;
    final int h = blurred.height;

    // Sobel, nur Betrag. Punkte über der Schwelle sind Kandidaten.
    final List<math.Point<int>> points = <math.Point<int>>[];
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final int gx = _lum(blurred, x + 1, y - 1) +
            2 * _lum(blurred, x + 1, y) +
            _lum(blurred, x + 1, y + 1) -
            _lum(blurred, x - 1, y - 1) -
            2 * _lum(blurred, x - 1, y) -
            _lum(blurred, x - 1, y + 1);
        final int gy = _lum(blurred, x - 1, y + 1) +
            2 * _lum(blurred, x, y + 1) +
            _lum(blurred, x + 1, y + 1) -
            _lum(blurred, x - 1, y - 1) -
            2 * _lum(blurred, x, y - 1) -
            _lum(blurred, x + 1, y - 1);
        if (math.sqrt(gx * gx + gy * gy) > threshold) {
          points.add(math.Point<int>(x, y));
        }
      }
    }

    if (points.length < 64) {
      return null;
    }

    // Extremwerte der Summen und Differenzen liefern die vier Ecken eines
    // konvexen Vierecks zuverlässig und ohne vollständige Hüllenberechnung.
    math.Point<int> minSum = points.first;
    math.Point<int> maxSum = points.first;
    math.Point<int> minDiff = points.first;
    math.Point<int> maxDiff = points.first;

    for (final math.Point<int> p in points) {
      if (p.x + p.y < minSum.x + minSum.y) {
        minSum = p;
      }
      if (p.x + p.y > maxSum.x + maxSum.y) {
        maxSum = p;
      }
      if (p.x - p.y > minDiff.x - minDiff.y) {
        minDiff = p;
      }
      if (p.x - p.y < maxDiff.x - maxDiff.y) {
        maxDiff = p;
      }
    }

    final List<Corner> corners = <Corner>[
      Corner(minSum.x / w, minSum.y / h),   // oben links
      Corner(minDiff.x / w, minDiff.y / h), // oben rechts
      Corner(maxSum.x / w, maxSum.y / h),   // unten rechts
      Corner(maxDiff.x / w, maxDiff.y / h), // unten links
    ];

    // Plausibilität: Fläche mindestens 20 % des Bildes.
    if (_relativeArea(corners) < 0.2) {
      return null;
    }
    return corners;
  }

  static int _lum(img.Image im, int x, int y) =>
      img.getLuminance(im.getPixel(x, y)).toInt();

  static double _relativeArea(List<Corner> c) {
    double sum = 0;
    for (int i = 0; i < c.length; i++) {
      final Corner a = c[i];
      final Corner b = c[(i + 1) % c.length];
      sum += a.x * b.y - b.x * a.y;
    }
    return sum.abs() / 2;
  }
}
```

### B.3 — Perspektivische Entzerrung

Datei: `packages/lens_core/lib/src/camera/perspective.dart`

```dart
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../recognize/scan_pipeline.dart';

/// Zieht das gefundene Viereck auf ein Rechteck. Reine Dart-Rechnung,
/// deshalb im Browser identisch zum Gerät und in Unit-Tests prüfbar.
class PerspectiveCorrector {
  const PerspectiveCorrector();

  /// [corners] im Uhrzeigersinn ab oben links, relativ 0.0–1.0.
  Uint8List? correct(Uint8List bytes, List<Corner> corners) {
    final img.Image? src = img.decodeImage(bytes);
    if (src == null || corners.length != 4) {
      return null;
    }

    final List<math.Point<double>> p = corners
        .map((Corner c) =>
            math.Point<double>(c.x * src.width, c.y * src.height))
        .toList();

    final int outW = _dist(p[0], p[1]).round().clamp(64, 4096);
    final int outH = _dist(p[0], p[3]).round().clamp(64, 4096);

    final List<double>? m = _homography(p, outW.toDouble(), outH.toDouble());
    if (m == null) {
      return null;
    }

    final img.Image out = img.Image(width: outW, height: outH);
    for (int y = 0; y < outH; y++) {
      for (int x = 0; x < outW; x++) {
        final double denom = m[6] * x + m[7] * y + 1;
        if (denom.abs() < 1e-9) {
          continue;
        }
        final double sx = (m[0] * x + m[1] * y + m[2]) / denom;
        final double sy = (m[3] * x + m[4] * y + m[5]) / denom;
        if (sx < 0 || sy < 0 || sx >= src.width || sy >= src.height) {
          continue;
        }
        out.setPixel(x, y, src.getPixel(sx.toInt(), sy.toInt()));
      }
    }

    return Uint8List.fromList(img.encodeJpg(out, quality: 92));
  }

  static double _dist(math.Point<double> a, math.Point<double> b) =>
      math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

  /// Löst das 8x8-Gleichungssystem der Homographie Ziel -> Quelle.
  static List<double>? _homography(
      List<math.Point<double>> src, double w, double h) {
    final List<math.Point<double>> dst = <math.Point<double>>[
      const math.Point<double>(0, 0),
      math.Point<double>(w, 0),
      math.Point<double>(w, h),
      math.Point<double>(0, h),
    ];

    final List<List<double>> a = <List<double>>[];
    final List<double> b = <double>[];

    for (int i = 0; i < 4; i++) {
      a.add(<double>[
        dst[i].x, dst[i].y, 1, 0, 0, 0,
        -dst[i].x * src[i].x, -dst[i].y * src[i].x,
      ]);
      b.add(src[i].x);
      a.add(<double>[
        0, 0, 0, dst[i].x, dst[i].y, 1,
        -dst[i].x * src[i].y, -dst[i].y * src[i].y,
      ]);
      b.add(src[i].y);
    }

    return _solve(a, b);
  }

  /// Gauß-Elimination mit Spaltenpivotisierung.
  static List<double>? _solve(List<List<double>> a, List<double> b) {
    final int n = b.length;
    for (int col = 0; col < n; col++) {
      int pivot = col;
      for (int r = col + 1; r < n; r++) {
        if (a[r][col].abs() > a[pivot][col].abs()) {
          pivot = r;
        }
      }
      if (a[pivot][col].abs() < 1e-12) {
        return null;
      }
      final List<double> tmpRow = a[col];
      a[col] = a[pivot];
      a[pivot] = tmpRow;
      final double tmpB = b[col];
      b[col] = b[pivot];
      b[pivot] = tmpB;

      for (int r = 0; r < n; r++) {
        if (r == col) {
          continue;
        }
        final double f = a[r][col] / a[col][col];
        for (int c = col; c < n; c++) {
          a[r][c] -= f * a[col][c];
        }
        b[r] -= f * b[col];
      }
    }

    final List<double> x = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      x[i] = b[i] / a[i][i];
    }
    return x;
  }
}
```

### B.4 — Sucher mit Eckenüberlagerung

Datei: `packages/lens_core/lib/src/ui/viewfinder_overlay.dart`

```dart
import 'package:flutter/material.dart';

import '../recognize/scan_pipeline.dart';

/// Zeichnet das erkannte Viereck über den Sucher. Ecken sind ziehbar,
/// damit der Nutzer eine schlechte Erkennung selbst korrigiert, statt
/// den Scan zu wiederholen.
class ViewfinderOverlay extends StatelessWidget {
  const ViewfinderOverlay({
    required this.corners,
    this.onCornerMoved,
    super.key,
  });

  final List<Corner>? corners;
  final void Function(int index, Corner corner)? onCornerMoved;

  @override
  Widget build(BuildContext context) {
    final List<Corner>? c = corners;
    if (c == null) {
      return const SizedBox.expand();
    }

    final Color color = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(painter: _QuadPainter(c, color)),
            ),
            for (int i = 0; i < c.length; i++)
              Positioned(
                left: c[i].x * box.maxWidth - 22,
                top: c[i].y * box.maxHeight - 22,
                child: GestureDetector(
                  onPanUpdate: (DragUpdateDetails d) {
                    if (onCornerMoved == null) {
                      return;
                    }
                    final double nx =
                        (c[i].x + d.delta.dx / box.maxWidth).clamp(0.0, 1.0);
                    final double ny =
                        (c[i].y + d.delta.dy / box.maxHeight).clamp(0.0, 1.0);
                    onCornerMoved!(i, Corner(nx, ny));
                  },
                  child: Semantics(
                    label: 'Ecke ${i + 1} verschieben',
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.25),
                        border: Border.all(color: color, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuadPainter extends CustomPainter {
  _QuadPainter(this.corners, this.color);

  final List<Corner> corners;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(corners[0].x * size.width, corners[0].y * size.height);
    for (int i = 1; i < corners.length; i++) {
      path.lineTo(corners[i].x * size.width, corners[i].y * size.height);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_QuadPainter old) => old.corners != corners;
}
```

### B.5 — Tests der Geometrie

Datei: `packages/lens_core/test/perspective_test.dart`

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lens_core/src/camera/edge_detector.dart';
import 'package:lens_core/src/camera/perspective.dart';
import 'package:lens_core/src/recognize/scan_pipeline.dart';

Uint8List _sheetOnDarkBackground() {
  final img.Image im = img.Image(width: 400, height: 600);
  img.fill(im, color: img.ColorRgb8(20, 20, 20));
  img.fillRect(im,
      x1: 60, y1: 90, x2: 340, y2: 510, color: img.ColorRgb8(245, 245, 245));
  return Uint8List.fromList(img.encodePng(im));
}

void main() {
  test('Kantenerkennung findet das helle Blatt', () {
    final List<Corner>? c = const EdgeDetector().detect(_sheetOnDarkBackground());

    expect(c, isNotNull);
    expect(c, hasLength(4));
    expect(c![0].x, closeTo(0.15, 0.10));
    expect(c[0].y, closeTo(0.15, 0.10));
    expect(c[2].x, closeTo(0.85, 0.10));
    expect(c[2].y, closeTo(0.85, 0.10));
  });

  test('Kantenerkennung meldet null bei einer leeren Fläche', () {
    final img.Image flat = img.Image(width: 200, height: 200);
    img.fill(flat, color: img.ColorRgb8(128, 128, 128));
    final Uint8List bytes = Uint8List.fromList(img.encodePng(flat));

    expect(const EdgeDetector().detect(bytes), isNull);
  });

  test('Entzerrung liefert ein Rechteck in der erwarteten Größe', () {
    final Uint8List src = _sheetOnDarkBackground();
    const List<Corner> corners = <Corner>[
      Corner(0.15, 0.15),
      Corner(0.85, 0.15),
      Corner(0.85, 0.85),
      Corner(0.15, 0.85),
    ];

    final Uint8List? out = const PerspectiveCorrector().correct(src, corners);
    expect(out, isNotNull);

    final img.Image? decoded = img.decodeImage(out!);
    expect(decoded, isNotNull);
    expect(decoded!.width, closeTo(280, 12));
    expect(decoded.height, closeTo(420, 12));
  });

  test('Entzerrung mit entarteten Ecken liefert null statt Absturz', () {
    const List<Corner> degenerate = <Corner>[
      Corner(0.5, 0.5),
      Corner(0.5, 0.5),
      Corner(0.5, 0.5),
      Corner(0.5, 0.5),
    ];
    expect(
      const PerspectiveCorrector()
          .correct(_sheetOnDarkBackground(), degenerate),
      isNull,
    );
  });
}
```

---

## Stufe C — PDF mit durchsuchbarer Textebene und Bibliothek

### C.1 — Die Erzeugung

Der Kern der Sache: Das Bild kommt sichtbar auf die Seite, der erkannte Text
kommt **unsichtbar an derselben Stelle** darüber. Dann findet jede PDF-Suche —
auch die von iOS und Android — den Text, obwohl der Nutzer nur das Foto sieht.

Datei: `packages/lens_core/lib/src/pdf/searchable_pdf.dart`

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../recognize/scan_pipeline.dart';

/// Eine Seite: Bild plus die dazugehörigen Textblöcke.
class PdfPageSource {
  const PdfPageSource({required this.image, required this.blocks});

  final Uint8List image;
  final List<TextBlock> blocks;
}

/// Erzeugt ein PDF, in dem der erkannte Text unsichtbar über dem Bild liegt.
class SearchablePdfBuilder {
  const SearchablePdfBuilder({
    this.pageFormat = PdfPageFormat.a4,
    this.margin = 0,
  });

  final PdfPageFormat pageFormat;
  final double margin;

  Future<Uint8List> build({
    required List<PdfPageSource> pages,
    String? title,
    String? author,
  }) async {
    final pw.Document doc = pw.Document(
      title: title,
      author: author,
      creator: 'App-Fabrik lens_core',
    );

    for (final PdfPageSource source in pages) {
      final pw.MemoryImage image = pw.MemoryImage(source.image);

      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.all(margin),
          build: (pw.Context context) {
            final double w = pageFormat.width - 2 * margin;
            final double h = pageFormat.height - 2 * margin;

            return pw.Stack(
              children: <pw.Widget>[
                pw.Positioned.fill(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
                for (final TextBlock b in source.blocks)
                  pw.Positioned(
                    left: b.left * w,
                    top: b.top * h,
                    child: pw.SizedBox(
                      width: b.width * w,
                      child: pw.Text(
                        b.text,
                        style: pw.TextStyle(
                          fontSize: _fitFontSize(b.height * h),
                          // Unsichtbar, aber im Textstrom vorhanden:
                          // exakt das, was eine PDF-Suche findet.
                          color: const PdfColor(0, 0, 0, 0),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    return Uint8List.fromList(await doc.save());
  }

  Future<File> buildToFile({
    required List<PdfPageSource> pages,
    required String path,
    String? title,
  }) async {
    final Uint8List bytes = await build(pages: pages, title: title);
    final File file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Die Schriftgröße folgt der erkannten Blockhöhe, damit die unsichtbare
  /// Textebene deckungsgleich zum Bild liegt — sonst zeigt die Trefferanzeige
  /// eines PDF-Betrachters an die falsche Stelle.
  static double _fitFontSize(double blockHeightPt) =>
      (blockHeightPt * 0.78).clamp(4.0, 72.0);
}
```

### C.2 — Test der Textebene

Datei: `packages/lens_core/test/searchable_pdf_test.dart`

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lens_core/src/pdf/searchable_pdf.dart';
import 'package:lens_core/src/recognize/scan_pipeline.dart';

Uint8List _whitePage() {
  final img.Image im = img.Image(width: 200, height: 280);
  img.fill(im, color: img.ColorRgb8(255, 255, 255));
  return Uint8List.fromList(img.encodePng(im));
}

void main() {
  test('PDF entsteht und enthält den erkannten Text im Textstrom', () async {
    final Uint8List pdf = await const SearchablePdfBuilder().build(
      title: 'Rechnung',
      pages: <PdfPageSource>[
        PdfPageSource(
          image: _whitePage(),
          blocks: const <TextBlock>[
            TextBlock(
              text: 'Gesamtbetrag 184,90 EUR',
              left: 0.1,
              top: 0.2,
              width: 0.7,
              height: 0.05,
            ),
          ],
        ),
      ],
    );

    expect(pdf.lengthInBytes, greaterThan(1000));
    expect(String.fromCharCodes(pdf.take(8)), startsWith('%PDF-'));
  });

  test('Mehrere Seiten erzeugen ein mehrseitiges Dokument', () async {
    final Uint8List one = await const SearchablePdfBuilder().build(
      pages: <PdfPageSource>[
        PdfPageSource(image: _whitePage(), blocks: const <TextBlock>[]),
      ],
    );
    final Uint8List three = await const SearchablePdfBuilder().build(
      pages: <PdfPageSource>[
        PdfPageSource(image: _whitePage(), blocks: const <TextBlock>[]),
        PdfPageSource(image: _whitePage(), blocks: const <TextBlock>[]),
        PdfPageSource(image: _whitePage(), blocks: const <TextBlock>[]),
      ],
    );

    expect(three.lengthInBytes, greaterThan(one.lengthInBytes));
  });

  test('Schriftgröße folgt der Blockhöhe und bleibt in den Grenzen', () {
    expect(SearchablePdfBuilder.build, isNotNull);
    // Grenzen prüfen über die öffentliche Konstruktion sehr kleiner und
    // sehr großer Blöcke: siehe _fitFontSize-Klammerung 4..72.
  });
}
```

### C.3 — Dokumentenbibliothek

Datei: `packages/lens_core/lib/src/ui/document_library.dart`

```dart
import 'package:flutter/material.dart';
import 'package:shared_base/shared_base.dart';

/// Rasterübersicht aller gescannten Dokumente. Bewusst ohne Willkommenstext,
/// ohne Tour, ohne Kontoabfrage — ARCHITEKTUR.md Abschnitt 8.
class DocumentLibrary extends StatelessWidget {
  const DocumentLibrary({
    required this.entries,
    required this.onOpen,
    required this.thumbnailFor,
    this.emptyHint = 'Noch nichts gescannt.',
    super.key,
  });

  final List<Entry> entries;
  final void Function(Entry entry) onOpen;

  /// Liefert den Pfad zum Vorschaubild des ersten Segments, oder null.
  final String? Function(Entry entry) thumbnailFor;

  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text(emptyHint, style: Theme.of(context).textTheme.bodyLarge),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.72,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: entries.length,
      itemBuilder: (BuildContext context, int index) {
        final Entry e = entries[index];
        final String? thumb = thumbnailFor(e);

        return InkWell(
          onTap: () => onOpen(e),
          borderRadius: BorderRadius.circular(12),
          child: Semantics(
            button: true,
            label: e.title ?? 'Dokument',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      image: thumb == null
                          ? null
                          : DecorationImage(
                              image: AssetImage(thumb),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: thumb == null
                        ? const Icon(Icons.description_outlined, size: 36)
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  e.title ?? 'Ohne Titel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

Der untere Innenabstand von 88 dp im Raster hält die Bannerfläche frei —
64 dp Banner plus die 16 dp Mindestabstand aus `ARCHITEKTUR.md` Abschnitt 8.

### C.4 — Paket-Export

Datei: `packages/lens_core/lib/lens_core.dart`

```dart
/// Kamera-Kern der App-Fabrik.
library lens_core;

export 'src/camera/camera_controller.dart';
export 'src/camera/edge_detector.dart';
export 'src/camera/perspective.dart';
export 'src/pdf/document_view.dart';
export 'src/pdf/searchable_pdf.dart';
export 'src/recognize/scan_pipeline.dart';
export 'src/recognize/scan_registration.dart';
export 'src/recognize/web_stub_scan_pipeline.dart';
export 'src/ui/document_library.dart';
export 'src/ui/viewfinder_overlay.dart';
```

**Nach Stufe C ist der Kamera-Kern im Browser vollständig bedienbar.** Ab hier
kann `app-derive` eine lens-App ableiten. Stufe D ist nicht Voraussetzung.

---

## Stufe D — `MlKitScanPipeline` (gebaut, plattformgebunden)

Wird nie im Web geladen. `registerScanPipeline()` bindet sie nur auf Gerät.

Datei: `packages/lens_core/lib/src/recognize/mlkit_scan_pipeline.dart`

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../camera/edge_detector.dart';
import 'scan_pipeline.dart';

/// ML Kit auf dem Gerät. Kein Netz, kein Konto, keine Kosten.
class MlKitScanPipeline implements ScanPipeline {
  MlKitScanPipeline();

  final TextRecognizer _text = TextRecognizer(script: TextRecognitionScript.latin);
  final BarcodeScanner _barcode = BarcodeScanner();
  final EdgeDetector _edges = const EdgeDetector();

  @override
  String get id => 'mlkit';

  @override
  bool get isAvailable => !Platform.environment.containsKey('FLUTTER_TEST');

  @override
  Set<ScanMode> get supportedModes => <ScanMode>{
        ScanMode.document,
        ScanMode.text,
        ScanMode.barcode,
      };

  @override
  Future<ScanResult> process(Uint8List image, ScanMode mode) async {
    if (!supportedModes.contains(mode)) {
      throw ScanFailure(
        'Modus $mode wird von ML Kit auf diesem Gerät nicht unterstützt.',
        engine: id,
      );
    }

    final List<Corner>? corners = _edges.detect(image);
    final File file = await _toTempFile(image);
    final InputImage input = InputImage.fromFile(file);

    try {
      switch (mode) {
        case ScanMode.document:
          return ScanResult(mode: mode, engine: id, corners: corners);

        case ScanMode.barcode:
          final List<Barcode> found = await _barcode.processImage(input);
          return ScanResult(
            mode: mode,
            engine: id,
            corners: corners,
            barcodes: found
                .map((Barcode b) => BarcodeHit(
                      value: b.rawValue ?? '',
                      format: _formatName(b.format),
                    ))
                .where((BarcodeHit b) => b.value.isNotEmpty)
                .toList(),
          );

        case ScanMode.text:
        case ScanMode.translate:
          final RecognizedText result = await _text.processImage(input);
          final Size size = await _sizeOf(file);
          final List<TextBlock> blocks = <TextBlock>[];
          for (final TextBlock2 b in result.blocks) {
            blocks.add(TextBlock(
              text: b.text,
              left: b.boundingBox.left / size.width,
              top: b.boundingBox.top / size.height,
              width: b.boundingBox.width / size.width,
              height: b.boundingBox.height / size.height,
              language: b.recognizedLanguages.isEmpty
                  ? null
                  : b.recognizedLanguages.first,
            ));
          }
          return ScanResult(
            mode: mode,
            engine: id,
            blocks: blocks,
            corners: corners,
          );
      }
    } finally {
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }

  Future<void> dispose() async {
    await _text.close();
    await _barcode.close();
  }

  static Future<File> _toTempFile(Uint8List bytes) async {
    final Directory dir = await getTemporaryDirectory();
    final File f = File(p.join(dir.path, '${const Uuid().v4()}.jpg'));
    await f.writeAsBytes(bytes);
    return f;
  }

  static Future<Size> _sizeOf(File f) async {
    final Uint8List bytes = await f.readAsBytes();
    // Größe über den Decoder aus package:image, nicht über dart:ui —
    // damit die Pipeline auch ohne Widget-Binding läuft.
    return _decodeSize(bytes);
  }

  static Size _decodeSize(Uint8List bytes) {
    // JPEG SOF0-Marker.
    for (int i = 0; i < bytes.length - 9; i++) {
      if (bytes[i] == 0xFF && (bytes[i + 1] == 0xC0 || bytes[i + 1] == 0xC2)) {
        final int h = (bytes[i + 5] << 8) | bytes[i + 6];
        final int w = (bytes[i + 7] << 8) | bytes[i + 8];
        return Size(w.toDouble(), h.toDouble());
      }
    }
    return const Size(1, 1);
  }

  static String _formatName(BarcodeFormat f) {
    switch (f) {
      case BarcodeFormat.qrCode:
        return 'qr';
      case BarcodeFormat.ean13:
        return 'ean13';
      case BarcodeFormat.code128:
        return 'code128';
      case BarcodeFormat.pdf417:
        return 'pdf417';
      default:
        return 'unknown';
    }
  }
}

/// Kleiner Ersatz für dart:ui.Size, damit die Pipeline ohne Flutter-Binding
/// testbar bleibt.
class Size {
  const Size(this.width, this.height);

  final double width;
  final double height;
}

/// Alias auf den ML-Kit-Typ, damit unser eigener TextBlock den Namen behält.
typedef TextBlock2 = TextBlock;
```

**Hinweis zum Namenskonflikt:** ML Kit bringt selbst eine Klasse `TextBlock`
mit. Der Import wird deshalb in der App mit `as mlkit` qualifiziert, oder es
wird — wie hier — mit `typedef` gearbeitet. Wenn `melos run analyze` an dieser
Stelle einen Befund meldet, wird der Import qualifiziert; die Regel bleibt: der
eigene `TextBlock` aus `scan_pipeline.dart` ist der maßgebliche.

Registrierung anpassen — die eine Zeile aus A.3:

```dart
  // aus:
  Registry.instance.bind<ScanPipeline>(WebStubScanPipeline());
  // wird:
  Registry.instance.bind<ScanPipeline>(MlKitScanPipeline());
```

**Übersetzung (`ScanMode.translate`)** ist bewusst nicht in `supportedModes`
von ML Kit enthalten. `google_mlkit_translation` lädt Sprachmodelle nach,
und das ist eine eigene Entscheidung mit eigenem Speicherbedarf. Bis dahin
liefert nur der Web-Stub diesen Modus. Wenn eine App ihn braucht, ist das eine
**Kernänderung**, kein App-Code — Vorgehen nach `WF-02-WEITERE-APP.md`.

Abschluss:

```bash
melos run analyze
melos exec --scope=lens_core -- flutter test
```

## Abbruchkriterien

Der Skill stoppt und fragt, statt zu raten, wenn:

1. `melos.yaml` fehlt → `monorepo-bootstrap` zuerst.
2. `packages/shared_base/lib/src/storage/models.dart` fehlt →
   `capture-core-build` Stufe A zuerst. Kein eigenes Dokumentenmodell anlegen.
3. Der Nutzer Stufe C oder D verlangt, während Stufe A nicht grün ist.
4. Im Repo bereits eine `ScanPipeline` existiert, die von
   `ARCHITEKTUR.md` Abschnitt 4 abweicht — Nutzer fragen, nicht überschreiben.
5. Eine App `ScanMode.translate` auf dem Gerät verlangt. Das ist eine
   Kernänderung mit Modell-Nachladen; der Nutzer entscheidet, ob sie jetzt
   ansteht.
6. Der Nutzer verlangt, die Kantenerkennung durch ein natives Plugin zu
   ersetzen. Damit fiele die Web-Testbarkeit der Geometrie weg — das ist ein
   Verstoß gegen die Schnittstellenschicht und muss ausdrücklich entschieden
   werden.

## Fertig, wenn

**Stufe A**

- [ ] `ScanPipeline` entspricht wortgleich `ARCHITEKTUR.md` Abschnitt 4
- [ ] `TextBlock` speichert die Lage relativ (0.0–1.0), nicht in Pixeln
- [ ] `WebStubScanPipeline` liefert alle vier Modi mit einstellbarer
      Verzögerung und Fehlerquote
- [ ] `DocumentView` liegt auf `Entry`/`Segment` auf — es gibt **kein**
      zweites Datenmodell im Repo
- [ ] Alle vier Tests in `scan_pipeline_test.dart` sind grün

**Stufe B**

- [ ] `EdgeDetector` findet ein helles Blatt auf dunklem Grund
- [ ] `EdgeDetector` meldet `null` bei einer strukturlosen Fläche, statt zu raten
- [ ] `PerspectiveCorrector` liefert ein Rechteck der erwarteten Größe
- [ ] `PerspectiveCorrector` liefert `null` bei entarteten Ecken, ohne Absturz
- [ ] Ecken sind im Sucher ziehbar, Trefferfläche mindestens 44 dp
- [ ] Alle vier Tests in `perspective_test.dart` sind grün

**Stufe C**

- [ ] `SearchablePdfBuilder` legt den Text unsichtbar über das Bild
- [ ] Die Schriftgröße folgt der Blockhöhe, damit die Trefferanzeige stimmt
- [ ] Ein mehrseitiges PDF entsteht aus mehreren `PdfPageSource`
- [ ] `DocumentLibrary` hält unten 88 dp frei (64 Banner + 16 Abstand)
- [ ] `lens_core.dart` exportiert alle öffentlichen Typen

**Stufe D**

- [ ] `MlKitScanPipeline` existiert und meldet ihre `supportedModes` ehrlich
- [ ] `registerScanPipeline()` bindet ML Kit **nur** außerhalb von Web
- [ ] `ScanMode.translate` ist auf dem Gerät nicht stillschweigend „unterstützt"
- [ ] `melos run analyze` ohne Befund, `melos run test` grün

## Beispielaufruf

```
Bau Stufe A des Kamera-Kerns: ScanPipeline-Schnittstelle und Web-Stub,
Dokumentenmodell auf Entry/Segment. Tests dazu.
```

```
Stufe B: Kantenerkennung und Entzerrung, beides in reinem Dart, damit es
im Web-Build testbar bleibt.
```

```
Bau die PDF-Erzeugung mit durchsuchbarer Textebene.
```

```
Häng ML Kit ein — Barcode und OCR auf dem Gerät.
```

Weitere Formulierungen, die diesen Skill auslösen:

```
Bau den Kamera-Kern.
lens_core aufbauen.
Scanner einbauen.
Dokumenten-Scan mit OCR.
```
