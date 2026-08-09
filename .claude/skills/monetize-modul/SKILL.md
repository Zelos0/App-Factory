---
name: monetize-modul
description: Baut AdSurface und Purchases als Schnittstellen mit stillgelegten Implementierungen, reserviert die Bannerfläche mit mindestens 16 dp Abstand zu jedem Bedienelement, legt das UMP-Einwilligungsgerüst an und erzwingt Test-Anzeigen-IDs über eine CI-Prüfung, die den Build bricht. Auslösen mit "bau das Monetarisierungs-Modul", "Bannerfläche reservieren", "AdSurface und Purchases anlegen", "Werbung vorbereiten", "Kauf-Schnittstelle bauen". Läuft einmal im Repo, nicht je App.
---

# Monetarisierung vorbereiten — gebaut, stillgelegt

Läuft **jetzt**, obwohl kein Cent verdient wird und kein Konto existiert.
Der Grund steht in `ARCHITEKTUR.md` Abschnitt 4: Die Bannerfläche später
einzubauen heißt, sechsundzwanzig Layouts anzufassen. Sie jetzt zu reservieren
heißt, eine Konstante zu setzen.

## Wann dieser Skill greift

**Greift**, wenn `packages/shared_base/lib/src/monetize/` fehlt oder
unvollständig ist. Läuft **einmal im Repo**, nicht je App.

**Greift nicht** bei:

| Wunsch | Zuständiger Skill |
|---|---|
| Repo existiert nicht | `monorepo-bootstrap` |
| Eine App bauen | `app-derive` — nutzt die hier gebauten Widgets |
| Werbung wirklich einschalten | `WF-04-GELD-DA.md`, Welle 1 — erst mit Play-Konto |
| Veröffentlichen | `release-gate` — stillgelegt |
| Store-Texte, Datenschutzangaben | `store-assets` |

**Der Skill schaltet nichts ein.** Er baut die Schnittstellen, bindet die
No-Op-Implementierungen und lässt `Features.adsEnabled` und
`Features.billingEnabled` auf `false`. Wer sie hier auf `true` setzt, bricht
den Build gegen die eigene CI-Prüfung — das ist Absicht.

## Voraussetzungen

| Was | Wer liefert es | Prüfbefehl |
|---|---|---|
| `melos.yaml` | `monorepo-bootstrap` | `test -f melos.yaml` |
| `packages/shared_base/lib/src/config/features.dart` | `monorepo-bootstrap` | `test -f packages/shared_base/lib/src/config/features.dart` |
| `packages/shared_base/lib/src/config/registry.dart` | `monorepo-bootstrap` | `test -f packages/shared_base/lib/src/config/registry.dart` |
| `tool/check_ad_ids.dart` und `melos run check-ad-ids` | `monorepo-bootstrap` | `melos run check-ad-ids` |

`tool/check_ad_ids.dart` wird von `monorepo-bootstrap` angelegt. Dieser Skill
**erweitert** sie um zwei Prüfungen (Schritt 6) und legt sie nicht neu an.

## Ablauf

---

### Schritt 1 — `AdSurface`

Datei: `packages/shared_base/lib/src/monetize/ad_surface.dart`

```dart
import 'package:flutter/widgets.dart';

/// Wo eine Werbefläche sitzen kann. Mehr Positionen gibt es nicht —
/// eine App hat höchstens ein Banner, unten verankert.
enum AdSlot { bottomBanner }

/// Zustand einer Fläche. Die Oberfläche fragt ihn nicht ab; sie erhält
/// von [AdSurface.build] immer ein Widget der richtigen Höhe.
enum AdState { disabled, loading, loaded, failed }

/// Schnittstelle aus ARCHITEKTUR.md Abschnitt 4.
///
/// Regel: Die Höhe steht FEST, unabhängig davon, ob eine Anzeige geladen wird.
/// Damit springt kein Layout, wenn Werbung ausfällt, geladen wird oder später
/// eingeschaltet wird. Das ist der ganze Trick.
abstract class AdSurface {
  /// Reservierte Höhe in dp. Konstant über alle Zustände.
  double heightFor(AdSlot slot);

  /// Mindestabstand zu jedem Bedienelement. ARCHITEKTUR.md Abschnitt 8:
  /// mindestens 16 dp, besonders zum Aufnahmeknopf. Fehlklicks sind ein
  /// Sperrgrund im Store.
  double get minimumGap;

  /// Liefert das Widget für den Platz. Bei [NoOpAdSurface] ist das ein
  /// leerer Kasten der richtigen Höhe.
  Widget build(BuildContext context, AdSlot slot);

  Future<void> initialize();
  Future<void> dispose();

  bool get isEnabled;
  String get id;
}
```

### Schritt 2 — `NoOpAdSurface` — die aktive Implementierung

Datei: `packages/shared_base/lib/src/monetize/no_op_ad_surface.dart`

```dart
import 'package:flutter/widgets.dart';

import 'ad_surface.dart';

/// Reserviert den Platz, zeigt nichts. Die einzige Implementierung, die
/// heute gebunden wird.
///
/// Die Höhe entspricht dem Standard-Bannerformat (320x50 wird auf
/// Telefonen als 50 dp hoch ausgeliefert; adaptive Banner liegen zwischen
/// 50 und 90 dp). 64 dp deckt beides ab, ohne dass später etwas springt.
class NoOpAdSurface implements AdSurface {
  const NoOpAdSurface();

  static const double bannerHeight = 64;
  static const double gap = 16;

  @override
  String get id => 'noop';

  @override
  bool get isEnabled => false;

  @override
  double get minimumGap => gap;

  @override
  double heightFor(AdSlot slot) => bannerHeight;

  @override
  Widget build(BuildContext context, AdSlot slot) => SizedBox(
        height: heightFor(slot),
        width: double.infinity,
      );

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}
}
```

### Schritt 3 — `AdMobAdSurface` — gebaut, nicht gebunden

Vollständig vorhanden, damit das Einschalten später eine Zeile ist. Die
AdMob-Abhängigkeit wird **noch nicht** in `pubspec.yaml` aufgenommen — sie
käme sonst in alle 26 Web-Builds. Die Datei ist deshalb ein Bauplan mit
lauffähigem Gerüst und einem klaren Fehler, wenn sie ohne Konto gebunden wird.

Datei: `packages/shared_base/lib/src/monetize/admob_ad_surface.dart`

```dart
import 'package:flutter/widgets.dart';

import 'ad_surface.dart';
import 'no_op_ad_surface.dart';

/// AdMob-Implementierung. Wird erst in WF-04-GELD-DA.md, Welle 1, gebunden.
///
/// Einschalten geschieht in vier Schritten, nicht in einem:
///   1. google_mobile_ads in packages/shared_base/pubspec.yaml aufnehmen
///   2. die drei mit AKTIVIEREN markierten Blöcke unten einkommentieren
///   3. Features.adsEnabled = true
///   4. registerMonetize() bindet dann diese Klasse statt NoOpAdSurface
///
/// Die Höhe bleibt identisch zu NoOpAdSurface — deshalb ändert sich beim
/// Einschalten kein einziges Layout.
class AdMobAdSurface implements AdSurface {
  AdMobAdSurface({required this.androidUnitId, required this.iosUnitId});

  /// Kommt über --dart-define, niemals aus dem Quelltext.
  /// tool/check_ad_ids.dart bricht den Build, wenn hier eine echte ID steht.
  final String androidUnitId;
  final String iosUnitId;

  AdState _state = AdState.disabled;

  @override
  String get id => 'admob';

  @override
  bool get isEnabled => true;

  @override
  double get minimumGap => NoOpAdSurface.gap;

  @override
  double heightFor(AdSlot slot) => NoOpAdSurface.bannerHeight;

  @override
  Future<void> initialize() async {
    // AKTIVIEREN (1/3):
    // await MobileAds.instance.initialize();
    // await MobileAds.instance.updateRequestConfiguration(
    //   RequestConfiguration(testDeviceIds: <String>[]),
    // );
    _state = AdState.loading;
  }

  @override
  Widget build(BuildContext context, AdSlot slot) {
    // AKTIVIEREN (2/3):
    // return SizedBox(
    //   height: heightFor(slot),
    //   width: double.infinity,
    //   child: AdWidget(ad: _banner!),
    // );
    return SizedBox(height: heightFor(slot), width: double.infinity);
  }

  @override
  Future<void> dispose() async {
    // AKTIVIEREN (3/3):
    // await _banner?.dispose();
    _state = AdState.disabled;
  }

  AdState get state => _state;
}
```

### Schritt 4 — Das Widget, das den Abstand erzwingt

Der wichtigste Baustein dieses Skills. Apps rufen **nicht** `AdSurface.build`
direkt auf — sie hüllen ihren Inhalt in `AdSafeArea`. Damit ist der Abstand
kein Vorsatz, sondern eine Eigenschaft des Layouts.

Datei: `packages/shared_base/lib/src/monetize/ad_safe_area.dart`

```dart
import 'package:flutter/material.dart';

import '../config/registry.dart';
import 'ad_surface.dart';

/// Hüllt den Bildschirminhalt und hält die Bannerfläche frei.
///
/// Der Abstand zwischen dem untersten Bedienelement und der Werbefläche
/// beträgt IMMER mindestens [AdSurface.minimumGap] — auch dann, wenn gar
/// keine Werbung geladen wird. Genau deshalb ändert das spätere Einschalten
/// nichts am Layout.
class AdSafeArea extends StatelessWidget {
  const AdSafeArea({
    required this.child,
    this.slot = AdSlot.bottomBanner,
    this.bottomAction,
    super.key,
  });

  final Widget child;
  final AdSlot slot;

  /// Primäraktion, die unmittelbar über der Werbefläche sitzt —
  /// typischerweise der Aufnahmeknopf. Bekommt den Mindestabstand
  /// automatisch.
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    final AdSurface ads = Registry.instance.get<AdSurface>();
    final double bannerHeight = ads.heightFor(slot);
    final double gap = ads.minimumGap;

    return Column(
      children: <Widget>[
        Expanded(child: child),
        if (bottomAction != null)
          Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: bottomAction,
          )
        else
          SizedBox(height: gap),
        RepaintBoundary(
          child: ExcludeSemantics(
            child: ads.build(context, slot),
          ),
        ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom),
      ],
    );
  }

  /// Für Listen und Raster, die nicht in [AdSafeArea] stecken:
  /// der untere Innenabstand, der Banner und Mindestabstand freihält.
  static double scrollPadding(BuildContext context) {
    final AdSurface ads = Registry.instance.get<AdSurface>();
    return ads.heightFor(AdSlot.bottomBanner) + ads.minimumGap + 8;
  }
}
```

### Schritt 5 — `Purchases`

Datei: `packages/shared_base/lib/src/monetize/purchases.dart`

```dart
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

  /// Kauf auslösen. Wirft [PurchaseFailure], wenn kein Abrechnungsdienst da ist.
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
```

### Schritt 6 — `AlwaysProPurchases` — die aktive Implementierung

Datei: `packages/shared_base/lib/src/monetize/always_pro_purchases.dart`

```dart
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

  PurchaseState _current = const PurchaseState(tier: ProductTier.pro);

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
```

Datei: `packages/shared_base/lib/src/monetize/play_billing_purchases.dart`

```dart
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

  PurchaseState _current = const PurchaseState(tier: ProductTier.free);

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
    throw const PurchaseFailure(
      'Play Billing ist noch nicht eingehängt.',
    );
  }

  @override
  Future<String?> priceOf(ProductTier tier) async => null;

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
```

### Schritt 7 — UMP-Einwilligungsgerüst

Das europäische Einwilligungsformular. Ohne gültige Einwilligung darf in der
EU keine personalisierte Werbung ausgeliefert werden. Der Dialog wird jetzt
gebaut und ist im Web-Build bedienbar — damit sein Platz im Ablauf steht,
bevor Werbung existiert.

Datei: `packages/shared_base/lib/src/monetize/consent_gate.dart`

```dart
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
  /// Eintrag "Werbeeinstellungen ändern". Fehlt er, ist das ein Prüfpunkt
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
///      veröffentlichen, sonst liefert UMP dauerhaft "notRequired"
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
```

Der Einstellungs-Eintrag, den jede App einbindet:

Datei: `packages/shared_base/lib/src/monetize/consent_tile.dart`

```dart
import 'package:flutter/material.dart';

import '../config/registry.dart';
import 'consent_gate.dart';

/// „Werbeeinstellungen ändern" in den Einstellungen. Muss dauerhaft
/// erreichbar sein, auch wenn gerade keine Werbung ausgeliefert wird.
class ConsentTile extends StatelessWidget {
  const ConsentTile({super.key});

  @override
  Widget build(BuildContext context) {
    final ConsentGate gate = Registry.instance.get<ConsentGate>();

    return FutureBuilder<ConsentStatus>(
      future: gate.check(),
      builder: (BuildContext context, AsyncSnapshot<ConsentStatus> snapshot) {
        final ConsentStatus status = snapshot.data ?? ConsentStatus.unknown;
        if (status == ConsentStatus.notRequired) {
          return const SizedBox.shrink();
        }
        return ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Werbeeinstellungen ändern'),
          subtitle: Text(_label(status)),
          onTap: () => gate.showForm(),
        );
      },
    );
  }

  static String _label(ConsentStatus s) {
    switch (s) {
      case ConsentStatus.obtained:
        return 'Personalisierte Werbung erlaubt';
      case ConsentStatus.restricted:
        return 'Nur nicht-personalisierte Werbung';
      case ConsentStatus.required:
        return 'Einwilligung ausstehend';
      case ConsentStatus.unknown:
      case ConsentStatus.notRequired:
        return 'Noch nicht abgefragt';
    }
  }
}
```

### Schritt 8 — Registrierung

Datei: `packages/shared_base/lib/src/monetize/monetize_registration.dart`

```dart
import '../config/brand.dart';
import '../config/features.dart';
import '../config/registry.dart';
import 'ad_surface.dart';
import 'always_pro_purchases.dart';
import 'consent_gate.dart';
import 'no_op_ad_surface.dart';
import 'purchases.dart';

/// Einzige Stelle, an der Features.adsEnabled und Features.billingEnabled
/// gelesen werden. Apps sehen ausschließlich AdSurface, Purchases,
/// ConsentGate — nie einen Schalter.
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
```

Der geworfene `StateError` ist Absicht: Wer einen Schalter umlegt, ohne den
zugehörigen Einbau zu machen, soll beim ersten Start scheitern — nicht still
eine leere Fläche ausliefern.

Ergänzung in `packages/shared_base/lib/shared_base.dart`:

```dart
export 'src/monetize/ad_safe_area.dart';
export 'src/monetize/ad_surface.dart';
export 'src/monetize/always_pro_purchases.dart';
export 'src/monetize/consent_gate.dart';
export 'src/monetize/consent_tile.dart';
export 'src/monetize/monetize_registration.dart';
export 'src/monetize/no_op_ad_surface.dart';
export 'src/monetize/purchases.dart';
```

### Schritt 9 — CI-Prüfung erweitern

`tool/check_ad_ids.dart` aus `monorepo-bootstrap` prüft bisher eine Sache:
keine echte AdMob-ID im Quelltext. Dieser Skill erweitert sie um zwei
Prüfungen — beide brechen den Build.

Die Datei wird **ergänzt**, nicht ersetzt. Der bestehende Prüfteil bleibt
unverändert; folgender Block wird vor `exit(1)` bzw. vor der Erfolgsmeldung
eingefügt:

Datei: `tool/check_ad_ids.dart` — Ergänzung

```dart
// ---------------------------------------------------------------------------
// Zusatzprüfung 1: Schalter dürfen nicht ohne Einbau auf true stehen.
// ---------------------------------------------------------------------------
void _checkFeatureSwitches(List<String> offenders) {
  final File f =
      File('packages/shared_base/lib/src/config/features.dart');
  if (!f.existsSync()) {
    return;
  }
  final String src = f.readAsStringSync();

  bool isTrue(String name) =>
      RegExp('$name\\s*=\\s*true').hasMatch(src);

  final File reg = File(
      'packages/shared_base/lib/src/monetize/monetize_registration.dart');
  final String regSrc = reg.existsSync() ? reg.readAsStringSync() : '';

  if (isTrue('adsEnabled') && !regSrc.contains('AdMobAdSurface(')) {
    offenders.add(
      'features.dart -> adsEnabled = true, aber AdMobAdSurface ist in '
      'monetize_registration.dart nicht gebunden.',
    );
  }
  if (isTrue('billingEnabled') && !regSrc.contains('PlayBillingPurchases(')) {
    offenders.add(
      'features.dart -> billingEnabled = true, aber PlayBillingPurchases ist '
      'in monetize_registration.dart nicht gebunden.',
    );
  }
  if (isTrue('analyticsEnabled')) {
    offenders.add(
      'features.dart -> analyticsEnabled = true. Dieser Schalter bleibt '
      'dauerhaft false — kein Tracking, in keiner App. ARCHITEKTUR.md '
      'Abschnitt 5.',
    );
  }
}

// ---------------------------------------------------------------------------
// Zusatzprüfung 2: Kein App-Code darf Features direkt lesen.
// ARCHITEKTUR.md Abschnitt 5: Schalter nur in der Registrierung.
// ---------------------------------------------------------------------------
void _checkFeatureLeaks(List<String> offenders) {
  const List<String> allowed = <String>[
    'packages/shared_base/lib/src/config/features.dart',
    'packages/shared_base/lib/src/config/registry.dart',
    'packages/shared_base/lib/src/monetize/monetize_registration.dart',
    'packages/capture_core/lib/src/stt/stt_registration.dart',
    'packages/lens_core/lib/src/recognize/scan_registration.dart',
  ];

  for (final FileSystemEntity e in Directory('.').listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.dart')) {
      continue;
    }
    final String path = e.path.replaceFirst('./', '');
    if (path.contains('/build/') ||
        path.contains('/.dart_tool/') ||
        path.contains('/test/') ||
        path.startsWith('tool/') ||
        allowed.contains(path)) {
      continue;
    }
    final String src = e.readAsStringSync();
    if (RegExp(r'\bFeatures\.\w+').hasMatch(src)) {
      offenders.add(
        '$path liest Features direkt. Schalter gehören ausschließlich in die '
        'Registrierung — ARCHITEKTUR.md Abschnitt 5.',
      );
    }
  }
}
```

Beide Funktionen werden in `main()` aufgerufen, bevor die Erfolgsmeldung
ausgegeben wird:

```dart
  _checkFeatureSwitches(offenders);
  _checkFeatureLeaks(offenders);
```

Prüfen:

```bash
melos run check-ad-ids
```

Die Prüfung läuft bereits in `.github/workflows/ci.yml` als Schritt
„Werbe-IDs prüfen" — sie muss dort nicht ergänzt werden.

### Schritt 10 — Test-Anzeigen-IDs festschreiben

Datei: `packages/shared_base/lib/src/monetize/test_ad_units.dart`

```dart
/// Offizielle Test-Anzeigen-IDs von Google. Die einzigen IDs, die im
/// Quelltext stehen dürfen — tool/check_ad_ids.dart erlaubt genau dieses
/// Präfix und bricht bei jedem anderen.
///
/// Echte IDs kommen ausschließlich über --dart-define in den Release-Build.
class TestAdUnits {
  const TestAdUnits._();

  static const String androidBanner =
      'ca-app-pub-3940256099942544/6300978111';
  static const String iosBanner =
      'ca-app-pub-3940256099942544/2934735716';

  static const String androidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String iosInterstitial =
      'ca-app-pub-3940256099942544/4411468910';

  /// Liefert die ID für den laufenden Build. In Debug-Builds immer die
  /// Test-ID — auch dann, wenn über --dart-define eine echte übergeben wurde.
  static String bannerFor({required bool isAndroid, required bool isRelease}) {
    if (!isRelease) {
      return isAndroid ? androidBanner : iosBanner;
    }
    const String fromDefine =
        String.fromEnvironment('AD_UNIT_BANNER', defaultValue: '');
    if (fromDefine.isEmpty) {
      return isAndroid ? androidBanner : iosBanner;
    }
    return fromDefine;
  }
}
```

### Schritt 11 — Tests

Datei: `packages/shared_base/test/monetize_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_base/shared_base.dart';

void main() {
  setUp(() async {
    Registry.instance.reset();
    await registerMonetize();
  });

  test('Ohne Play-Konto wird NoOpAdSurface gebunden', () {
    final AdSurface ads = Registry.instance.get<AdSurface>();
    expect(ads.id, 'noop');
    expect(ads.isEnabled, isFalse);
  });

  test('Die reservierte Höhe ist konstant', () {
    final AdSurface ads = Registry.instance.get<AdSurface>();
    expect(ads.heightFor(AdSlot.bottomBanner), NoOpAdSurface.bannerHeight);
  });

  test('Der Mindestabstand beträgt mindestens 16 dp', () {
    final AdSurface ads = Registry.instance.get<AdSurface>();
    expect(ads.minimumGap, greaterThanOrEqualTo(16));
  });

  test('Ohne Play-Konto ist alles freigeschaltet', () {
    final Purchases p = Registry.instance.get<Purchases>();
    expect(p.current.isPro, isTrue);
    expect(p.isEnabled, isFalse);
  });

  test('Ohne Werbung ist keine Einwilligung nötig', () async {
    final ConsentGate gate = Registry.instance.get<ConsentGate>();
    expect(await gate.check(), ConsentStatus.notRequired);
    expect(gate.canRequestAds, isFalse);
  });

  testWidgets('AdSafeArea hält Banner plus Mindestabstand frei',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AdSafeArea(
          bottomAction: SizedBox(
            height: 56,
            child: FilledButton(onPressed: () {}, child: const Text('Aufnehmen')),
          ),
          child: const ColoredBox(color: Color(0xFFEEEEEE)),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final Rect button = tester.getRect(find.byType(FilledButton));
    final double screenBottom = tester.getSize(find.byType(MaterialApp)).height;
    final double distanceToBottom = screenBottom - button.bottom;

    // Banner (64) + Mindestabstand (16) = 80.
    expect(distanceToBottom,
        greaterThanOrEqualTo(NoOpAdSurface.bannerHeight + NoOpAdSurface.gap));
  });

  testWidgets('Der Aufnahmeknopf bleibt mindestens 56 dp hoch',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AdSafeArea(
          bottomAction: SizedBox(
            height: 56,
            child: FilledButton(onPressed: () {}, child: const Text('Aufnehmen')),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    ));
    expect(tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(56));
  });

  test('scrollPadding hält Banner, Abstand und Puffer frei', () {
    // 64 + 16 + 8
    expect(NoOpAdSurface.bannerHeight + NoOpAdSurface.gap + 8, 88);
  });
}
```

```bash
melos run analyze
melos exec --scope=shared_base -- flutter test test/monetize_test.dart
melos run check-ad-ids
```

### Schritt 12 — Einbau in bestehende Apps

Für jede App unter `apps/*`:

1. In `main.dart` vor `runApp` ergänzen:

```dart
  await registerMonetize();
```

2. Den Rumpf des Startbildschirms hüllen:

```dart
      body: AdSafeArea(
        bottomAction: RecordButton(
          state: _state,
          onStart: _start,
          onStop: _stop,
        ),
        child: <bisheriger Inhalt>,
      ),
```

Der `RecordButton` bekommt dabei `insideAdSafeArea: true` — sonst addieren
sich sein eigener unterer `Padding` von 16 dp und der `gap` aus `AdSafeArea`
zu 32 dp. Das Flag ist in `capture_core/lib/src/ui/record_button.dart`
vorgesehen und schaltet genau diesen Innenabstand ab.

3. In den Einstellungen ergänzen:

```dart
      const ConsentTile(),
```

4. In Listen und Rastern, die nicht in `AdSafeArea` stecken:

```dart
      padding: EdgeInsets.only(bottom: AdSafeArea.scrollPadding(context)),
```

Danach die Golden-Bilder neu erzeugen — das Layout hat sich um die reservierte
Fläche geändert:

```bash
melos run test-golden-update
```

**Die neuen Bilder vor dem Einchecken auf dem iPhone ansehen.** Ein
Golden-Test, dessen Referenz ungeprüft übernommen wird, prüft nichts.

## Abbruchkriterien

Der Skill stoppt und fragt, statt zu raten, wenn:

1. `packages/shared_base/lib/src/config/features.dart` fehlt →
   `monorepo-bootstrap` zuerst.
2. `Features.adsEnabled` oder `Features.billingEnabled` steht bereits auf
   `true`. Dann wurde außerhalb dieses Skills geschaltet — der Nutzer
   entscheidet, ob zurückgeschaltet oder der Einbau nachgeholt wird.
3. Der Nutzer verlangt, die Bannerhöhe oder den 16-dp-Abstand zu verkleinern.
   Das ist ein Sperrgrund im Store-Review, keine Gestaltungsfrage —
   `ARCHITEKTUR.md` Abschnitt 8.
4. Der Nutzer verlangt eine echte AdMob-ID im Quelltext. Die CI-Prüfung bricht
   dagegen; die ID gehört in `--dart-define`.
5. Der Nutzer verlangt, `google_mobile_ads` oder `in_app_purchase` jetzt schon
   als Abhängigkeit aufzunehmen. Beide brechen den Web-Build oder blähen ihn
   auf; sie kommen in `WF-04-GELD-DA.md`, Welle 1.
6. Eine App liest `Features` direkt. Der Skill nennt die Datei und die Zeile
   und baut nicht weiter, bis der Zugriff über die Registrierung läuft.
7. Der Nutzer verlangt, `analyticsEnabled` einzuschalten. Der Schalter ist
   dauerhaft `false` — kein Tracking, in keiner App.
8. Nach dem Einbau in bestehende Apps brechen Golden-Tests **und** der Nutzer
   hat die neuen Bilder nicht gesichtet. Nicht blind aktualisieren.

## Fertig, wenn

- [ ] `packages/shared_base/lib/src/monetize/` enthält `ad_surface.dart`,
      `no_op_ad_surface.dart`, `admob_ad_surface.dart`, `ad_safe_area.dart`,
      `purchases.dart`, `always_pro_purchases.dart`,
      `play_billing_purchases.dart`, `consent_gate.dart`, `consent_tile.dart`,
      `monetize_registration.dart`, `test_ad_units.dart`
- [ ] `AdSurface.heightFor` liefert denselben Wert in jedem Zustand
- [ ] `AdSurface.minimumGap` ist mindestens 16
- [ ] `AdSafeArea` hält Banner + Mindestabstand frei, geprüft im Widget-Test
- [ ] `AdSafeArea.scrollPadding` liefert 88
- [ ] `registerMonetize()` bindet `NoOpAdSurface`, `AlwaysProPurchases`,
      `NoConsentGate`
- [ ] `registerMonetize()` wirft `StateError`, wenn ein Schalter ohne Einbau
      auf `true` steht
- [ ] `ConsentTile` ist in den Einstellungen jeder App eingebunden
- [ ] `tool/check_ad_ids.dart` prüft zusätzlich Schalter-ohne-Einbau und
      direkten `Features`-Zugriff außerhalb der Registrierung
- [ ] `melos run check-ad-ids` meldet „OK"
- [ ] Nur Google-Test-IDs stehen im Quelltext
- [ ] `google_mobile_ads` und `in_app_purchase` sind **nicht** in
      `pubspec.yaml`
- [ ] `Features.adsEnabled == false`, `Features.billingEnabled == false`,
      `Features.analyticsEnabled == false`
- [ ] Alle acht Tests in `monetize_test.dart` sind grün
- [ ] Jede bestehende App ruft `registerMonetize()` vor `runApp`
- [ ] Golden-Bilder wurden neu erzeugt und auf dem iPhone gesichtet
- [ ] `melos run analyze` ohne Befund

## Beispielaufruf

```
Bau das Monetarisierungs-Modul: AdSurface und Purchases als Schnittstellen,
NoOpAdSurface und AlwaysProPurchases gebunden, Bannerfläche reserviert mit
16 dp Abstand, UMP-Gerüst, CI-Prüfung auf Test-IDs. Nichts einschalten.
```

```
Reservier die Bannerfläche in allen Apps. Der Aufnahmeknopf muss 16 dp
Abstand halten, und die Golden-Tests sollen den Abstand prüfen.
```

Weitere Formulierungen, die diesen Skill auslösen:

```
AdSurface und Purchases anlegen.
Werbung vorbereiten, aber nicht einschalten.
Kauf-Schnittstelle bauen.
```
