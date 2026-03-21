enum BoardType {
  daily,
  weekly,
  monthly,
  yearly,
  custom;

  String get displayName {
    switch (this) {
      case BoardType.daily:
        return 'Daily';
      case BoardType.weekly:
        return 'Weekly';
      case BoardType.monthly:
        return 'Monthly';
      case BoardType.yearly:
        return 'Yearly';
      case BoardType.custom:
        return 'Custom';
    }
  }
}
