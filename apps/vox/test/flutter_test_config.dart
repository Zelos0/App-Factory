import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_base/shared_base.dart';

/// Feste Fläche aller Golden-Bilder: iPhone 14, 390 × 844 logische Pixel.
const Size kGoldenSurface = Size(390, 844);

/// Läuft vor jeder Testdatei unterhalb von test/ (test-loop-free, Stufe 0.1).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // AdSafeArea liest die AdSurface — ohne Bindung kein Bild, nur StateError.
  Registry.instance.reset();
  await registerMonetize();
  // Ohne geladene Schriften rendert der Test Kästchen statt Buchstaben.
  await _loadManifestFonts();
  await _loadRoboto();
  // Schatten rastern je nach Treiber verschieden — häufigste Ursache für
  // Ein-Pixel-Abweichungen zwischen CI und Sandbox.
  debugDisableShadows = true;
  await testMain();
}

/// Alles aus FontManifest.json: Crimson Pro und die Icon-Schrift.
Future<void> _loadManifestFonts() async {
  final String manifest;
  try {
    manifest = await rootBundle.loadString('FontManifest.json');
  } on FlutterError {
    return;
  }
  for (final dynamic raw in json.decode(manifest) as List<dynamic>) {
    final Map<String, dynamic> family = raw as Map<String, dynamic>;
    final FontLoader loader = FontLoader(family['family'] as String);
    for (final dynamic a in family['fonts'] as List<dynamic>) {
      loader.addFont(
        rootBundle.load((a as Map<String, dynamic>)['asset'] as String),
      );
    }
    await loader.load();
  }
}

/// Roboto liegt nicht im App-Paket — Flutter bringt sie auf Android und im
/// Browser selbst mit. Für Tests kommt sie aus dem SDK, damit Golden-Bilder
/// echte Buchstaben zeigen. FLUTTER_ROOT setzt `flutter test` selbst.
Future<void> _loadRoboto() async {
  final String? root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) {
    return;
  }
  final Directory dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) {
    return;
  }
  final FontLoader loader = FontLoader('Roboto');
  for (final String name in <String>[
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]) {
    final File f = File('${dir.path}/$name');
    if (f.existsSync()) {
      loader.addFont(
        Future<ByteData>.value(
          ByteData.sublistView(f.readAsBytesSync()),
        ),
      );
    }
  }
  await loader.load();
}
