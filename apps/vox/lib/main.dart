import 'package:flutter/material.dart';
import 'package:shared_base/shared_base.dart';

/// Gerüst. Beweist an Tag 1, dass die Kette Push -> Build -> Deploy -> iPhone
/// steht. `app-derive` ersetzt Startbildschirm, Theme und Interpreter.
void main() {
  runApp(const VoxApp());
}

class VoxApp extends StatelessWidget {
  const VoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Liest den Flavor aus brand.dart — beweist an Tag 1 zugleich, dass
      // --dart-define=FLAVOR durch den ganzen Build durchkommt.
      title: kFlavor,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: const ScaffoldShell(),
    );
  }
}

class ScaffoldShell extends StatelessWidget {
  const ScaffoldShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(kFlavor)),
      body: Column(
        children: <Widget>[
          const Expanded(
            child: Center(child: Text('Noch nichts aufgenommen.')),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.mic_rounded),
                label: const Text('Aufnehmen'),
              ),
            ),
          ),
          // Reservierte Bannerfläche. monetize-modul ersetzt sie durch
          // AdSafeArea; die Höhe bleibt dieselbe.
          const SizedBox(height: 64),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}
