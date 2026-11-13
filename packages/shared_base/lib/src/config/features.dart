/// Zentrale Schalter der App-Fabrik.
///
/// Regel aus ARCHITEKTUR.md Abschnitt 5: Kein Schalter darf im App-Code
/// abgefragt werden, nur in der Registrierung (`registry.dart`).
/// Apps sehen ausschließlich die Schnittstellen.
class Features {
  const Features._();

  /// Werbung. Bleibt aus, bis ein Play-Console-Konto existiert.
  static const bool adsEnabled = false;

  /// Käufe. Bleibt aus, bis ein Play-Console-Konto existiert.
  static const bool billingEnabled = false;

  /// Parakeet-Engine. Bleibt aus, bis die Kern-Integration steht und ein
  /// echtes Android-Gerät zum Messen von Ladezeit und Speicher da ist.
  static const bool parakeetEnabled = false;

  /// Welche SttEngine registriert wird: 'web' | 'platform' | 'parakeet'.
  /// Wird beim Web-Build durch die Plattformprüfung in registry.dart
  /// ohnehin auf 'web' gezwungen.
  static const String sttEngine =
      String.fromEnvironment('STT_ENGINE', defaultValue: 'platform');

  /// Dauerhaft aus. Kein Tracking, in keiner App, zu keinem Zeitpunkt.
  static const bool analyticsEnabled = false;

  /// True im Web-Build. Wird von registry.dart gesetzt, nicht von Hand.
  static const bool isWebStub = bool.fromEnvironment('dart.library.js_interop');
}
