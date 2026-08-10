import 'package:flutter/material.dart';

import '../config/registry.dart';
import 'ad_surface.dart';

/// Hüllt den Bildschirminhalt und hält die Bannerfläche frei.
///
/// Der Abstand zwischen dem untersten Bedienelement und der Werbefläche
/// beträgt IMMER mindestens [AdSurface.minimumGap] — auch dann, wenn gar
/// keine Werbung geladen wird. Genau deshalb ändert das spätere Einschalten
/// nichts am Layout.
class AdSafeArea extends StatelessWidget {
  const AdSafeArea({
    required this.child,
    this.slot = AdSlot.bottomBanner,
    this.bottomAction,
    super.key,
  });

  final Widget child;
  final AdSlot slot;

  /// Primäraktion, die unmittelbar über der Werbefläche sitzt —
  /// typischerweise der Aufnahmeknopf. Bekommt den Mindestabstand
  /// automatisch.
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    final AdSurface ads = Registry.instance.get<AdSurface>();
    final double gap = ads.minimumGap;

    return Column(
      children: <Widget>[
        Expanded(child: child),
        if (bottomAction != null)
          Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: bottomAction,
          )
        else
          SizedBox(height: gap),
        RepaintBoundary(
          child: ExcludeSemantics(child: ads.build(context, slot)),
        ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom),
      ],
    );
  }

  /// Für Listen und Raster, die nicht in [AdSafeArea] stecken:
  /// der untere Innenabstand, der Banner und Mindestabstand freihält.
  static double scrollPadding(BuildContext context) {
    final AdSurface ads = Registry.instance.get<AdSurface>();
    return ads.heightFor(AdSlot.bottomBanner) + ads.minimumGap + 8;
  }
}
