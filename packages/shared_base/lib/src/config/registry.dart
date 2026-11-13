import 'package:flutter/foundation.dart';

import 'features.dart';

/// Zentrale Registrierung aller Schnittstellen-Implementierungen.
///
/// Einzige Stelle im gesamten Monorepo, an der `Features` gelesen wird.
/// Kerne und Apps beziehen Implementierungen ausschließlich über [get].
class Registry {
  Registry._();

  static final Registry instance = Registry._();

  final Map<Type, Object> _bindings = <Type, Object>{};

  /// Bindet eine Implementierung an ihre Schnittstelle.
  void bind<T extends Object>(T implementation) {
    _bindings[T] = implementation;
  }

  /// Liefert die gebundene Implementierung. Wirft, wenn nichts gebunden ist —
  /// das ist ein Programmierfehler, kein Laufzeitfall.
  T get<T extends Object>() {
    final Object? value = _bindings[T];
    if (value == null) {
      throw StateError(
        'Keine Implementierung für $T gebunden. '
        'Registrierung fehlt in configureRegistry().',
      );
    }
    return value as T;
  }

  /// True, wenn die Bindung existiert. Für Tests.
  bool has<T extends Object>() => _bindings.containsKey(T);

  /// Nur für Tests.
  @visibleForTesting
  void reset() => _bindings.clear();
}

/// Ergebnis der Plattform- und Schalterauswertung. Wird von den Kern-Skills
/// (`capture-core-build`, `lens-core-build`, `monetize-modul`) erweitert,
/// indem sie ihre Bindungen hier eintragen.
String resolveSttEngineId() {
  if (kIsWeb) {
    return 'web';
  }
  if (Features.sttEngine == 'parakeet' && !Features.parakeetEnabled) {
    return 'platform';
  }
  return Features.sttEngine;
}
