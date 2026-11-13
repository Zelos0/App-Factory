/// Gemeinsamer Unterbau der App-Fabrik.
///
/// Einzige öffentliche Tür des Pakets. Kern und Apps importieren
/// ausschließlich `package:shared_base/shared_base.dart` — niemals
/// `package:shared_base/src/...`.
///
/// Diese Datei wächst mit den Kern-Skills:
///   capture-core-build Stufe A ergänzt die storage-Exporte
///   monetize-modul     ergänzt die monetize-Exporte
///   app-derive         schiebt Geteiltes aus Apps hierher (src/text/)
library shared_base;

export 'src/config/brand.dart';
export 'src/config/features.dart';
export 'src/config/registry.dart';
export 'src/design/tokens.dart';
export 'src/export/pdf_export.dart';
export 'src/export/vault_export.dart';
export 'src/monetize/ad_safe_area.dart';
export 'src/monetize/ad_surface.dart';
export 'src/monetize/always_pro_purchases.dart';
export 'src/monetize/consent_gate.dart';
export 'src/monetize/consent_tile.dart';
export 'src/monetize/monetize_registration.dart';
export 'src/monetize/no_op_ad_surface.dart';
export 'src/monetize/purchases.dart';
export 'src/monetize/test_ad_units.dart';
export 'src/storage/connection.dart';
export 'src/storage/database.dart';
export 'src/storage/entry_store.dart';
export 'src/storage/file_vault.dart';
export 'src/storage/indexed_db_vault.dart';
export 'src/storage/models.dart';
export 'src/storage/native_vault.dart';
export 'src/storage/vault_registration.dart';
export 'src/text/spoken_dates.dart';
export 'src/text/spoken_numbers.dart';
