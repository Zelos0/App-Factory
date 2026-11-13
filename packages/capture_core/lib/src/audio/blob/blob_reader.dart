// Liest eine Blob-Adresse (blob:https://…) des Browsers als Bytes.
// Außerhalb des Browsers gibt es keine Blob-Adressen.
export 'blob_reader_stub.dart'
    if (dart.library.js_interop) 'blob_reader_web.dart';
