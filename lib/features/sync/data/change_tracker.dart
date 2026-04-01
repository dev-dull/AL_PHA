import 'package:drift/drift.dart';
import 'package:alpha/shared/database.dart';

/// A single change to push to the server.
class SyncChange {
  final String table;
  final String id;
  final Map<String, dynamic> data;
  final String updatedAt;
  final bool deleted;

  SyncChange({
    required this.table,
    required this.id,
    required this.data,
    required this.updatedAt,
    this.deleted = false,
  });

  Map<String, dynamic> toJson() => {
        'table': table,
        'id': id,
        'data': data,
        'updated_at': updatedAt,
        'deleted': deleted,
      };
}

/// Scans local tables for rows modified since the last sync.
/// Data is small (<10MB) so a full scan takes milliseconds.
class ChangeTracker {
  final AlphaDatabase _db;

  ChangeTracker(this._db);

  /// Collect all changes since the last sync time.
  /// Returns them in dependency order for the server.
  Future<List<SyncChange>> getChangesSince(DateTime? since) async {
    final changes = <SyncChange>[];
    // Drift stores DateTime as epoch seconds in SQLite.
    final sinceEpoch = (since?.millisecondsSinceEpoch ?? 0) ~/ 1000;

    // Tags first (no FK dependencies).
    changes.addAll(await _queryTable(
      tableName: 'tags',
      timestampColumn: 'created_at',
      sinceEpoch: sinceEpoch,
      columns: ['id', 'name', 'color', 'position', 'created_at'],
    ));

    // Boards.
    changes.addAll(await _queryTable(
      tableName: 'boards',
      timestampColumn: 'updated_at',
      sinceEpoch: sinceEpoch,
      columns: [
        'id', 'name', 'type', 'created_at', 'updated_at',
        'archived', 'week_start',
      ],
    ));

    // Board columns (use board's updated_at via join).
    final colRows = await _db.customSelect(
      'SELECT bc.* FROM board_columns bc '
      'JOIN boards b ON bc.board_id = b.id '
      'WHERE b.updated_at > ?',
      variables: [Variable(sinceEpoch)],
    ).get();
    for (final row in colRows) {
      changes.add(_rowToChange(
        'board_columns',
        row,
        ['id', 'board_id', 'label', 'position', 'type'],
      ));
    }

    // Recurring series.
    changes.addAll(await _queryTable(
      tableName: 'recurring_series',
      timestampColumn: 'created_at',
      sinceEpoch: sinceEpoch,
      columns: [
        'id', 'title', 'description', 'priority', 'recurrence_rule',
        'is_event', 'scheduled_time', 'created_at', 'ended_at',
      ],
    ));

    // Tasks.
    changes.addAll(await _queryTable(
      tableName: 'tasks',
      timestampColumn: 'updated_at',
      sinceEpoch: sinceEpoch,
      columns: [
        'id', 'board_id', 'title', 'description', 'state',
        'priority', 'position', 'created_at', 'updated_at',
        'completed_at', 'deadline', 'migrated_from_board_id',
        'migrated_from_task_id', 'is_event', 'scheduled_time',
        'recurrence_rule', 'series_id',
      ],
    ));

    // Markers.
    changes.addAll(await _queryTable(
      tableName: 'markers',
      timestampColumn: 'updated_at',
      sinceEpoch: sinceEpoch,
      columns: [
        'id', 'task_id', 'column_id', 'board_id', 'symbol',
        'updated_at',
      ],
    ));

    // Task notes.
    changes.addAll(await _queryTable(
      tableName: 'task_notes',
      timestampColumn: 'updated_at',
      sinceEpoch: sinceEpoch,
      columns: [
        'id', 'task_id', 'content', 'created_at', 'updated_at',
      ],
    ));

    // Task tags (use task's updated_at via join).
    final ttRows = await _db.customSelect(
      'SELECT tt.* FROM task_tags tt '
      'JOIN tasks t ON tt.task_id = t.id '
      'WHERE t.updated_at > ?',
      variables: [Variable(sinceEpoch)],
    ).get();
    for (final row in ttRows) {
      changes.add(SyncChange(
        table: 'task_tags',
        id: '${row.read<String>('task_id')}:${row.read<String>('tag_id')}',
        data: {
          'task_id': row.read<String>('task_id'),
          'tag_id': row.read<String>('tag_id'),
          'slot': row.read<int>('slot'),
        },
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      ));
    }

    // Series tags (use series's created_at via join).
    final stRows = await _db.customSelect(
      'SELECT st.* FROM series_tags st '
      'JOIN recurring_series rs ON st.series_id = rs.id '
      'WHERE rs.created_at > ?',
      variables: [Variable(sinceEpoch)],
    ).get();
    for (final row in stRows) {
      changes.add(SyncChange(
        table: 'series_tags',
        id: '${row.read<String>('series_id')}:${row.read<String>('tag_id')}',
        data: {
          'series_id': row.read<String>('series_id'),
          'tag_id': row.read<String>('tag_id'),
          'slot': row.read<int>('slot'),
        },
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      ));
    }

    return changes;
  }

  /// Query a single table for rows modified since [sinceEpoch].
  Future<List<SyncChange>> _queryTable({
    required String tableName,
    required String timestampColumn,
    required int sinceEpoch,
    required List<String> columns,
  }) async {
    final rows = await _db.customSelect(
      'SELECT * FROM $tableName WHERE $timestampColumn > ?',
      variables: [Variable(sinceEpoch)],
    ).get();

    return rows.map((row) => _rowToChange(tableName, row, columns)).toList();
  }

  SyncChange _rowToChange(
    String tableName,
    QueryRow row,
    List<String> columns,
  ) {
    final data = <String, dynamic>{};
    for (final col in columns) {
      data[col] = row.data[col];
    }

    // Determine the ID (single PK tables use 'id').
    final id = data['id']?.toString() ?? '';

    // Determine updatedAt from the most relevant timestamp.
    // Drift stores DateTime as epoch seconds in SQLite.
    final updatedAt = data['updated_at'] ?? data['created_at'];
    final ts = updatedAt is int
        ? DateTime.fromMillisecondsSinceEpoch(updatedAt * 1000)
            .toUtc()
            .toIso8601String()
        : DateTime.now().toUtc().toIso8601String();

    return SyncChange(
      table: tableName,
      id: id,
      data: data,
      updatedAt: ts,
    );
  }
}
