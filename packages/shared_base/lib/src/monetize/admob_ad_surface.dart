import 'package:flutter/widgets.dart';

import 'ad_surface.dart';
import 'no_op_ad_surface.dart';

/// AdMob-Implementierung. Wird erst in WF-04-GELD-DA.md, Welle 1, gebunden.
///
/// Einschalten geschieht in vier Schritten, nicht in einem:
///   1. google_mobile_ads in packages/shared_base/pubspec.yaml aufnehmen
///   2. die drei mit AKTIVIEREN markierten Blöcke unten einkommentieren
///   3. Features.adsEnabled = true
///   4. registerMonetize() bindet dann diese Klasse statt NoOpAdSurface
///
/// Die Höhe bleibt identisch zu [NoOpAdSurface] — deshalb ändert sich beim
/// Einschalten kein einziges Layout.
class AdMobAdSurface implements AdSurface {
  AdMobAdSurface({required this.androidUnitId, required this.iosUnitId});

  /// Kommt über --dart-define, niemals aus dem Quelltext.
  /// tool/check_ad_ids.dart bricht den Build, wenn hier eine echte ID steht.
  final String androidUnitId;
  final String iosUnitId;

  AdState _state = AdState.disabled;

  @override
  String get id => 'admob';

  @override
  bool get isEnabled => true;

  @override
  double get minimumGap => NoOpAdSurface.gap;

  @override
  double heightFor(AdSlot slot) => NoOpAdSurface.bannerHeight;

  @override
  Future<void> initialize() async {
    // AKTIVIEREN (1/3):
    // await MobileAds.instance.initialize();
    // await MobileAds.instance.updateRequestConfiguration(
    //   RequestConfiguration(testDeviceIds: <String>[]),
    // );
    _state = AdState.loading;
  }

  @override
  Widget build(BuildContext context, AdSlot slot) {
    // AKTIVIEREN (2/3):
    // return SizedBox(
    //   height: heightFor(slot),
    //   width: double.infinity,
    //   child: AdWidget(ad: _banner!),
    // );
    return SizedBox(height: heightFor(slot), width: double.infinity);
  }

  @override
  Future<void> dispose() async {
    // AKTIVIEREN (3/3):
    // await _banner?.dispose();
    _state = AdState.disabled;
  }

  AdState get state => _state;
}
