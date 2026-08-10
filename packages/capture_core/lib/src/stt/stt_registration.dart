import 'package:shared_base/shared_base.dart';

import 'platform_stt_engine.dart';
import 'stt_engine.dart';
import 'web_stub_stt_engine.dart';

/// Einzige Stelle, an der eine konkrete Engine gewählt wird.
/// Aufruf beim App-Start, vor dem ersten Zugriff.
Future<void> registerSttEngine() async {
  final String wanted = resolveSttEngineId();

  switch (wanted) {
    case 'web':
      Registry.instance.bind<SttEngine>(WebStubSttEngine());
    case 'parakeet':
      // Bis Stufe D aktiv ist, fängt resolveSttEngineId() diesen Fall ab.
      // Der Zweig bleibt, damit das Einhängen später eine Zeile ist.
      final PlatformSttEngine fallback = PlatformSttEngine();
      await fallback.init();
      Registry.instance.bind<SttEngine>(fallback);
    case 'platform':
    default:
      final PlatformSttEngine engine = PlatformSttEngine();
      await engine.init();
      Registry.instance.bind<SttEngine>(engine);
  }
}
