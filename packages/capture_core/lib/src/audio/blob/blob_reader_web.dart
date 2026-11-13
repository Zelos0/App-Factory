import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Holt die Bytes hinter einer Blob-Adresse. null, wenn sie nicht mehr
/// existiert — dann bleibt die Aufnahme beim alten Weg, statt verloren zu
/// gehen.
Future<Uint8List?> readBlobUrl(String url) async {
  if (!url.startsWith('blob:')) {
    return null;
  }
  try {
    final web.Response res = await web.window.fetch(url.toJS).toDart;
    final JSArrayBuffer buf = await res.arrayBuffer().toDart;
    return buf.toDart.asUint8List();
  } on Object {
    return null;
  }
}

/// Gibt den Speicher des Blobs frei, sobald die Bytes in der Ablage liegen.
void releaseBlobUrl(String url) {
  if (url.startsWith('blob:')) {
    web.URL.revokeObjectURL(url);
  }
}
