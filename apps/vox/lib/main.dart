import 'package:capture_core/capture_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_base/shared_base.dart';

import 'src/home_screen.dart';
import 'src/vox_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Reihenfolge: erst alle Schnittstellen binden, dann Oberfläche starten.
  // Keine dieser Zeilen liest einen Schalter — das tun ausschließlich die
  // register*-Funktionen selbst. ARCHITEKTUR.md Abschnitt 5.
  registerFileVault();
  await registerSttEngine();
  await registerMonetize();

  final AppDatabase db = AppDatabase(openConnection(kFlavor));
  final EntryStore store = EntryStore(db, type: kFlavor);

  runApp(VoxApp(store: store));
}

class VoxApp extends StatelessWidget {
  const VoxApp({required this.store, super.key});

  final EntryStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vox',
      theme: VoxTheme.light(),
      darkTheme: VoxTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: HomeScreen(store: store),
    );
  }
}
