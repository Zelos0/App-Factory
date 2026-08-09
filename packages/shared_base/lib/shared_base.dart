/// Gemeinsamer Unterbau der App-Fabrik.
///
/// Einzige öffentliche Tür des Pakets. Kern und Apps importieren
/// ausschließlich `package:shared_base/shared_base.dart` — niemals
/// `package:shared_base/src/...`.
///
/// Diese Datei wächst mit den Kern-Skills:
///   capture-core-build Stufe A ergänzt die storage-Exporte
///   monetize-modul     ergänzt die monetize-Exporte
library shared_base;

export 'src/config/brand.dart';
export 'src/config/features.dart';
export 'src/config/registry.dart';
