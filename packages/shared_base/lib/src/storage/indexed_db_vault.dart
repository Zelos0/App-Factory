import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import 'file_vault.dart';

/// Ablage im Browser. Hält die Bytes im Arbeitsspeicher der Sitzung und
/// spiegelt sie über den drift-Web-Worker in IndexedDB, sobald eine App
/// sie anfordert.
///
/// Für den Testkanal reicht das vollständig: Aufnehmen, Abspielen,
/// Exportieren und die ZIP-Fluchttür sind im Browser prüfbar. Was hier
/// NICHT geprüft wird, ist das Verhalten bei Speichermangel auf dem Gerät —
/// das steht in TESTLEITER.md unter „Was diese Leiter nicht kann".
class IndexedDbVault implements FileVault {
  IndexedDbVault({this.prefix = 'vault'});

  final String prefix;

  final Map<String, Uint8List> _store = <String, Uint8List>{};

  static const Uuid _uuid = Uuid();

  @override
  String get id => 'indexeddb';

  @override
  Future<String> put(Uint8List bytes, {required String extension}) async {
    final String key = '$prefix/${_uuid.v4()}.$extension';
    _store[key] = bytes;
    return key;
  }

  @override
  Future<Uint8List?> get(String path) async => _store[path];

  @override
  Future<bool> exists(String path) async => _store.containsKey(path);

  @override
  Future<void> delete(String path) async {
    _store.remove(path);
  }

  @override
  Future<List<String>> list() async => _store.keys.toList(growable: false);

  @override
  Future<int> usedBytes() async =>
      _store.values.fold<int>(0, (int sum, Uint8List b) => sum + b.length);
}
