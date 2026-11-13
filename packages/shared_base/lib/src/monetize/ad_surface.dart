import 'package:flutter/widgets.dart';

/// Wo eine Werbefläche sitzen kann. Mehr Positionen gibt es nicht —
/// eine App hat höchstens ein Banner, unten verankert.
enum AdSlot { bottomBanner }

/// Zustand einer Fläche. Die Oberfläche fragt ihn nicht ab; sie erhält
/// von [AdSurface.build] immer ein Widget der richtigen Höhe.
enum AdState { disabled, loading, loaded, failed }

/// Schnittstelle aus ARCHITEKTUR.md Abschnitt 4.
///
/// Regel: Die Höhe steht FEST, unabhängig davon, ob eine Anzeige geladen wird.
/// Damit springt kein Layout, wenn Werbung ausfällt, geladen wird oder später
/// eingeschaltet wird. Das ist der ganze Trick.
abstract class AdSurface {
  /// Reservierte Höhe in dp. Konstant über alle Zustände.
  double heightFor(AdSlot slot);

  /// Mindestabstand zu jedem Bedienelement. ARCHITEKTUR.md Abschnitt 8:
  /// mindestens 16 dp, besonders zum Aufnahmeknopf. Fehlklicks sind ein
  /// Sperrgrund im Store.
  double get minimumGap;

  /// Liefert das Widget für den Platz. Bei `NoOpAdSurface` ist das ein
  /// leerer Kasten der richtigen Höhe.
  Widget build(BuildContext context, AdSlot slot);

  Future<void> initialize();
  Future<void> dispose();

  bool get isEnabled;
  String get id;
}
