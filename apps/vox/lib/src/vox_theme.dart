import 'package:flutter/material.dart';

/// Vier Farben, zwei Schriften. Mehr gehört keiner App.
/// ARCHITEKTUR.md Abschnitt 8, Bauplan Abschnitt 7.
///
/// Bernstein ist Primär, weil der Aufnahme-Knopf der einzige farbige Punkt
/// auf dem Startbildschirm ist. Graphit ist Akzent und Textfarbe zugleich.
class VoxTheme {
  const VoxTheme._();

  /// Bernstein — der Aufnahmeknopf.
  static const Color primary = Color(0xFFD97706);

  /// Stein — Datumszeilen, Beschriftungen, alles Zweitrangige.
  static const Color secondary = Color(0xFF78716C);

  /// Papier — die Fläche.
  static const Color surface = Color(0xFFF5F2ED);

  /// Graphit — Text und Akzent.
  static const Color accent = Color(0xFF1C1917);

  static const String headlineFamily = 'Serif';
  static const String bodyFamily = 'Roboto';

  /// Zeilenabstand für Transkripte. Steht im Steckbrief, nicht im Ermessen.
  static const double transcriptHeight = 1.6;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      tertiary: accent,
      surface: isLight ? surface : const Color(0xFF14120F),
      onSurface: isLight ? accent : const Color(0xFFEDE9E3),
    );

    final TextTheme base = isLight
        ? Typography.material2021().black
        : Typography.material2021().white;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      // Papier und Tinte: keine Trennlinien, keine Rahmen um die Zeilen.
      dividerTheme: const DividerThemeData(color: Colors.transparent),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      textTheme: base.copyWith(
        displayLarge: base.displayLarge?.copyWith(fontFamily: headlineFamily),
        displayMedium: base.displayMedium?.copyWith(fontFamily: headlineFamily),
        displaySmall: base.displaySmall?.copyWith(fontFamily: headlineFamily),
        headlineLarge: base.headlineLarge?.copyWith(fontFamily: headlineFamily),
        headlineMedium:
            base.headlineMedium?.copyWith(fontFamily: headlineFamily),
        headlineSmall: base.headlineSmall?.copyWith(fontFamily: headlineFamily),
        titleLarge: base.titleLarge?.copyWith(fontFamily: headlineFamily),
        titleMedium: base.titleMedium?.copyWith(fontFamily: headlineFamily),
        bodyLarge: base.bodyLarge?.copyWith(
          fontFamily: bodyFamily,
          height: transcriptHeight,
        ),
        bodyMedium: base.bodyMedium?.copyWith(fontFamily: bodyFamily),
        labelLarge: base.labelLarge?.copyWith(fontFamily: bodyFamily),
        labelMedium: base.labelMedium?.copyWith(fontFamily: bodyFamily),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // Primäraktion mindestens 56 dp — ARCHITEKTUR.md Abschnitt 8.
          minimumSize: const Size.fromHeight(56),
        ),
      ),
    );
  }
}
