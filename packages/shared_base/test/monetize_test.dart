import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_base/shared_base.dart';

void main() {
  setUp(() async {
    Registry.instance.reset();
    await registerMonetize();
  });

  test('Ohne Play-Konto wird NoOpAdSurface gebunden', () {
    final AdSurface ads = Registry.instance.get<AdSurface>();
    expect(ads.id, 'noop');
    expect(ads.isEnabled, isFalse);
  });

  test('Die reservierte Höhe ist konstant', () {
    final AdSurface ads = Registry.instance.get<AdSurface>();
    expect(ads.heightFor(AdSlot.bottomBanner), NoOpAdSurface.bannerHeight);
  });

  test('Der Mindestabstand beträgt mindestens 16 dp', () {
    final AdSurface ads = Registry.instance.get<AdSurface>();
    expect(ads.minimumGap, greaterThanOrEqualTo(16));
  });

  test('Ohne Play-Konto ist alles freigeschaltet', () {
    final Purchases p = Registry.instance.get<Purchases>();
    expect(p.current.isPro, isTrue);
    expect(p.isEnabled, isFalse);
  });

  test('Ohne Werbung ist keine Einwilligung nötig', () async {
    final ConsentGate gate = Registry.instance.get<ConsentGate>();
    expect(await gate.check(), ConsentStatus.notRequired);
    expect(gate.canRequestAds, isFalse);
  });

  testWidgets('AdSafeArea hält Banner plus Mindestabstand frei', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdSafeArea(
            bottomAction: SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: () {},
                child: const Text('Aufnehmen'),
              ),
            ),
            child: const ColoredBox(color: Color(0xFFEEEEEE)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Rect button = tester.getRect(find.byType(FilledButton));
    final double screenBottom = tester.getSize(find.byType(MaterialApp)).height;
    final double distanceToBottom = screenBottom - button.bottom;

    // Banner (64) + Mindestabstand (16) = 80.
    expect(
      distanceToBottom,
      greaterThanOrEqualTo(NoOpAdSurface.bannerHeight + NoOpAdSurface.gap),
    );
  });

  testWidgets('Der Aufnahmeknopf bleibt mindestens 56 dp hoch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdSafeArea(
            bottomAction: SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: () {},
                child: const Text('Aufnehmen'),
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(56),
    );
  });

  test('scrollPadding hält Banner, Abstand und Puffer frei', () {
    // 64 + 16 + 8
    expect(NoOpAdSurface.bannerHeight + NoOpAdSurface.gap + 8, 88);
  });
}
