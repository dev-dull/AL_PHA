import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:alpha/features/column/domain/column_type.dart';

part 'board_column.freezed.dart';
part 'board_column.g.dart';

@freezed
abstract class BoardColumn with _$BoardColumn {
  const factory BoardColumn({
    required String id,
    required String boardId,
    required String label,
    required int position,
    @Default(ColumnType.custom) ColumnType type,
  }) = _BoardColumn;

  factory BoardColumn.fromJson(Map<String, dynamic> json) =>
      _$BoardColumnFromJson(json);
}
