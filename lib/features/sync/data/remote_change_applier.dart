import 'package:drift/drift.dart' hide isNull, isNotNull;

import 'package:planyr/shared/database.dart';

/// Applies remote sync changes (`pull` results) to the local Drift DB.
///
/// Uses **last-write-wins** based on each table's timestamp column:
///   - if no local row exists → `INSERT`
///   - if local row exists and cloud's timestamp is **newer** → `UPDATE`
///   - if local row exists and cloud's timestamp is **older or equal** → skip
///     (the local row has unsynced edits or already matches)
///
/// Tables without a per-row timestamp (`board_columns`, `task_tags`,
/// `series_tags`) are unconditionally overwritten with cloud's value —
/// the cloud is the source of truth for those.
///
/// Earlier this code used `INSERT OR IGNORE`, which silently dropped
/// every cloud-newer update for rows that already existed locally —
/// any field change on one device never propagated to another. This
/// class is the fix.
class RemoteChangeApplier {
  final PlanyrDatabase _db;

  RemoteChangeApplier(this._db);

  /// Server-side fields that don't exist in local SQLite.
  static const _serverOnlyColumns = {'deleted_at', 'user_id'};

  /// Columns whose Postgres value is an ISO timestamp string but
  /// whose Drift counterpart stores epoch-seconds ints.
  static const _timestampColumns = {
    'created_at', 'updated_at', 'completed_at', 'deadline',
    'week_start', 'ended_at',
  };

  /// Mirror of `lambda/sync_push.py:_TIMESTAMP_COL`. The column we
  /// compare on for last-write-wins, per table.
  static const _lwwColumnByTable = {
    'boards': 'updated_at',
    'tasks': 'updated_at',
    'markers': 'updated_at',
    'task_notes': 'updated_at',
    'tags': 'updated_at',
    'recurring_series': 'created_at',
  };

  /// Apply [changes] to the local DB and notify Drift watchers.
  Future<void> apply(List<Map<String, dynamic>> changes) async {
    final touched = <String>{};

    for (final change in changes) {
      final table = change['table'] as String?;
      final data = change['data'] as Map<String, dynamic>?;
      final deleted = change['deleted'] as bool? ?? false;

      if (table == null || data == null) continue;

      if (deleted) {
        await _deleteLocal(table, data);
      } else {
        await _upsertLocal(table, data);
      }
      touched.add(table);
    }

    if (touched.isNotEmpty) {
      _db.notifyUpdates(_updatesFor(touched));
    }
  }

  Future<void> _upsertLocal(
    String table,
    Map<String, dynamic> data,
  ) async {
    final filtered = <String, dynamic>{};
    for (final entry in data.entries) {
      if (_serverOnlyColumns.contains(entry.key)) continue;
      filtered[entry.key] = _toEpochSeconds(entry.key, entry.value);
    }

    final lwwCol = _lwwColumnByTable[table];
    if (lwwCol != null && filtered['id'] != null) {
      // LWW: only update when cloud's timestamp is strictly newer.
      final id = filtered['id'] as String;
      final existing = await _db.customSelect(
        'SELECT $lwwCol AS ts FROM $table WHERE id = ?',
        variables: [Variable(id)],
      ).get();
      if (existing.isNotEmpty) {
        final localTs = existing.first.data['ts'] as int? ?? 0;
        final incomingTs = filtered[lwwCol] as int? ?? 0;
        if (incomingTs <= localTs) return; // local wins or already in sync
        await _updateById(table, id, filtered);
        return;
      }
      // No local row — fall through to insert.
    }

    // For tables without a timestamp (board_columns + junction tables)
    // and for fresh inserts, take cloud's row directly. INSERT OR
    // REPLACE handles both single and composite primary keys.
    await _insertOrReplace(table, filtered);
  }

  Future<void> _insertOrReplace(
    String table,
    Map<String, dynamic> filtered,
  ) async {
    final cols = filtered.keys.toList();
    final vals = filtered.values.toList();
    final placeholders = List.filled(cols.length, '?').join(', ');
    await _db.customStatement(
      'INSERT OR REPLACE INTO $table (${cols.join(', ')}) '
      'VALUES ($placeholders)',
      vals,
    );
  }

  Future<void> _updateById(
    String table,
    String id,
    Map<String, dynamic> filtered,
  ) async {
    final setCols = filtered.keys.where((k) => k != 'id').toList();
    if (setCols.isEmpty) return;
    final setClause = setCols.map((c) => '$c = ?').join(', ');
    final values = [for (final c in setCols) filtered[c], id];
    await _db.customStatement(
      'UPDATE $table SET $setClause WHERE id = ?',
      values,
    );
  }

  Future<void> _deleteLocal(
    String table,
    Map<String, dynamic> data,
  ) async {
    final id = data['id'];
    if (id != null) {
      await _db.customStatement(
        'DELETE FROM $table WHERE id = ?',
        [id],
      );
    } else if (table == 'task_tags') {
      await _db.customStatement(
        'DELETE FROM task_tags WHERE task_id = ? AND tag_id = ?',
        [data['task_id'], data['tag_id']],
      );
    } else if (table == 'series_tags') {
      await _db.customStatement(
        'DELETE FROM series_tags WHERE series_id = ? AND tag_id = ?',
        [data['series_id'], data['tag_id']],
      );
    }
  }

  /// Convert a Postgres ISO timestamp string to epoch seconds for
  /// SQLite storage. Returns the value unchanged if it's already an
  /// int or null.
  static dynamic _toEpochSeconds(String key, dynamic value) {
    if (!_timestampColumns.contains(key)) return value;
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final dt = DateTime.tryParse(value);
      if (dt != null) return dt.millisecondsSinceEpoch ~/ 1000;
    }
    return value;
  }

  /// Map sync table names to Drift [TableUpdate]s so [notifyUpdates]
  /// can wake the right `watch()` Streams (and thus the UI).
  Set<TableUpdate> _updatesFor(Iterable<String> names) {
    final out = <TableUpdate>{};
    for (final name in names) {
      switch (name) {
        case 'boards':
          out.add(TableUpdate.onTable(_db.boards));
        case 'board_columns':
          out.add(TableUpdate.onTable(_db.boardColumns));
        case 'tasks':
          out.add(TableUpdate.onTable(_db.tasks));
        case 'markers':
          out.add(TableUpdate.onTable(_db.markers));
        case 'task_notes':
          out.add(TableUpdate.onTable(_db.taskNotes));
        case 'tags':
          out.add(TableUpdate.onTable(_db.tags));
        case 'recurring_series':
          out.add(TableUpdate.onTable(_db.recurringSeriesTable));
        case 'task_tags':
          out.add(TableUpdate.onTable(_db.taskTags));
        case 'series_tags':
          out.add(TableUpdate.onTable(_db.seriesTags));
      }
    }
    return out;
  }
}
