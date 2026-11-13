import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'models.dart';

/// Einzige Tür zu den Daten. Kein Kern und keine App greift direkt auf
/// [AppDatabase] zu.
class EntryStore {
  /// [clock] nur für Tests und Golden-Bilder: Mit fester Uhr sehen
  /// Zeitstempel an jedem Tag gleich aus.
  EntryStore(this._db, {required this.type, DateTime Function()? clock})
      : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  /// Flavor-Kennung. Trennt die Einträge mehrerer Apps in derselben Datei.
  final String type;

  static const Uuid _uuid = Uuid();

  /// Legt einen leeren Eintrag an. Segmente kommen per [appendSegment] dazu.
  Future<Entry> createEntry({String? title, List<String>? tags}) async {
    final DateTime now = _now();
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
    required String engine,
    String? mediaPath,
    String? transcript,
  }) async {
    final int next = await _nextOrder(entryId);
    final Segment segment = Segment(
      id: _uuid.v4(),
      entryId: entryId,
      order: next,
      mediaPath: mediaPath,
      transcript: transcript,
      engine: engine,
      createdAt: _now(),
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
        updatedAt: Value<DateTime>(_now()),
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
          (List<EntryRow> rows) => rows.map(_fromRow).toList(growable: false),
        );
  }

  /// Volltextsuche über alle Segmenttexte dieser App.
  Future<List<Entry>> search(String query) async {
    if (query.trim().isEmpty) {
      return <Entry>[];
    }
    final List<QueryRow> rows = await _db.customSelect(
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
    ).get();
    return rows.map((QueryRow r) => _fromRow(_db.entries.map(r.data))).toList();
  }

  Future<void> deleteEntry(String entryId) async {
    await _db.customStatement(
      'DELETE FROM segment_fts WHERE entry_id = ?',
      <Object>[entryId],
    );
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
        .write(EntriesCompanion(updatedAt: Value<DateTime>(_now())));
  }

  Future<void> _reindex(Segment s) async {
    await _db.customStatement(
      'DELETE FROM segment_fts WHERE segment_id = ?',
      <Object>[s.id],
    );
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
