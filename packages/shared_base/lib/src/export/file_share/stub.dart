import 'dart:typed_data';
import 'dart:ui';

import 'outcome.dart';

/// Plattform ohne Dateisystem und ohne Browser — kommt in Apps nicht vor.
Future<ShareOutcome> shareFile({
  required Uint8List bytes,
  required String name,
  required String mime,
  Rect? origin,
}) =>
    throw UnsupportedError('Dateien teilen ist auf dieser Plattform nicht '
        'möglich.');
