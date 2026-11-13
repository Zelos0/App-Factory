import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import 'file_vault.dart';
import 'idb/idb_backend.dart';

/// Ablage im Browser — dauerhaft in IndexedDB.
///
/// Originalaufnahmen und -bilder überleben damit Neuladen, Schließen des
/// Tabs und das Öffnen vom Home-Bildschirm. Ein Zwischenspeicher im
/// Arbeitsspeicher spart wiederholtes Lesen.
///
/// Außerhalb des Browsers (VM-Tests) und falls IndexedDB nicht verfügbar ist
/// (privates Fenster in alten Safari-Versionen), arbeitet die Ablage nur im
/// Arbeitsspeicher weiter, statt zu scheitern — [isPersistent] sagt, welcher
/// Fall vorliegt.
///
/// Was hier NICHT geprüft wird, ist das Verhalten bei vollem Speicher —
/// das steht in TESTLEITER.md unter „Was diese Leiter nicht kann".
class IndexedDbVault implements FileVault {
  IndexedDbVault({this.prefix = 'vault', IdbBackend? backend})
      : _backend = backend ?? openIdbBackend('app-fabrik-vault-$prefix');

  final String prefix;
  final IdbBackend _backend;
  final Map<String, Uint8List> _cache = <String, Uint8List>{};

  static const Uuid _uuid = Uuid();

  @override
  String get id => 'indexeddb';

  /// True, wenn die Bytes ein Neuladen überleben.
  Future<bool> get isPersistent => _backend.isPersistent;

  /// Erkennt Pfade, die diese Ablage vergeben hat.
  bool owns(String path) => path.startsWith('$prefix/');

  @override
  Future<String> put(Uint8List bytes, {required String extension}) async {
    final String key = '$prefix/${_uuid.v4()}.$extension';
    _cache[key] = bytes;
    await _backend.put(key, bytes);
    return key;
  }

  @override
  Future<Uint8List?> get(String path) async {
    final Uint8List? hit = _cache[path];
    if (hit != null) {
      return hit;
    }
    final Uint8List? stored = await _backend.get(path);
    if (stored != null) {
      _cache[path] = stored;
    }
    return stored;
  }

  @override
  Future<bool> exists(String path) async =>
      _cache.containsKey(path) || await _backend.get(path) != null;

  @override
  Future<void> delete(String path) async {
    _cache.remove(path);
    await _backend.delete(path);
  }

  @override
  Future<List<String>> list() async {
    final Set<String> keys = <String>{..._cache.keys, ...await _backend.keys()};
    return keys.where(owns).toList()..sort();
  }

  @override
  Future<int> usedBytes() async {
    int sum = 0;
    for (final String k in await list()) {
      sum += (await get(k))?.length ?? 0;
    }
    return sum;
  }
}

/// Dateityp zu einer Endung — für Wiedergabe und Export.
String mimeForExtension(String path) {
  final String ext = path.split('.').last.toLowerCase();
  return switch (ext) {
    'webm' => 'audio/webm',
    'ogg' || 'opus' => 'audio/ogg',
    'm4a' || 'mp4' || 'aac' => 'audio/mp4',
    'wav' => 'audio/wav',
    'mp3' => 'audio/mpeg',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'pdf' => 'application/pdf',
    _ => 'application/octet-stream',
  };
}
