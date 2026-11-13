import 'package:capture_core/capture_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveTranscript', () {
    test('vorläufige Ergebnisse ersetzen sich, endgültige bleiben', () {
      final LiveTranscript t = LiveTranscript()
        ..add('Brot', isFinal: false)
        ..add('Brot und', isFinal: false)
        ..add('Brot und Milch', isFinal: true);
      expect(t.text, 'Brot und Milch');

      t
        ..add('kaufen', isFinal: false)
        ..add('kaufen bis', isFinal: false);
      expect(t.text, 'Brot und Milch kaufen bis');
    });

    test('nach einer Sprechpause geht nichts verloren', () {
      // Die Engine beendet sich mitten im Satz; das Vorläufige muss als
      // endgültig übernommen werden, bevor der Neustart bei null beginnt.
      final LiveTranscript t = LiveTranscript()
        ..add('erster Gedanke', isFinal: false)
        ..commitPartial()
        ..add('zweiter Gedanke', isFinal: true);
      expect(t.text, 'erster Gedanke zweiter Gedanke');
    });

    test('commitPartial ohne Vorläufiges ändert nichts', () {
      final LiveTranscript t = LiveTranscript()
        ..add('fertig', isFinal: true)
        ..commitPartial()
        ..commitPartial();
      expect(t.text, 'fertig');
    });

    test('Leerzeichen und leere Ergebnisse werden geglättet', () {
      final LiveTranscript t = LiveTranscript()
        ..add('  eins ', isFinal: true)
        ..add('   ', isFinal: true)
        ..add('zwei', isFinal: true);
      expect(t.text, 'eins zwei');
    });

    test('„Nichts erkannt" nach erkanntem Text ist kein Fehler', () {
      final LiveTranscript t = LiveTranscript()
        ..add('Termin morgen', isFinal: true)
        ..fail('error_no_match');
      expect(t.error, isNull);
      expect(t.text, 'Termin morgen');
    });

    test('„Nichts erkannt" ohne Text wird gemeldet', () {
      final LiveTranscript t = LiveTranscript()..fail('no-speech');
      expect(t.error, contains('Nichts verstanden'));
    });

    test('reset verwirft Text und Fehler', () {
      final LiveTranscript t = LiveTranscript()
        ..add('alt', isFinal: true)
        ..fail('network');
      t.reset();
      expect(t.text, isEmpty);
      expect(t.error, isNull);
    });
  });

  group('Fehlertexte', () {
    // Codes so, wie Android, iOS und die Web Speech API sie liefern.
    final Map<String, String> expected = <String, String>{
      'error_permission': 'nicht erlaubt',
      'not-allowed': 'nicht erlaubt',
      'error_network': 'Internet',
      'network': 'Internet',
      'error_server': 'Internet',
      'audio-capture': 'Mikrofon',
      'error_busy': 'Mikrofon',
      'unavailable': 'keine Spracherkennung',
      'language-not-supported': 'keine Spracherkennung',
    };

    expected.forEach((String code, String fragment) {
      test('$code → verständlich', () {
        final String text = LiveTranscript.describe(code);
        expect(text, contains(fragment));
        expect(text, contains('Aufnahme ist gespeichert'));
      });
    });

    test('Unbekannter Code bleibt zur Fehlersuche sichtbar', () {
      expect(LiveTranscript.describe('xyz_42'), contains('xyz_42'));
    });
  });

  group('PlatformSttEngine', () {
    test('ohne Live-Sitzung verweigert sie die Datei ehrlich', () async {
      final PlatformSttEngine e = PlatformSttEngine();
      await expectLater(
        e.transcribe('a.m4a'),
        throwsA(
          isA<SttFailure>().having(
            (SttFailure f) => f.message,
            'message',
            contains('Pro-Engine'),
          ),
        ),
      );
    });

    test('ist eine LiveSttEngine — der Recorder steuert sie', () {
      expect(PlatformSttEngine(), isA<LiveSttEngine>());
    });

    test('Stub ist KEINE LiveSttEngine — liest weiter „Dateien"', () {
      expect(WebStubSttEngine(), isNot(isA<LiveSttEngine>()));
    });
  });
}
