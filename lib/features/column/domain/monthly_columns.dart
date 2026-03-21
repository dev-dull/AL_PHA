import 'package:alpha/features/column/domain/column_type.dart';

/// Fixed monthly columns: W1 W2 W3 W4 W5 >
const monthlyColumnDefs = [
  (label: 'W1', position: 0, type: ColumnType.date),
  (label: 'W2', position: 1, type: ColumnType.date),
  (label: 'W3', position: 2, type: ColumnType.date),
  (label: 'W4', position: 3, type: ColumnType.date),
  (label: 'W5', position: 4, type: ColumnType.date),
  (label: '>', position: 5, type: ColumnType.custom),
];
