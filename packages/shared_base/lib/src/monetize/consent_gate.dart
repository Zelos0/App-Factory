/// Zustand der Werbe-Einwilligung.
enum ConsentStatus {
  /// Noch nicht gefragt.
  unknown,

  /// Einwilligung nötig, Formular noch nicht gezeigt.
  required,

  /// Erteilt — personalisierte Werbung zulässig.
  obtained,

  /// Abgelehnt oder eingeschränkt — nur nicht-personalisierte Werbung.
  restricted,

  /// Außerhalb des Geltungsbereichs.
  notRequired,
}

/// Schnittstelle über der UMP-Bibliothek.
abstract class ConsentGate {
  Future<ConsentStatus> check();

  /// Zeigt das Formular, wenn nötig. Liefert den Zustand danach.
  Future<ConsentStatus> requestIfNeeded();

  /// Muss dauerhaft erreichbar sein — die Einstellungen brauchen einen
  /// Eintrag „Werbeeinstellungen ändern". Fehlt er, ist das ein Prüfpunkt
  /// im Store-Review.
  Future<ConsentStatus> showForm();

  /// Nur für Testläufe und den Web-Build.
  Future<void> reset();

  bool get canRequestAds;
}

/// Aktive Implementierung, solange keine Werbung existiert.
class NoConsentGate implements ConsentGate {
  const NoConsentGate();

  @override
  bool get canRequestAds => false;

  @override
  Future<ConsentStatus> check() async => ConsentStatus.notRequired;

  @override
  Future<ConsentStatus> requestIfNeeded() async => ConsentStatus.notRequired;

  @override
  Future<ConsentStatus> showForm() async => ConsentStatus.notRequired;

  @override
  Future<void> reset() async {}
}

/// UMP-Implementierung. Wird mit der Werbung zusammen gebunden.
///
/// Einschalten:
///   1. google_mobile_ads liefert UMP mit — keine zweite Abhängigkeit
///   2. die AKTIVIEREN-Blöcke einkommentieren
///   3. In der AdMob-Konsole eine Datenschutzmeldung anlegen und
///      veröffentlichen, sonst liefert UMP dauerhaft „notRequired"
class UmpConsentGate implements ConsentGate {
  UmpConsentGate();

  ConsentStatus _status = ConsentStatus.unknown;

  @override
  bool get canRequestAds =>
      _status == ConsentStatus.obtained || _status == ConsentStatus.restricted;

  @override
  Future<ConsentStatus> check() async {
    // AKTIVIEREN:
    // final ConsentInformation info = ConsentInformation.instance;
    // ... info.requestConsentInfoUpdate(...)
    return _status;
  }

  @override
  Future<ConsentStatus> requestIfNeeded() async {
    final ConsentStatus current = await check();
    if (current == ConsentStatus.required) {
      return showForm();
    }
    return current;
  }

  @override
  Future<ConsentStatus> showForm() async {
    // AKTIVIEREN:
    // await ConsentForm.loadAndShowConsentFormIfRequired(...)
    return _status;
  }

  @override
  Future<void> reset() async {
    _status = ConsentStatus.unknown;
  }
}
