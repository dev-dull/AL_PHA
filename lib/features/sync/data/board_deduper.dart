import 'dart:developer' as dev;

import 'package:drift/drift.dart' hide isNull, isNotNull;

import 'package:planyr/features/sync/data/change_tracker.dart';
import 'package:planyr/features/sync/data/tombstone_repository.dart';
import 'package:planyr/shared/database.dart';

/// Merges weekly boards that share a (week_start, type=weekly) into
/// a single canonical board.
///
/// Two devices launching offline can each create a new weekly board
/// for the current week with different UUIDs. After they sync, both
/// boards land in each other's local DB. This class consolidates them
/// onto a single canonical board so the user sees one set of tasks
/// per week instead of an empty placeholder next to a real one.
///
/// The canonical is the row with the oldest [createdAt] (ties broken
/// lexicographically by id). Both devices applying the same rule
/// converge on the same canonical regardless of pull order.
class BoardDeduper {
  final PlanyrDatabase _db;
  final TombstoneRepository? _tombstones;

  BoardDeduper(this._db, [this._tombstones]);

  /// Run the dedupe pass and return the list of board deletions that
  /// should be pushed so other devices also drop the duplicates.
  Future<List<SyncChange>> dedupeWeeklyBoards() async {
    final deletes = <SyncChange>[];
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final nowEpoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

    final groups = await _db.customSelect(
      'SELECT week_start FROM boards '
      'WHERE type = ? AND archived = 0 '
      'AND week_start IS NOT NULL '
      'GROUP BY week_start HAVING COUNT(*) > 1',
      variables: [const Variable('weekly')],
    ).get();

    for (final g in groups) {
      final weekStart = g.read<int>('week_start');
      final boardRows = await _db.customSelect(
        'SELECT id FROM boards '
        'WHERE type = ? AND archived = 0 AND week_start = ? '
        'ORDER BY created_at ASC, id ASC',
        variables: [const Variable('weekly'), Variable(weekStart)],
      ).get();
      if (boardRows.length < 2) continue;

      final canonicalId = boardRows.first.read<String>('id');
      final dupIds =
          boardRows.skip(1).map((r) => r.read<String>('id')).toList();

      for (final dupId in dupIds) {
        // Safety gate (#62): only auto-merge if the duplicate is
        // empty of user data. The legit case this code exists for —
        // two devices each created an empty board for the same
        // week while offline — always satisfies this. A duplicate
        // that DOES have its own tasks/markers means something
        // unusual: a buggy migration mangling week_starts, a
        // deliberate-but-confusing user action, an old sync
        // recovery artifact. Auto-merging in that case re-FKs
        // user data across boards silently, which is exactly what
        // bit us on 2026-05-03. Log loudly and let the user
        // reconcile via the UI.
        if (await _boardHasUserData(dupId)) {
          dev.log(
            'BoardDeduper: skipping merge of $dupId into '
            '$canonicalId — duplicate has its own tasks/markers, '
            'manual reconciliation required',
            name: 'BoardDeduper',
          );
          continue;
        }
        await _mergeBoardLocal(dupId, canonicalId, nowEpoch);
        deletes.add(SyncChange(
          table: 'boards',
          id: dupId,
          data: {'id': dupId},
          updatedAt: nowIso,
          deleted: true,
        ));
      }
    }

    if (deletes.isNotEmpty) {
      // customStatement bypasses Drift's change tracker — wake the
      // watching Streams so the UI rebuilds without a navigation.
      _db.notifyUpdates({
        TableUpdate.onTable(_db.boards),
        TableUpdate.onTable(_db.boardColumns),
        TableUpdate.onTable(_db.tasks),
        TableUpdate.onTable(_db.markers),
      });
    }

    return deletes;
  }

  /// Returns true if [boardId] has any live tasks or markers of
  /// its own. Auto-generated `board_columns` don't count — every
  /// new weekly board gets 8 of them at creation time, so requiring
  /// "zero columns" would block every legit merge. User data is
  /// what we're trying not to silently re-FK.
  Future<bool> _boardHasUserData(String boardId) async {
    final tasks = await _db.customSelect(
      'SELECT 1 FROM tasks WHERE board_id = ? LIMIT 1',
      variables: [Variable(boardId)],
    ).get();
    if (tasks.isNotEmpty) return true;
    final markers = await _db.customSelect(
      'SELECT 1 FROM markers WHERE board_id = ? LIMIT 1',
      variables: [Variable(boardId)],
    ).get();
    return markers.isNotEmpty;
  }

  /// Re-FKs a duplicate board's tasks and markers onto the canonical
  /// board, then hard-deletes the duplicate's columns and the board
  /// row itself locally.
  ///
  /// Caller must have verified via [_boardHasUserData] that the
  /// duplicate is empty (#62). This method still contains the
  /// re-FK logic for tasks/markers from the legacy era when the
  /// safety gate wasn't there — it's harmless on an empty board
  /// (the UPDATE/DELETE statements just affect zero rows) and is
  /// kept defensively in case a future caller wants to merge a
  /// non-empty duplicate after explicit user confirmation.
  Future<void> _mergeBoardLocal(
    String fromId,
    String toId,
    int nowEpoch,
  ) async {
    // position → column_id on the canonical board
    final toCols = await _db.customSelect(
      'SELECT id, position FROM board_columns WHERE board_id = ?',
      variables: [Variable(toId)],
    ).get();
    final toColByPos = <int, String>{
      for (final c in toCols)
        c.read<int>('position'): c.read<String>('id'),
    };

    final fromCols = await _db.customSelect(
      'SELECT id, position FROM board_columns WHERE board_id = ?',
      variables: [Variable(fromId)],
    ).get();

    // Re-FK markers per column.
    for (final fc in fromCols) {
      final pos = fc.read<int>('position');
      final fromColId = fc.read<String>('id');
      final toColId = toColByPos[pos];
      if (toColId == null) continue;

      // Drop any markers on the canonical that would conflict with
      // the (task_id, column_id) unique constraint after the move.
      // The duplicate's marker is preferred — it's typically the
      // newer write that came from a still-active device.
      await _db.customStatement(
        'DELETE FROM markers WHERE column_id = ? AND task_id IN ('
        ' SELECT task_id FROM markers WHERE column_id = ?)',
        [toColId, fromColId],
      );
      await _db.customStatement(
        'UPDATE markers SET board_id = ?, column_id = ?, '
        'updated_at = ? WHERE column_id = ?',
        [toId, toColId, nowEpoch, fromColId],
      );
    }

    // Re-FK tasks. Bumping updated_at means the next push propagates
    // the new board_id assignment.
    await _db.customStatement(
      'UPDATE tasks SET board_id = ?, updated_at = ? WHERE board_id = ?',
      [toId, nowEpoch, fromId],
    );

    // Tombstone every duplicate column before hard-deleting them
    // locally — without this they'd live forever on the cloud as
    // orphans pointing at a deleted board (issue #41). The board
    // itself gets a tombstone via the SyncChange returned from
    // [dedupeWeeklyBoards].
    final tombs = _tombstones;
    if (tombs != null) {
      for (final fc in fromCols) {
        await tombs.record('board_columns', fc.read<String>('id'));
      }
    }

    // Drop the duplicate's columns (no markers reference them now).
    await _db.customStatement(
      'DELETE FROM board_columns WHERE board_id = ?',
      [fromId],
    );

    // Drop the duplicate board itself.
    await _db.customStatement(
      'DELETE FROM boards WHERE id = ?',
      [fromId],
    );
  }
}
