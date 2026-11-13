import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'idb_backend_base.dart';

IdbBackend openIdbBackend(String dbName) => _WebIdbBackend(dbName);

/// IndexedDB über package:web. Eine Datenbank je App, ein Objektspeicher
/// `files`, Schlüssel = Vault-Pfad, Wert = Uint8Array.
///
/// Lässt sich IndexedDB nicht öffnen (privates Fenster in alten Safari-
/// Versionen, gesperrte Website-Daten), läuft alles im Arbeitsspeicher
/// weiter. Eine Aufnahme scheitert nie an der Ablage.
class _WebIdbBackend implements IdbBackend {
  _WebIdbBackend(this._name);

  static const String _store = 'files';

  final String _name;
  final MemoryIdbBackend _fallback = MemoryIdbBackend();
  Future<web.IDBDatabase?>? _db;

  Future<web.IDBDatabase?> _open() => _db ??= () async {
        try {
          final web.IDBOpenDBRequest req = web.window.indexedDB.open(_name, 1);
          req.onupgradeneeded = ((web.Event _) {
            final web.IDBDatabase db = req.result! as web.IDBDatabase;
            if (!db.objectStoreNames.contains(_store)) {
              db.createObjectStore(_store);
            }
          }).toJS;
          return await _done<web.IDBDatabase>(req);
        } on Object {
          return null;
        }
      }();

  Future<web.IDBObjectStore?> _tx(String mode) async {
    final web.IDBDatabase? db = await _open();
    return db?.transaction(_store.toJS, mode).objectStore(_store);
  }

  @override
  Future<bool> get isPersistent async => await _open() != null;

  @override
  Future<void> put(String key, Uint8List bytes) async {
    final web.IDBObjectStore? s = await _tx('readwrite');
    if (s == null) {
      return _fallback.put(key, bytes);
    }
    await _done<JSAny?>(s.put(bytes.toJS, key.toJS));
  }

  @override
  Future<Uint8List?> get(String key) async {
    final web.IDBObjectStore? s = await _tx('readonly');
    if (s == null) {
      return _fallback.get(key);
    }
    final JSAny? v = await _done<JSAny?>(s.get(key.toJS));
    if (v == null || v.isUndefinedOrNull) {
      return null;
    }
    return (v as JSUint8Array).toDart;
  }

  @override
  Future<void> delete(String key) async {
    final web.IDBObjectStore? s = await _tx('readwrite');
    if (s == null) {
      return _fallback.delete(key);
    }
    await _done<JSAny?>(s.delete(key.toJS));
  }

  @override
  Future<List<String>> keys() async {
    final web.IDBObjectStore? s = await _tx('readonly');
    if (s == null) {
      return _fallback.keys();
    }
    final JSArray<JSAny?> all = await _done<JSArray<JSAny?>>(s.getAllKeys());
    return all.toDart
        .whereType<JSString>()
        .map((JSString k) => k.toDart)
        .toList();
  }

  /// Wartet auf das Ergebnis einer IndexedDB-Anfrage.
  static Future<T> _done<T extends JSAny?>(web.IDBRequest req) {
    final Completer<T> c = Completer<T>();
    req.onsuccess = ((web.Event _) => c.complete(req.result as T)).toJS;
    req.onerror = ((web.Event _) => c.completeError(
          StateError('IndexedDB: ${req.error?.message ?? 'unbekannt'}'),
        )).toJS;
    return c.future;
  }
}
