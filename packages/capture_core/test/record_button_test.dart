import 'package:capture_core/capture_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Aufnahmeknopf ist mindestens 56 dp hoch', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecordButton(
            state: RecordingState.idle,
            onStart: () {},
            onStop: () {},
          ),
        ),
      ),
    );
    // byType prueft den exakten Laufzeittyp. FilledButton.icon erzeugt die
    // private Unterklasse _FilledButtonWithIcon, die byType(FilledButton)
    // deshalb NICHT findet — der Test schluege mit "Bad state: No element"
    // fehl, ohne dass am Knopf etwas falsch waere.
    final Finder button =
        find.byWidgetPredicate((Widget w) => w is FilledButton);
    expect(button, findsOneWidget);
    expect(
      t.getSize(button).height,
      greaterThanOrEqualTo(RecordButton.minHeight),
    );
  });

  testWidgets('Unterer Abstand zur Bannerfläche beträgt mindestens 16 dp', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecordButton(
            state: RecordingState.idle,
            onStart: () {},
            onStop: () {},
          ),
        ),
      ),
    );
    final Padding padding = t.widget<Padding>(
      find
          .ancestor(
            of: find.byType(SizedBox),
            matching: find.byType(Padding),
          )
          .first,
    );
    expect(
      (padding.padding as EdgeInsets).bottom,
      greaterThanOrEqualTo(RecordButton.bannerGap),
    );
  });

  testWidgets('In AdSafeArea entfaellt der eigene untere Abstand', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecordButton(
            state: RecordingState.idle,
            onStart: () {},
            onStop: () {},
            insideAdSafeArea: true,
          ),
        ),
      ),
    );
    final Padding padding = t.widget<Padding>(
      find
          .ancestor(
            of: find.byType(SizedBox),
            matching: find.byType(Padding),
          )
          .first,
    );
    // Sonst stuenden 16 dp aus AdSafeArea plus 16 dp von hier — 32 statt 16.
    expect((padding.padding as EdgeInsets).bottom, 0);
  });
}
