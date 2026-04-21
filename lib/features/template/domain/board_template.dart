import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:planyr/features/board/domain/board_type.dart';
import 'package:planyr/features/column/domain/column_type.dart';

part 'board_template.freezed.dart';
part 'board_template.g.dart';

@freezed
abstract class BoardTemplate with _$BoardTemplate {
  const factory BoardTemplate({
    required String id,
    required String name,
    required String description,
    required BoardType boardType,
    required List<TemplateColumn> columns,
  }) = _BoardTemplate;

  factory BoardTemplate.fromJson(Map<String, dynamic> json) =>
      _$BoardTemplateFromJson(json);
}

@freezed
abstract class TemplateColumn with _$TemplateColumn {
  const factory TemplateColumn({
    required String label,
    required int position,
    @Default(ColumnType.custom) ColumnType type,
  }) = _TemplateColumn;

  factory TemplateColumn.fromJson(Map<String, dynamic> json) =>
      _$TemplateColumnFromJson(json);
}
