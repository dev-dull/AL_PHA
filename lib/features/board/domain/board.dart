import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:planyr/features/board/domain/board_type.dart';

part 'board.freezed.dart';
part 'board.g.dart';

@freezed
abstract class Board with _$Board {
  const factory Board({
    required String id,
    required String name,
    required BoardType type,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool archived,
    DateTime? weekStart,
  }) = _Board;

  factory Board.fromJson(Map<String, dynamic> json) => _$BoardFromJson(json);
}
