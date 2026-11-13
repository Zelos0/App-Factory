import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_base/shared_base.dart';

/// Woher die Bytes einer Aufnahme kommen.
enum MediaKind {
  /// Keine Aufnahme am Segment.
  none,

  /// Adresse, die der Player selbst lädt (blob:, http(s):, data:).
  url,

  /// Datei auf dem Gerät.
  file,

  /// Pfad in der [FileVault] — im Browser IndexedDB.
  vault,
}

/// Ordnet einen `Segment.mediaPath` zu. Reine Logik, damit testbar.
MediaKind mediaKindOf(String? path, {bool web = kIsWeb}) {
  if (path == null || path.isEmpty) {
    return MediaKind.none;
  }
  if (RegExp(r'^(blob|https?|data):').hasMatch(path)) {
    return MediaKind.url;
  }
  if (web) {
    return MediaKind.vault;
  }
  return path.startsWith('/') || RegExp(r'^[A-Za-z]:\\').hasMatch(path)
      ? MediaKind.file
      : MediaKind.vault;
}

/// Spielt die Originalaufnahme eines Segments ab. Ein Tippen startet,
/// ein zweites hält an. Ohne Aufnahme zeichnet der Knopf nichts.
///
/// Fehlt die Aufnahme (gelöscht, alter Browser-Stand), meldet
/// [onUnavailable] das in Klartext — der Text des Segments bleibt ja da.
class SegmentPlayButton extends StatefulWidget {
  const SegmentPlayButton({
    required this.mediaPath,
    this.onUnavailable,
    super.key,
  });

  final String? mediaPath;
  final ValueChanged<String>? onUnavailable;

  @override
  State<SegmentPlayButton> createState() => _SegmentPlayButtonState();
}

class _SegmentPlayButtonState extends State<SegmentPlayButton> {
  ap.AudioPlayer? _player;
  StreamSubscription<void>? _done;
  bool _playing = false;
  bool _loading = false;

  @override
  void dispose() {
    unawaited(_done?.cancel());
    unawaited(_player?.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player?.stop();
      if (mounted) {
        setState(() => _playing = false);
      }
      return;
    }
    setState(() => _loading = true);
    try {
      final ap.Source? source = await _source(widget.mediaPath!);
      if (source == null) {
        widget.onUnavailable?.call(
          'Die Originalaufnahme ist nicht mehr vorhanden — der Text bleibt.',
        );
        return;
      }
      final ap.AudioPlayer player = _player ??= ap.AudioPlayer();
      _done ??= player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() => _playing = false);
        }
      });
      await player.play(source);
      if (mounted) {
        setState(() => _playing = true);
      }
    } on Object {
      widget.onUnavailable?.call('Die Aufnahme ließ sich nicht abspielen.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  static Future<ap.Source?> _source(String path) async {
    final String mime = mimeForExtension(path);
    switch (mediaKindOf(path)) {
      case MediaKind.none:
        return null;
      case MediaKind.url:
        return ap.UrlSource(path);
      case MediaKind.file:
        return ap.DeviceFileSource(path, mimeType: mime);
      case MediaKind.vault:
        if (!Registry.instance.has<FileVault>()) {
          return null;
        }
        final Uint8List? bytes =
            await Registry.instance.get<FileVault>().get(path);
        return bytes == null ? null : ap.BytesSource(bytes, mimeType: mime);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mediaKindOf(widget.mediaPath) == MediaKind.none) {
      return const SizedBox.shrink();
    }
    return IconButton(
      onPressed: _loading ? null : () => unawaited(_toggle()),
      tooltip: _playing ? 'Anhalten' : 'Abspielen',
      icon: _loading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
    );
  }
}
