import 'package:flutter_test/flutter_test.dart';
import 'package:shared_base/shared_base.dart';

void main() {
  final DateTime at = DateTime(2026, 3, 7);

  test('Name trägt Datum und Endung', () {
    expect(exportName('vox', 'md', at: at), 'vox-2026-03-07.md');
  });

  test('Umlaute und Sonderzeichen werden dateisystemfest', () {
    expect(
      exportName('Vox Fluchttür / Größe', 'zip', at: at),
      'vox-fluchttuer-groesse-2026-03-07.zip',
    );
  });

  test('Leerer Stamm fällt auf „export" zurück', () {
    expect(exportName('—', 'json', at: at), 'export-2026-03-07.json');
  });
}
