import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:alpha/features/board/domain/board.dart';
import 'package:alpha/features/board/domain/board_type.dart';
import 'package:alpha/features/column/domain/board_column.dart';
import 'package:alpha/features/column/domain/weekly_columns.dart';
import 'package:alpha/features/preferences/providers/preferences_providers.dart';
import 'package:alpha/shared/providers.dart';
import 'package:alpha/shared/week_utils.dart';

part 'weekly_board_provider.g.dart';

/// Looks up a weekly board by its week-start date, creating one
/// (with columns) if none exists. Returns the board ID.
@riverpod
Future<String> weeklyBoard(WeeklyBoardRef ref, DateTime weekStart) async {
  final firstDay = ref.watch(preferencesProvider).firstDayOfWeek;
  final repo = ref.watch(boardRepositoryProvider);
  final existing = await repo.getByWeekStart(weekStart);
  if (existing != null) return existing.id;

  // Auto-create board + columns.
  const uuid = Uuid();
  final boardId = uuid.v4();
  final now = DateTime.now().toUtc();

  await repo.create(
    Board(
      id: boardId,
      name: weekBoardName(weekStart),
      type: BoardType.weekly,
      weekStart: weekStart,
      createdAt: now,
      updatedAt: now,
    ),
  );

  final colRepo = ref.read(columnRepositoryProvider);
  for (final col in weeklyColumnDefs(firstDay: firstDay)) {
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
