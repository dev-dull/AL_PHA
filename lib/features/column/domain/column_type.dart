enum ColumnType {
  date,
  context,
  priority,
  custom;

  String get displayName {
    switch (this) {
      case ColumnType.date:
        return 'Date';
      case ColumnType.context:
        return 'Context';
      case ColumnType.priority:
        return 'Priority';
      case ColumnType.custom:
        return 'Custom';
    }
  }
}
