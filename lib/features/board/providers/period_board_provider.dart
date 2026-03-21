import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:alpha/features/board/domain/board.dart';
import 'package:alpha/features/board/domain/board_type.dart';
import 'package:alpha/features/column/domain/board_column.dart';
import 'package:alpha/features/column/domain/monthly_columns.dart';
import 'package:alpha/features/column/domain/quarterly_columns.dart';
import 'package:alpha/features/column/domain/yearly_columns.dart';
import 'package:alpha/shared/period_utils.dart';
import 'package:alpha/shared/providers.dart';

part 'period_board_provider.g.dart';

/// Returns the column definitions for a given board type.
List<({String label, int position, dynamic type})> columnDefsForType(
  BoardType type,
) {
  switch (type) {
    case BoardType.monthly:
      return monthlyColumnDefs;
    case BoardType.quarterly:
      return quarterlyColumnDefs;
    case BoardType.yearly:
      return yearlyColumnDefs;
    default:
      throw ArgumentError('No column defs for type: $type');
  }
}

/// Looks up a monthly board by its period start date,
/// creating one (with columns) if none exists.
@riverpod
Future<String> monthlyBoard(
  MonthlyBoardRef ref,
  DateTime monthStart,
) async {
  return _getOrCreatePeriodBoard(ref, BoardType.monthly, monthStart);
}

/// Looks up a quarterly board by its period start date,
/// creating one (with columns) if none exists.
@riverpod
Future<String> quarterlyBoard(
  QuarterlyBoardRef ref,
  DateTime quarterStart,
) async {
  return _getOrCreatePeriodBoard(ref, BoardType.quarterly, quarterStart);
}

/// Looks up a yearly board by its period start date,
/// creating one (with columns) if none exists.
@riverpod
Future<String> yearlyBoard(
  YearlyBoardRef ref,
  DateTime yearStart,
) async {
  return _getOrCreatePeriodBoard(ref, BoardType.yearly, yearStart);
}

Future<String> _getOrCreatePeriodBoard(
  dynamic ref,
  BoardType type,
  DateTime periodStart,
) async {
  final repo = ref.watch(boardRepositoryProvider);
  final existing = await repo.getByPeriodStart(periodStart, type);
  if (existing != null) return existing.id;

  const uuid = Uuid();
  final boardId = uuid.v4();
  final now = DateTime.now();

  await repo.create(
    Board(
      id: boardId,
      name: periodBoardName(type, periodStart),
      type: type,
      weekStart: periodStart,
      createdAt: now,
      updatedAt: now,
    ),
  );

  final colRepo = ref.read(columnRepositoryProvider);
  final colDefs = columnDefsForType(type);
  for (final col in colDefs) {
    await colRepo.create(
      BoardColumn(
        id: uuid.v4(),
        boardId: boardId,
        label: col.label,
        position: col.position,
        type: col.type,
      ),
    );
  }

  return boardId;
}
