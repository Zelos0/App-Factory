/// Was mit der Datei passiert ist — damit die App das Richtige meldet.
enum ShareOutcome {
  /// Das Teilen-Menü wurde benutzt.
  shared,

  /// Die Datei wurde heruntergeladen (Browser am Rechner, oder Rückfall).
  downloaded,

  /// Der Nutzer hat das Teilen-Menü geschlossen. Kein Fehler.
  cancelled,
}

/// Gängige Dateitypen der Exporte.
abstract final class Mime {
  static const String markdown = 'text/markdown';
  static const String text = 'text/plain';
  static const String json = 'application/json';
  static const String pdf = 'application/pdf';
  static const String zip = 'application/zip';
}

/// Dateiname mit Datum, ohne Zeichen, die ein Dateisystem stören:
/// `exportName('vox', 'md')` → `vox-2026-11-13.md`.
String exportName(String stem, String extension, {DateTime? at}) {
  final DateTime d = at ?? DateTime.now();
  final String date = '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  final String clean = stem
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return '${clean.isEmpty ? 'export' : clean}-$date.$extension';
}
