// Eine Datei aus der App hinausgeben — der letzte Meter jedes Exports.
//
// Browser: Auf dem Telefon öffnet sich das Teilen-Menü des Systems
//          (In Dateien sichern, AirDrop, Notizen, Mail …), am Rechner ein
//          normaler Download. Klappt das Teilen nicht, wird heruntergeladen.
// Gerät:   Teilen-Menü von Android bzw. iOS.
//
// Apps rufen nur shareFile(); welcher Weg greift, entscheidet der Build.
export 'file_share/outcome.dart';
export 'file_share/stub.dart'
    if (dart.library.io) 'file_share/native.dart'
    if (dart.library.js_interop) 'file_share/web.dart';
