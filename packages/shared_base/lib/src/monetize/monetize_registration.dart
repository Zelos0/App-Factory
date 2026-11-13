import '../config/features.dart';
import '../config/registry.dart';
import 'ad_surface.dart';
import 'always_pro_purchases.dart';
import 'consent_gate.dart';
import 'no_op_ad_surface.dart';
import 'purchases.dart';

/// Einzige Stelle, an der Features.adsEnabled und Features.billingEnabled
/// gelesen werden. Apps sehen ausschließlich [AdSurface], [Purchases],
/// [ConsentGate] — nie einen Schalter.
///
/// Hinweis für Welle 1: Der Produktbezeichner lautet dort
/// `'$kApplicationId.pro'`. `brand.dart` wird deshalb erst mit dem
/// Einkommentieren importiert — vorher wäre der Import unbenutzt und
/// scheiterte an `--fatal-infos`.
Future<void> registerMonetize() async {
  // --- Werbung ---
  if (Features.adsEnabled) {
    // WF-04-GELD-DA.md, Welle 1, Punkt 6:
    //   Registry.instance.bind<AdSurface>(AdMobAdSurface(
    //     androidUnitId: const String.fromEnvironment('AD_UNIT_ANDROID'),
    //     iosUnitId: const String.fromEnvironment('AD_UNIT_IOS'),
    //   ));
    //   Registry.instance.bind<ConsentGate>(UmpConsentGate());
    throw StateError(
      'Features.adsEnabled ist true, aber AdMobAdSurface ist nicht gebunden. '
      'Ablauf steht in WF-04-GELD-DA.md, Welle 1.',
    );
  } else {
    Registry.instance.bind<AdSurface>(const NoOpAdSurface());
    Registry.instance.bind<ConsentGate>(const NoConsentGate());
  }

  // --- Käufe ---
  if (Features.billingEnabled) {
    // WF-04-GELD-DA.md, Welle 1, Punkt 5:
    //   final PlayBillingPurchases p =
    //       PlayBillingPurchases(productIdPro: '$kApplicationId.pro');
    //   await p.initialize();
    //   Registry.instance.bind<Purchases>(p);
    throw StateError(
      'Features.billingEnabled ist true, aber PlayBillingPurchases ist nicht '
      'gebunden. Ablauf steht in WF-04-GELD-DA.md, Welle 1.',
    );
  } else {
    final AlwaysProPurchases purchases = AlwaysProPurchases();
    await purchases.initialize();
    Registry.instance.bind<Purchases>(purchases);
  }
}
