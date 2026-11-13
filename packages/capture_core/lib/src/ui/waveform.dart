import 'dart:async';

import 'package:flutter/material.dart';

/// Laufende Wellenform während der Aufnahme. Rein dekorativ, aber die
/// einzige Rückmeldung, dass das Mikrofon wirklich arbeitet.
class Waveform extends StatefulWidget {
  const Waveform({
    required this.amplitude,
    this.barCount = 48,
    this.height = 64,
    super.key,
  });

  final Stream<double> amplitude;
  final int barCount;
  final double height;

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform> {
  late final List<double> _values = List<double>.filled(
    widget.barCount,
    0.02,
    growable: false,
  );

  StreamSubscription<double>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.amplitude.listen((double v) {
      if (!mounted) {
        return;
      }
      setState(() {
        for (int i = 0; i < _values.length - 1; i++) {
          _values[i] = _values[i + 1];
        }
        _values[_values.length - 1] = v.clamp(0.02, 1.0);
      });
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: widget.height,
      child: Semantics(
        label: 'Aufnahmepegel',
        child: CustomPaint(
          painter: _WaveformPainter(_values, color),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double slot = size.width / values.length;
    final double barWidth = slot * 0.6;
    final Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    for (int i = 0; i < values.length; i++) {
      final double h = (size.height * values[i]).clamp(2.0, size.height);
      final double x = slot * i + slot / 2;
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => true;
}
