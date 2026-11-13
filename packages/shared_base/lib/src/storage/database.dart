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
