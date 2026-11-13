// Gibt jeder App ihr Gesicht im Browser: Manifest, Seitentitel, Farbe der
// Browserleiste und Icons für Home-Bildschirm, Tab und Installation.
//
// Quelle ist allein tool/flavors.yaml (label, core, color, tagline). Ohne
// diesen Schritt trägt jede neue App die Flutter-Vorlage: Name in
// Kleinbuchstaben, „A new Flutter project." und das blaue Flutter-Logo.
//
// Aufruf:  dart run tool/gen_web_meta.dart          alle Flavors
//          dart run tool/gen_web_meta.dart vox      nur einer
//
// Idempotent. web.yml ruft das vor jedem Build auf; app-derive ebenso.
import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  final Map<String, Map<String, String>> flavors = readFlavors();
  final Iterable<String> wanted = args.isEmpty ? flavors.keys : args;

  for (final String f in wanted) {
    final Map<String, String>? meta = flavors[f];
    if (meta == null) {
      stderr.writeln('$f steht nicht in tool/flavors.yaml.');
      exitCode = 1;
      continue;
    }
    final Directory web = Directory('apps/$f/web');
    if (!web.existsSync()) {
      stdout.writeln('$f: kein web/-Verzeichnis, übersprungen.');
      continue;
    }
    final _Meta m = _Meta.of(f, meta);
    _writeManifest(web, m);
    _patchIndex(web, m);
    _writeIcons(web, m);
    stdout.writeln('$f: Manifest, Titel und Icons (${m.color}, ${m.core}).');
  }
}

class _Meta {
  _Meta(this.flavor, this.label, this.core, this.color, this.tagline);

  factory _Meta.of(String flavor, Map<String, String> y) => _Meta(
        flavor,
        y['label'] ?? flavor,
        y['core'] ?? 'capture',
        _hex(y['color']) ?? '#57534E',
        y['tagline'] ?? '',
      );

  final String flavor;
  final String label;
  final String core;
  final String color;
  final String tagline;

  String get description =>
      tagline.isEmpty ? '$label — App-Fabrik' : '$label — $tagline';

  static String? _hex(String? v) {
    final String s = (v ?? '').replaceAll('"', '').replaceAll("'", '').trim();
    return RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(s) ? s.toUpperCase() : null;
  }
}

// --- Manifest -------------------------------------------------------------

void _writeManifest(Directory web, _Meta m) {
  final Map<String, Object> manifest = <String, Object>{
    'name': m.label,
    'short_name': m.label,
    'description': m.description,
    'lang': 'de',
    'start_url': '.',
    'scope': '.',
    'display': 'standalone',
    'orientation': 'portrait-primary',
    'background_color': _paper,
    'theme_color': m.color,
    'prefer_related_applications': false,
    'icons': <Map<String, String>>[
      _icon('icons/Icon-192.png', 192),
      _icon('icons/Icon-512.png', 512),
      _icon('icons/Icon-maskable-192.png', 192, maskable: true),
      _icon('icons/Icon-maskable-512.png', 512, maskable: true),
    ],
  };
  File('${web.path}/manifest.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
}

Map<String, String> _icon(String src, int size, {bool maskable = false}) =>
    <String, String>{
      'src': src,
      'sizes': '${size}x$size',
      'type': 'image/png',
      if (maskable) 'purpose': 'maskable',
    };

// --- index.html -------------------------------------------------------------

void _patchIndex(Directory web, _Meta m) {
  final File f = File('${web.path}/index.html');
  if (!f.existsSync()) {
    return;
  }
  String s = f.readAsStringSync();
  final String desc = _attr(m.description);
  final String label = _attr(m.label);

  s = s.replaceFirst('<html>', '<html lang="de">');
  s = s.replaceAll(
    RegExp(r'<meta name="description" content="[^"]*">'),
    '<meta name="description" content="$desc">',
  );
  s = s.replaceAll(
    RegExp(r'<meta name="apple-mobile-web-app-title" content="[^"]*">'),
    '<meta name="apple-mobile-web-app-title" content="$label">',
  );
  // Helle Apps: dunkle Schrift in der Statusleiste, nicht schwarzer Balken.
  s = s.replaceAll(
    RegExp(r'<meta name="apple-mobile-web-app-status-bar-style" '
        r'content="[^"]*">'),
    '<meta name="apple-mobile-web-app-status-bar-style" content="default">',
  );
  s = s.replaceAll(
    RegExp(r'<link rel="apple-touch-icon" href="[^"]*">'),
    '<link rel="apple-touch-icon" href="icons/apple-touch-icon.png">',
  );
  s = s.replaceAll(RegExp(r'<title>[^<]*</title>'), '<title>$label</title>');

  final String theme = '<meta name="theme-color" content="${m.color}">';
  final RegExp oldTheme = RegExp(r'<meta name="theme-color" content="[^"]*">');
  s = oldTheme.hasMatch(s)
      ? s.replaceAll(oldTheme, theme)
      : s.replaceFirst(
          '<meta name="description"',
          '$theme\n  <meta name="description"',
        );
  f.writeAsStringSync(s);
}

String _attr(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

// --- Icons ------------------------------------------------------------------

const String _paper = '#FAF9F6';

/// Zeichnet viermal so groß und rechnet herunter — glatte Kanten ohne
/// eigene Kantenglättung.
const int _ss = 4;

void _writeIcons(Directory web, _Meta m) {
  Directory('${web.path}/icons').createSync(recursive: true);
  // "any": abgerundet, transparente Ecken — für Browser-Tabs und
  // Desktop-Installationen.
  _png('${web.path}/icons/Icon-192.png', _draw(m, 192, rounded: true));
  _png('${web.path}/icons/Icon-512.png', _draw(m, 512, rounded: true));
  // "maskable" und iOS: randlos. Das System schneidet selbst zu; das
  // Zeichen bleibt in der inneren Sicherheitszone (80 %).
  _png(
    '${web.path}/icons/Icon-maskable-192.png',
    _draw(m, 192, rounded: false, glyphScale: 0.42),
  );
  _png(
    '${web.path}/icons/Icon-maskable-512.png',
    _draw(m, 512, rounded: false, glyphScale: 0.42),
  );
  _png(
    '${web.path}/icons/apple-touch-icon.png',
    _draw(m, 180, rounded: false, glyphScale: 0.5),
  );
  _png('${web.path}/favicon.png', _draw(m, 32, rounded: true));
}

void _png(String path, img.Image image) =>
    File(path).writeAsBytesSync(img.encodePng(image));

img.Image _draw(
  _Meta m,
  int size, {
  required bool rounded,
  double glyphScale = 0.52,
}) {
  final int s = size * _ss;
  final img.Image canvas = img.Image(width: s, height: s, numChannels: 4)
    ..clear(img.ColorRgba8(0, 0, 0, 0));
  final img.Color bg = _rgb(m.color);
  final img.Color fg = img.ColorRgba8(255, 255, 255, 255);

  img.fillRect(
    canvas,
    x1: 0,
    y1: 0,
    x2: s - 1,
    y2: s - 1,
    color: bg,
    radius: rounded ? s * 0.225 : 0,
  );

  final double box = s * glyphScale;
  final double ox = (s - box) / 2;
  final double oy = (s - box) / 2;

  switch (m.core) {
    case 'lens':
      _viewfinder(canvas, ox, oy, box, fg);
      img.fillCircle(
        canvas,
        x: (s / 2).round(),
        y: (s / 2).round(),
        radius: (box * 0.11).round(),
        color: fg,
      );
    case 'both':
      _viewfinder(canvas, ox, oy, box, fg);
      _wave(canvas, ox + box * 0.22, oy + box * 0.22, box * 0.56, fg);
    case 'capture':
    default:
      _wave(canvas, ox, oy, box, fg);
  }

  return img.copyResize(
    canvas,
    width: size,
    height: size,
    interpolation: img.Interpolation.average,
  );
}

/// Fünf Balken einer Schallwelle — das Zeichen des Sprach-Kerns.
void _wave(img.Image c, double x, double y, double box, img.Color fg) {
  const List<double> heights = <double>[0.38, 0.72, 1.0, 0.72, 0.38];
  final double bar = box / 9;
  for (int i = 0; i < heights.length; i++) {
    final double h = box * heights[i];
    final double bx = x + bar * (i * 2);
    final double by = y + (box - h) / 2;
    img.fillRect(
      c,
      x1: bx.round(),
      y1: by.round(),
      x2: (bx + bar).round(),
      y2: (by + h).round(),
      color: fg,
      radius: bar / 2,
    );
  }
}

/// Vier Ecken eines Suchers — das Zeichen des Kamera-Kerns.
void _viewfinder(img.Image c, double x, double y, double box, img.Color fg) {
  final double t = box * 0.09;
  final double l = box * 0.32;
  final double r = t / 2;
  for (final (double cx, double cy, int dx, int dy)
      in <(double, double, int, int)>[
    (x, y, 1, 1),
    (x + box, y, -1, 1),
    (x, y + box, 1, -1),
    (x + box, y + box, -1, -1),
  ]) {
    _bar(c, cx, cy, cx + dx * l, cy + dy * t, fg, r);
    _bar(c, cx, cy, cx + dx * t, cy + dy * l, fg, r);
  }
}

void _bar(
  img.Image c,
  double x1,
  double y1,
  double x2,
  double y2,
  img.Color fg,
  double radius,
) =>
    img.fillRect(
      c,
      x1: (x1 < x2 ? x1 : x2).round(),
      y1: (y1 < y2 ? y1 : y2).round(),
      x2: (x1 < x2 ? x2 : x1).round(),
      y2: (y1 < y2 ? y2 : y1).round(),
      color: fg,
      radius: radius,
    );

img.Color _rgb(String hex) {
  final int v = int.parse(hex.substring(1), radix: 16);
  return img.ColorRgba8((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF, 255);
}

/// Liest tool/flavors.yaml ohne YAML-Paket — festes, flaches Muster.
Map<String, Map<String, String>> readFlavors() {
  final Map<String, Map<String, String>> out = <String, Map<String, String>>{};
  String? current;
  for (final String line in File('tool/flavors.yaml').readAsLinesSync()) {
    final RegExpMatch? head = RegExp(r'^  ([a-z0-9_]+):\s*$').firstMatch(line);
    if (head != null) {
      current = head.group(1);
      out[current!] = <String, String>{};
      continue;
    }
    final RegExpMatch? kv =
        RegExp(r'^    ([a-zA-Z]+):\s*(.+?)\s*$').firstMatch(line);
    if (kv != null && current != null) {
      out[current]![kv.group(1)!] = kv.group(2)!.replaceAll('"', '');
    }
  }
  return out;
}
