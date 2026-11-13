// Erzeugt build/web/index.html — die Übersicht aller Flavor-Demos.
// app-derive muss diese Datei nicht ändern; sie liest das Verzeichnis.
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

  final StringBuffer items = StringBuffer();
  for (final String f in flavors) {
    items.writeln('    <li><a href="/$f/">$f</a></li>');
  }

  File('build/web/index.html').writeAsStringSync('''
<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <title>App-Fabrik — Web-Demos</title>
  <style>
    :root { color-scheme: light dark; }
    body { font: 17px/1.5 -apple-system, system-ui, sans-serif; margin: 0; padding: 24px; }
    h1 { font-size: 22px; margin: 0 0 4px; }
    p { margin: 0 0 24px; opacity: .7; }
    ul { list-style: none; padding: 0; margin: 0; }
    li { margin: 0 0 12px; }
    a { display: block; padding: 16px; min-height: 56px; box-sizing: border-box;
        border: 1px solid currentColor; border-radius: 12px; text-decoration: none;
        color: inherit; }
  </style>
</head>
<body>
  <h1>App-Fabrik</h1>
  <p>${flavors.length} Demo(s) · Branch-Vorschau</p>
  <ul>
$items  </ul>
</body>
</html>
''');

  stdout.writeln('Übersicht erzeugt für: ${flavors.join(", ")}');
}
