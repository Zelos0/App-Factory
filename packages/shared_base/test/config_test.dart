import 'package:flutter_test/flutter_test.dart';
import 'package:shared_base/shared_base.dart';

/// Prueft das Fundament: die Schalter stehen im kostenlosen Zustand, die
/// Marke stimmt, und die Registrierung verhaelt sich wie in ARCHITEKTUR.md
/// Abschnitt 4 und 5 beschrieben.
void main() {
  group('Features — kostenloser Zustand', () {
    test('alle kostenpflichtigen Schalter sind aus', () {
      expect(Features.adsEnabled, isFalse);
      expect(Features.billingEnabled, isFalse);
      expect(Features.parakeetEnabled, isFalse);
    });

    test('Analytics ist dauerhaft aus — kein Tracking, in keiner App', () {
      expect(Features.analyticsEnabled, isFalse);
    });

    test('sttEngine ist ohne --dart-define die Plattform-Engine', () {
      expect(Features.sttEngine, 'platform');
    });
  });

  group('Marke und Flavor', () {
    test('kBrand folgt dem Muster aus Abschnitt 9', () {
      expect(kBrand, 'de.zeta');
    });

    test('kApplicationId setzt sich aus Marke und Flavor zusammen', () {
      expect(kApplicationId, '$kBrand.$kFlavor');
    });
  });

  group('Registry', () {
    setUp(Registry.instance.reset);

    test('bind und get liefern dieselbe Instanz zurueck', () {
      const _Beispiel implementierung = _Beispiel();
      Registry.instance.bind<_Beispiel>(implementierung);

      expect(Registry.instance.has<_Beispiel>(), isTrue);
      expect(Registry.instance.get<_Beispiel>(), same(implementierung));
    });

    test('get wirft, wenn nichts gebunden ist — Programmierfehler', () {
      expect(Registry.instance.get<_Beispiel>, throwsStateError);
    });

    test('reset loest alle Bindungen', () {
      Registry.instance.bind<_Beispiel>(const _Beispiel());
      Registry.instance.reset();

      expect(Registry.instance.has<_Beispiel>(), isFalse);
    });
  });

  group('resolveSttEngineId', () {
    test('faellt ohne Web und ohne Parakeet auf die Plattform-Engine', () {
      expect(resolveSttEngineId(), 'platform');
    });
  });
}

class _Beispiel {
  const _Beispiel();
}
