import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Schreibt die Screenshots des Integrationstests als PNG nach
/// integration_test/screenshots/ (in .gitignore — Artefakte, keine Quellen).
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (
      String name,
      List<int> bytes, [
      Map<String, Object?>? args,
    ]) async {
      final File file = File('integration_test/screenshots/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      stdout.writeln('Screenshot: ${file.path} (${bytes.length} Bytes)');
      return true;
    },
  );
}
