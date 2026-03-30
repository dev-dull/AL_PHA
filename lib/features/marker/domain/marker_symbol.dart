enum MarkerSymbol {
  dot,
  slash,
  x,
  migratedForward,
  doneEarly,
  event;

  String get displayChar {
    switch (this) {
      case MarkerSymbol.dot:
        return '•';
      case MarkerSymbol.slash:
        return '/';
      case MarkerSymbol.x:
        return '✓';
      case MarkerSymbol.migratedForward:
        return '>';
      case MarkerSymbol.doneEarly:
        return '<';
      case MarkerSymbol.event:
        return '○';
    }
  }

  String get displayName {
    switch (this) {
      case MarkerSymbol.dot:
        return 'Scheduled';
      case MarkerSymbol.slash:
        return 'In Progress';
      case MarkerSymbol.x:
        return 'Done';
      case MarkerSymbol.migratedForward:
        return 'Migrated';
      case MarkerSymbol.doneEarly:
        return 'Done Early';
      case MarkerSymbol.event:
        return 'Event';
    }
  }

  /// Returns the next symbol in the tap cycle, or null for empty.
  /// Cycle: empty → dot → slash → x → empty
  MarkerSymbol? get nextInCycle {
    switch (this) {
      case MarkerSymbol.dot:
        return MarkerSymbol.slash;
      case MarkerSymbol.slash:
        return MarkerSymbol.x;
      case MarkerSymbol.x:
        return null; // back to empty
      case MarkerSymbol.migratedForward:
      case MarkerSymbol.doneEarly:
      case MarkerSymbol.event:
        return null; // special symbols exit to empty
    }
  }

  /// The first symbol when tapping an empty cell.
  static MarkerSymbol get cycleStart => MarkerSymbol.dot;

  /// Whether this is a "scheduled" marker (dot or event) that
  /// should be migrated when the day passes.
  bool get isScheduled =>
      this == MarkerSymbol.dot || this == MarkerSymbol.event;

  /// Returns the default marker symbol for a task based on
  /// whether it's an event.
  static MarkerSymbol defaultFor({required bool isEvent}) =>
      isEvent ? MarkerSymbol.event : MarkerSymbol.dot;
}
