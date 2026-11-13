import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'dart:ui';

import 'package:web/web.dart' as web;

import 'outcome.dart';

/// Browser: auf Touch-Geräten das Teilen-Menü (Web Share API mit Dateien —
/// Safari ab iOS 15, Chrome auf Android), sonst ein Download.
///
/// Safari erlaubt navigator.share() nur kurz nach einem Fingertipp. Hat das
/// Erzeugen der Datei zu lange gedauert, lehnt Safari ab — dann wird
/// heruntergeladen. Auf dem iPhone öffnet sich auch dabei eine Vorschau mit
/// Teilen-Knopf; verloren geht nichts.
Future<ShareOutcome> shareFile({
  required Uint8List bytes,
  required String name,
  required String mime,
  Rect? origin,
}) async {
  final JSArray<JSAny> parts = <JSAny>[bytes.toJS].toJS;

  if (_prefersShareSheet()) {
    final web.File file =
        web.File(parts, name, web.FilePropertyBag(type: mime));
    final web.ShareData data =
        web.ShareData(files: <web.File>[file].toJS, title: name);
    if (_canShare(data)) {
      try {
        await web.window.navigator.share(data).toDart;
        return ShareOutcome.shared;
      } on Object catch (e) {
        // AbortError: der Nutzer hat das Menü geschlossen. Alles andere
        // (meist NotAllowedError, Fingertipp zu lange her) → Download.
        if (e.toString().contains('AbortError')) {
          return ShareOutcome.cancelled;
        }
      }
    }
  }

  _download(web.Blob(parts, web.BlobPropertyBag(type: mime)), name);
  return ShareOutcome.downloaded;
}

/// Teilen-Menü nur dort, wo es das Gewohnte ist: Telefon und Tablet.
/// Am Rechner erwartet man einen Download.
bool _prefersShareSheet() => web.window.navigator.maxTouchPoints > 0;

bool _canShare(web.ShareData data) {
  final web.Navigator nav = web.window.navigator;
  if (!(nav as JSObject).hasProperty('canShare'.toJS).toDart) {
    return false;
  }
  try {
    return nav.canShare(data);
  } on Object {
    return false;
  }
}

void _download(web.Blob blob, String name) {
  final String url = web.URL.createObjectURL(blob);
  final web.HTMLAnchorElement a =
      web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = name
        ..style.display = 'none';
  web.document.body?.append(a);
  a.click();
  a.remove();
  // Erst später freigeben: Safari liest die Blob-URL asynchron.
  Timer(const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
}
