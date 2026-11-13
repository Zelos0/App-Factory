import 'package:flutter_test/flutter_test.dart';
import 'package:shared_base/shared_base.dart';

void main() {
  group('SpokenNumbers.parseWord — deutsche Zahlwörter', () {
    test('Einer, Zehner und die Engine-Variante "zwo"', () {
      expect(SpokenNumbers.parseWord('drei'), 3);
      expect(SpokenNumbers.parseWord('zwo'), 2);
      expect(SpokenNumbers.parseWord('zwölf'), 12);
      expect(SpokenNumbers.parseWord('fünfzig'), 50);
    });

    test('fehlende Umlaute werden mitgelesen', () {
      expect(SpokenNumbers.parseWord('fuenf'), 5);
      expect(SpokenNumbers.parseWord('zwoelf'), 12);
      expect(SpokenNumbers.parseWord('dreissig'), 30);
    });

    test('Zusammensetzungen — der Einer steht vorn', () {
      expect(SpokenNumbers.parseWord('einundzwanzig'), 21);
      expect(SpokenNumbers.parseWord('zweiundzwanzig'), 22);
      expect(SpokenNumbers.parseWord('neunundneunzig'), 99);
    });

    test('Hunderter und Tausender', () {
      expect(SpokenNumbers.parseWord('hundert'), 100);
      expect(SpokenNumbers.parseWord('hundertvier'), 104);
      expect(SpokenNumbers.parseWord('zweihundert'), 200);
      expect(SpokenNumbers.parseWord('hundertvierundachtzig'), 184);
      expect(SpokenNumbers.parseWord('tausend'), 1000);
      expect(SpokenNumbers.parseWord('fünftausend'), 5000);
      expect(SpokenNumbers.parseWord('zweitausendfünfhundert'), 2500);
    });

    test('Ziffern gehen auch durch', () {
      expect(SpokenNumbers.parseWord('184'), 184);
      expect(SpokenNumbers.parseWord('0'), 0);
    });

    test('kein Zahlwort ergibt null, nicht 0', () {
      expect(SpokenNumbers.parseWord('rewe'), isNull);
      expect(SpokenNumbers.parseWord(''), isNull);
      expect(SpokenNumbers.parseWord('null'), 0, reason: 'null IST eine Zahl');
    });
  });

  group('SpokenNumbers.parseAmount — Beträge, wie sie gesprochen werden', () {
    test('Ziffernform mit Komma und Punkt', () {
      expect(SpokenNumbers.parseAmount('22,50 bei Rewe'), 22.50);
      expect(SpokenNumbers.parseAmount('22.50 bei Rewe'), 22.50);
      expect(SpokenNumbers.parseAmount('8,9 Liter'), 8.90);
    });

    test('der Satz, an dem sich alles misst', () {
      expect(SpokenNumbers.parseAmount('zweiundzwanzig fünfzig bei Rewe'),
          22.50);
    });

    test('Engine-Fehler: "zwo" statt "zwei"', () {
      expect(SpokenNumbers.parseAmount('zwo euro fünfzig'), 2.50);
    });

    test('Euro-Marker trennt Euro und Cent', () {
      expect(SpokenNumbers.parseAmount('acht euro neunzig beim Bäcker'), 8.90);
      expect(SpokenNumbers.parseAmount('drei euro im Kiosk'), 3.0);
      expect(SpokenNumbers.parseAmount('sechzig euro tanken'), 60.0);
    });

    test('Cent ohne Euro-Anteil — der Fall, den die Vorlage verlor', () {
      expect(SpokenNumbers.parseAmount('neunundneunzig cent bei Aldi'), 0.99);
    });

    test('einstellig gesprochene Cent sind Zehner', () {
      expect(SpokenNumbers.parseAmount('vierzehn siebzig'), 14.70);
      expect(SpokenNumbers.parseAmount('drei fünf'), 3.50);
    });

    test('große Zahl aus einem Kompositum', () {
      expect(
        SpokenNumbers.parseAmount('hundertvierundachtzig neunzig Werkstatt'),
        184.90,
      );
    });

    test('ohne Zahl kommt null zurück', () {
      expect(SpokenNumbers.parseAmount('bei dm gewesen'), isNull);
      expect(SpokenNumbers.parseAmount(''), isNull);
    });
  });

  group('SpokenDates.parse — Zeitangaben', () {
    // Ein Dienstag. Fester Bezugspunkt, damit die Tests um Mitternacht
    // dasselbe sagen wie um Mittag.
    final DateTime now = DateTime(2026, 8, 11, 14, 30);
    final DateTime today = DateTime(2026, 8, 11);

    test('heute, gestern, vorgestern, morgen', () {
      expect(SpokenDates.parse('heute eingekauft', now: now), today);
      expect(
        SpokenDates.parse('gestern eingekauft', now: now),
        DateTime(2026, 8, 10),
      );
      expect(
        SpokenDates.parse('vorgestern eingekauft', now: now),
        DateTime(2026, 8, 9),
      );
      expect(
        SpokenDates.parse('morgen einkaufen', now: now),
        DateTime(2026, 8, 12),
      );
    });

    test('"vorgestern" gewinnt gegen das darin steckende "gestern"', () {
      // Regression: ohne Wortgrenzenprüfung gewann "gestern", weil es in
      // "vorgestern" steckt und drei Zeichen weiter rechts steht.
      expect(
        SpokenDates.parse('vorgestern', now: now),
        DateTime(2026, 8, 9),
      );
      expect(
        SpokenDates.parse('übermorgen', now: now),
        DateTime(2026, 8, 13),
      );
    });

    test('die Uhrzeit fällt weg — der Tag zählt', () {
      expect(SpokenDates.parse('heute', now: now)!.hour, 0);
    });

    test('ein Wochentag ohne Richtungswort meint den vergangenen', () {
      // Dienstag, 11.8. — der letzte Freitag war der 7.8.
      expect(
        SpokenDates.parse('letzten Freitag getankt', now: now),
        DateTime(2026, 8, 7),
      );
      expect(
        SpokenDates.parse('am Montag bezahlt', now: now),
        DateTime(2026, 8, 10),
      );
    });

    test('derselbe Wochentag heute meint die Woche davor', () {
      expect(
        SpokenDates.parse('am Dienstag bezahlt', now: now),
        DateTime(2026, 8, 4),
        reason: 'Festgehalten wird, was war — nicht der heutige Tag',
      );
    });

    test('"nächsten" dreht die Richtung um', () {
      expect(
        SpokenDates.parse('nächsten Montag anrufen', now: now),
        DateTime(2026, 8, 17),
      );
      expect(
        SpokenDates.parse('nächsten Dienstag anrufen', now: now),
        DateTime(2026, 8, 18),
      );
    });

    test('explizites Datum, mit und ohne Jahr', () {
      expect(
        SpokenDates.parse('am 12.03.2026 bezahlt', now: now),
        DateTime(2026, 3, 12),
      );
      expect(
        SpokenDates.parse('am 12.3. bezahlt', now: now),
        DateTime(2026, 3, 12),
      );
      expect(
        SpokenDates.parse('am 12.3.25 bezahlt', now: now),
        DateTime(2025, 3, 12),
      );
    });

    test('der letzte Treffer gewinnt — Selbstkorrektur beim Sprechen', () {
      expect(
        SpokenDates.parse('gestern, ähm nein, am Montag', now: now),
        DateTime(2026, 8, 10),
      );
    });

    test('ohne Angabe kommt null zurück — der Aufrufer entscheidet', () {
      expect(SpokenDates.parse('bei Rewe eingekauft', now: now), isNull);
      expect(SpokenDates.parse('', now: now), isNull);
    });
  });
}
