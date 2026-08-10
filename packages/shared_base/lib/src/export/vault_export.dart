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
