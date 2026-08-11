import 'package:flutter/material.dart';
import 'package:shared_base/shared_base.dart';

import 'vox_interpreter.dart';
import 'vox_theme.dart';

/// Auswertung. Zuschnitt aus dem Bauplan Abschnitt 5.
///
/// Die eine große Zahl ist **gesprochene Wörter gesamt**. VOX hat keine
/// Beträge, die sich addieren — was sich addiert, ist gesprochener Umfang,
/// und genau der ist der Beweis von „Sprechen ist schneller als Tippen".
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({required this.store, super.key});

  final EntryStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auswertung')),
      body: StreamBuilder<List<Entry>>(
        stream: store.watchAll(),
        builder: (BuildContext context, AsyncSnapshot<List<Entry>> snapshot) {
          final List<Entry> entries = snapshot.data ?? const <Entry>[];
          if (entries.isEmpty) {
            return const Center(child: Text('Noch nichts aufgenommen.'));
          }
          return _Report(summary: VoxSummary.of(entries));
        },
      ),
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.summary});

  final VoxSummary summary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> weeks = summary.byWeek.keys.toList()..sort();
    final int peak = summary.peakWeekWords;

    return ListView(
      // Freistehende Liste: der untere Abstand hält Banner und Mindest-
      // abstand frei, weil dieser Bildschirm nicht in AdSafeArea steckt.
      padding: EdgeInsets.fromLTRB(
        Tokens.m,
        Tokens.m,
        Tokens.m,
        AdSafeArea.scrollPadding(context),
      ),
      children: <Widget>[
        Text('Gesprochene Wörter', style: theme.textTheme.labelLarge),
        // Die eine große Zahl. Bewusst umbruchfähig statt beschnitten,
        // damit sie auch bei größter Schriftstufe vollständig lesbar ist.
        Text(
          '${summary.totalWords}',
          style: theme.textTheme.displaySmall,
          softWrap: true,
        ),
        const SizedBox(height: Tokens.xs),
        Text(
          '${summary.entryCount} Einträge · '
          '${summary.totalSpokenMinutesEstimate} Minuten gesprochen (geschätzt)',
          style:
              theme.textTheme.labelMedium?.copyWith(color: VoxTheme.secondary),
        ),
        const SizedBox(height: Tokens.xl),

        // --- Hauptform: Verlauf je Woche ---
        Text('Verlauf je Woche', style: theme.textTheme.labelLarge),
        const SizedBox(height: Tokens.s),
        for (final String w in weeks)
          Padding(
            padding: const EdgeInsets.only(bottom: Tokens.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(child: Text(w)),
                    Text('${summary.byWeek[w]}'),
                  ],
                ),
                const SizedBox(height: Tokens.xs),
                LinearProgressIndicator(
                  value: peak == 0 ? 0 : summary.byWeek[w]! / peak,
                  minHeight: Tokens.s,
                ),
              ],
            ),
          ),

        // --- Nebenform: Häufigkeitsliste der Schlagworte ---
        if (summary.keywordCounts.isNotEmpty) ...<Widget>[
          const SizedBox(height: Tokens.l),
          Text('Häufigste Schlagworte', style: theme.textTheme.labelLarge),
          const SizedBox(height: Tokens.s),
          for (final MapEntry<String, int> k in summary.topKeywords)
            Padding(
              padding: const EdgeInsets.only(bottom: Tokens.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(child: Text(k.key)),
                  Text(
                    '${k.value}',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: VoxTheme.secondary),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// Die Rechnung hinter der Auswertung — ohne Flutter, deshalb im Unit-Test
/// prüfbar. Genau dafür steht sie neben dem Bildschirm und nicht in ihm.
class VoxSummary {
  const VoxSummary({
    required this.entryCount,
    required this.totalWords,
    required this.byWeek,
    required this.keywordCounts,
  });

  factory VoxSummary.of(List<Entry> entries) {
    int totalWords = 0;
    final Map<String, int> byWeek = <String, int>{};
    final Map<String, int> keywords = <String, int>{};

    for (final Entry e in entries) {
      final VoxResult r = VoxResult.fromJson(e.data);
      totalWords += r.wordCount;

      final String week = weekKey(e.createdAt);
      byWeek[week] = (byWeek[week] ?? 0) + r.wordCount;

      for (final String k in r.keywords) {
        final String key = k.toLowerCase();
        keywords[key] = (keywords[key] ?? 0) + 1;
      }
    }

    return VoxSummary(
      entryCount: entries.length,
      totalWords: totalWords,
      byWeek: byWeek,
      keywordCounts: keywords,
    );
  }

  final int entryCount;
  final int totalWords;

  /// Schlüssel im Muster `2026-KW32`, damit alphabetisch sortiert zugleich
  /// chronologisch sortiert ist.
  final Map<String, int> byWeek;

  final Map<String, int> keywordCounts;

  int get peakWeekWords => byWeek.values.isEmpty
      ? 0
      : byWeek.values.reduce((int a, int b) => a > b ? a : b);

  /// Grobe Schätzung bei 130 gesprochenen Wörtern je Minute. Sie steht
  /// ausdrücklich als Schätzung dran — eine genaue Zahl bräuchte die
  /// Audiodauer, und die fehlt, solange Segmente ohne Medium erlaubt sind.
  int get totalSpokenMinutesEstimate => (totalWords / 130).round();

  List<MapEntry<String, int>> get topKeywords {
    final List<MapEntry<String, int>> all = keywordCounts.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
        final int byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return all.take(10).toList();
  }

  /// ISO-8601-Kalenderwoche. Donnerstag derselben Woche bestimmt das Jahr —
  /// sonst landet der 31. Dezember in Woche 1 des Vorjahres.
  static String weekKey(DateTime d) {
    final DateTime date = DateTime(d.year, d.month, d.day);
    // DateTime.weekday ist bereits ISO: Montag 1 … Sonntag 7.
    final DateTime thursday = date.add(Duration(days: 4 - date.weekday));
    final DateTime firstJanuary = DateTime(thursday.year, 1, 1);
    final int week =
        ((thursday.difference(firstJanuary).inDays) / 7).floor() + 1;
    return '${thursday.year}-KW${week.toString().padLeft(2, '0')}';
  }
}
