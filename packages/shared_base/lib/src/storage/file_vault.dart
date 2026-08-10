import 'dart:typed_data';

/// Ablage der Originaldateien. Kein Geschäftslogik-Code kennt eine
/// konkrete Implementierung — ARCHITEKTUR.md Abschnitt 4.
abstract class FileVault {
  /// Legt Bytes ab und liefert den Pfad, der in `Segment.mediaPath` landet.
  Future<String> put(Uint8List bytes, {required String extension});

  Future<Uint8List?> get(String path);

  Future<bool> exists(String path);

  Future<void> delete(String path);

  /// Alle abgelegten Pfade. Grundlage für den ZIP-Teil der Fluchttür.
  Future<List<String>> list();

  /// Belegter Speicher in Bytes. Für die Einstellungen.
  Future<int> usedBytes();

  String get id;
}
