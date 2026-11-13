// Erzeugt build/web/index.html — die Übersicht aller Flavor-Demos.
// app-derive muss diese Datei nicht ändern; sie liest das Verzeichnis und
// holt sich die Anzeigenamen aus tool/flavors.yaml.
//
// Alle Links sind RELATIV. Dieselbe Seite funktioniert damit unter
// Cloudflare (https://<projekt>.pages.dev/) und unter GitHub Pages
// (https://<nutzer>.github.io/<repo>/), ohne dass sie den Pfad kennen muss.
import 'dart:io';

void main() {
  final Directory root = Directory('build/web');
  if (!root.existsSync()) {
    stderr.writeln('build/web fehlt — erst bauen.');
    exit(1);
  }

  final List<String> flavors = root
      .listSync()
      .whereType<Directory>()
      .map((Directory d) => d.path.split(Platform.pathSeparator).last)
      .toList()
    ..sort();

  final Map<String, Map<String, String>> meta = _readFlavors();

  final StringBuffer items = StringBuffer();
  for (final String f in flavors) {
    final String label = _esc(meta[f]?['label'] ?? f);
    final String core = _esc(meta[f]?['core'] ?? '');
    final String kern = switch (core) {
      'capture' => 'Sprach-Kern',
      'lens' => 'Kamera-Kern',
      'both' => 'Sprach- und Kamera-Kern',
      _ => '',
    };
    final String tagline = _esc(meta[f]?['tagline']?.replaceAll('"', '') ?? '');
    final String sub = tagline.isNotEmpty ? tagline : kern;
    items.writeln('    <li><a href="$f/"><strong>$label</strong>'
        '${sub.isEmpty ? '' : '<span>$sub</span>'}</a></li>');
  }

  final String stamp = DateTime.now()
      .toUtc()
      .toIso8601String()
      .substring(0, 16)
      .replaceFirst('T', ' ');
  final String ref = Platform.environment['GITHUB_REF_NAME'] ?? 'lokal';
  final String sha =
      (Platform.environment['GITHUB_SHA'] ?? '').padRight(7).substring(0, 7);

  File('build/web/index.html').writeAsStringSync('''
<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <title>App-Fabrik — Web-Demos</title>
  <style>
    :root { color-scheme: light dark; --bg: #faf9f6; --fg: #1c1b19; --mut: #6b6862; --line: #d9d6cf; }
    @media (prefers-color-scheme: dark) {
      :root { --bg: #151413; --fg: #ecebe8; --mut: #9a968f; --line: #34322f; }
    }
    body { font: 17px/1.5 -apple-system, system-ui, sans-serif; margin: 0;
           padding: max(24px, env(safe-area-inset-top)) 20px 32px;
           background: var(--bg); color: var(--fg); }
    main { max-width: 560px; margin: 0 auto; }
    h1 { font-size: 26px; margin: 8px 0 4px; letter-spacing: -.01em; }
    p { margin: 0 0 24px; color: var(--mut); }
    ul { list-style: none; padding: 0; margin: 0; }
    li { margin: 0 0 12px; }
    a { display: flex; flex-direction: column; justify-content: center; gap: 2px;
        padding: 16px 18px; min-height: 64px; box-sizing: border-box;
        border: 1px solid var(--line); border-radius: 14px; text-decoration: none;
        color: inherit; }
    a:active { background: var(--line); }
    a span { font-size: 14px; color: var(--mut); }
    footer { margin-top: 32px; font-size: 13px; color: var(--mut); }
  </style>
</head>
<body>
<main>
  <h1>App-Fabrik</h1>
  <p>${flavors.length} ${flavors.length == 1 ? 'App' : 'Apps'} im Browser — antippen und ausprobieren.</p>
  <ul>
$items  </ul>
  <footer>Stand $stamp UTC · $ref${sha.trim().isEmpty ? '' : ' · $sha'}</footer>
</main>
</body>
</html>
''');

  stdout.writeln('Übersicht erzeugt für: ${flavors.join(", ")}');
}

/// Liest `tool/flavors.yaml` ohne YAML-Paket: die Datei hat ein festes,
/// flaches Muster (`  <flavor>:` gefolgt von `    key: value`).
Map<String, Map<String, String>> _readFlavors() {
  final File f = File('tool/flavors.yaml');
  final Map<String, Map<String, String>> out = <String, Map<String, String>>{};
  if (!f.existsSync()) {
    return out;
  }
  String? current;
  for (final String line in f.readAsLinesSync()) {
    final RegExpMatch? head = RegExp(r'^  ([a-z0-9_]+):\s*$').firstMatch(line);
    if (head != null) {
      current = head.group(1);
      out[current!] = <String, String>{};
      continue;
    }
    final RegExpMatch? kv =
        RegExp(r'^    ([a-zA-Z]+):\s*(.+?)\s*$').firstMatch(line);
    if (kv != null && current != null) {
      out[current]![kv.group(1)!] = kv.group(2)!;
    }
  }
  return out;
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
