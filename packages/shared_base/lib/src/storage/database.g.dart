// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EntriesTable extends Entries with TableInfo<$EntriesTable, EntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant<String>('[]'));
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant<String>('{}'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, type, title, createdAt, updatedAt, tags, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(Insertable<EntryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }
}

class EntryRow extends DataClass implements Insertable<EntryRow> {
  final String id;
  final String type;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// JSON-Liste.
  final String tags;

  /// JSON-Objekt — Ergebnis des Interpreters.
  final String data;
  const EntryRow(
      {required this.id,
      required this.type,
      this.title,
      required this.createdAt,
      required this.updatedAt,
      required this.tags,
      required this.data});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['tags'] = Variable<String>(tags);
    map['data'] = Variable<String>(data);
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      type: Value(type),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      tags: Value(tags),
      data: Value(data),
    );
  }

  factory EntryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String?>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      tags: serializer.fromJson<String>(json['tags']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String?>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'tags': serializer.toJson<String>(tags),
      'data': serializer.toJson<String>(data),
    };
  }

  EntryRow copyWith(
          {String? id,
          String? type,
          Value<String?> title = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          String? tags,
          String? data}) =>
      EntryRow(
        id: id ?? this.id,
        type: type ?? this.type,
        title: title.present ? title.value : this.title,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        tags: tags ?? this.tags,
        data: data ?? this.data,
      );
  EntryRow copyWithCompanion(EntriesCompanion data) {
    return EntryRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      tags: data.tags.present ? data.tags.value : this.tags,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('tags: $tags, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, title, createdAt, updatedAt, tags, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.tags == this.tags &&
          other.data == this.data);
}

class EntriesCompanion extends UpdateCompanion<EntryRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<String?> title;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> tags;
  final Value<String> data;
  final Value<int> rowid;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.tags = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntriesCompanion.insert({
    required String id,
    required String type,
    this.title = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.tags = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        type = Value(type),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<EntryRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? tags,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (tags != null) 'tags': tags,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? type,
      Value<String?>? title,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String>? tags,
      Value<String>? data,
      Value<int>? rowid}) {
    return EntriesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      data: data ?? this.data,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('tags: $tags, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SegmentsTable extends Segments
    with TableInfo<$SegmentsTable, SegmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entryIdMeta =
      const VerificationMeta('entryId');
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
      'entry_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES entries (id) ON DELETE CASCADE'));
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _mediaPathMeta =
      const VerificationMeta('mediaPath');
  @override
  late final GeneratedColumn<String> mediaPath = GeneratedColumn<String>(
      'media_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _transcriptMeta =
      const VerificationMeta('transcript');
  @override
  late final GeneratedColumn<String> transcript = GeneratedColumn<String>(
      'transcript', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _engineMeta = const VerificationMeta('engine');
  @override
  late final GeneratedColumn<String> engine = GeneratedColumn<String>(
      'engine', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, entryId, order, mediaPath, transcript, engine, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'segments';
  @override
  VerificationContext validateIntegrity(Insertable<SegmentRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(_entryIdMeta,
          entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta));
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_orderMeta,
          order.isAcceptableOrUnknown(data['sort_order']!, _orderMeta));
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('media_path')) {
      context.handle(_mediaPathMeta,
          mediaPath.isAcceptableOrUnknown(data['media_path']!, _mediaPathMeta));
    }
    if (data.containsKey('transcript')) {
      context.handle(
          _transcriptMeta,
          transcript.isAcceptableOrUnknown(
              data['transcript']!, _transcriptMeta));
    }
    if (data.containsKey('engine')) {
      context.handle(_engineMeta,
          engine.isAcceptableOrUnknown(data['engine']!, _engineMeta));
    } else if (isInserting) {
      context.missing(_engineMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SegmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SegmentRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      entryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_id'])!,
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      mediaPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_path']),
      transcript: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transcript']),
      engine: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}engine'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SegmentsTable createAlias(String alias) {
    return $SegmentsTable(attachedDatabase, alias);
  }
}

class SegmentRow extends DataClass implements Insertable<SegmentRow> {
  final String id;
  final String entryId;

  /// `order` ist in SQL ein Schlüsselwort. Der Dart-Name bleibt `order`,
  /// weil ARCHITEKTUR.md Abschnitt 3 ihn so festlegt; die Spalte heißt
  /// deshalb ausdrücklich `sort_order`, damit kein Zitieren nötig ist.
  final int order;
  final String? mediaPath;
  final String? transcript;
  final String engine;
  final DateTime createdAt;
  const SegmentRow(
      {required this.id,
      required this.entryId,
      required this.order,
      this.mediaPath,
      this.transcript,
      required this.engine,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['sort_order'] = Variable<int>(order);
    if (!nullToAbsent || mediaPath != null) {
      map['media_path'] = Variable<String>(mediaPath);
    }
    if (!nullToAbsent || transcript != null) {
      map['transcript'] = Variable<String>(transcript);
    }
    map['engine'] = Variable<String>(engine);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SegmentsCompanion toCompanion(bool nullToAbsent) {
    return SegmentsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      order: Value(order),
      mediaPath: mediaPath == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaPath),
      transcript: transcript == null && nullToAbsent
          ? const Value.absent()
          : Value(transcript),
      engine: Value(engine),
      createdAt: Value(createdAt),
    );
  }

  factory SegmentRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SegmentRow(
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      order: serializer.fromJson<int>(json['order']),
      mediaPath: serializer.fromJson<String?>(json['mediaPath']),
      transcript: serializer.fromJson<String?>(json['transcript']),
      engine: serializer.fromJson<String>(json['engine']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'order': serializer.toJson<int>(order),
      'mediaPath': serializer.toJson<String?>(mediaPath),
      'transcript': serializer.toJson<String?>(transcript),
      'engine': serializer.toJson<String>(engine),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SegmentRow copyWith(
          {String? id,
          String? entryId,
          int? order,
          Value<String?> mediaPath = const Value.absent(),
          Value<String?> transcript = const Value.absent(),
          String? engine,
          DateTime? createdAt}) =>
      SegmentRow(
        id: id ?? this.id,
        entryId: entryId ?? this.entryId,
        order: order ?? this.order,
        mediaPath: mediaPath.present ? mediaPath.value : this.mediaPath,
        transcript: transcript.present ? transcript.value : this.transcript,
        engine: engine ?? this.engine,
        createdAt: createdAt ?? this.createdAt,
      );
  SegmentRow copyWithCompanion(SegmentsCompanion data) {
    return SegmentRow(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      order: data.order.present ? data.order.value : this.order,
      mediaPath: data.mediaPath.present ? data.mediaPath.value : this.mediaPath,
      transcript:
          data.transcript.present ? data.transcript.value : this.transcript,
      engine: data.engine.present ? data.engine.value : this.engine,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SegmentRow(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('order: $order, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('transcript: $transcript, ')
          ..write('engine: $engine, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entryId, order, mediaPath, transcript, engine, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SegmentRow &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.order == this.order &&
          other.mediaPath == this.mediaPath &&
          other.transcript == this.transcript &&
          other.engine == this.engine &&
          other.createdAt == this.createdAt);
}

class SegmentsCompanion extends UpdateCompanion<SegmentRow> {
  final Value<String> id;
  final Value<String> entryId;
  final Value<int> order;
  final Value<String?> mediaPath;
  final Value<String?> transcript;
  final Value<String> engine;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SegmentsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.order = const Value.absent(),
    this.mediaPath = const Value.absent(),
    this.transcript = const Value.absent(),
    this.engine = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SegmentsCompanion.insert({
    required String id,
    required String entryId,
    required int order,
    this.mediaPath = const Value.absent(),
    this.transcript = const Value.absent(),
    required String engine,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        entryId = Value(entryId),
        order = Value(order),
        engine = Value(engine),
        createdAt = Value(createdAt);
  static Insertable<SegmentRow> custom({
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<int>? order,
    Expression<String>? mediaPath,
    Expression<String>? transcript,
    Expression<String>? engine,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (order != null) 'sort_order': order,
      if (mediaPath != null) 'media_path': mediaPath,
      if (transcript != null) 'transcript': transcript,
      if (engine != null) 'engine': engine,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SegmentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? entryId,
      Value<int>? order,
      Value<String?>? mediaPath,
      Value<String?>? transcript,
      Value<String>? engine,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return SegmentsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      order: order ?? this.order,
      mediaPath: mediaPath ?? this.mediaPath,
      transcript: transcript ?? this.transcript,
      engine: engine ?? this.engine,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (order.present) {
      map['sort_order'] = Variable<int>(order.value);
    }
    if (mediaPath.present) {
      map['media_path'] = Variable<String>(mediaPath.value);
    }
    if (transcript.present) {
      map['transcript'] = Variable<String>(transcript.value);
    }
    if (engine.present) {
      map['engine'] = Variable<String>(engine.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SegmentsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('order: $order, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('transcript: $transcript, ')
          ..write('engine: $engine, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $SegmentsTable segments = $SegmentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [entries, segments];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('entries',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('segments', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$EntriesTableCreateCompanionBuilder = EntriesCompanion Function({
  required String id,
  required String type,
  Value<String?> title,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String> tags,
  Value<String> data,
  Value<int> rowid,
});
typedef $$EntriesTableUpdateCompanionBuilder = EntriesCompanion Function({
  Value<String> id,
  Value<String> type,
  Value<String?> title,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> tags,
  Value<String> data,
  Value<int> rowid,
});

final class $$EntriesTableReferences
    extends BaseReferences<_$AppDatabase, $EntriesTable, EntryRow> {
  $$EntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SegmentsTable, List<SegmentRow>>
      _segmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.segments,
          aliasName: $_aliasNameGenerator(db.entries.id, db.segments.entryId));

  $$SegmentsTableProcessedTableManager get segmentsRefs {
    final manager = $$SegmentsTableTableManager($_db, $_db.segments)
        .filter((f) => f.entryId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_segmentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  Expression<bool> segmentsRefs(
      Expression<bool> Function($$SegmentsTableFilterComposer f) f) {
    final $$SegmentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.segments,
        getReferencedColumn: (t) => t.entryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SegmentsTableFilterComposer(
              $db: $db,
              $table: $db.segments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  Expression<T> segmentsRefs<T extends Object>(
      Expression<T> Function($$SegmentsTableAnnotationComposer a) f) {
    final $$SegmentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.segments,
        getReferencedColumn: (t) => t.entryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SegmentsTableAnnotationComposer(
              $db: $db,
              $table: $db.segments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EntriesTable,
    EntryRow,
    $$EntriesTableFilterComposer,
    $$EntriesTableOrderingComposer,
    $$EntriesTableAnnotationComposer,
    $$EntriesTableCreateCompanionBuilder,
    $$EntriesTableUpdateCompanionBuilder,
    (EntryRow, $$EntriesTableReferences),
    EntryRow,
    PrefetchHooks Function({bool segmentsRefs})> {
  $$EntriesTableTableManager(_$AppDatabase db, $EntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EntriesCompanion(
            id: id,
            type: type,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: tags,
            data: data,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String type,
            Value<String?> title = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<String> tags = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EntriesCompanion.insert(
            id: id,
            type: type,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: tags,
            data: data,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$EntriesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({segmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (segmentsRefs) db.segments],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (segmentsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$EntriesTableReferences._segmentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EntriesTableReferences(db, table, p0)
                                .segmentsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.entryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$EntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EntriesTable,
    EntryRow,
    $$EntriesTableFilterComposer,
    $$EntriesTableOrderingComposer,
    $$EntriesTableAnnotationComposer,
    $$EntriesTableCreateCompanionBuilder,
    $$EntriesTableUpdateCompanionBuilder,
    (EntryRow, $$EntriesTableReferences),
    EntryRow,
    PrefetchHooks Function({bool segmentsRefs})>;
typedef $$SegmentsTableCreateCompanionBuilder = SegmentsCompanion Function({
  required String id,
  required String entryId,
  required int order,
  Value<String?> mediaPath,
  Value<String?> transcript,
  required String engine,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$SegmentsTableUpdateCompanionBuilder = SegmentsCompanion Function({
  Value<String> id,
  Value<String> entryId,
  Value<int> order,
  Value<String?> mediaPath,
  Value<String?> transcript,
  Value<String> engine,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$SegmentsTableReferences
    extends BaseReferences<_$AppDatabase, $SegmentsTable, SegmentRow> {
  $$SegmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EntriesTable _entryIdTable(_$AppDatabase db) => db.entries
      .createAlias($_aliasNameGenerator(db.segments.entryId, db.entries.id));

  $$EntriesTableProcessedTableManager get entryId {
    final manager = $$EntriesTableTableManager($_db, $_db.entries)
        .filter((f) => f.id($_item.entryId));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get order => $composableBuilder(
      column: $table.order, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaPath => $composableBuilder(
      column: $table.mediaPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcript => $composableBuilder(
      column: $table.transcript, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get engine => $composableBuilder(
      column: $table.engine, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$EntriesTableFilterComposer get entryId {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.entryId,
        referencedTable: $db.entries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EntriesTableFilterComposer(
              $db: $db,
              $table: $db.entries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get order => $composableBuilder(
      column: $table.order, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaPath => $composableBuilder(
      column: $table.mediaPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcript => $composableBuilder(
      column: $table.transcript, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get engine => $composableBuilder(
      column: $table.engine, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$EntriesTableOrderingComposer get entryId {
    final $$EntriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.entryId,
        referencedTable: $db.entries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EntriesTableOrderingComposer(
              $db: $db,
              $table: $db.entries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<String> get mediaPath =>
      $composableBuilder(column: $table.mediaPath, builder: (column) => column);

  GeneratedColumn<String> get transcript => $composableBuilder(
      column: $table.transcript, builder: (column) => column);

  GeneratedColumn<String> get engine =>
      $composableBuilder(column: $table.engine, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$EntriesTableAnnotationComposer get entryId {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.entryId,
        referencedTable: $db.entries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.entries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SegmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SegmentsTable,
    SegmentRow,
    $$SegmentsTableFilterComposer,
    $$SegmentsTableOrderingComposer,
    $$SegmentsTableAnnotationComposer,
    $$SegmentsTableCreateCompanionBuilder,
    $$SegmentsTableUpdateCompanionBuilder,
    (SegmentRow, $$SegmentsTableReferences),
    SegmentRow,
    PrefetchHooks Function({bool entryId})> {
  $$SegmentsTableTableManager(_$AppDatabase db, $SegmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> entryId = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<String?> mediaPath = const Value.absent(),
            Value<String?> transcript = const Value.absent(),
            Value<String> engine = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SegmentsCompanion(
            id: id,
            entryId: entryId,
            order: order,
            mediaPath: mediaPath,
            transcript: transcript,
            engine: engine,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String entryId,
            required int order,
            Value<String?> mediaPath = const Value.absent(),
            Value<String?> transcript = const Value.absent(),
            required String engine,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SegmentsCompanion.insert(
            id: id,
            entryId: entryId,
            order: order,
            mediaPath: mediaPath,
            transcript: transcript,
            engine: engine,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SegmentsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (entryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.entryId,
                    referencedTable:
                        $$SegmentsTableReferences._entryIdTable(db),
                    referencedColumn:
                        $$SegmentsTableReferences._entryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SegmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SegmentsTable,
    SegmentRow,
    $$SegmentsTableFilterComposer,
    $$SegmentsTableOrderingComposer,
    $$SegmentsTableAnnotationComposer,
    $$SegmentsTableCreateCompanionBuilder,
    $$SegmentsTableUpdateCompanionBuilder,
    (SegmentRow, $$SegmentsTableReferences),
    SegmentRow,
    PrefetchHooks Function({bool entryId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$SegmentsTableTableManager get segments =>
      $$SegmentsTableTableManager(_db, _db.segments);
}
