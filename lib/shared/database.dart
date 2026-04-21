import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// --- Table definitions ---

@DataClassName('BoardRow')
class Boards extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get weekStart => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BoardColumnRow')
class BoardColumns extends Table {
  TextColumn get id => text()();
  TextColumn get boardId => text().references(Boards, #id)();
  TextColumn get label => text()();
  IntColumn get position => integer()();
  TextColumn get type => text().withDefault(const Constant('custom'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskRow')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get boardId => text().references(Boards, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get state => text().withDefault(const Constant('open'))();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  IntColumn get position => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get deadline => dateTime().nullable()();
  TextColumn get migratedFromBoardId => text().nullable()();
  TextColumn get migratedFromTaskId => text().nullable()();
  BoolColumn get isEvent => boolean().withDefault(const Constant(false))();
  TextColumn get scheduledTime => text().nullable()();
  TextColumn get recurrenceRule => text().nullable()();
  TextColumn get seriesId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MarkerRow')
class Markers extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get columnId => text().references(BoardColumns, #id)();
  TextColumn get boardId => text().references(Boards, #id)();
  TextColumn get symbol => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {taskId, columnId},
  ];
}

@DataClassName('TaskNoteRow')
class TaskNotes extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecurringSeriesRow')
class RecurringSeriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get recurrenceRule => text()();
  BoolColumn get isEvent =>
      boolean().withDefault(const Constant(false))();
  TextColumn get scheduledTime => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  @override
  String get tableName => 'recurring_series';

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SeriesTagRow')
class SeriesTags extends Table {
  TextColumn get seriesId =>
      text().references(RecurringSeriesTable, #id)();
  TextColumn get tagId => text().references(Tags, #id)();
  IntColumn get slot => integer()();

  @override
  Set<Column> get primaryKey => {seriesId, tagId};
}

@DataClassName('TagRow')
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 30)();
  IntColumn get color => integer()();
  IntColumn get position => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskTagRow')
class TaskTags extends Table {
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get tagId => text().references(Tags, #id)();
  IntColumn get slot => integer()();

  @override
  Set<Column> get primaryKey => {taskId, tagId};
}

@DataClassName('SyncMetaRow')
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  Boards,
  BoardColumns,
  Tasks,
  Markers,
  TaskNotes,
  Tags,
  TaskTags,
  RecurringSeriesTable,
  SeriesTags,
  SyncMeta,
])
class PlanyrDatabase extends _$PlanyrDatabase {
  PlanyrDatabase() : super(_openConnection());

  PlanyrDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await customStatement(
          "UPDATE markers SET symbol = 'event' WHERE symbol = 'circle'",
        );
        await customStatement(
          "UPDATE markers SET symbol = 'slash' WHERE symbol = 'tilde'",
        );
        await customStatement(
          "UPDATE markers SET symbol = 'migratedForward' WHERE symbol = 'migrated'",
        );
        await customStatement(
          "UPDATE markers SET symbol = 'dot' WHERE symbol = 'star'",
        );
      }
      if (from < 3) {
        await customStatement(
          'ALTER TABLE boards ADD COLUMN week_start INTEGER',
        );
        // Backfill weekly boards: compute Monday from createdAt.
        // SQLite: strftime('%w') gives 0=Sun..6=Sat.
        // Monday offset: (weekday + 6) % 7 days before createdAt.
        await customStatement(
          'UPDATE boards SET week_start = '
          "created_at - ((CAST(strftime('%w', created_at / 1000, 'unixepoch') AS INTEGER) + 6) % 7) * 86400000 "
          "WHERE type = 'weekly'",
        );
      }
      if (from < 4) {
        await customStatement(
          'ALTER TABLE tasks ADD COLUMN is_event INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE tasks ADD COLUMN scheduled_time TEXT',
        );
      }
      if (from < 5) {
        await customStatement(
          'ALTER TABLE tasks ADD COLUMN recurrence_rule TEXT',
        );
      }
      if (from < 6) {
        await migrator.createTable(taskNotes);
      }
      if (from < 7) {
        await migrator.createTable(tags);
        await migrator.createTable(taskTags);
      }
      if (from < 8) {
        await migrator.createTable(recurringSeriesTable);
        await migrator.createTable(seriesTags);
        await customStatement(
          'ALTER TABLE tasks ADD COLUMN series_id TEXT',
        );
        // Migrate existing recurring tasks to series.
        await _migrateRecurringToSeries();
      }
      if (from < 9) {
        // Add updatedAt to tasks for sync change tracking.
        await customStatement(
          'ALTER TABLE tasks ADD COLUMN updated_at INTEGER',
        );
        // Backfill: set updatedAt = createdAt for existing tasks.
        await customStatement(
          'UPDATE tasks SET updated_at = created_at '
          'WHERE updated_at IS NULL',
        );
        // SyncMeta table for sync state (device_id, last_sync).
        await migrator.createTable(syncMeta);
      }
    },
  );

  /// One-time migration: converts existing recurring tasks into
  /// RecurringSeries rows and links them via series_id.
  Future<void> _migrateRecurringToSeries() async {
    final rows = await customSelect(
      'SELECT * FROM tasks WHERE recurrence_rule IS NOT NULL '
      "AND recurrence_rule LIKE '%FREQ=%'",
    ).get();

    // Group by (title, recurrence_rule) to form series.
    final groups = <String, List<QueryRow>>{};
    for (final row in rows) {
      final key =
          '${row.read<String>('title')}||${row.read<String>('recurrence_rule')}';
      groups.putIfAbsent(key, () => []).add(row);
    }

    for (final entry in groups.entries) {
      final source = entry.value.first;
      final seriesId =
          'series_${source.read<String>('id').substring(0, 8)}';
      final now = DateTime.now().millisecondsSinceEpoch;

      await customStatement(
        'INSERT OR IGNORE INTO recurring_series '
        '(id, title, description, priority, recurrence_rule, '
        'is_event, scheduled_time, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          seriesId,
          source.read<String>('title'),
          source.read<String>('description'),
          source.read<int>('priority'),
          source.read<String>('recurrence_rule'),
          source.read<bool>('is_event') ? 1 : 0,
          source.readNullable<String>('scheduled_time'),
          now,
        ],
      );

      // Link all tasks in the group to the series.
      for (final task in entry.value) {
        await customStatement(
          'UPDATE tasks SET series_id = ? WHERE id = ?',
          [seriesId, task.read<String>('id')],
        );
      }

      // Copy tags from source task to series.
      final taskTags = await customSelect(
        'SELECT tag_id, slot FROM task_tags WHERE task_id = ?',
        variables: [Variable(source.read<String>('id'))],
      ).get();
      for (final tt in taskTags) {
        await customStatement(
          'INSERT OR IGNORE INTO series_tags '
          '(series_id, tag_id, slot) VALUES (?, ?, ?)',
          [
            seriesId,
            tt.read<String>('tag_id'),
            tt.read<int>('slot'),
          ],
        );
      }
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'planyr.db'));
    return NativeDatabase.createInBackground(file);
  });
}
