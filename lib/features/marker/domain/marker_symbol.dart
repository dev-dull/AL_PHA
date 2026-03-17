enum MarkerSymbol {
  dot,
  circle,
  x,
  star,
  tilde,
  migrated;

  String get displayChar {
    switch (this) {
      case MarkerSymbol.dot:
        return '•';
      case MarkerSymbol.circle:
        return '○';
      case MarkerSymbol.x:
        return '✕';
      case MarkerSymbol.star:
        return '★';
      case MarkerSymbol.tilde:
        return '~';
      case MarkerSymbol.migrated:
        return '>';
    }
  }

  String get displayName {
    switch (this) {
      case MarkerSymbol.dot:
        return 'Dot';
      case MarkerSymbol.circle:
        return 'Circle';
      case MarkerSymbol.x:
        return 'X';
      case MarkerSymbol.star:
        return 'Star';
      case MarkerSymbol.tilde:
        return 'Tilde';
      case MarkerSymbol.migrated:
        return 'Migrated';
    }
  }

  /// Returns the next symbol in the tap cycle, or null for empty.
  /// Cycle: empty → dot → circle → x → empty
  MarkerSymbol? get nextInCycle {
    switch (this) {
      case MarkerSymbol.dot:
        return MarkerSymbol.circle;
      case MarkerSymbol.circle:
        return MarkerSymbol.x;
      case MarkerSymbol.x:
        return null; // back to empty
      case MarkerSymbol.star:
      case MarkerSymbol.tilde:
      case MarkerSymbol.migrated:
        return null; // special symbols exit to empty
    }
  }

  /// The first symbol when tapping an empty cell.
  static MarkerSymbol get cycleStart => MarkerSymbol.dot;
}
