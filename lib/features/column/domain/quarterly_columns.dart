import 'package:alpha/features/column/domain/column_type.dart';

/// Fixed quarterly columns: M1 M2 M3 >
const quarterlyColumnDefs = [
  (label: 'M1', position: 0, type: ColumnType.date),
  (label: 'M2', position: 1, type: ColumnType.date),
  (label: 'M3', position: 2, type: ColumnType.date),
  (label: '>', position: 3, type: ColumnType.custom),
];
