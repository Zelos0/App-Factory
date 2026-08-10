/// Was gekauft werden kann. Bewusst wenige Stufen — jede weitere kostet
/// Erklärung im Store und Pflege in der Abrechnung.
enum ProductTier {
  /// Kostenlos. Fluchttür-Export ist hier bereits enthalten.
  free,

  /// Einmalkauf: Pro-Engine, aufbereitete Exportformate, keine Werbung.
  pro,
}

class PurchaseState {
  const PurchaseState({required this.tier, this.since});

  final ProductTier tier;
  final DateTime? since;

  bool get isPro => tier == ProductTier.pro;
}

/// Schnittstelle aus ARCHITEKTUR.md Abschnitt 4.
abstract class Purchases {
  Future<void> initialize();

  Stream<PurchaseState> get state;
  PurchaseState get current;

  /// Kauf auslösen. Wirft [PurchaseFailure], wenn kein Abrechnungsdienst
  /// da ist.
  Future<PurchaseState> buy(ProductTier tier);

  /// Käufe wiederherstellen. Pflicht in beiden Stores.
  Future<PurchaseState> restore();

  /// Preis in der Landeswährung, formatiert. Null, wenn unbekannt.
  Future<String?> priceOf(ProductTier tier);

  Future<void> dispose();

  bool get isEnabled;
  String get id;
}

class PurchaseFailure implements Exception {
  const PurchaseFailure(this.message);

  final String message;

  @override
  String toString() => 'PurchaseFailure: $message';
}
