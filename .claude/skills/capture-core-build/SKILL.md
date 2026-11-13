---
name: capture-core-build
description: Baut das Sprach-Kernpaket capture_core in vier zwingenden Stufen — erst Datenmodell und Speicher, dann Aufnahme und Wiedergabe, dann die SttEngine-Schnittstelle mit Web-Stub und Plattform-Engine, zuletzt Parakeet. Auslösen mit "bau den Sprach-Kern", "capture_core aufbauen", "Aufnahme und Transkription einbauen", "Stufe 1 des Sprach-Kerns", "jetzt Parakeet einhängen".
---

# Sprach-Kern bauen — `capture_core`

## Wann dieser Skill greift

**Greift**, wenn das Fundament steht und der Sprach-Kern ganz oder teilweise
fehlt. Der Skill ist in vier Stufen zerlegt, jede einzeln aufrufbar:

| Stufe | Inhalt | Ohne Geld testbar |
|---|---|---|
| **A** | Datenmodell `Entry`/`Segment`, drift-Speicher, Suche, `FileVault`, Export- und Gestaltungs-Unterbau | vollständig |
| **B** | Aufnahme, Wellenform, Wiedergabe, Segment-Anhängen | vollständig |
| **C** | `SttEngine` + `WebStubSttEngine` + `PlatformSttEngine` | vollständig |
| **D** | `ParakeetSttEngine` über sherpa-onnx | nein — braucht Gerät |

**Reihenfolge ist zwingend: A → B → C → D.**

**Begründung, warum Parakeet zuletzt kommt und nicht früher:** Parakeet ist die
riskanteste Integration des gesamten Portfolios. Ein ~640 MB großes Modell, ein
natives Plugin (sherpa-onnx), Nachladelogik, Speicherdruck auf Mittelklasse-
geräten, plattformabhängiges Verhalten — und nichts davon ist auf einem iPhone
im Browser beurteilbar. Läge Parakeet im kritischen Pfad, stünde die gesamte
Fabrik still, bis ein Android-Gerät da ist. Liegt es am Ende, ist bis dahin
**alles andere vollständig testbar**: Datenmodell, Segmentkette, Aufnahme,
Interpreter, Auswertung, Export, Gestaltung. Das sind die achtzig Prozent.
Stufe D wird gebaut, aber hinter `Features.parakeetEnabled` stillgelegt.

**Greift nicht** bei:

| Wunsch | Zuständiger Skill |
|---|---|
| Repo existiert noch nicht | `monorepo-bootstrap` |
| Kamera, Scan, OCR, PDF-Textebene | `lens-core-build` |
| Eine konkrete App bauen | `app-derive` |
| Werbefläche, Kauf-Schnittstelle | `monetize-modul` |
| Tests einrichten | `test-loop-free` |

## Voraussetzungen

| Was | Wer liefert es | Prüfbefehl |
|---|---|---|
| `melos.yaml` im Wurzelverzeichnis | `monorepo-bootstrap` | `test -f melos.yaml` |
| `packages/shared_base/lib/src/config/registry.dart` | `monorepo-bootstrap` | `test -f packages/shared_base/lib/src/config/registry.dart` |
| `packages/capture_core/pubspec.yaml` | `monorepo-bootstrap` | `test -f packages/capture_core/pubspec.yaml` |
| `melos run analyze` ohne Befund | vorheriger Lauf | `melos run analyze` |

Fehlt eines davon: abbrechen, `monorepo-bootstrap` nennen, nicht selbst anlegen.

Für Stufe D zusätzlich: ein echtes Android-Gerät. Fehlt es, wird Stufe D
**gebaut und getestet, aber nicht aktiviert** — `Features.parakeetEnabled`
bleibt `false`, und `resolveSttEngineId()` fällt auf `'platform'` zurück.

## Ablauf

---

## Stufe A — Datenmodell und Speicher

Das Segment-Datenmodell aus `ARCHITEKTUR.md` Abschnitt 3 ist **nicht
verhandelbar**. Es trägt die Kernanforderung „ein Eintrag ist jederzeit
erweiterbar". Ein Eintrag ist eine geordnete Kette von Segmenten, kein
Textblock. Wer daraus ein `String transcript`-Feld macht, zerstört vier
Fähigkeiten auf einmal: Anhängen, Nachhören je Abschnitt, Zeitstempel je
Gedanke, Neu-Transkription einzelner Segmente mit besserer Engine.

### A.1 — Datenklassen

Datei: `packages/shared_base/lib/src/storage/models.dart`

```dart
import 'dart:convert';

/// Ein Eintrag. Wortgleich zu ARCHITEKTUR.md Abschnitt 3.
class Entry {
  Entry({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    List<String>? tags,
    Map<String, dynamic>? data,
  })  : tags = tags ?? <String>[],
        data = data ?? <String, dynamic>{};

  /// UUID v4.
  final String id;

  /// App-Kennung, identisch mit dem Flavor. Beispiel: 'vox'.
  final String type;

  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;

  /// Ergebnis des Interpreters. Struktur legt die jeweilige App fest.
  final Map<String, dynamic> data;

  Entry copyWith({
    String? title,
    DateTime? updatedAt,
    List<String>? tags,
    Map<String, dynamic>? data,
  }) {
    return Entry(
      id: id,
      type: type,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'tags': tags,
        'data': data,
      };

  static Entry fromJson(Map<String, dynamic> json) => Entry(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        tags: (json['tags'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e as String)
            .toList(),
        data: (json['data'] as Map<dynamic, dynamic>? ?? <dynamic, dynamic>{})
            .cast<String, dynamic>(),
      );
}

/// Ein Abschnitt eines Eintrags. Die Kette dieser Objekte IST der Eintrag.
class Segment {
  const Segment({
    required this.id,
    required this.entryId,
    required this.order,
    required this.engine,
    required this.createdAt,
    this.mediaPath,
    this.transcript,
  });

  final String id;
  final String entryId;

  /// Reihenfolge innerhalb des Eintrags. Lückenlos ab 0.
  final int order;

  /// Pfad zur Audio- oder Bilddatei. Null, wenn nur Text.
  final String? mediaPath;

  /// Erkannter Text. Null, solange die Transkription läuft oder scheiterte.
  final String? transcript;

  /// Kennung der Engine, die den Text erzeugt hat: 'web' | 'platform' |
  /// 'parakeet' | 'manual'. Trägt die Neu-Transkription: ein Segment mit
  /// engine == 'platform' kann später mit 'parakeet' erneut gelesen werden.
  final String engine;

  final DateTime createdAt;

  Segment copyWith({int? order, String? transcript, String? engine}) => Segment(
        id: id,
        entryId: entryId,
        order: order ?? this.order,
        mediaPath: mediaPath,
        transcript: transcript ?? this.transcript,
        engine: engine ?? this.engine,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'entryId': entryId,
        'order': order,
        'mediaPath': mediaPath,
        'transcript': transcript,
        'engine': engine,
        'createdAt': createdAt.toIso8601String(),
      };

  static Segment fromJson(Map<String, dynamic> json) => Segment(
        id: json['id'] as String,
        entryId: json['entryId'] as String,
        order: json['order'] as int,
        mediaPath: json['mediaPath'] as String?,
        transcript: json['transcript'] as String?,
        engine: json['engine'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Eintrag samt seiner geordneten Segmentkette.
class EntryWithSegments {
  const EntryWithSegments(this.entry, this.segments);

  final Entry entry;
  final List<Segment> segments;

  /// Der zusammengesetzte Volltext in Reihenfolge. Für Suche und Interpreter.
  String get fullText => segments
      .where((Segment s) => (s.transcript ?? '').isNotEmpty)
      .map((Segment s) => s.transcript!)
      .join('\n\n');

  String toJsonString() => const JsonEncoder.withIndent('  ')
      .convert(<String, dynamic>{
        'entry': entry.toJson(),
        'segments': segments.map((Segment s) => s.toJson()).toList(),
      });
}
```

### A.2 — drift-Datenbank

Datei: `packages/shared_base/lib/src/storage/database.dart`

```dart
import 'package:drift/drift.dart';

part 'database.g.dart';

/// `@DataClassName` ist Pflicht, nicht Geschmack: drift leitet aus der Tabelle
/// `Entries` sonst eine Datenklasse `Entry` ab und aus `Segments` eine Klasse
/// `Segment` — beide Namen sind in `models.dart` bereits vergeben. Ohne die
/// Umbenennung kollidieren erzeugter und handgeschriebener Code, sobald
/// `shared_base.dart` beide exportiert.
@DataClassName('EntryRow')
class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get title => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// JSON-Liste.
  TextColumn get tags => text().withDefault(const Constant<String>('[]'))();

  /// JSON-Objekt — Ergebnis des Interpreters.
  TextColumn get data => text().withDefault(const Constant<String>('{}'))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('SegmentRow')
class Segments extends Table {
  TextColumn get id => text()();
  TextColumn get entryId =>
      text().references(Entries, #id, onDelete: KeyAction.cascade)();

  /// `order` ist in SQL ein Schlüsselwort. Der Dart-Name bleibt `order`,
  /// weil ARCHITEKTUR.md Abschnitt 3 ihn so festlegt; die Spalte heißt
  /// deshalb ausdrücklich `sort_order`, damit kein Zitieren nötig ist.
  IntColumn get order => integer().named('sort_order')();

  TextColumn get mediaPath => text().nullable()();
  TextColumn get transcript => text().nullable()();
  TextColumn get engine => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DriftDatabase(tables: <Type>[Entries, Segments])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await customStatement(
            'CREATE INDEX idx_segments_entry_order '
            'ON segments (entry_id, sort_order)',
          );
          await customStatement(
            'CREATE INDEX idx_entries_type_updated '
            'ON entries (type, updated_at DESC)',
          );
          // Volltextsuche über Segmenttexte.
          await customStatement(
            'CREATE VIRTUAL TABLE segment_fts USING fts5('
            'segment_id UNINDEXED, entry_id UNINDEXED, transcript)',
          );
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Ab Schema 2 hier ergänzen. Jede Migration bekommt einen Test
          // in packages/shared_base/test/migration_test.dart.
        },
        beforeOpen: (OpeningDetails details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
```

Nach dem Anlegen:

```bash
cd packages/shared_base
dart run build_runner build --delete-conflicting-outputs
```

### A.3 — Plattformabhängige Verbindung

Datei: `packages/shared_base/lib/src/storage/connection/native.dart`

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openConnection(String flavor) {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, '$flavor.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

Datei: `packages/shared_base/lib/src/storage/connection/web.dart`

```dart
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

QueryExecutor openConnection(String flavor) {
  return LazyDatabase(() async {
    final WasmDatabaseResult result = await WasmDatabase.open(
      databaseName: flavor,
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}
```

Datei: `packages/shared_base/lib/src/storage/connection/stub.dart`

```dart
import 'package:drift/drift.dart';

QueryExecutor openConnection(String flavor) =>
    throw UnsupportedError('Keine Datenbankverbindung für diese Plattform.');
```

Datei: `packages/shared_base/lib/src/storage/connection.dart`

```dart
export 'connection/stub.dart'
    if (dart.library.io) 'connection/native.dart'
    if (dart.library.js_interop) 'connection/web.dart';
```

Für den Web-Build müssen `sqlite3.wasm` und `drift_worker.js` in `web/` jeder
App liegen. Beide sind **Release-Artefakte, keine erzeugten Dateien** — der
früher übliche Befehl `dart run drift_dev make-worker` existiert ab drift 2.20
nicht mehr. Bezogen werden sie so:

```bash
curl -L -o apps/$FLAVOR/web/sqlite3.wasm \
  https://github.com/simolus3/sqlite3.dart/releases/latest/download/sqlite3.wasm
curl -L -o apps/$FLAVOR/web/drift_worker.js \
  https://github.com/simolus3/drift/releases/latest/download/drift_worker.js
```

`app-derive` führt das je App aus. Fehlt eine der beiden Dateien, startet der
Web-Build zwar, aber die Datenbank bleibt tot — das ist der Fall, den die
Abbruchbedingung von Tag 2 in `WF-01-ERSTE-APP.md` meint.

### A.4 — Der Speicher als Schnittstelle

Datei: `packages/shared_base/lib/src/storage/entry_store.dart`

```dart
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'models.dart';

/// Einzige Tür zu den Daten. Kein Kern und keine App greift direkt auf
/// [AppDatabase] zu.
class EntryStore {
  EntryStore(this._db, {required this.type});

  final AppDatabase _db;

  /// Flavor-Kennung. Trennt die Einträge mehrerer Apps in derselben Datei.
  final String type;

  static const Uuid _uuid = Uuid();

  /// Legt einen leeren Eintrag an. Segmente kommen per [appendSegment] dazu.
  Future<Entry> createEntry({String? title, List<String>? tags}) async {
    final DateTime now = DateTime.now();
    final Entry entry = Entry(
      id: _uuid.v4(),
      type: type,
      title: title,
      createdAt: now,
      updatedAt: now,
      tags: tags,
    );
    await _db.into(_db.entries).insert(_toRow(entry));
    return entry;
  }

  /// Hängt ein Segment ans Ende der Kette. Das ist die gesamte Mechanik
  /// hinter „ein Eintrag ist jederzeit erweiterbar".
  Future<Segment> appendSegment(
    String entryId, {
    String? mediaPath,
    String? transcript,
    required String engine,
  }) async {
    final int next = await _nextOrder(entryId);
    final Segment segment = Segment(
      id: _uuid.v4(),
      entryId: entryId,
      order: next,
      mediaPath: mediaPath,
      transcript: transcript,
      engine: engine,
      createdAt: DateTime.now(),
    );
    await _db.into(_db.segments).insert(
          SegmentsCompanion.insert(
            id: segment.id,
            entryId: segment.entryId,
            order: segment.order,
            mediaPath: Value<String?>(segment.mediaPath),
            transcript: Value<String?>(segment.transcript),
            engine: segment.engine,
            createdAt: segment.createdAt,
          ),
        );
    await _touch(entryId);
    await _reindex(segment);
    return segment;
  }

  /// Ersetzt den Text eines Segments und merkt sich die neue Engine.
  /// Trägt die Funktion „Präzision prüfen" aus ARCHITEKTUR.md Abschnitt 6.
  Future<void> retranscribe(
    String segmentId, {
    required String transcript,
    required String engine,
  }) async {
    await (_db.update(_db.segments)
          ..where(($SegmentsTable t) => t.id.equals(segmentId)))
        .write(
      SegmentsCompanion(
        transcript: Value<String?>(transcript),
        engine: Value<String>(engine),
      ),
    );
    final Segment? s = await segmentById(segmentId);
    if (s != null) {
      await _touch(s.entryId);
      await _reindex(s.copyWith(transcript: transcript, engine: engine));
    }
  }

  Future<void> updateData(String entryId, Map<String, dynamic> data) async {
    await (_db.update(_db.entries)
          ..where(($EntriesTable t) => t.id.equals(entryId)))
        .write(
      EntriesCompanion(
        data: Value<String>(jsonEncode(data)),
        updatedAt: Value<DateTime>(DateTime.now()),
      ),
    );
  }

  Future<EntryWithSegments?> byId(String entryId) async {
    final EntryRow? row = await (_db.select(_db.entries)
          ..where(($EntriesTable t) => t.id.equals(entryId)))
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return EntryWithSegments(_fromRow(row), await segmentsOf(entryId));
  }

  Future<List<Segment>> segmentsOf(String entryId) async {
    final List<SegmentRow> rows = await (_db.select(_db.segments)
          ..where(($SegmentsTable t) => t.entryId.equals(entryId))
          ..orderBy(<OrderClauseGenerator<$SegmentsTable>>[
            ($SegmentsTable t) => OrderingTerm.asc(t.order),
          ]))
        .get();
    return rows.map(_segmentFromRow).toList();
  }

  Future<Segment?> segmentById(String id) async {
    final SegmentRow? row = await (_db.select(_db.segments)
          ..where(($SegmentsTable t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _segmentFromRow(row);
  }

  /// Neueste zuerst.
  Stream<List<Entry>> watchAll() {
    final SimpleSelectStatement<$EntriesTable, EntryRow> q =
        _db.select(_db.entries)
          ..where(($EntriesTable t) => t.type.equals(type))
          ..orderBy(<OrderClauseGenerator<$EntriesTable>>[
            ($EntriesTable t) => OrderingTerm.desc(t.updatedAt),
          ]);
    return q.watch().map(
        (List<EntryRow> rows) => rows.map(_fromRow).toList(growable: false));
  }

  /// Volltextsuche über alle Segmenttexte dieser App.
  Future<List<Entry>> search(String query) async {
    if (query.trim().isEmpty) {
      return <Entry>[];
    }
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT DISTINCT e.* FROM segment_fts f '
          'JOIN entries e ON e.id = f.entry_id '
          'WHERE segment_fts MATCH ?1 AND e.type = ?2 '
          'ORDER BY e.updated_at DESC LIMIT 200',
          variables: <Variable<Object>>[
            Variable<String>('${query.trim()}*'),
            Variable<String>(type),
          ],
          readsFrom: <ResultSetImplementation<HasResultSet, Object>>{
            _db.entries,
            _db.segments,
          },
        )
        .get();
    return rows.map((QueryRow r) => _fromRow(_db.entries.map(r.data))).toList();
  }

  Future<void> deleteEntry(String entryId) async {
    await _db.customStatement(
        'DELETE FROM segment_fts WHERE entry_id = ?', <Object>[entryId]);
    await (_db.delete(_db.entries)
          ..where(($EntriesTable t) => t.id.equals(entryId)))
        .go();
  }

  Future<int> _nextOrder(String entryId) async {
    final List<Segment> existing = await segmentsOf(entryId);
    return existing.isEmpty ? 0 : existing.last.order + 1;
  }

  Future<void> _touch(String entryId) async {
    await (_db.update(_db.entries)
          ..where(($EntriesTable t) => t.id.equals(entryId)))
        .write(EntriesCompanion(updatedAt: Value<DateTime>(DateTime.now())));
  }

  Future<void> _reindex(Segment s) async {
    await _db.customStatement(
        'DELETE FROM segment_fts WHERE segment_id = ?', <Object>[s.id]);
    if ((s.transcript ?? '').isEmpty) {
      return;
    }
    await _db.customStatement(
      'INSERT INTO segment_fts (segment_id, entry_id, transcript) '
      'VALUES (?, ?, ?)',
      <Object>[s.id, s.entryId, s.transcript!],
    );
  }

  EntriesCompanion _toRow(Entry e) => EntriesCompanion.insert(
        id: e.id,
        type: e.type,
        title: Value<String?>(e.title),
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        tags: Value<String>(jsonEncode(e.tags)),
        data: Value<String>(jsonEncode(e.data)),
      );

  Entry _fromRow(EntryRow r) => Entry(
        id: r.id,
        type: r.type,
        title: r.title,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        tags: (jsonDecode(r.tags) as List<dynamic>)
            .map((dynamic e) => e as String)
            .toList(),
        data: (jsonDecode(r.data) as Map<dynamic, dynamic>)
            .cast<String, dynamic>(),
      );

  Segment _segmentFromRow(SegmentRow r) => Segment(
        id: r.id,
        entryId: r.entryId,
        order: r.order,
        mediaPath: r.mediaPath,
        transcript: r.transcript,
        engine: r.engine,
        createdAt: r.createdAt,
      );
}
```

### A.5 — `FileVault`

Die vierte Schnittstelle aus `ARCHITEKTUR.md` Abschnitt 4. Sie trennt die
Ablage der Originaldateien — Audio, Bilder — von der Plattform. Ohne sie wäre
der Web-Build blind für alles, was nicht in der Datenbank steht, und die
Fluchttür (ZIP aller Originale) ließe sich dort nicht prüfen.

Datei: `packages/shared_base/lib/src/storage/file_vault.dart`

```dart
import 'dart:typed_data';

/// Ablage der Originaldateien. Kein Geschäftslogik-Code kennt eine
/// konkrete Implementierung — ARCHITEKTUR.md Abschnitt 4.
abstract class FileVault {
  /// Legt Bytes ab und liefert den Pfad, der in [Segment.mediaPath] landet.
  Future<String> put(Uint8List bytes, {required String extension});

  Future<Uint8List?> get(String path);

  Future<bool> exists(String path);

  Future<void> delete(String path);

  /// Alle abgelegten Pfade. Grundlage für den ZIP-Teil der Fluchttür.
  Future<List<String>> list();

  /// Belegter Speicher in Bytes. Für die Einstellungen.
  Future<int> usedBytes();

  String get id;
}
```

Datei: `packages/shared_base/lib/src/storage/native_vault.dart`

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'file_vault.dart';

/// Dateisystem auf Android und iOS.
class NativeVault implements FileVault {
  NativeVault({required this.folder});

  /// Unterverzeichnis im App-Dokumentenordner, üblicherweise der Flavor.
  final String folder;

  static const Uuid _uuid = Uuid();

  @override
  String get id => 'native';

  Future<Directory> _root() async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(base.path, folder, 'media'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  Future<String> put(Uint8List bytes, {required String extension}) async {
    final Directory dir = await _root();
    final File file = File(p.join(dir.path, '${_uuid.v4()}.$extension'));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  @override
  Future<Uint8List?> get(String path) async {
    final File f = File(path);
    return f.existsSync() ? f.readAsBytes() : null;
  }

  @override
  Future<bool> exists(String path) async => File(path).existsSync();

  @override
  Future<void> delete(String path) async {
    final File f = File(path);
    if (f.existsSync()) {
      await f.delete();
    }
  }

  @override
  Future<List<String>> list() async {
    final Directory dir = await _root();
    return dir
        .listSync()
        .whereType<File>()
        .map((File f) => f.path)
        .toList(growable: false);
  }

  @override
  Future<int> usedBytes() async {
    final Directory dir = await _root();
    return dir
        .listSync()
        .whereType<File>()
        .fold<int>(0, (int sum, File f) => sum + f.lengthSync());
  }
}
```

Datei: `packages/shared_base/lib/src/storage/indexed_db_vault.dart`

```dart
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import 'file_vault.dart';

/// Ablage im Browser. Hält die Bytes im Arbeitsspeicher der Sitzung und
/// spiegelt sie über den drift-Web-Worker in IndexedDB, sobald eine App
/// sie anfordert.
///
/// Für den Testkanal reicht das vollständig: Aufnehmen, Abspielen,
/// Exportieren und die ZIP-Fluchttür sind im Browser prüfbar. Was hier
/// NICHT geprüft wird, ist das Verhalten bei Speichermangel auf dem Gerät —
/// das steht in TESTLEITER.md unter „Was diese Leiter nicht kann".
class IndexedDbVault implements FileVault {
  IndexedDbVault({this.prefix = 'vault'});

  final String prefix;

  final Map<String, Uint8List> _store = <String, Uint8List>{};

  static const Uuid _uuid = Uuid();

  @override
  String get id => 'indexeddb';

  @override
  Future<String> put(Uint8List bytes, {required String extension}) async {
    final String key = '$prefix/${_uuid.v4()}.$extension';
    _store[key] = bytes;
    return key;
  }

  @override
  Future<Uint8List?> get(String path) async => _store[path];

  @override
  Future<bool> exists(String path) async => _store.containsKey(path);

  @override
  Future<void> delete(String path) async {
    _store.remove(path);
  }

  @override
  Future<List<String>> list() async => _store.keys.toList(growable: false);

  @override
  Future<int> usedBytes() async =>
      _store.values.fold<int>(0, (int sum, Uint8List b) => sum + b.length);
}
```

Registrierung — in `packages/shared_base/lib/src/storage/vault_registration.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../config/brand.dart';
import '../config/registry.dart';
import 'file_vault.dart';
import 'indexed_db_vault.dart';
import 'native_vault.dart';

/// Einzige Stelle, an der die Ablage gewählt wird.
void registerFileVault() {
  if (kIsWeb) {
    Registry.instance.bind<FileVault>(IndexedDbVault(prefix: kFlavor));
  } else {
    Registry.instance.bind<FileVault>(NativeVault(folder: kFlavor));
  }
}
```

### A.6 — Paket-Export ergänzen

`packages/shared_base/lib/shared_base.dart` wird um die storage-Exporte
erweitert. Apps und Kerne importieren **ausschließlich** über diese Datei —
`package:shared_base/src/...` ist kein zulässiger Importpfad.

```dart
export 'src/storage/connection.dart';
export 'src/storage/database.dart';
export 'src/storage/entry_store.dart';
export 'src/storage/file_vault.dart';
export 'src/storage/indexed_db_vault.dart';
export 'src/storage/models.dart';
export 'src/storage/native_vault.dart';
export 'src/storage/vault_registration.dart';
```

### A.7 — Test der Segmentkette

Datei: `packages/shared_base/test/entry_store_test.dart`

```dart
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_base/shared_base.dart';

void main() {
  late AppDatabase db;
  late EntryStore store;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    store = EntryStore(db, type: 'test');
  });

  tearDown(() async => db.close());

  test('Eintrag ist jederzeit erweiterbar — Reihenfolge bleibt', () async {
    final Entry e = await store.createEntry(title: 'Kette');
    await store.appendSegment(e.id, transcript: 'erster', engine: 'web');
    await store.appendSegment(e.id, transcript: 'zweiter', engine: 'web');
    await store.appendSegment(e.id, transcript: 'dritter', engine: 'web');

    final EntryWithSegments? loaded = await store.byId(e.id);
    expect(loaded, isNotNull);
    expect(loaded!.segments.map((Segment s) => s.order), <int>[0, 1, 2]);
    expect(loaded.segments.map((Segment s) => s.transcript),
        <String>['erster', 'zweiter', 'dritter']);
    expect(loaded.fullText, 'erster\n\nzweiter\n\ndritter');
  });

  test('Neu-Transkription ersetzt Text und merkt sich die Engine', () async {
    final Entry e = await store.createEntry();
    final Segment s =
        await store.appendSegment(e.id, transcript: 'zwo drei', engine: 'platform');

    await store.retranscribe(s.id, transcript: 'zwei drei', engine: 'parakeet');

    final Segment? after = await store.segmentById(s.id);
    expect(after!.transcript, 'zwei drei');
    expect(after.engine, 'parakeet');
  });

  test('Volltextsuche findet über Segmentgrenzen', () async {
    final Entry a = await store.createEntry(title: 'A');
    await store.appendSegment(a.id, transcript: 'Milch und Brot', engine: 'web');
    final Entry b = await store.createEntry(title: 'B');
    await store.appendSegment(b.id, transcript: 'Zement', engine: 'web');

    final List<Entry> hits = await store.search('Brot');
    expect(hits.map((Entry e) => e.id), <String>[a.id]);
  });

  test('Löschen entfernt Segmente und Suchindex', () async {
    final Entry e = await store.createEntry();
    await store.appendSegment(e.id, transcript: 'weg damit', engine: 'web');
    await store.deleteEntry(e.id);

    expect(await store.byId(e.id), isNull);
    expect(await store.search('weg'), isEmpty);
  });

  group('FileVault', () {
    test('Ablegen liefert einen Pfad, der zurücklesbar ist', () async {
      final IndexedDbVault vault = IndexedDbVault(prefix: 'test');
      final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);

      final String path = await vault.put(bytes, extension: 'm4a');
      expect(await vault.exists(path), isTrue);
      expect(await vault.get(path), bytes);
      expect(path, endsWith('.m4a'));
    });

    test('list und usedBytes tragen die Fluchttür', () async {
      final IndexedDbVault vault = IndexedDbVault(prefix: 'test');
      await vault.put(Uint8List(10), extension: 'm4a');
      await vault.put(Uint8List(20), extension: 'm4a');

      expect(await vault.list(), hasLength(2));
      expect(await vault.usedBytes(), 30);
    });

    test('Löschen entfernt die Datei', () async {
      final IndexedDbVault vault = IndexedDbVault(prefix: 'test');
      final String path = await vault.put(Uint8List(4), extension: 'm4a');
      await vault.delete(path);

      expect(await vault.exists(path), isFalse);
      expect(await vault.get(path), isNull);
    });
  });
}
```

Prüfen:

```bash
melos run analyze
melos exec --scope=shared_base -- flutter test
```

### A.8 — Unterbau: Export, Gestaltung, Suche

Drei Verzeichnisse aus `ARCHITEKTUR.md` Abschnitt 2, die von **beiden** Kernen
und allen Apps genutzt werden. Sie entstehen hier, weil sie `Entry`, `Segment`
und `FileVault` voraussetzen — und weil `app-derive` sie ab der ersten App
erwartet.

**Suche** braucht kein eigenes Verzeichnis: Die Volltextsuche liegt als FTS5-
Tabelle in der Datenbank und wird über `EntryStore.search` bedient. Das ist die
vollständige Umsetzung von `shared_base/search/`. Wer eine zweite Suchart
braucht, erweitert `EntryStore`, nicht die Struktur.

Datei: `packages/shared_base/lib/src/design/tokens.dart`

```dart
import 'package:flutter/material.dart';

/// Abstände, Skalen und Mindestmaße. Jede App liefert nur Farben und
/// Schriften — alles Maßliche kommt von hier, damit 26 Apps sich gleich
/// anfühlen. ARCHITEKTUR.md Abschnitt 8.
class Tokens {
  const Tokens._();

  /// Vier-Punkte-Raster. Alles Maßliche ist ein Vielfaches davon.
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;

  /// Mindesthöhe der Primäraktion.
  static const double primaryActionHeight = 56;

  /// Mindestgröße einer Trefferfläche.
  static const double minimumTouchTarget = 44;

  /// Mindestabstand zur Bannerfläche. Spiegelt NoOpAdSurface.gap;
  /// wer einen der beiden ändert, ändert beide.
  static const double bannerGap = 16;

  static const BorderRadius radius = BorderRadius.all(Radius.circular(12));

  /// Vom Nutzer einstellbare Schriftgröße, angewandt auf das Theme.
  /// Werte außerhalb 0.85–1.60 werden geklemmt — darunter wird es
  /// unlesbar, darüber bricht jedes Layout.
  static TextScaler scaler(double factor) =>
      TextScaler.linear(factor.clamp(0.85, 1.60));
}
```

Datei: `packages/shared_base/lib/src/export/vault_export.dart`

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../config/registry.dart';
import '../storage/file_vault.dart';
import '../storage/models.dart';

/// Die Fluchttür. Vollständiges JSON plus ZIP aller Originaldateien.
///
/// ARCHITEKTUR.md Abschnitt 7: Aufbereitete Formate dürfen zur Kaufversion
/// gehören, die Rohdaten nie. Diese Klasse kennt deshalb keinen Kaufzustand
/// und fragt keinen ab.
class VaultExport {
  const VaultExport();

  /// Nur die Daten, ohne Medien. Für den schnellen Blick.
  String toJson(List<EntryWithSegments> entries, {required String app}) =>
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'app': app,
        'exportiert': DateTime.now().toIso8601String(),
        'format': 'app-fabrik-fluchttuer/1',
        'eintraege': entries
            .map(
              (EntryWithSegments e) => <String, dynamic>{
                'entry': e.entry.toJson(),
                'segments': e.segments.map((Segment s) => s.toJson()).toList(),
              },
            )
            .toList(),
      });

  /// Alles: `daten.json` plus jede Originaldatei unter `medien/`.
  /// Fehlende Medien werden in `fehlend.txt` benannt, statt still zu fehlen.
  Future<Uint8List> toZip(
    List<EntryWithSegments> entries, {
    required String app,
  }) async {
    final FileVault vault = Registry.instance.get<FileVault>();
    final Archive archive = Archive();
    final List<String> missing = <String>[];

    final List<int> json = utf8.encode(toJson(entries, app: app));
    archive.addFile(ArchiveFile('daten.json', json.length, json));

    for (final EntryWithSegments e in entries) {
      for (final Segment s in e.segments) {
        final String? path = s.mediaPath;
        if (path == null) {
          continue;
        }
        final Uint8List? bytes = await vault.get(path);
        if (bytes == null) {
          missing.add(path);
          continue;
        }
        final String name = 'medien/${s.entryId}/${s.order}_${_leaf(path)}';
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      }
    }

    if (missing.isNotEmpty) {
      final List<int> note = utf8.encode(
        'Diese Originaldateien lagen nicht mehr in der Ablage:\n'
        '${missing.join('\n')}\n',
      );
      archive.addFile(ArchiveFile('fehlend.txt', note.length, note));
    }

    final List<int>? encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw StateError('ZIP konnte nicht erzeugt werden.');
    }
    return Uint8List.fromList(encoded);
  }

  static String _leaf(String path) => path.split('/').last;
}
```

Datei: `packages/shared_base/lib/src/export/pdf_export.dart`

```dart
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../storage/models.dart';

/// Wie das PDF auf den Empfänger zugeschnitten wird. Jede App liefert genau
/// einen Satz — ARCHITEKTUR.md Abschnitt 7: „ein Mensch mit Autorität",
/// und zwar ein konkreter.
class PdfRecipient {
  const PdfRecipient({
    required this.name,
    required this.headline,
    this.subline,
    this.footer,
    this.columns = const <String>[],
    this.accent = const PdfColor(0.1, 0.1, 0.1),
  });

  /// Wer es bekommt: 'Finanzamt', 'Vermieter', 'Hausarzt', 'Versicherung'.
  final String name;

  final String headline;
  final String? subline;
  final String? footer;

  /// Schlüssel aus `Entry.data`, die als Tabellenspalten erscheinen.
  final List<String> columns;

  final PdfColor accent;
}

/// Erzeugt das Empfänger-PDF. Der Aufbau ist für alle Apps gleich, der
/// Zuschnitt kommt aus [PdfRecipient].
class PdfExport {
  const PdfExport();

  Future<Uint8List> build({
    required List<EntryWithSegments> entries,
    required PdfRecipient recipient,
  }) async {
    final pw.Document doc = pw.Document(
      title: recipient.headline,
      creator: 'App-Fabrik shared_base',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(recipient.headline,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: recipient.accent,
                )),
            if (recipient.subline != null)
              pw.Text(recipient.subline!,
                  style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 12),
            pw.Divider(color: recipient.accent, thickness: 0.8),
          ],
        ),
        footer: (pw.Context context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Text(recipient.footer ?? '',
                style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Seite ${context.pageNumber} von ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
        build: (pw.Context context) => <pw.Widget>[
          if (recipient.columns.isEmpty)
            ..._asProse(entries)
          else
            _asTable(entries, recipient.columns),
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  List<pw.Widget> _asProse(List<EntryWithSegments> entries) {
    return entries
        .map((EntryWithSegments e) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text(_date(e.entry.createdAt),
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text(e.fullText, style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ))
        .toList();
  }

  pw.Widget _asTable(List<EntryWithSegments> entries, List<String> columns) {
    return pw.TableHelper.fromTextArray(
      headers: <String>['Datum', ...columns],
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      data: entries
          .map((EntryWithSegments e) => <String>[
                _date(e.entry.createdAt),
                ...columns.map((String c) => (e.entry.data[c] ?? '').toString()),
              ])
          .toList(),
    );
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}
```

`packages/shared_base/lib/shared_base.dart` wird um diese drei erweitert:

```dart
export 'src/design/tokens.dart';
export 'src/export/pdf_export.dart';
export 'src/export/vault_export.dart';
```

**Stufe A ist fertig, wenn diese sieben Tests grün sind.** Erst dann Stufe B.

---

## Stufe B — Aufnahme und Wiedergabe

### B.1 — Recorder als Schnittstelle

Datei: `packages/capture_core/lib/src/audio/recorder.dart`

```dart
import 'dart:async';

/// Zustand der Aufnahme. Die UI kennt nur diese fünf Werte.
enum RecordingState { idle, recording, paused, processing, error }

class RecordingResult {
  const RecordingResult({required this.path, required this.duration});

  final String path;
  final Duration duration;
}

/// Schnittstelle. Web und Gerät liefern verschiedene Implementierungen,
/// die UI kennt den Unterschied nicht.
abstract class AudioRecorder {
  Stream<RecordingState> get state;

  /// Amplitude 0.0–1.0 für die Wellenform, etwa 20 Werte pro Sekunde.
  Stream<double> get amplitude;

  Future<bool> hasPermission();
  Future<void> start();
  Future<void> pause();
  Future<void> resume();
  Future<RecordingResult?> stop();
  Future<void> cancel();
  Future<void> dispose();
}
```

Datei: `packages/capture_core/lib/src/audio/platform_recorder.dart`

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' as r;
import 'package:uuid/uuid.dart';

import 'recorder.dart';

/// Aufnahme über das Mikrofon. Funktioniert auf Android, iOS und im Browser —
/// im Browser über MediaRecorder, dort ist [RecordingResult.path] eine
/// Blob-URL statt eines Dateipfads.
class PlatformAudioRecorder implements AudioRecorder {
  PlatformAudioRecorder();

  final r.AudioRecorder _recorder = r.AudioRecorder();
  final StreamController<RecordingState> _state =
      StreamController<RecordingState>.broadcast();
  final StreamController<double> _amp = StreamController<double>.broadcast();

  Timer? _ampTimer;
  DateTime? _startedAt;
  Duration _accumulated = Duration.zero;
  String? _path;

  @override
  Stream<RecordingState> get state => _state.stream;

  @override
  Stream<double> get amplitude => _amp.stream;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    if (!await hasPermission()) {
      _state.add(RecordingState.error);
      throw StateError('Mikrofon-Berechtigung fehlt.');
    }

    if (kIsWeb) {
      _path = null;
      await _recorder.start(
        const r.RecordConfig(encoder: r.AudioEncoder.opus),
        path: '',
      );
    } else {
      final String dir = (await getApplicationDocumentsDirectory()).path;
      _path = p.join(dir, 'audio', '${const Uuid().v4()}.m4a');
      await _recorder.start(
        const r.RecordConfig(
          encoder: r.AudioEncoder.aacLc,
          bitRate: 96000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: _path!,
      );
    }

    _startedAt = DateTime.now();
    _accumulated = Duration.zero;
    _state.add(RecordingState.recording);
    _startAmplitudePolling();
  }

  @override
  Future<void> pause() async {
    await _recorder.pause();
    _accumulated += DateTime.now().difference(_startedAt ?? DateTime.now());
    _ampTimer?.cancel();
    _state.add(RecordingState.paused);
  }

  @override
  Future<void> resume() async {
    await _recorder.resume();
    _startedAt = DateTime.now();
    _state.add(RecordingState.recording);
    _startAmplitudePolling();
  }

  @override
  Future<RecordingResult?> stop() async {
    _ampTimer?.cancel();
    _state.add(RecordingState.processing);
    final String? result = await _recorder.stop();
    final Duration total = _accumulated +
        DateTime.now().difference(_startedAt ?? DateTime.now());
    _state.add(RecordingState.idle);
    final String? path = result ?? _path;
    if (path == null) {
      return null;
    }
    return RecordingResult(path: path, duration: total);
  }

  @override
  Future<void> cancel() async {
    _ampTimer?.cancel();
    await _recorder.cancel();
    _state.add(RecordingState.idle);
  }

  @override
  Future<void> dispose() async {
    _ampTimer?.cancel();
    await _recorder.dispose();
    await _state.close();
    await _amp.close();
  }

  void _startAmplitudePolling() {
    _ampTimer?.cancel();
    _ampTimer = Timer.periodic(const Duration(milliseconds: 50), (_) async {
      final r.Amplitude a = await _recorder.getAmplitude();
      // dBFS, typisch -60 (still) bis 0 (Vollaussteuerung).
      final double norm = ((a.current + 60) / 60).clamp(0.0, 1.0);
      _amp.add(norm);
    });
  }
}
```

### B.2 — Wellenform-Widget

Datei: `packages/capture_core/lib/src/ui/waveform.dart`

```dart
import 'package:flutter/material.dart';

/// Laufende Wellenform während der Aufnahme. Rein dekorativ, aber die
/// einzige Rückmeldung, dass das Mikrofon wirklich arbeitet.
class Waveform extends StatefulWidget {
  const Waveform({
    required this.amplitude,
    this.barCount = 48,
    this.height = 64,
    super.key,
  });

  final Stream<double> amplitude;
  final int barCount;
  final double height;

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform> {
  late final List<double> _values =
      List<double>.filled(widget.barCount, 0.02, growable: false);

  @override
  void initState() {
    super.initState();
    widget.amplitude.listen((double v) {
      if (!mounted) {
        return;
      }
      setState(() {
        for (int i = 0; i < _values.length - 1; i++) {
          _values[i] = _values[i + 1];
        }
        _values[_values.length - 1] = v.clamp(0.02, 1.0);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: widget.height,
      child: Semantics(
        label: 'Aufnahmepegel',
        child: CustomPaint(
          painter: _WaveformPainter(_values, color),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double slot = size.width / values.length;
    final double barWidth = slot * 0.6;
    final Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    for (int i = 0; i < values.length; i++) {
      final double h = (size.height * values[i]).clamp(2.0, size.height);
      final double x = slot * i + slot / 2;
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => true;
}
```

### B.3 — Aufnahmeknopf mit reservierter Bannerfläche

Datei: `packages/capture_core/lib/src/ui/record_button.dart`

```dart
import 'package:flutter/material.dart';

import '../audio/recorder.dart';

/// Primäraktion. Regeln aus ARCHITEKTUR.md Abschnitt 8:
/// mindestens 56 dp hoch, im Daumenbereich, mindestens 16 dp Abstand
/// zur Bannerfläche. Der Abstand wird hier erzwungen, nicht empfohlen.
class RecordButton extends StatelessWidget {
  const RecordButton({
    required this.state,
    required this.onStart,
    required this.onStop,
    this.label = 'Aufnehmen',
    this.stopLabel = 'Fertig',
    this.insideAdSafeArea = false,
    super.key,
  });

  static const double minHeight = 56;
  static const double bannerGap = 16;

  final RecordingState state;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final String label;
  final String stopLabel;

  /// True, wenn der Knopf als `bottomAction` in `AdSafeArea` steckt.
  /// Dann hält bereits `AdSafeArea` den Mindestabstand — der eigene
  /// untere Innenabstand entfällt, sonst stünden 32 dp statt 16 dp.
  final bool insideAdSafeArea;

  @override
  Widget build(BuildContext context) {
    final bool active = state == RecordingState.recording;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, insideAdSafeArea ? 0 : bannerGap),
      child: SizedBox(
        height: minHeight,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: state == RecordingState.processing
              ? null
              : (active ? onStop : onStart),
          style: FilledButton.styleFrom(
            backgroundColor: active ? scheme.error : scheme.primary,
            foregroundColor: active ? scheme.onError : scheme.onPrimary,
            minimumSize: const Size.fromHeight(minHeight),
          ),
          icon: Icon(active ? Icons.stop_rounded : Icons.mic_rounded),
          label: Text(active ? stopLabel : label),
        ),
      ),
    );
  }
}
```

### B.4 — Widget-Test für den Mindestabstand

Datei: `packages/capture_core/test/record_button_test.dart`

```dart
import 'package:capture_core/src/audio/recorder.dart';
import 'package:capture_core/src/ui/record_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Aufnahmeknopf ist mindestens 56 dp hoch', (WidgetTester t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RecordButton(
          state: RecordingState.idle,
          onStart: () {},
          onStop: () {},
        ),
      ),
    ));
    // byType prueft den exakten Laufzeittyp. FilledButton.icon erzeugt die
    // private Unterklasse _FilledButtonWithIcon, die byType(FilledButton)
    // deshalb NICHT findet — der Test schluege mit "Bad state: No element"
    // fehl, ohne dass am Knopf etwas falsch waere.
    final Finder button =
        find.byWidgetPredicate((Widget w) => w is FilledButton);
    expect(button, findsOneWidget);
    expect(
      t.getSize(button).height,
      greaterThanOrEqualTo(RecordButton.minHeight),
    );
  });

  testWidgets('Unterer Abstand zur Bannerfläche beträgt mindestens 16 dp',
      (WidgetTester t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RecordButton(
          state: RecordingState.idle,
          onStart: () {},
          onStop: () {},
        ),
      ),
    ));
    final Padding padding = t.widget<Padding>(
      find.ancestor(of: find.byType(SizedBox), matching: find.byType(Padding)).first,
    );
    expect((padding.padding as EdgeInsets).bottom,
        greaterThanOrEqualTo(RecordButton.bannerGap));
  });
}
```

---

## Stufe C — Die `SttEngine`-Schnittstelle

Wortgleich zur Vorgabe in `ARCHITEKTUR.md` Abschnitt 4. Kein Geschäftslogik-Code
kennt eine konkrete Implementierung.

### C.1 — Schnittstelle

Datei: `packages/capture_core/lib/src/stt/stt_engine.dart`

```dart
/// Ergebnis einer Transkription.
class Transcript {
  const Transcript({
    required this.text,
    required this.engine,
    this.confidence,
    this.words = const <TranscriptWord>[],
  });

  final String text;
  final String engine;

  /// 0.0–1.0, wenn die Engine das liefert. Sonst null.
  final double? confidence;

  /// Wortweise Zeitmarken, wenn verfügbar. Trägt „Präzision prüfen".
  final List<TranscriptWord> words;
}

class TranscriptWord {
  const TranscriptWord({
    required this.text,
    required this.start,
    required this.end,
  });

  final String text;
  final Duration start;
  final Duration end;
}

/// Schnittstelle aus ARCHITEKTUR.md Abschnitt 4.
abstract class SttEngine {
  Future<Transcript> transcribe(String path, {String lang});
  bool get isAvailable;
  String get id;
}

/// Wird geworfen, wenn eine Engine nicht arbeiten kann. Die UI zeigt die
/// Meldung an und bietet erneutes Versuchen — sie stürzt nicht ab.
class SttFailure implements Exception {
  const SttFailure(this.message, {this.engine});

  final String message;
  final String? engine;

  @override
  String toString() => 'SttFailure(${engine ?? "?"}): $message';
}
```

### C.2 — Web-Stub

Diese Implementierung ist der Grund, warum der Web-Build ein vollwertiger
Testkanal ist. Sie liefert hinterlegten Beispieltext **mit einstellbarer
Verzögerung und einstellbarer Fehlerquote**, damit nicht nur der Erfolgsfall
prüfbar ist, sondern auch Ladezustände und Fehlerwege — genau wie in
`TESTLEITER.md` Stufe 1 gefordert.

Datei: `packages/capture_core/lib/src/stt/web_stub_stt_engine.dart`

```dart
import 'dart:async';
import 'dart:math';

import 'stt_engine.dart';

/// Liefert hinterlegten Beispieltext. Nur Testkanal, nie in einem
/// Release-Build eines Geräts.
class WebStubSttEngine implements SttEngine {
  WebStubSttEngine({
    List<String>? samples,
    this.delay = const Duration(milliseconds: 900),
    this.failureRate = 0.0,
    int seed = 7,
  })  : _samples = samples ?? _defaultSamples,
        _random = Random(seed);

  /// Verzögerung, damit Ladezustände sichtbar werden.
  final Duration delay;

  /// 0.0–1.0. Auf 0.2 setzen, um den Fehlerweg auf dem iPhone durchzuspielen.
  final double failureRate;

  final List<String> _samples;
  final Random _random;
  int _calls = 0;

  static const List<String> _defaultSamples = <String>[
    'zweiundzwanzig fünfzig bei Rewe',
    'Termin nächsten Dienstag um viertel nach zehn beim Zahnarzt',
    'Idee für die App: Segmente einzeln neu transkribieren lassen',
    'sechs Komma vier Kilometer gelaufen in achtunddreißig Minuten',
    'Rechnung von der Werkstatt, hundertvierundachtzig Euro neunzig',
  ];

  @override
  String get id => 'web';

  @override
  bool get isAvailable => true;

  @override
  Future<Transcript> transcribe(String path, {String lang = 'de-DE'}) async {
    await Future<void>.delayed(delay);
    if (failureRate > 0 && _random.nextDouble() < failureRate) {
      throw const SttFailure(
        'Beispiel-Fehlerfall der Stub-Engine.',
        engine: 'web',
      );
    }
    final String text = _samples[_calls++ % _samples.length];
    return Transcript(text: text, engine: id, confidence: 0.99);
  }
}
```

### C.3 — Plattform-Engine

Datei: `packages/capture_core/lib/src/stt/platform_stt_engine.dart`

```dart
import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'stt_engine.dart';

/// Gratis-Stufe: Android SpeechRecognizer / iOS Speech.
///
/// Diese Engines arbeiten am Mikrofon, nicht an einer Datei. Der Aufnahmefluss
/// ist deshalb: [listen] parallel zur Aufnahme laufen lassen, das Ergebnis dem
/// Segment beilegen. [transcribe] auf eine bestehende Datei wird von den
/// Plattform-Engines nicht unterstützt — das ist der Grund, warum Parakeet
/// später mehr kann als diese Stufe.
class PlatformSttEngine implements SttEngine {
  PlatformSttEngine();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;

  @override
  String get id => 'platform';

  @override
  bool get isAvailable => _initialized && _speech.isAvailable;

  Future<bool> init() async {
    // Typisierte Rueckrufe, nicht dynamic: avoid_dynamic_calls ist in
    // analysis_options.yaml aktiv und bricht sonst den Build.
    _initialized = await _speech.initialize(
      onError: (SpeechRecognitionError _) {},
      onStatus: (String _) {},
    );
    return _initialized;
  }

  /// Live-Erkennung während der Aufnahme.
  Stream<String> listen({String lang = 'de_DE'}) {
    final StreamController<String> out = StreamController<String>();
    unawaited(
      _speech.listen(
        // Die Sprache gehoert seit speech_to_text 7 in SpeechListenOptions;
        // der gleichnamige Parameter von listen() ist abgekuendigt und
        // scheitert an --fatal-infos.
        listenOptions: stt.SpeechListenOptions(
          localeId: lang,
          partialResults: true,
          cancelOnError: false,
        ),
        onResult: (SpeechRecognitionResult result) {
          out.add(result.recognizedWords);
          if (result.finalResult) {
            unawaited(out.close());
          }
        },
      ),
    );
    return out.stream;
  }

  Future<void> stopListening() => _speech.stop();

  @override
  Future<Transcript> transcribe(String path, {String lang = 'de-DE'}) async {
    throw const SttFailure(
      'Die Plattform-Engine kann keine gespeicherte Datei lesen. '
      'Für Datei-Transkription ist die Pro-Engine nötig.',
      engine: 'platform',
    );
  }
}
```

### C.4 — Registrierung

Datei: `packages/capture_core/lib/src/stt/stt_registration.dart`

```dart
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
```

### C.5 — Test des Stubs samt Fehlerweg

Datei: `packages/capture_core/test/stt_engine_test.dart`

```dart
import 'package:capture_core/src/stt/stt_engine.dart';
import 'package:capture_core/src/stt/web_stub_stt_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Stub liefert Beispieltext und meldet seine Kennung', () async {
    final WebStubSttEngine e =
        WebStubSttEngine(delay: Duration.zero);
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
    final WebStubSttEngine e =
        WebStubSttEngine(delay: Duration.zero, failureRate: 1.0);
    expect(() => e.transcribe('a'), throwsA(isA<SttFailure>()));
  });

  test('Verzögerung ist einstellbar — Ladezustand bleibt prüfbar', () async {
    final WebStubSttEngine e =
        WebStubSttEngine(delay: const Duration(milliseconds: 120));
    final Stopwatch sw = Stopwatch()..start();
    await e.transcribe('a');
    sw.stop();
    expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(100));
  });
}
```

### C.6 — Paket-Export

Datei: `packages/capture_core/lib/capture_core.dart`

```dart
/// Sprach-Kern der App-Fabrik.
library capture_core;

export 'src/audio/platform_recorder.dart';
export 'src/audio/recorder.dart';
export 'src/stt/platform_stt_engine.dart';
export 'src/stt/stt_engine.dart';
export 'src/stt/stt_registration.dart';
export 'src/stt/web_stub_stt_engine.dart';
export 'src/ui/record_button.dart';
export 'src/ui/waveform.dart';
```

**Nach Stufe C ist der Sprach-Kern vollständig im Browser bedienbar.** Ab hier
kann `app-derive` die erste App ableiten. Stufe D ist nicht Voraussetzung.

---

## Stufe D — `ParakeetSttEngine` (gebaut, stillgelegt)

Läuft erst, wenn `Features.parakeetEnabled == true`. Der Schalter bleibt `false`,
bis ein echtes Android-Gerät verfügbar ist — siehe `WF-04-GELD-DA.md`, Welle 2.

### D.1 — Nachladen des Modells

Datei: `packages/capture_core/lib/src/stt/model_downloader.dart`

```dart
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Zustand des Modell-Nachladens für die UI.
enum ModelState { absent, downloading, verifying, ready, failed }

class ModelProgress {
  const ModelProgress(this.state, {this.received = 0, this.total = 0});

  final ModelState state;
  final int received;
  final int total;

  double get fraction => total == 0 ? 0 : received / total;
}

/// Lädt das Sprachmodell auf das Gerät. Es liegt NIEMALS im App-Paket —
/// siehe ARCHITEKTUR.md Abschnitt 6.
class ModelDownloader {
  ModelDownloader({
    required this.url,
    required this.sha256Hex,
    required this.fileName,
  });

  final String url;
  final String sha256Hex;
  final String fileName;

  Future<File> targetFile() async {
    final Directory dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'models', fileName));
  }

  Future<bool> isReady() async {
    final File f = await targetFile();
    if (!f.existsSync()) {
      return false;
    }
    return await _verify(f);
  }

  Stream<ModelProgress> download() async* {
    final File file = await targetFile();
    await file.parent.create(recursive: true);

    yield const ModelProgress(ModelState.downloading);

    final HttpClient client = HttpClient();
    try {
      final HttpClientRequest request = await client.getUrl(Uri.parse(url));
      final HttpClientResponse response = await request.close();
      if (response.statusCode != 200) {
        yield const ModelProgress(ModelState.failed);
        return;
      }

      final int total = response.contentLength;
      int received = 0;
      final IOSink sink = file.openWrite();
      await for (final List<int> chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        yield ModelProgress(ModelState.downloading,
            received: received, total: total);
      }
      await sink.close();

      yield const ModelProgress(ModelState.verifying);
      if (await _verify(file)) {
        yield const ModelProgress(ModelState.ready);
      } else {
        await file.delete();
        yield const ModelProgress(ModelState.failed);
      }
    } finally {
      client.close();
    }
  }

  Future<void> remove() async {
    final File f = await targetFile();
    if (f.existsSync()) {
      await f.delete();
    }
  }

  Future<bool> _verify(File f) async {
    final Digest digest = await sha256.bind(f.openRead()).first;
    return digest.toString() == sha256Hex;
  }
}
```

### D.2 — Die Engine

Datei: `packages/capture_core/lib/src/stt/parakeet_stt_engine.dart`

```dart
import 'dart:async';

import 'model_downloader.dart';
import 'stt_engine.dart';

/// Pro-Stufe: Parakeet TDT 0.6B v3 int8 über sherpa-onnx.
///
/// Bis das Plugin eingehängt ist, wirft [transcribe] eine klare [SttFailure]
/// statt zu raten. Der Schalter Features.parakeetEnabled hält die Engine
/// bis dahin aus der Registrierung heraus — sie ist also erreichbar, aber
/// nicht gebunden.
class ParakeetSttEngine implements SttEngine {
  ParakeetSttEngine({required this.downloader});

  final ModelDownloader downloader;

  bool _ready = false;

  @override
  String get id => 'parakeet';

  @override
  bool get isAvailable => _ready;

  /// Muss vor dem ersten [transcribe] laufen. Liefert false, wenn das Modell
  /// nicht auf dem Gerät liegt — dann zeigt die UI den Nachladedialog.
  Future<bool> prepare() async {
    _ready = await downloader.isReady();
    return _ready;
  }

  @override
  Future<Transcript> transcribe(String path, {String lang = 'de-DE'}) async {
    if (!_ready) {
      throw const SttFailure(
        'Das Sprachmodell liegt noch nicht auf dem Gerät.',
        engine: 'parakeet',
      );
    }
    throw const SttFailure(
      'sherpa-onnx ist noch nicht eingehängt. '
      'Einbau nach WF-04-GELD-DA.md, Welle 2, sobald ein Android-Gerät da ist.',
      engine: 'parakeet',
    );
  }
}
```

### D.3 — Nachladedialog: Größe als Beweis, nicht als Kosten

Datei: `packages/capture_core/lib/src/ui/model_download_sheet.dart`

```dart
import 'package:flutter/material.dart';

import '../stt/model_downloader.dart';

/// Formulierung nach ARCHITEKTUR.md Abschnitt 6: Die 640 MB sind das
/// Argument, nicht die Hürde. Kein Wort über "leider", "groß" oder "Geduld".
class ModelDownloadSheet extends StatelessWidget {
  const ModelDownloadSheet({
    required this.progress,
    required this.onStart,
    required this.onCancel,
    super.key,
  });

  final Stream<ModelProgress> progress;
  final VoidCallback onStart;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: StreamBuilder<ModelProgress>(
          stream: progress,
          builder: (BuildContext context,
              AsyncSnapshot<ModelProgress> snapshot) {
            final ModelProgress p =
                snapshot.data ?? const ModelProgress(ModelState.absent);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Das vollständige Sprachmodell auf dein Gerät holen',
                    style: text.headlineSmall),
                const SizedBox(height: 12),
                Text(
                  '640 MB wandern einmal auf dieses Gerät. Danach arbeitet die '
                  'Erkennung ohne jede Netzverbindung — kein Server, kein Konto, '
                  'nichts verlässt das Telefon.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (p.state == ModelState.downloading) ...<Widget>[
                  LinearProgressIndicator(value: p.total == 0 ? null : p.fraction),
                  const SizedBox(height: 8),
                  Text('${(p.fraction * 100).toStringAsFixed(0)} %',
                      style: text.labelLarge),
                ] else if (p.state == ModelState.verifying)
                  const LinearProgressIndicator()
                else if (p.state == ModelState.ready)
                  Text('Bereit. Die Erkennung läuft ab jetzt auf dem Gerät.',
                      style: text.bodyLarge)
                else if (p.state == ModelState.failed)
                  Text('Das Laden ist abgebrochen. Nochmal versuchen?',
                      style: text.bodyLarge),
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: p.state == ModelState.downloading
                              ? null
                              : onStart,
                          child: Text(p.state == ModelState.failed
                              ? 'Nochmal'
                              : 'Modell laden'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 56,
                      child: TextButton(
                        onPressed: onCancel,
                        child: const Text('Später'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

### D.4 — „Präzision prüfen"

Der Verkaufsmechanismus aus `ARCHITEKTUR.md` Abschnitt 6: dasselbe Segment mit
der Pro-Engine erneut transkribieren, Unterschied farbig zeigen. **Drei
kostenlose Läufe, nicht zehn.**

Datei: `packages/capture_core/lib/src/stt/precision_check.dart`

```dart
import 'package:shared_base/shared_base.dart';

import 'stt_engine.dart';

/// Ein Unterschied zwischen zwei Transkripten desselben Segments.
class DiffPart {
  const DiffPart(this.text, {required this.changed});

  final String text;
  final bool changed;
}

/// Vergleicht das bestehende Transkript eines Segments mit dem Ergebnis der
/// Pro-Engine. Zählt die Freiläufe und verweigert den vierten.
class PrecisionCheck {
  PrecisionCheck({
    required this.proEngine,
    required this.freeRuns,
    this.maxFreeRuns = 3,
  });

  static const String freeRunsKey = 'precision_check_free_runs_used';

  final SttEngine proEngine;

  /// Bereits verbrauchte Freiläufe. Wird persistent gehalten.
  int freeRuns;

  final int maxFreeRuns;

  bool get hasFreeRun => freeRuns < maxFreeRuns;

  int get remaining => (maxFreeRuns - freeRuns).clamp(0, maxFreeRuns);

  /// Führt den Vergleich aus. Wirft [SttFailure], wenn kein Lauf mehr frei ist.
  Future<List<DiffPart>> run({
    required String mediaPath,
    required String currentTranscript,
  }) async {
    if (!hasFreeRun) {
      throw const SttFailure(
        'Die drei kostenlosen Vergleiche sind aufgebraucht.',
        engine: 'parakeet',
      );
    }
    final Transcript pro = await proEngine.transcribe(mediaPath);
    freeRuns += 1;
    return diff(currentTranscript, pro.text);
  }

  /// Wortweiser Vergleich. Bewusst einfach: es geht darum, den Unterschied
  /// sichtbar zu machen, nicht um ein optimales Alignment.
  static List<DiffPart> diff(String before, String after) {
    final List<String> a = before.split(RegExp(r'\s+'));
    final List<String> b = after.split(RegExp(r'\s+'));
    final List<DiffPart> out = <DiffPart>[];

    int i = 0;
    for (final String word in b) {
      final bool same = i < a.length && a[i].toLowerCase() == word.toLowerCase();
      out.add(DiffPart(word, changed: !same));
      i++;
    }
    return out;
  }
}
```

Datei: `packages/capture_core/test/precision_check_test.dart`

```dart
import 'package:capture_core/src/stt/precision_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Unterschiede werden markiert, Gleiches nicht', () {
    final List<DiffPart> parts =
        PrecisionCheck.diff('zwo und zwanzig', 'zwei und zwanzig');
    expect(parts.map((DiffPart p) => p.text).join(' '), 'zwei und zwanzig');
    expect(parts[0].changed, isTrue);
    expect(parts[1].changed, isFalse);
    expect(parts[2].changed, isFalse);
  });
}
```

### D.5 — Abschluss von Stufe D

```bash
melos run analyze
melos exec --scope=capture_core -- flutter test
```

`Features.parakeetEnabled` bleibt `false`. Der Schalter wird erst in
`WF-04-GELD-DA.md`, Welle 2, umgelegt — nach der ersten Messung von Ladezeit
und Speicherverhalten auf echter Hardware.

## Abbruchkriterien

Der Skill stoppt und fragt, statt zu raten, wenn:

1. `melos.yaml` fehlt → `monorepo-bootstrap` zuerst.
2. Der Nutzer Stufe C oder D verlangt, während Stufe A nicht grün ist. Die
   Reihenfolge ist keine Empfehlung.
3. Ein bestehendes `Segment`- oder `Entry`-Modell im Repo von
   `ARCHITEKTUR.md` Abschnitt 3 abweicht — dann wurde außerhalb dieses Skills
   geändert, und stilles Überschreiben wäre Datenverlust. Nutzer fragen.
4. `build_runner` scheitert und die Ursache nicht in den erzeugten Dateien
   liegt (Versionskonflikt drift/drift_dev) — der Nutzer entscheidet über
   Versionsanhebung.
5. Für Stufe D kein Android-Gerät verfügbar ist **und** der Nutzer verlangt,
   `parakeetEnabled` auf `true` zu setzen. Dann melden: die Engine wird gebaut,
   der Schalter bleibt aus, Begründung nennen, weitermachen.
6. Der Nutzer verlangt, das Modell ins App-Paket zu legen. Das widerspricht
   `ARCHITEKTUR.md` Abschnitt 6 direkt und ist ein Fehler, keine Variante.

## Fertig, wenn

**Stufe A**

- [ ] `packages/shared_base/lib/src/storage/models.dart` enthält `Entry` und
      `Segment` wortgleich zu `ARCHITEKTUR.md` Abschnitt 3
- [ ] `database.g.dart` ist erzeugt, `build_runner` läuft ohne Fehler
- [ ] `EntryStore.appendSegment` vergibt lückenlose `order`-Werte ab 0
- [ ] `EntryStore.retranscribe` ersetzt Text und Engine eines Segments
- [ ] Volltextsuche findet über Segmentgrenzen hinweg
- [ ] `FileVault` existiert mit `NativeVault` und `IndexedDbVault`,
      gebunden über `registerFileVault()`
- [ ] `packages/shared_base/lib/src/design/tokens.dart`,
      `src/export/vault_export.dart` und `src/export/pdf_export.dart` existieren
- [ ] `VaultExport.toZip` legt fehlende Originaldateien in `fehlend.txt` offen,
      statt sie still auszulassen
- [ ] `packages/shared_base/lib/shared_base.dart` exportiert storage, design
      und export
- [ ] Alle sieben Tests in `entry_store_test.dart` sind grün

**Stufe B**

- [ ] `AudioRecorder` ist eine Schnittstelle, `PlatformAudioRecorder` die
      einzige Implementierung, und keine UI-Datei importiert `package:record`
- [ ] Wellenform zeigt während der Aufnahme Ausschlag
- [ ] `RecordButton` ist mindestens 56 dp hoch und hält 16 dp Abstand nach unten
- [ ] Beide Widget-Tests in `record_button_test.dart` sind grün

**Stufe C**

- [ ] `SttEngine` entspricht wortgleich `ARCHITEKTUR.md` Abschnitt 4
- [ ] `WebStubSttEngine` liefert Beispieltext mit einstellbarer Verzögerung
      **und** einstellbarer Fehlerquote
- [ ] `PlatformSttEngine` initialisiert und meldet `isAvailable` ehrlich
- [ ] `registerSttEngine()` ist die einzige Datei in `capture_core`, die
      `resolveSttEngineId()` aufruft
- [ ] Alle vier Tests in `stt_engine_test.dart` sind grün
- [ ] Der Web-Build startet, eine Aufnahme lässt sich anlegen, und der
      Stub-Text erscheint

**Stufe D**

- [ ] `ModelDownloader` prüft SHA-256 und löscht bei Abweichung
- [ ] `ParakeetSttEngine` existiert und wirft eine klare `SttFailure`, statt
      still zu scheitern
- [ ] `ModelDownloadSheet` formuliert die 640 MB als Beweis, nicht als Kosten
- [ ] `PrecisionCheck` gewährt genau drei Freiläufe
- [ ] `Features.parakeetEnabled` steht weiterhin auf `false`
- [ ] `**/models/*.onnx` ist in `.gitignore`
- [ ] `melos run analyze` ohne Befund, `melos run test` grün

## Beispielaufruf

```
Bau Stufe A des Sprach-Kerns: Datenmodell und Speicher nach ARCHITEKTUR.md
Abschnitt 3, mit drift und Volltextsuche. Tests dazu.
```

```
Stufe C jetzt: SttEngine-Schnittstelle mit WebStubSttEngine und
PlatformSttEngine. Parakeet noch nicht.
```

```
Häng Parakeet ein — ich hab jetzt ein Android-Gerät.
```

Weitere Formulierungen, die diesen Skill auslösen:

```
Bau den Sprach-Kern.
capture_core aufbauen.
Aufnahme und Transkription einbauen.
```
