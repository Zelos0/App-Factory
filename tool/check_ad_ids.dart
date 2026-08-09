// Bricht den Build, wenn eine echte AdMob-ID im Quelltext auftaucht.
// Test-IDs von Google beginnen mit ca-app-pub-3940256099942544.
// Aufruf: dart run tool/check_ad_ids.dart
import 'dart:io';

const String _googleTestPrefix = 'ca-app-pub-3940256099942544';
final RegExp _adUnit = RegExp(r'ca-app-pub-\d{16}[/~]\d{10}');

void main() {
  final List<String> offenders = <String>[];

  for (final FileSystemEntity e in Directory('.').listSync(recursive: true)) {
    if (e is! File) {
      continue;
    }
    final String p = e.path;
    if (!p.endsWith('.dart') && !p.endsWith('.xml') && !p.endsWith('.plist')) {
      continue;
    }
    if (p.contains('/build/') ||
        p.contains('/.dart_tool/') ||
        p.endsWith('check_ad_ids.dart')) {
      continue;
    }
    for (final RegExpMatch m in _adUnit.allMatches(e.readAsStringSync())) {
      final String id = m.group(0)!;
      if (!id.startsWith(_googleTestPrefix)) {
        offenders.add('$p  ->  $id');
      }
    }
  }

  if (offenders.isEmpty) {
    stdout.writeln('OK: nur Test-Anzeigen-IDs im Quelltext.');
    return;
  }

  stderr.writeln('ABBRUCH: echte AdMob-IDs gefunden.');
  for (final String o in offenders) {
    stderr.writeln('  $o');
  }
  stderr.writeln('Echte IDs gehören ausschließlich in Release-Builds über '
      '--dart-define, niemals in den Quelltext.');
  exit(1);
}
