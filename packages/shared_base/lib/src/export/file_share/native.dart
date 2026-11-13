import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'outcome.dart';

/// Android und iOS: Datei in den Zwischenspeicher der App schreiben und das
/// Teilen-Menü des Systems öffnen.
///
/// [origin] ist auf dem iPad Pflicht — dort hängt das Menü als Sprechblase
/// an einer Stelle des Bildschirms. Ohne Angabe stürzt es dort ab.
Future<ShareOutcome> shareFile({
  required Uint8List bytes,
  required String name,
  required String mime,
  Rect? origin,
}) async {
  final Directory dir = await getTemporaryDirectory();
  final File file = File(p.join(dir.path, 'export', name));
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);

  final ShareResult r = await Share.shareXFiles(
    <XFile>[XFile(file.path, mimeType: mime, name: name)],
    sharePositionOrigin: origin,
  );
  return r.status == ShareResultStatus.dismissed
      ? ShareOutcome.cancelled
      : ShareOutcome.shared;
}
