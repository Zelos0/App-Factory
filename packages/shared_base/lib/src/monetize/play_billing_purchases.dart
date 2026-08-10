import 'dart:async';

import 'purchases.dart';

/// Google Play Billing. Wird erst in WF-04-GELD-DA.md, Welle 1, gebunden —
/// NACH dem Zwölf-Tester-Lauf, aber VOR der Werbung.
///
/// Reihenfolge-Begründung: Die Pro-Stufe entfernt die Werbung. Wer Werbung
/// zuerst einschaltet, testet einen Zustand, den zahlende Nutzer nie sehen,
/// und findet die Fehler im Pro-Pfad zuletzt.
///
/// Einschalten:
///   1. in_app_purchase in packages/shared_base/pubspec.yaml aufnehmen
///   2. die mit AKTIVIEREN markierten Blöcke einkommentieren
///   3. Produkt-IDs in der Play Console anlegen: de.zeta.<flavor>.pro
///   4. Features.billingEnabled = true
class PlayBillingPurchases implements Purchases {
  PlayBillingPurchases({required this.productIdPro});

  final String productIdPro;

  final StreamController<PurchaseState> _controller =
      StreamController<PurchaseState>.broadcast();

  final PurchaseState _current = const PurchaseState(tier: ProductTier.free);

  @override
  String get id => 'play-billing';

  @override
  bool get isEnabled => true;

  @override
  PurchaseState get current => _current;

  @override
  Stream<PurchaseState> get state => _controller.stream;

  @override
  Future<void> initialize() async {
    // AKTIVIEREN:
    // final bool available = await InAppPurchase.instance.isAvailable();
    // if (!available) throw const PurchaseFailure('Kein Abrechnungsdienst.');
    // InAppPurchase.instance.purchaseStream.listen(_onPurchaseUpdate);
    _controller.add(_current);
  }

  @override
  Future<PurchaseState> buy(ProductTier tier) async {
    throw const PurchaseFailure(
      'Play Billing ist noch nicht eingehängt. '
      'Ablauf steht in WF-04-GELD-DA.md, Welle 1.',
    );
  }

  @override
  Future<PurchaseState> restore() async {
    throw const PurchaseFailure('Play Billing ist noch nicht eingehängt.');
  }

  @override
  Future<String?> priceOf(ProductTier tier) async => null;

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
