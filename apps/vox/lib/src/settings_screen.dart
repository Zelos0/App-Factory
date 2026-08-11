import 'dart:async';

import 'package:capture_core/capture_core.dart';
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

  /// Der Web-Build hat keinen Dateidialog. Statt eine halbe Lösung zu
  /// bauen, landet der Export in der Zwischenablage — von dort geht er
  /// überall hin. Der Datei-Export kommt mit `test-loop-free` Stufe 1.
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
            subtitle: Text(Registry.instance.get<SttEngine>().id),
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
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Markdown'),
            subtitle: const Text('Für die eigene Ablage, mit [[Verweisen]]'),
            enabled: !_busy,
            onTap: () => unawaited(
              _copy('Markdown', () async {
                final List<EntryWithSegments> all = await _all();
                return all.map(_export.markdown).join('\n\n---\n\n');
              }),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('Kontextbündel für ein KI-Modell'),
            subtitle: const Text('Schema, Einträge und ein fertiger Auftrag'),
            enabled: !_busy,
            onTap: () => unawaited(
              _copy('Kontextbündel', () async => _export.aiBundle(await _all())),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.data_object),
            title: const Text('JSON mit Zeitstempeln je Segment'),
            enabled: !_busy,
            onTap: () => unawaited(
              _copy('JSON', () async => _export.json(await _all())),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notes_outlined),
            title: const Text('Nur Text'),
            enabled: !_busy,
            onTap: () => unawaited(
              _copy('Text', () async {
                final List<EntryWithSegments> all = await _all();
                return all.map(_export.plainText).join('\n\n');
              }),
            ),
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
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Fluchttür — alles mitnehmen'),
            subtitle: const Text(
              'Vollständiges JSON aller Einträge und Segmente. '
              'Dauerhaft kostenlos.',
            ),
            enabled: !_busy,
            onTap: () => unawaited(
              _copy('Fluchttür-Export', () async => _export.escapeHatch(
                    await _all(),
                  )),
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
