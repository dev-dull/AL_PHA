import 'dart:ui';

/// Curated palette of 12 colors for tags.
/// Muted, ink-on-paper tones matching the bullet journal aesthetic.
class TagPalette {
  TagPalette._();

  static const colors = <({int value, String name})>[
    (value: 0xFFC0392B, name: 'Red'),
    (value: 0xFF2B5E9E, name: 'Blue'),
    (value: 0xFF2D5A3D, name: 'Green'),
    (value: 0xFF5C3A6E, name: 'Purple'),
    (value: 0xFFD4A03C, name: 'Mustard'),
    (value: 0xFFCF7A5A, name: 'Terracotta'),
    (value: 0xFFB5838D, name: 'Dusty Rose'),
    (value: 0xFF5B8A72, name: 'Sage'),
    (value: 0xFF4A7C9B, name: 'Slate Blue'),
    (value: 0xFF8B6F47, name: 'Sienna'),
    (value: 0xFF7B8FA1, name: 'Steel'),
    (value: 0xFF9B7CB8, name: 'Lavender'),
  ];

  static Color colorFromValue(int value) => Color(value);
}
