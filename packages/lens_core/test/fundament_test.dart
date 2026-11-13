import 'package:flutter_test/flutter_test.dart';
import 'package:shared_base/shared_base.dart';

/// Der Kamera-Kern ist an dieser Stelle noch leer — `lens-core-build`
/// fuellt ihn in vier Stufen. Dieser Test haelt nur fest, dass die
/// Abhaengigkeit auf `shared_base` steht und ausschliesslich ueber die
/// oeffentliche Tuer `package:shared_base/shared_base.dart` laeuft.
void main() {
  test('lens_core erreicht shared_base ueber die oeffentliche Tuer', () {
    expect(kBrand, isNotEmpty);
    expect(Features.analyticsEnabled, isFalse);
  });
}
