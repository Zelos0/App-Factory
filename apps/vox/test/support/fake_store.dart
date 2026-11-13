import 'dart:async';

import 'package:capture_core/capture_core.dart';
import 'package:drift/native.dart';
import 'package:shared_base/shared_base.dart';
import 'package:vox/src/vox_interpreter.dart';

/// Feste Uhrzeit aller Testdaten. Ohne sie änderte sich jedes Golden-Bild
/// mit jedem Tag, und die Prüfung wäre wertlos.
final DateTime kFixedNow = DateTime(2026, 3, 14, 9, 41);

/// Echter EntryStore auf einer Datenbank im Arbeitsspeicher, mit fester
/// Uhr. Golden-Bilder zeigen damit die ECHTEN Bildschirme mit echten Daten —
/// keine nachgebauten Attrappen, die an Layoutfehlern vorbeisehen.
class FakeVox {
  FakeVox._(this.db, this.store, this._clock);

  static Future<FakeVox> open() async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    final _Clock clock = _Clock();
    final EntryStore store =
        EntryStore(db, type: 'vox', clock: () => clock.now);
    return FakeVox._(db, store, clock);
  }

  final AppDatabase db;
  final EntryStore store;
  final _Clock _clock;

  /// Legt einen Eintrag an, wie die App es tut: Segmente anhängen, danach
  /// den Interpreter darüberlaufen lassen.
  Future<String> add(
    List<String?> segments, {
    Duration ago = Duration.zero,
    String? mediaPath,
  }) async {
    _clock.now = kFixedNow.subtract(ago);
    final Entry e = await store.createEntry();
    for (int i = 0; i < segments.length; i++) {
      _clock.now = kFixedNow.subtract(ago).add(Duration(minutes: 3 * i));
      await store.appendSegment(
        e.id,
        transcript: segments[i],
        engine: 'platform',
        mediaPath: mediaPath,
      );
    }
    final EntryWithSegments full = (await store.byId(e.id))!;
    await store.updateData(
      e.id,
      const VoxInterpreter().parse(full.fullText, now: kFixedNow).toJson(),
    );
    return e.id;
  }

  /// Drei Einträge, bewusst gemischt: mehrteilig mit Schlagworten, einfach,
  /// und einer ohne erkannten Text — damit das Bild nicht nur den
  /// Schönfall zeigt.
  Future<String> seed() async {
    await add(
      <String?>[null],
      ago: const Duration(days: 5),
      mediaPath: 'vox/ohne-text.webm',
    );
    await add(
      <String?>[
        'Rückruf bei der Werkstatt wegen der Bremsen, Termin Donnerstag',
      ],
      ago: const Duration(days: 1),
    );
    return add(
      <String?>[
        'Idee für den Garten: Hochbeet an der Südseite, '
            'Tomaten und Basilikum zusammen pflanzen',
        'Basilikum braucht viel Sonne, Tomaten auch. '
            'Hochbeet im April bauen, Erde vom Kompost nehmen',
      ],
      mediaPath: 'vox/garten.webm',
    );
  }

  Future<void> close() => db.close();
}

class _Clock {
  DateTime now = kFixedNow;
}

/// Mikrofon-Attrappe: steht still, nimmt nichts auf, braucht kein Plugin.
class FakeRecorder implements AudioRecorder {
  final StreamController<RecordingState> _state =
      StreamController<RecordingState>.broadcast();

  @override
  Stream<RecordingState> get state => _state.stream;

  @override
  Stream<double> get amplitude => const Stream<double>.empty();

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> start() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<RecordingResult?> stop() async => null;

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() => _state.close();
}
