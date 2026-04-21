import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:planyr/features/marker/domain/marker_symbol.dart';

part 'marker.freezed.dart';
part 'marker.g.dart';

@freezed
abstract class Marker with _$Marker {
  const factory Marker({
    required String id,
    required String taskId,
    required String columnId,
    required String boardId,
    required MarkerSymbol symbol,
    required DateTime updatedAt,
  }) = _Marker;

  factory Marker.fromJson(Map<String, dynamic> json) => _$MarkerFromJson(json);
}
