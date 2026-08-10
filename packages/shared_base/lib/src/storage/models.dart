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

  String toJsonString() =>
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'entry': entry.toJson(),
        'segments': segments.map((Segment s) => s.toJson()).toList(),
      });
}
