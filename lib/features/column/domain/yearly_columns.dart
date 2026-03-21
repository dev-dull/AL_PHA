import 'package:alpha/features/column/domain/column_type.dart';

/// Fixed yearly columns: Q1 Q2 Q3 Q4 >
const yearlyColumnDefs = [
  (label: 'Q1', position: 0, type: ColumnType.date),
  (label: 'Q2', position: 1, type: ColumnType.date),
  (label: 'Q3', position: 2, type: ColumnType.date),
  (label: 'Q4', position: 3, type: ColumnType.date),
  (label: '>', position: 4, type: ColumnType.custom),
];
