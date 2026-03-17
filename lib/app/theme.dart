import 'package:flutter/material.dart';
import 'package:alpha/features/marker/domain/marker_symbol.dart';

class AlphaTheme {
  static const _seedColor = Color(0xFF4A6FA5);

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

  // ── Theme builders ──────────────────────────────────────────────────

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
      ),
    );
  }

  // ── Marker colors (theme-aware) ─────────────────────────────────────

  /// Light-theme marker colors — WCAG AA on white/light surfaces.
  static const _lightMarkerColors = {
    MarkerSymbol.dot: Color(0xFF1565C0), // blue 800
    MarkerSymbol.slash: Color(0xFFEF6C00), // orange 800
    MarkerSymbol.x: Color(0xFF2E7D32), // green 800
    MarkerSymbol.migratedForward: Color(0xFF546E7A), // blue-grey 600
    MarkerSymbol.doneEarly: Color(0xFF43A047), // green 600
    MarkerSymbol.event: Color(0xFF6A1B9A), // purple 800
  };

  /// Dark-theme marker colors — lighter variants, WCAG AA on dark surfaces.
  static const _darkMarkerColors = {
    MarkerSymbol.dot: Color(0xFF64B5F6), // blue 300
    MarkerSymbol.slash: Color(0xFFFFB74D), // orange 300
    MarkerSymbol.x: Color(0xFF81C784), // green 300
    MarkerSymbol.migratedForward: Color(0xFF90A4AE), // blue-grey 300
    MarkerSymbol.doneEarly: Color(0xFF81C784), // green 300
    MarkerSymbol.event: Color(0xFFCE93D8), // purple 200
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
