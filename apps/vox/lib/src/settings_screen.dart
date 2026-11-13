import 'dart:async';
import 'dart:convert';

import 'package:capture_core/capture_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_base/shared_base.dart';

import 'vox_export.dart';
import 'vox_interpreter.dart';

/// Einstellungen. Der wichtigste Eintrag steht ganz unten und ist der
/// einzige, der nie etwas kostet: die Fluchttür.
///
/// ARCHITEKTUR.md Abschnitt 7: Aufbereitete Formate dürfen zur Kaufversion
/// gehören, die Rohdaten nie.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.store, super.key});

  final EntryStore store;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final VoxExport _export = const VoxExport();

  bool _busy = false;

  Future<List<EntryWithSegments>> _all() async {
    final List<Entry> entries = await widget.store.watchAll().first;
    final List<EntryWithSegments> full = <EntryWithSegments>[];
    for (final Entry e in entries) {
      final EntryWithSegments? one = await widget.store.byId(e.id);
      if (one != null) {
        full.add(one);
      }
    }
    return full;
  }

  /// Zweitweg für jedes Textformat: direkt in die Zwischenablage, etwa um
  /// es in einen Chat mit einem KI-Modell einzufügen.
  Future<void> _copy(String label, Future<String> Function() build) async {
    setState(() => _busy = true);
    try {
      final String content = await build();
      await Clipboard.setData(ClipboardData(text: content));
      _report('$label in die Zwischenablage kopiert.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Hauptweg: als Datei hinausgeben — Teilen-Menü auf dem Telefon,
  /// Download am Rechner. [anchor] verortet das Menü auf dem iPad.
  Future<void> _share(
    BuildContext anchor, {
    required String label,
    required String name,
    required String mime,
    required Future<Uint8List> Function() build,
  }) async {
    final Rect? origin = _originOf(anchor);
    setState(() => _busy = true);
    try {
      final Uint8List bytes = await build();
      final ShareOutcome outcome = await shareFile(
        bytes: bytes,
        name: name,
        mime: mime,
        origin: origin,
      );
      switch (outcome) {
        case ShareOutcome.shared:
          break;
        case ShareOutcome.downloaded:
          _report('$label gespeichert: $name');
        case ShareOutcome.cancelled:
          break;
      }
    } on Object catch (e) {
      _report('$label ließ sich nicht erzeugen: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  static Rect? _originOf(BuildContext context) {
    final RenderObject? box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return null;
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static Uint8List _utf8(String s) => Uint8List.fromList(utf8.encode(s));

  Future<String> _markdownAll() async {
    final List<EntryWithSegments> all = await _all();
    return all.map(_export.markdown).join('\n\n---\n\n');
  }

  Future<String> _textAll() async {
    final List<EntryWithSegments> all = await _all();
    return all.map(_export.plainText).join('\n\n');
  }

  /// Eine Zeile im Exportbereich: Tippen gibt die Datei hinaus, das
  /// Symbol rechts kopiert den Inhalt.
  Widget _exportTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required String label,
    required String name,
    required String mime,
    required Future<String> Function() text,
  }) {
    return Builder(
      builder: (BuildContext tileContext) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        enabled: !_busy,
        onTap: () => unawaited(
          _share(
            tileContext,
            label: label,
            name: name,
            mime: mime,
            build: () async => _utf8(await text()),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy_rounded),
          tooltip: '$label kopieren',
          onPressed: _busy ? null : () => unawaited(_copy(label, text)),
        ),
      ),
    );
  }

  /// Menschlicher Name der laufenden Engine statt ihrer Kennung.
  static String _engineLabel(SttEngine e) => switch (e.id) {
        'web' => 'Beispielsätze — Testmodus',
        'platform' => kIsWeb
            ? 'Spracherkennung des Browsers'
            : 'Spracherkennung des Geräts',
        'parakeet' => 'Präzisions-Engine, offline',
        _ => e.id,
      };

  void _report(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: EdgeInsets.only(bottom: AdSafeArea.scrollPadding(context)),
        children: <Widget>[
          const ListTile(
            leading: Icon(Icons.brightness_6_outlined),
            title: Text('Hell und dunkel'),
            subtitle: Text('Folgt der Systemeinstellung des Geräts'),
          ),
          const ListTile(
            leading: Icon(Icons.format_size),
            title: Text('Schriftgröße'),
            subtitle: Text('Folgt der Systemeinstellung des Geräts'),
          ),
          ListTile(
            leading: const Icon(Icons.record_voice_over_outlined),
            title: const Text('Spracherkennung'),
            subtitle: Text(_engineLabel(Registry.instance.get<SttEngine>())),
          ),
          const ConsentTile(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.m,
              Tokens.m,
              Tokens.m,
              Tokens.s,
            ),
            child: Text('Export', style: theme.textTheme.labelLarge),
          ),
          _exportTile(
            icon: Icons.description_outlined,
            title: 'Markdown',
            subtitle: 'Für die eigene Ablage, mit [[Verweisen]]',
            label: 'Markdown',
            name: exportName('vox', 'md'),
            mime: Mime.markdown,
            text: _markdownAll,
          ),
          Builder(
            builder: (BuildContext tileContext) => ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDF'),
              subtitle: const Text('Zum Lesen und Drucken, mit Uhrzeiten'),
              enabled: !_busy,
              onTap: () => unawaited(
                _share(
                  tileContext,
                  label: 'PDF',
                  name: exportName('vox', 'pdf'),
                  mime: Mime.pdf,
                  build: () async {
                    final List<EntryWithSegments> all = await _all();
                    return const PdfExport().build(
                      entries: all,
                      recipient: _export.pdfRecipientFor(all),
                    );
                  },
                ),
              ),
            ),
          ),
          _exportTile(
            icon: Icons.smart_toy_outlined,
            title: 'Kontextbündel für ein KI-Modell',
            subtitle: 'Schema, Einträge und ein fertiger Auftrag',
            label: 'Kontextbündel',
            name: exportName('vox-ki-kontext', 'md'),
            mime: Mime.markdown,
            text: () async => _export.aiBundle(await _all()),
          ),
          _exportTile(
            icon: Icons.data_object,
            title: 'JSON mit Zeitstempeln je Segment',
            label: 'JSON',
            name: exportName('vox', 'json'),
            mime: Mime.json,
            text: () async => _export.json(await _all()),
          ),
          _exportTile(
            icon: Icons.notes_outlined,
            title: 'Nur Text',
            label: 'Text',
            name: exportName('vox', 'txt'),
            mime: Mime.text,
            text: _textAll,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.m,
              Tokens.m,
              Tokens.m,
              Tokens.s,
            ),
            child: Text('Deine Daten', style: theme.textTheme.labelLarge),
          ),
          Builder(
            builder: (BuildContext tileContext) => ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Fluchttür — alles mitnehmen'),
              subtitle: const Text(
                'ZIP mit allen Einträgen, Segmenten und Originalaufnahmen. '
                'Dauerhaft kostenlos.',
              ),
              enabled: !_busy,
              onTap: () => unawaited(
                _share(
                  tileContext,
                  label: 'Fluchttür',
                  name: exportName('vox-fluchttuer', 'zip'),
                  mime: Mime.zip,
                  build: () async => const VaultExport().toZip(
                    await _all(),
                    app: VoxInterpreter.id,
                  ),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'Daten als JSON kopieren',
                onPressed: _busy
                    ? null
                    : () => unawaited(
                          _copy(
                            'Fluchttür-JSON',
                            () async => _export.escapeHatch(await _all()),
                          ),
                        ),
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(Tokens.m),
            child: Text(
              'Alles bleibt auf diesem Gerät. Kein Konto, kein Server, '
              'keine Übertragung, keine Auswertung deiner Inhalte.',
              style: theme.textTheme.labelMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.m,
              0,
              Tokens.m,
              Tokens.m,
            ),
            child: Text(
              '${VoxInterpreter.id} · Schema ${VoxInterpreter.schemaVersion} · '
              '$kApplicationId',
              style: theme.textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}
