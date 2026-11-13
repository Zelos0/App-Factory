import 'dart:async';

import 'purchases.dart';

/// Solange kein Play-Konto existiert, ist jede Fähigkeit freigeschaltet.
///
/// Das ist keine Notlösung, sondern die einzig ehrliche Variante: Eine
/// Bezahlschranke ohne Bezahlmöglichkeit ist eine Sackgasse im Test.
/// Damit ist im Web-Build jeder Pfad erreichbar — auch die Pro-Ansichten,
/// die sonst nie jemand zu Gesicht bekäme.
class AlwaysProPurchases implements Purchases {
  AlwaysProPurchases();

  final StreamController<PurchaseState> _controller =
      StreamController<PurchaseState>.broadcast();

  final PurchaseState _current = const PurchaseState(tier: ProductTier.pro);

  @override
  String get id => 'always-pro';

  @override
  bool get isEnabled => false;

  @override
  PurchaseState get current => _current;

  @override
  Stream<PurchaseState> get state => _controller.stream;

  @override
  Future<void> initialize() async {
    _controller.add(_current);
  }

  @override
  Future<PurchaseState> buy(ProductTier tier) async => _current;

  @override
  Future<PurchaseState> restore() async => _current;

  @override
  Future<String?> priceOf(ProductTier tier) async => null;

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
