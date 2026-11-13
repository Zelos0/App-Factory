// Speicherschicht unter IndexedDbVault. Im Browser IndexedDB, sonst
// Arbeitsspeicher — so bleibt die Ablage in VM-Tests prüfbar.
export 'idb_backend_base.dart';
export 'idb_backend_memory.dart'
    if (dart.library.js_interop) 'idb_backend_web.dart';
