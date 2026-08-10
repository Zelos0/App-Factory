import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' as r;
import 'package:uuid/uuid.dart';

import 'recorder.dart';

/// Aufnahme über das Mikrofon. Funktioniert auf Android, iOS und im Browser —
/// im Browser über MediaRecorder, dort ist [RecordingResult.path] eine
/// Blob-URL statt eines Dateipfads.
class PlatformAudioRecorder implements AudioRecorder {
  PlatformAudioRecorder();

  final r.AudioRecorder _recorder = r.AudioRecorder();
  final StreamController<RecordingState> _state =
      StreamController<RecordingState>.broadcast();
  final StreamController<double> _amp = StreamController<double>.broadcast();

  Timer? _ampTimer;
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
      await _recorder.start(
        const r.RecordConfig(encoder: r.AudioEncoder.opus),
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
  }

  @override
  Future<void> pause() async {
    await _recorder.pause();
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
  }

  @override
  Future<RecordingResult?> stop() async {
    _ampTimer?.cancel();
    _state.add(RecordingState.processing);
    final String? result = await _recorder.stop();
    final Duration total =
        _accumulated + DateTime.now().difference(_startedAt ?? DateTime.now());
    _state.add(RecordingState.idle);
    final String? path = result ?? _path;
    if (path == null) {
      return null;
    }
    return RecordingResult(path: path, duration: total);
  }

  @override
  Future<void> cancel() async {
    _ampTimer?.cancel();
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
