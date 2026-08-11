import 'dart:convert';

import 'package:shared_base/shared_base.dart';

import 'vox_interpreter.dart';

/// Die vier Empfänger aus ARCHITEKTUR.md Abschnitt 7, plus Fluchttür.
/// Zuschnitt: docs/baupläne/vox.md Abschnitt 6.
///
/// VOX hat keinen Empfänger mit Autorität — es ist eine private Notiz-App.
/// Das PDF ist deshalb ein Lesedokument für den Nutzer selbst, keine
/// Tabelle für ein Amt.
class VoxExport {
  const VoxExport();

  /// Empfänger: der Nutzer selbst, später. Schlagworte werden zu
  /// `[[Verweisen]]`, damit die Datei in einer Wissensablage andockt.
  String markdown(EntryWithSegments e) {
    final VoxResult r = VoxResult.fromJson(e.entry.data);
    final String title =
        e.entry.title ?? r.title ?? 'Eintrag vom ${_date(e.entry.createdAt)}';

    final StringBuffer b = StringBuffer()
      ..writeln('---')
      ..writeln('id: ${e.entry.id}')
      ..writeln('typ: ${e.entry.type}')
      ..writeln('erstellt: ${e.entry.createdAt.toIso8601String()}')
      ..writeln('titel: ${_quote(title)}')
      ..writeln('woerter: ${r.wordCount}')
      ..writeln(
        'schlagworte: [${r.keywords.map(_quote).join(', ')}]',
      )
      ..writeln('---')
      ..writeln()
      ..writeln('# $title')
      ..writeln();

    if (r.keywords.isNotEmpty) {
      b
        ..writeln(r.keywords.map((String k) => '[[$k]]').join(' · '))
        ..writeln();
    }

    for (final Segment s in e.segments) {
      b
        ..writeln('## ${_time(s.createdAt)}')
        ..writeln()
        ..writeln(s.transcript ?? '(kein Text)')
        ..writeln();
    }

    return b.toString();
  }

  /// Empfänger: ein KI-Modell. Schema-Kopf, Einträge, vorformulierter
  /// Auftrag, Token-Schätzung.
  String aiBundle(List<EntryWithSegments> entries, {String? auftrag}) {
    final StringBuffer b = StringBuffer()
      ..writeln('# Kontextbündel — Vox')
      ..writeln()
      ..writeln('## Schema')
      ..writeln('- title: Zeichenkette, erster Satz der Notiz')
      ..writeln('- keywords: Liste, häufigste Wörter der Notiz')
      ..writeln('- wordCount: Zahl, gesprochene Wörter')
      ..writeln('- confidence: 0..1, Zuverlässigkeit der Ordnung')
      ..writeln('- segments: geordnete Abschnitte eines Eintrags')
      ..writeln()
      ..writeln('## Einträge (${entries.length})')
      ..writeln();

    for (final EntryWithSegments e in entries) {
      b
        ..writeln('### ${e.entry.id}')
        ..writeln('erstellt: ${e.entry.createdAt.toIso8601String()}')
        ..writeln('daten: ${jsonEncode(e.entry.data)}')
        ..writeln('text: ${e.fullText}')
        ..writeln();
    }

    b
      ..writeln('## Auftrag')
      ..writeln(
        auftrag ??
            'Fasse die Notizen thematisch zusammen und nenne offene Punkte, '
                'die noch nicht zu Ende gedacht sind.',
      )
      ..writeln()
      ..writeln('## Umfang')
      ..writeln('geschätzte Token: ${_estimateTokens(b.toString())}');

    return b.toString();
  }

  /// Empfänger: andere Software. Reiner Volltext, ohne Kopf.
  String plainText(EntryWithSegments e) => e.fullText;

  /// Empfänger: andere Software. Zeitstempel je Segment, wie im Steckbrief
  /// verlangt.
  String json(List<EntryWithSegments> entries) =>
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'app': VoxInterpreter.id,
        'schema': VoxInterpreter.schemaVersion,
        'eintraege': entries.map(_entryAsJson).toList(),
      });

  static Map<String, dynamic> _entryAsJson(EntryWithSegments e) {
    final VoxResult r = VoxResult.fromJson(e.entry.data);
    return <String, dynamic>{
      'id': e.entry.id,
      'erstellt': e.entry.createdAt.toIso8601String(),
      'titel': e.entry.title ?? r.title,
      'woerter': r.wordCount,
      'schlagworte': r.keywords,
      'segmente': e.segments
          .map(
            (Segment s) => <String, dynamic>{
              'reihenfolge': s.order,
              'zeit': s.createdAt.toIso8601String(),
              'engine': s.engine,
              'text': s.transcript,
            },
          )
          .toList(),
    };
  }

  /// Empfänger: ein Mensch — hier der Nutzer selbst, später.
  ///
  /// Kostenlos wie jeder Export bei VOX — bezahlt wird für Tempo und
  /// Präzision, nie dafür, die eigenen Daten wieder herauszubekommen.
  ///
  /// Kein Amt, kein Briefkopf, keine Unterschriftszeile. Protokoll-Optik:
  /// Datum groß, die Segmentkette chronologisch mit Uhrzeit, Transkript in
  /// Lesetypografie. Im Fuß stehen die häufigsten Schlagworte — damit der
  /// Ausdruck wiederauffindbar ist, ohne ihn zu lesen.
  PdfRecipient pdfRecipientFor(List<EntryWithSegments> entries) =>
      PdfRecipient(
        name: 'Eigenes Archiv',
        headline: 'Sprachnotizen',
        subline: _range(entries),
        footer: _footer(entries),
        showSegmentTimes: true,
      );

  /// Zeitraum der Sammlung, statt eines leeren Untertitels.
  static String _range(List<EntryWithSegments> entries) {
    if (entries.isEmpty) {
      return 'Keine Einträge';
    }
    final List<DateTime> dates = entries
        .map((EntryWithSegments e) => e.entry.createdAt)
        .toList()
      ..sort();
    final String from = _date(dates.first);
    final String to = _date(dates.last);
    return from == to ? from : '$from bis $to';
  }

  /// Die häufigsten Schlagworte über alle Einträge, absteigend.
  static String _footer(List<EntryWithSegments> entries) {
    final Map<String, int> counts = <String, int>{};
    for (final EntryWithSegments e in entries) {
      for (final String k in VoxResult.fromJson(e.entry.data).keywords) {
        final String key = k.toLowerCase();
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) {
      return 'Vox · offline aufgezeichnet, ohne Konto';
    }
    final List<String> top = counts.keys.toList()
      ..sort((String a, String b) {
        final int byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    return 'Vox · ${top.take(6).join(' · ')}';
  }

  /// Fluchttür: vollständiges JSON. Immer kostenlos, immer sichtbar.
  /// Das ZIP der Originaldateien erzeugt `VaultExport.toZip`.
  String escapeHatch(List<EntryWithSegments> entries) =>
      const VaultExport().toJson(entries, app: VoxInterpreter.id);

  static int _estimateTokens(String s) => (s.length / 3.6).round();

  static String _quote(String s) => '"${s.replaceAll('"', r'\"')}"';

  static String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';

  static String _time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}
