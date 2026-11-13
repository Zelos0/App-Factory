import 'package:flutter/foundation.dart';

import '../config/brand.dart';
import '../config/registry.dart';
import 'file_vault.dart';
import 'indexed_db_vault.dart';
import 'native_vault.dart';

/// Einzige Stelle, an der die Ablage gewählt wird.
void registerFileVault() {
  if (kIsWeb) {
    Registry.instance.bind<FileVault>(IndexedDbVault(prefix: kFlavor));
  } else {
    Registry.instance.bind<FileVault>(NativeVault(folder: kFlavor));
  }
}
