import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' as r;
import 'package:shared_base/shared_base.dart';
import 'package:uuid/uuid.dart';

import '../stt/stt_engine.dart';
import 'blob/blob_reader.dart';
import 'recorder.dart';

/// Aufnahme über das Mikrofon. Funktioniert auf Android, iOS und im Browser.
///
/// Im Browser landet die Aufnahme nach dem Stopp in der registrierten
/// [FileVault] (IndexedDB) — [RecordingResult.path] ist dann ein Vault-Pfad
/// und überlebt Neuladen. Das Format wählt der Recorder selbst: Opus/WebM,
/// wo es geht (Chrome, Edge, Firefox), sonst AAC/MP4 (Safari), sonst WAV.
///
/// Ist eine [LiveSttEngine] registriert, hört sie automatisch mit: Start,
/// Pause, Fortsetzen und Stopp der Aufnahme steuern auch die Erkennung. Die
/// App merkt davon nichts — sie ruft wie immer `transcribe()` nach `stop()`.
class PlatformAudioRecorder implements AudioRecorder {
  /// [live] nur für Tests. Ohne Angabe gilt die registrierte [SttEngine],
  /// sofern sie mithören kann.
  PlatformAudioRecorder({LiveSttEngine? live}) : _liveOverride = live;

  final LiveSttEngine? _liveOverride;

  LiveSttEngine? get _live {
    final LiveSttEngine? own = _liveOverride;
    if (own != null) {
      return own;
    }
    if (!Registry.instance.has<SttEngine>()) {
      return null;
    }
    final SttEngine e = Registry.instance.get<SttEngine>();
    return e is LiveSttEngine ? e : null;
  }

  final r.AudioRecorder _recorder = r.AudioRecorder();
  final StreamController<RecordingState> _state =
      StreamController<RecordingState>.broadcast();
  final StreamController<double> _amp = StreamController<double>.broadcast();

  Timer? _ampTimer;
  _WebFormat? _webFormat;
  DateTime? _startedAt;
  Duration _accumulated = Duration.zero;
  String? _path;

  @override
  Stream<RecordingState> get state => _state.stream;

  @override
  Stream<double> get amplitude => _amp.stream;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    if (!await hasPermission()) {
      _state.add(RecordingState.error);
      throw StateError('Mikrofon-Berechtigung fehlt.');
    }

    if (kIsWeb) {
      _path = null;
      final _WebFormat format = _webFormat ??= await _pickWebFormat();
      await _recorder.start(
        r.RecordConfig(encoder: format.encoder, numChannels: 1),
        path: '',
      );
    } else {
      final String dir = (await getApplicationDocumentsDirectory()).path;
      _path = p.join(dir, 'audio', '${const Uuid().v4()}.m4a');
      await _recorder.start(
        const r.RecordConfig(
          bitRate: 96000,
          numChannels: 1,
          sampleRate: 44100,
        ),
        path: _path!,
      );
    }

    _startedAt = DateTime.now();
    _accumulated = Duration.zero;
    _state.add(RecordingState.recording);
    _startAmplitudePolling();
    await _live?.beginLive();
  }

  @override
  Future<void> pause() async {
    await _recorder.pause();
    await _live?.endLive();
    _accumulated += DateTime.now().difference(_startedAt ?? DateTime.now());
    _ampTimer?.cancel();
    _state.add(RecordingState.paused);
  }

  @override
  Future<void> resume() async {
    await _recorder.resume();
    _startedAt = DateTime.now();
    _state.add(RecordingState.recording);
    _startAmplitudePolling();
    await _live?.beginLive(append: true);
  }

  @override
  Future<RecordingResult?> stop() async {
    _ampTimer?.cancel();
    _state.add(RecordingState.processing);
    // Erst die Erkennung beenden — sie liefert ihr letztes Wort, solange das
    // Mikrofon noch offen ist.
    await _live?.endLive();
    final String? result = await _recorder.stop();
    final Duration total =
        _accumulated + DateTime.now().difference(_startedAt ?? DateTime.now());
    _state.add(RecordingState.idle);
    final String? path = result ?? _path;
    if (path == null) {
      return null;
    }
    if (kIsWeb) {
      return RecordingResult(path: await _keep(path), duration: total);
    }
    return RecordingResult(path: path, duration: total);
  }

  /// Übernimmt eine Browser-Aufnahme aus der flüchtigen Blob-Adresse in die
  /// Ablage. Klappt das nicht, bleibt die Blob-Adresse — in dieser Sitzung
  /// abspielbar, statt sofort verloren.
  Future<String> _keep(String blobUrl) async {
    if (!Registry.instance.has<FileVault>()) {
      return blobUrl;
    }
    final Uint8List? bytes = await readBlobUrl(blobUrl);
    if (bytes == null || bytes.isEmpty) {
      return blobUrl;
    }
    try {
      final String key = await Registry.instance
          .get<FileVault>()
          .put(bytes, extension: (_webFormat ?? _WebFormat.opus).extension);
      releaseBlobUrl(blobUrl);
      return key;
    } on Object {
      return blobUrl;
    }
  }

  /// Erstes Format, das dieser Browser aufnehmen kann.
  Future<_WebFormat> _pickWebFormat() async {
    for (final _WebFormat f in _WebFormat.values) {
      try {
        if (await _recorder.isEncoderSupported(f.encoder)) {
          return f;
        }
      } on Object {
        // Nächstes Format versuchen.
      }
    }
    // WAV über die Web-Audio-API kann jeder Browser mit Mikrofon.
    return _WebFormat.wav;
  }

  @override
  Future<void> cancel() async {
    _ampTimer?.cancel();
    await _live?.endLive();
    await _recorder.cancel();
    _state.add(RecordingState.idle);
  }

  @override
  Future<void> dispose() async {
    _ampTimer?.cancel();
    await _recorder.dispose();
    await _state.close();
    await _amp.close();
  }

  void _startAmplitudePolling() {
    _ampTimer?.cancel();
    _ampTimer = Timer.periodic(const Duration(milliseconds: 50), (
      Timer _,
    ) async {
      final r.Amplitude a = await _recorder.getAmplitude();
      // dBFS, typisch -60 (still) bis 0 (Vollaussteuerung).
      final double norm = ((a.current + 60) / 60).clamp(0.0, 1.0);
      _amp.add(norm);
    });
  }
}

/// Aufnahmeformate im Browser, in der Reihenfolge der Vorliebe: klein zuerst.
enum _WebFormat {
  opus(r.AudioEncoder.opus, 'webm'),
  aac(r.AudioEncoder.aacLc, 'm4a'),
  wav(r.AudioEncoder.wav, 'wav');

  const _WebFormat(this.encoder, this.extension);

  final r.AudioEncoder encoder;
  final String extension;
}
