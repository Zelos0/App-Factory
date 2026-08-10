import 'package:flutter/material.dart';
import 'package:shared_base/shared_base.dart';

/// Gerüst. Beweist an Tag 1, dass die Kette Push -> Build -> Deploy -> iPhone
/// steht. `app-derive` ersetzt Startbildschirm, Theme und Interpreter.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Bindet AdSurface, Purchases und ConsentGate. Muss vor runApp laufen —
  // AdSafeArea liest die Bindung im ersten build().
  await registerMonetize();
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
      // const, weil kFlavor eine Konstante ist. Ohne const meldet
      // prefer_const_constructors einen Hinweis, und --fatal-infos in
      // `melos run analyze` macht daraus einen Baustopp.
      appBar: AppBar(title: const Text(kFlavor)),
      // AdSafeArea hat an Tag 3 den festen SizedBox(height: 64) abgeloest.
      // Gleiche Hoehe, gleicher Abstand — das Layout aendert sich nicht.
      body: AdSafeArea(
        // Kein unterer Innenabstand — den liefert AdSafeArea. Waere er hier
        // noch einmal gesetzt, staenden 32 dp statt der geforderten 16.
        bottomAction: Padding(
          padding: const EdgeInsets.fromLTRB(Tokens.m, Tokens.s, Tokens.m, 0),
          child: SizedBox(
            height: Tokens.primaryActionHeight,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Aufnehmen'),
            ),
          ),
        ),
        child: const Center(child: Text('Noch nichts aufgenommen.')),
      ),
    );
  }
}
