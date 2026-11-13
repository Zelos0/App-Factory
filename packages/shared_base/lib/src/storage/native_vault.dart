import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'file_vault.dart';

/// Dateisystem auf Android und iOS.
class NativeVault implements FileVault {
  NativeVault({required this.folder});

  /// Unterverzeichnis im App-Dokumentenordner, üblicherweise der Flavor.
  final String folder;

  static const Uuid _uuid = Uuid();

  @override
  String get id => 'native';

  Future<Directory> _root() async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(base.path, folder, 'media'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  Future<String> put(Uint8List bytes, {required String extension}) async {
    final Directory dir = await _root();
    final File file = File(p.join(dir.path, '${_uuid.v4()}.$extension'));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  @override
  Future<Uint8List?> get(String path) async {
    final File f = File(path);
    return f.existsSync() ? f.readAsBytes() : null;
  }

  @override
  Future<bool> exists(String path) async => File(path).existsSync();

  @override
  Future<void> delete(String path) async {
    final File f = File(path);
    if (f.existsSync()) {
      await f.delete();
    }
  }

  @override
  Future<List<String>> list() async {
    final Directory dir = await _root();
    return dir
        .listSync()
        .whereType<File>()
        .map((File f) => f.path)
        .toList(growable: false);
  }

  @override
  Future<int> usedBytes() async {
    final Directory dir = await _root();
    return dir
        .listSync()
        .whereType<File>()
        .fold<int>(0, (int sum, File f) => sum + f.lengthSync());
  }
}
