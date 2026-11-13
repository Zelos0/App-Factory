export 'connection/stub.dart'
    if (dart.library.io) 'connection/native.dart'
    if (dart.library.js_interop) 'connection/web.dart';
