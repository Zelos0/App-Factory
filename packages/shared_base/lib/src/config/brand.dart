/// Markenpräfix aller Paket-IDs. Muster aus ARCHITEKTUR.md Abschnitt 9:
/// de.<marke>.<flavor>  —  Beispiel: de.zeta.onira
const String kBrand = 'de.zeta';

/// Aktiver Flavor. Wird beim Build gesetzt:
/// flutter build web --dart-define=FLAVOR=vox
const String kFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'vox');

/// Vollständige Paket-ID des laufenden Builds.
String get kApplicationId => '$kBrand.$kFlavor';
