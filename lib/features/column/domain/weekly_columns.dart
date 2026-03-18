import 'package:alpha/features/column/domain/column_type.dart';

/// The fixed weekly columns: M T W T F S S >
const weeklyColumnDefs = [
  (label: 'M', position: 0, type: ColumnType.date),
  (label: 'T', position: 1, type: ColumnType.date),
  (label: 'W', position: 2, type: ColumnType.date),
  (label: 'T', position: 3, type: ColumnType.date),
  (label: 'F', position: 4, type: ColumnType.date),
  (label: 'S', position: 5, type: ColumnType.date),
  (label: 'S', position: 6, type: ColumnType.date),
  (label: '>', position: 7, type: ColumnType.custom),
];
