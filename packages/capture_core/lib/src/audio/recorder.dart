import 'dart:async';

/// Zustand der Aufnahme. Die UI kennt nur diese fünf Werte.
enum RecordingState { idle, recording, paused, processing, error }

class RecordingResult {
  const RecordingResult({required this.path, required this.duration});

  final String path;
  final Duration duration;
}

/// Schnittstelle. Web und Gerät liefern verschiedene Implementierungen,
/// die UI kennt den Unterschied nicht.
abstract class AudioRecorder {
  Stream<RecordingState> get state;

  /// Amplitude 0.0–1.0 für die Wellenform, etwa 20 Werte pro Sekunde.
  Stream<double> get amplitude;

  Future<bool> hasPermission();
  Future<void> start();
  Future<void> pause();
  Future<void> resume();
  Future<RecordingResult?> stop();
  Future<void> cancel();
  Future<void> dispose();
}
