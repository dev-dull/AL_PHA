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

@DriftDatabase(tables: [Boards, BoardColumns, Tasks, Markers])
class AlphaDatabase extends _$AlphaDatabase {
  AlphaDatabase() : super(_openConnection());

  AlphaDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        // Rename old symbol values to new ones
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
