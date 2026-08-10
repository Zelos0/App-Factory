import 'dart:async';

import 'package:flutter/material.dart';

import '../config/registry.dart';
import 'consent_gate.dart';

/// „Werbeeinstellungen ändern" in den Einstellungen. Muss dauerhaft
/// erreichbar sein, auch wenn gerade keine Werbung ausgeliefert wird.
class ConsentTile extends StatelessWidget {
  const ConsentTile({super.key});

  @override
  Widget build(BuildContext context) {
    final ConsentGate gate = Registry.instance.get<ConsentGate>();

    return FutureBuilder<ConsentStatus>(
      future: gate.check(),
      builder: (BuildContext context, AsyncSnapshot<ConsentStatus> snapshot) {
        final ConsentStatus status = snapshot.data ?? ConsentStatus.unknown;
        if (status == ConsentStatus.notRequired) {
          return const SizedBox.shrink();
        }
        return ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Werbeeinstellungen ändern'),
          subtitle: Text(_label(status)),
          onTap: () => unawaited(gate.showForm()),
        );
      },
    );
  }

  static String _label(ConsentStatus s) {
    switch (s) {
      case ConsentStatus.obtained:
        return 'Personalisierte Werbung erlaubt';
      case ConsentStatus.restricted:
        return 'Nur nicht-personalisierte Werbung';
      case ConsentStatus.required:
        return 'Einwilligung ausstehend';
      case ConsentStatus.unknown:
      case ConsentStatus.notRequired:
        return 'Noch nicht abgefragt';
    }
  }
}
