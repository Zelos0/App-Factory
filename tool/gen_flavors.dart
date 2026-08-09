// Erzeugt android/app/flavors.gradle und ios/Flutter/Flavors.xcconfig
// aus tool/flavors.yaml. Aufruf:  dart run tool/gen_flavors.dart
import 'dart:io';

void main() {
  final File source = File('tool/flavors.yaml');
  if (!source.existsSync()) {
    stderr.writeln('tool/flavors.yaml fehlt.');
    exit(1);
  }

  final List<String> lines = source.readAsLinesSync();
  final List<_Flavor> flavors = <_Flavor>[];
  String? current;
  String? label;
  String? core;
  String? appId;

  for (final String raw in lines) {
    final String line = raw.trimRight();
    if (line.startsWith('  ') &&
        line.endsWith(':') &&
        !line.startsWith('    ')) {
      if (current != null) {
        flavors.add(
          _Flavor(
            current,
            label ?? current,
            core ?? 'capture',
            appId ?? 'de.zeta.$current',
          ),
        );
      }
      current = line.trim().replaceAll(':', '');
      label = null;
      core = null;
      appId = null;
    } else if (line.trimLeft().startsWith('label:')) {
      label = line.split(':').last.trim();
    } else if (line.trimLeft().startsWith('core:')) {
      core = line.split(':').last.trim();
    } else if (line.trimLeft().startsWith('applicationId:')) {
      appId = line.split(':').last.trim();
    }
  }
  if (current != null) {
    flavors.add(
      _Flavor(
        current,
        label ?? current,
        core ?? 'capture',
        appId ?? 'de.zeta.$current',
      ),
    );
  }

  for (final _Flavor f in flavors) {
    final Directory android = Directory('apps/${f.name}/android/app');
    if (!android.existsSync()) {
      continue;
    }
    File('apps/${f.name}/android/app/flavors.gradle').writeAsStringSync('''
// ERZEUGT von tool/gen_flavors.dart — nicht von Hand ändern.
android {
    flavorDimensions "app"
    productFlavors {
        ${f.name} {
            dimension "app"
            applicationId "${f.applicationId}"
            resValue "string", "app_name", "${f.label}"
        }
    }
}
''');
    File('apps/${f.name}/ios/Flutter/Flavors.xcconfig').writeAsStringSync('''
// ERZEUGT von tool/gen_flavors.dart — nicht von Hand ändern.
FLAVOR=${f.name}
PRODUCT_BUNDLE_IDENTIFIER=${f.applicationId}
APP_DISPLAY_NAME=${f.label}
''');
  }

  stdout.writeln(
    'Flavors erzeugt: ${flavors.map((_Flavor f) => f.name).join(", ")}',
  );
}

class _Flavor {
  const _Flavor(this.name, this.label, this.core, this.applicationId);
  final String name;
  final String label;
  final String core;
  final String applicationId;
}
