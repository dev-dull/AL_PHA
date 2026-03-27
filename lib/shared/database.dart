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
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get deadline => dateTime().nullable()();
  TextColumn get migratedFromBoardId => text().nullable()();
  TextColumn get migratedFromTaskId => text().nullable()();
  BoolColumn get isEvent => boolean().withDefault(const Constant(false))();
  TextColumn get scheduledTime => text().nullable()();
  TextColumn get recurrenceRule => text().nullable()();

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

@DriftDatabase(tables: [Boards, BoardColumns, Tasks, Markers, TaskNotes, Tags, TaskTags])
class AlphaDatabase extends _$AlphaDatabase {
  AlphaDatabase() : super(_openConnection());

  AlphaDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 7;

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
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'alpha.db'));
    return NativeDatabase.createInBackground(file);
  });
}
