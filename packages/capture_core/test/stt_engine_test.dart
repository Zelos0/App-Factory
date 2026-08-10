import 'package:capture_core/capture_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Stub liefert Beispieltext und meldet seine Kennung', () async {
    final WebStubSttEngine e = WebStubSttEngine(delay: Duration.zero);
    final Transcript t = await e.transcribe('egal.m4a');
    expect(t.text, isNotEmpty);
    expect(t.engine, 'web');
    expect(e.isAvailable, isTrue);
  });

  test('Stub liefert der Reihe nach verschiedene Sätze', () async {
    final WebStubSttEngine e = WebStubSttEngine(
      delay: Duration.zero,
      samples: <String>['eins', 'zwei'],
    );
    expect((await e.transcribe('a')).text, 'eins');
    expect((await e.transcribe('b')).text, 'zwei');
    expect((await e.transcribe('c')).text, 'eins');
  });

  test('Stub erzeugt den Fehlerweg, wenn die Fehlerquote 1.0 ist', () async {
    final WebStubSttEngine e = WebStubSttEngine(
      delay: Duration.zero,
      failureRate: 1.0,
    );
    expect(() => e.transcribe('a'), throwsA(isA<SttFailure>()));
  });

  test('Verzögerung ist einstellbar — Ladezustand bleibt prüfbar', () async {
    final WebStubSttEngine e = WebStubSttEngine(
      delay: const Duration(milliseconds: 120),
    );
    final Stopwatch sw = Stopwatch()..start();
    await e.transcribe('a');
    sw.stop();
    expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(100));
  });

  test('Plattform-Engine verweigert die Datei-Transkription ehrlich', () async {
    final PlatformSttEngine e = PlatformSttEngine();
    expect(() => e.transcribe('a.m4a'), throwsA(isA<SttFailure>()));
    // Ohne init() ist sie nicht verfuegbar — und sagt das auch.
    expect(e.isAvailable, isFalse);
  });
}
