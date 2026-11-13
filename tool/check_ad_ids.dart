// Prueft drei Dinge und bricht den Build bei jedem Befund:
//   1. keine echte AdMob-ID im Quelltext
//   2. kein Schalter auf true ohne den zugehoerigen Einbau
//   3. kein direkter Features-Zugriff ausserhalb der Registrierung
//
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

  _checkFeatureSwitches(offenders);
  _checkFeatureLeaks(offenders);

  if (offenders.isEmpty) {
    stdout.writeln('OK: nur Test-Anzeigen-IDs im Quelltext, Schalter '
        'unangetastet, kein direkter Features-Zugriff.');
    return;
  }

  stderr.writeln('ABBRUCH:');
  for (final String o in offenders) {
    stderr.writeln('  $o');
  }
  stderr.writeln('Echte IDs gehören ausschließlich in Release-Builds über '
      '--dart-define, niemals in den Quelltext.');
  exit(1);
}

// ---------------------------------------------------------------------------
// Zusatzprüfung 1: Schalter dürfen nicht ohne Einbau auf true stehen.
// ---------------------------------------------------------------------------
void _checkFeatureSwitches(List<String> offenders) {
  final File f = File('packages/shared_base/lib/src/config/features.dart');
  if (!f.existsSync()) {
    return;
  }
  final String src = f.readAsStringSync();

  bool isTrue(String name) => RegExp('$name\\s*=\\s*true').hasMatch(src);

  final File reg =
      File('packages/shared_base/lib/src/monetize/monetize_registration.dart');
  final String regSrc = reg.existsSync() ? reg.readAsStringSync() : '';

  // Der Einbau zaehlt nur, wenn er WIRKLICH gebunden ist. In der
  // stillgelegten Fassung steht die Bindung auskommentiert im Quelltext —
  // ein blosses contains() wuerde sie faelschlich als Einbau werten.
  bool bound(String call) => _withoutComments(regSrc).contains(call);

  if (isTrue('adsEnabled') && !bound('AdMobAdSurface(')) {
    offenders.add(
      'features.dart -> adsEnabled = true, aber AdMobAdSurface ist in '
      'monetize_registration.dart nicht gebunden.',
    );
  }
  if (isTrue('billingEnabled') && !bound('PlayBillingPurchases(')) {
    offenders.add(
      'features.dart -> billingEnabled = true, aber PlayBillingPurchases ist '
      'in monetize_registration.dart nicht gebunden.',
    );
  }
  if (isTrue('analyticsEnabled')) {
    offenders.add(
      'features.dart -> analyticsEnabled = true. Dieser Schalter bleibt '
      'dauerhaft false — kein Tracking, in keiner App. ARCHITEKTUR.md '
      'Abschnitt 5.',
    );
  }
}

// ---------------------------------------------------------------------------
// Zusatzprüfung 2: Kein App-Code darf Features direkt lesen.
// ARCHITEKTUR.md Abschnitt 5: Schalter nur in der Registrierung.
// ---------------------------------------------------------------------------
void _checkFeatureLeaks(List<String> offenders) {
  const List<String> allowed = <String>[
    'packages/shared_base/lib/src/config/features.dart',
    'packages/shared_base/lib/src/config/registry.dart',
    'packages/shared_base/lib/src/monetize/monetize_registration.dart',
    'packages/capture_core/lib/src/stt/stt_registration.dart',
    'packages/lens_core/lib/src/recognize/scan_registration.dart',
  ];

  for (final FileSystemEntity e in Directory('.').listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.dart')) {
      continue;
    }
    final String path = e.path.replaceFirst('./', '');
    if (path.contains('/build/') ||
        path.contains('/.dart_tool/') ||
        path.contains('/test/') ||
        path.startsWith('tool/') ||
        allowed.contains(path)) {
      continue;
    }
    // Ohne Kommentare pruefen: Dateien wie admob_ad_surface.dart und
    // play_billing_purchases.dart NENNEN die Schalter in ihrer
    // Einschalt-Anleitung, ohne sie zu lesen. Ein Treffer im Kommentar ist
    // ein Fehlalarm und haette die CI dauerhaft rot gehalten.
    final String src = _withoutComments(e.readAsStringSync());
    if (RegExp(r'\bFeatures\.\w+').hasMatch(src)) {
      offenders.add(
        '$path liest Features direkt. Schalter gehören ausschließlich in die '
        'Registrierung — ARCHITEKTUR.md Abschnitt 5.',
      );
    }
  }
}

/// Entfernt Zeilen- und Blockkommentare. Absichtlich einfach: Es geht darum,
/// Kommentare von Quelltext zu trennen, nicht darum, Dart zu parsen.
/// Zeichenketten, die `//` enthalten, koennen dabei gekuerzt werden — das
/// macht die Pruefung hoechstens nachsichtiger, nie strenger.
String _withoutComments(String source) => source
        .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
        .split('\n')
        .map((String line) {
      final int i = line.indexOf('//');
      return i == -1 ? line : line.substring(0, i);
    }).join('\n');
