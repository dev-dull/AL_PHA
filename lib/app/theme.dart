import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alpha/features/marker/domain/marker_symbol.dart';

// ── App theme identifiers ─────────────────────────────────────────
/// Available visual themes. More can be added later
/// (grid paper, lined paper, etc.).
enum AppThemeStyle { bulletJournal }

class AlphaTheme {
  // ── Design token constants ──────────────────────────────────────────

  /// Standard spacing scale (logical pixels).
  static const double spacingXS = 4;
  static const double spacingSM = 8;
  static const double spacingMD = 12;
  static const double spacingLG = 16;
  static const double spacingXL = 24;
  static const double spacingXXL = 32;

  /// Grid cell size in logical pixels.
  static const double cellSize = 48;

  /// App-bar / header row height.
  static const double headerHeight = 44;

  /// Width of the task-name column in the board grid.
  static const double taskColumnWidth = 140;

  // ── Bullet journal palette ────────────────────────────────────────

  /// Warm cream paper background.
  static const paperLight = Color(0xFFF5F0E8);

  /// Slightly darker cream for surface variants.
  static const paperLightVariant = Color(0xFFEDE7DA);

  /// Dark mode paper (warm dark grey).
  static const paperDark = Color(0xFF2C2A26);

  /// Dark mode surface variant.
  static const paperDarkVariant = Color(0xFF38352F);

  /// Dot grid color for the background pattern.
  static const dotGridLight = Color(0xFFD5CCBC);
  static const dotGridDark = Color(0xFF4A453D);

  /// Ink color (pen on paper).
  static const inkLight = Color(0xFF2C2520);
  static const inkDark = Color(0xFFE8E0D4);

  /// Accent — muted teal, like a washi tape highlight.
  static const _accentLight = Color(0xFF5B8A72);
  static const _accentDark = Color(0xFF8FBFA8);

  // ── Theme builders ──────────────────────────────────────────────────

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _accentLight,
      brightness: Brightness.light,
      surface: paperLight,
      onSurface: inkLight,
      surfaceContainerHighest: paperLightVariant,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _accentDark,
      brightness: Brightness.dark,
      surface: paperDark,
      onSurface: inkDark,
      surfaceContainerHighest: paperDarkVariant,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final textTheme = GoogleFonts.caveatTextTheme(
      ThemeData(colorScheme: colorScheme).textTheme,
    ).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.onSurface.withValues(alpha: 0.12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }

  // ── Marker colors (theme-aware) ─────────────────────────────────────
  // Ink-like colors that look handwritten on paper.

  /// Light-theme marker colors — dark ink on cream paper.
  static const _lightMarkerColors = {
    MarkerSymbol.dot: Color(0xFF1A3A5C), // dark navy ink
    MarkerSymbol.slash: Color(0xFF2B5E9E), // blue ink
    MarkerSymbol.x: Color(0xFF2D5A3D), // dark green ink
    MarkerSymbol.migratedForward: Color(0xFFC0392B), // red ink
    MarkerSymbol.doneEarly: Color(0xFF3D7A55), // green ink
    MarkerSymbol.event: Color(0xFF5C3A6E), // purple ink
  };

  /// Dark-theme marker colors — lighter ink on dark paper.
  static const _darkMarkerColors = {
    MarkerSymbol.dot: Color(0xFFA8C4E0), // light blue ink
    MarkerSymbol.slash: Color(0xFF6CA6E0), // light blue ink
    MarkerSymbol.x: Color(0xFF8FC4A0), // light green ink
    MarkerSymbol.migratedForward: Color(0xFFE57373), // light red ink
    MarkerSymbol.doneEarly: Color(0xFF8FC4A0), // light green ink
    MarkerSymbol.event: Color(0xFFC4A0D4), // light purple ink
  };

  /// Returns the correct marker color for the given [symbol] and
  /// screen [brightness].
  static Color markerColor(MarkerSymbol symbol, Brightness brightness) {
    final palette = brightness == Brightness.dark
        ? _darkMarkerColors
        : _lightMarkerColors;
    return palette[symbol]!;
  }
}
