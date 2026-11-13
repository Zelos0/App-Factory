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
    this.showSegmentTimes = false,
  });

  /// Wer es bekommt: 'Finanzamt', 'Vermieter', 'Hausarzt', 'Versicherung'.
  final String name;

  final String headline;
  final String? subline;
  final String? footer;

  /// Schlüssel aus `Entry.data`, die als Tabellenspalten erscheinen.
  final List<String> columns;

  final PdfColor accent;

  /// Protokoll-Optik: Datum groß über dem Eintrag, jedes Segment mit
  /// eigener Uhrzeit darunter. Für Empfänger, denen der Verlauf wichtiger
  /// ist als die Zusammenfassung — VOX (eigenes Archiv), ANAMNESE (Arzt),
  /// WERKBUCH (Bauherr). Ohne diesen Schalter wird der Volltext am Stück
  /// gesetzt, wie bisher.
  final bool showSegmentTimes;
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
            pw.Text(
              recipient.headline,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: recipient.accent,
              ),
            ),
            if (recipient.subline != null)
              pw.Text(
                recipient.subline!,
                style: const pw.TextStyle(fontSize: 11),
              ),
            pw.SizedBox(height: 12),
            pw.Divider(color: recipient.accent, thickness: 0.8),
          ],
        ),
        footer: (pw.Context context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Text(
              recipient.footer ?? '',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'Seite ${context.pageNumber} von ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        build: (pw.Context context) => <pw.Widget>[
          if (recipient.columns.isEmpty)
            ..._asProse(entries, showSegmentTimes: recipient.showSegmentTimes)
          else
            _asTable(entries, recipient.columns),
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  List<pw.Widget> _asProse(
    List<EntryWithSegments> entries, {
    required bool showSegmentTimes,
  }) {
    return entries
        .map(
          (EntryWithSegments e) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 18),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                if (e.entry.title != null)
                  pw.Text(
                    e.entry.title!,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                pw.Text(
                  _date(e.entry.createdAt),
                  style: pw.TextStyle(
                    fontSize: showSegmentTimes ? 13 : 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: showSegmentTimes ? 6 : 2),
                if (showSegmentTimes)
                  ..._segments(e)
                else
                  pw.Text(
                    e.fullText,
                    style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
                  ),
              ],
            ),
          ),
        )
        .toList();
  }

  /// Die Segmentkette einzeln, jedes mit seiner Uhrzeit. Das ist der
  /// Unterschied zwischen einem Protokoll und einer Textwand: man sieht,
  /// wann etwas dazugekommen ist.
  List<pw.Widget> _segments(EntryWithSegments e) {
    return e.segments
        .map(
          (Segment s) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.SizedBox(
                  width: 44,
                  child: pw.Text(
                    _time(s.createdAt),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    s.transcript ?? '(kein Text)',
                    style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  pw.Widget _asTable(List<EntryWithSegments> entries, List<String> columns) {
    return pw.TableHelper.fromTextArray(
      headers: <String>['Datum', ...columns],
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      data: entries
          .map(
            (EntryWithSegments e) => <String>[
              _date(e.entry.createdAt),
              ...columns.map((String c) => (e.entry.data[c] ?? '').toString()),
            ],
          )
          .toList(),
    );
  }

  static String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';

  static String _time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}
