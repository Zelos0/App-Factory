import 'package:flutter/material.dart';

import '../audio/recorder.dart';

/// Primäraktion. Regeln aus ARCHITEKTUR.md Abschnitt 8:
/// mindestens 56 dp hoch, im Daumenbereich, mindestens 16 dp Abstand
/// zur Bannerfläche. Der Abstand wird hier erzwungen, nicht empfohlen.
class RecordButton extends StatelessWidget {
  const RecordButton({
    required this.state,
    required this.onStart,
    required this.onStop,
    this.label = 'Aufnehmen',
    this.stopLabel = 'Fertig',
    this.insideAdSafeArea = false,
    super.key,
  });

  static const double minHeight = 56;
  static const double bannerGap = 16;

  final RecordingState state;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final String label;
  final String stopLabel;

  /// True, wenn der Knopf als `bottomAction` in `AdSafeArea` steckt.
  /// Dann hält bereits `AdSafeArea` den Mindestabstand — der eigene
  /// untere Innenabstand entfällt, sonst stünden 32 dp statt 16 dp.
  final bool insideAdSafeArea;

  @override
  Widget build(BuildContext context) {
    final bool active = state == RecordingState.recording;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, insideAdSafeArea ? 0 : bannerGap),
      child: SizedBox(
        height: minHeight,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: state == RecordingState.processing
              ? null
              : (active ? onStop : onStart),
          style: FilledButton.styleFrom(
            backgroundColor: active ? scheme.error : scheme.primary,
            foregroundColor: active ? scheme.onError : scheme.onPrimary,
            minimumSize: const Size.fromHeight(minHeight),
          ),
          icon: Icon(active ? Icons.stop_rounded : Icons.mic_rounded),
          label: Text(active ? stopLabel : label),
        ),
      ),
    );
  }
}
