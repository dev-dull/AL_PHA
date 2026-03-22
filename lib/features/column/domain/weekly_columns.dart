import 'package:alpha/features/column/domain/column_type.dart';

/// Day labels starting from Monday.
const _mondayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// Day labels starting from Sunday.
const _sundayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

/// Returns the fixed weekly column definitions for the given
/// [firstDay] (1 = Monday, 7 = Sunday).
List<({String label, int position, ColumnType type})> weeklyColumnDefs({
  int firstDay = DateTime.monday,
}) {
  final labels =
      firstDay == DateTime.sunday ? _sundayLabels : _mondayLabels;
  return [
    for (var i = 0; i < 7; i++)
      (label: labels[i], position: i, type: ColumnType.date),
    (label: '>', position: 7, type: ColumnType.custom),
  ];
}
