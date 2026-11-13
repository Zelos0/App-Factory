import 'package:flutter/material.dart';

/// Abstände, Skalen und Mindestmaße. Jede App liefert nur Farben und
/// Schriften — alles Maßliche kommt von hier, damit 26 Apps sich gleich
/// anfühlen. ARCHITEKTUR.md Abschnitt 8.
class Tokens {
  const Tokens._();

  /// Vier-Punkte-Raster. Alles Maßliche ist ein Vielfaches davon.
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;

  /// Mindesthöhe der Primäraktion.
  static const double primaryActionHeight = 56;

  /// Mindestgröße einer Trefferfläche.
  static const double minimumTouchTarget = 44;

  /// Mindestabstand zur Bannerfläche. Spiegelt NoOpAdSurface.gap;
  /// wer einen der beiden ändert, ändert beide.
  static const double bannerGap = 16;

  static const BorderRadius radius = BorderRadius.all(Radius.circular(12));

  /// Vom Nutzer einstellbare Schriftgröße, angewandt auf das Theme.
  /// Werte außerhalb 0.85–1.60 werden geklemmt — darunter wird es
  /// unlesbar, darüber bricht jedes Layout.
  static TextScaler scaler(double factor) =>
      TextScaler.linear(factor.clamp(0.85, 1.60));
}
