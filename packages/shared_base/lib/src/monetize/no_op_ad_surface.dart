import 'package:flutter/widgets.dart';

import 'ad_surface.dart';

/// Reserviert den Platz, zeigt nichts. Die einzige Implementierung, die
/// heute gebunden wird.
///
/// Die Höhe entspricht dem Standard-Bannerformat (320x50 wird auf
/// Telefonen als 50 dp hoch ausgeliefert; adaptive Banner liegen zwischen
/// 50 und 90 dp). 64 dp deckt beides ab, ohne dass später etwas springt.
class NoOpAdSurface implements AdSurface {
  const NoOpAdSurface();

  static const double bannerHeight = 64;
  static const double gap = 16;

  @override
  String get id => 'noop';

  @override
  bool get isEnabled => false;

  @override
  double get minimumGap => gap;

  @override
  double heightFor(AdSlot slot) => bannerHeight;

  @override
  Widget build(BuildContext context, AdSlot slot) =>
      SizedBox(height: heightFor(slot), width: double.infinity);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}
}
