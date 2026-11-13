import 'dart:typed_data';

/// Schlüssel-Wert-Speicher für Bytes.
abstract interface class IdbBackend {
  Future<void> put(String key, Uint8List bytes);
  Future<Uint8List?> get(String key);
  Future<void> delete(String key);
  Future<List<String>> keys();

  /// True, wenn die Daten ein Neuladen überleben.
  Future<bool> get isPersistent;
}

/// Flüchtiger Speicher. Rückfall, wenn IndexedDB fehlt, und VM-Tests.
class MemoryIdbBackend implements IdbBackend {
  final Map<String, Uint8List> _m = <String, Uint8List>{};

  @override
  Future<void> put(String key, Uint8List bytes) async => _m[key] = bytes;

  @override
  Future<Uint8List?> get(String key) async => _m[key];

  @override
  Future<void> delete(String key) async => _m.remove(key);

  @override
  Future<List<String>> keys() async => _m.keys.toList();

  @override
  Future<bool> get isPersistent async => false;
}
