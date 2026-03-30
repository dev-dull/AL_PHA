// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Automated codebase audit — catches the categories of bugs
/// we've encountered during development. Run with:
///   flutter test test/audit/codebase_audit_test.dart
void main() {
  final libDir = Directory('lib');
  final testDir = Directory('test');

  late List<File> dartFiles;
  late List<File> testFiles;

  setUpAll(() {
    dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.dart') && !f.path.endsWith('.g.dart') &&
            !f.path.endsWith('.freezed.dart'))
        .toList();
    testFiles = testDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
  });

  group('Repository field coverage', () {
    test('TaskRepository.update() includes all writable fields', () {
      final content = File(
        'lib/features/task/data/task_repository.dart',
      ).readAsStringSync();

      // Fields that MUST appear in the update() TasksCompanion.
      final requiredFields = [
        'title:',
        'description:',
        'state:',
        'priority:',
        'position:',
        'completedAt:',
        'deadline:',
        'isEvent:',
        'scheduledTime:',
        'recurrenceRule:',
        'seriesId:',
      ];

      // Extract the update() method body.
      final updateMatch = RegExp(
        r'Future<Task> update\(Task task\) async \{([\s\S]*?)\n  \}',
      ).firstMatch(content);
      expect(updateMatch, isNotNull,
          reason: 'update() method must exist');

      final updateBody = updateMatch!.group(1)!;
      for (final field in requiredFields) {
        expect(updateBody.contains(field), isTrue,
            reason:
                'update() must include $field in TasksCompanion');
      }
    });

    test('TaskRepository.create() includes seriesId', () {
      final content = File(
        'lib/features/task/data/task_repository.dart',
      ).readAsStringSync();

      final createMatch = RegExp(
        r'Future<Task> create\(Task task\) async \{([\s\S]*?)\n  \}',
      ).firstMatch(content);
      expect(createMatch, isNotNull);
      expect(createMatch!.group(1)!.contains('seriesId:'), isTrue,
          reason: 'create() must include seriesId');
    });

    test('TaskRepository._rowToTask() includes seriesId', () {
      final content = File(
        'lib/features/task/data/task_repository.dart',
      ).readAsStringSync();

      expect(content.contains('seriesId: row.seriesId'), isTrue,
          reason: '_rowToTask must read seriesId from the row');
    });
  });

  group('Async callback safety', () {
    test('no ValueChanged callbacks for async operations in '
        'task_detail_sheet.dart', () {
      final content = File(
        'lib/features/task/presentation/task_detail_sheet.dart',
      ).readAsStringSync();

      // ValueChanged<T> is void Function(T) — async callbacks
      // must use Future<void> Function(T) to be awaitable.
      final lines = content.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('ValueChanged<Task>') &&
            !line.trimLeft().startsWith('//')) {
          fail('Line ${i + 1}: ValueChanged<Task> found — use '
              'Future<void> Function(Task) for async callbacks');
        }
        if (line.contains('ValueChanged<List<String>>') &&
            !line.trimLeft().startsWith('//')) {
          fail('Line ${i + 1}: ValueChanged<List<String>> found '
              '— use Future<void> Function(List<String>) for '
              'async callbacks');
        }
      }
    });
  });

  group('InitState provider safety', () {
    test('initState does not use .valueOrNull for critical data', () {
      final content = File(
        'lib/features/board/presentation/board_grid_body.dart',
      ).readAsStringSync();

      // Find lines inside initState / _materializeVirtualInstances
      // that use .valueOrNull — these should read from DB directly.
      final matMethod = RegExp(
        r'Future<void> _materializeVirtualInstances\(\)([\s\S]*?)\n  \}',
      ).firstMatch(content);

      if (matMethod != null) {
        final body = matMethod.group(1)!;
        expect(
          body.contains('.valueOrNull'),
          isFalse,
          reason: '_materializeVirtualInstances must not use '
              '.valueOrNull — providers may not have settled. '
              'Read from DB directly.',
        );
      }
    });
  });

  group('Series/tag sync completeness', () {
    test('materialize() syncs tags for pre-existing tasks', () {
      final content = File(
        'lib/features/series/providers/series_providers.dart',
      ).readAsStringSync();

      // The safety check (early return for existing tasks) must
      // also sync series tags.
      final safetyCheck = RegExp(
        r'if \(match != null\)([\s\S]*?)return match;',
      ).firstMatch(content);

      expect(safetyCheck, isNotNull,
          reason: 'materialize must have a safety check');
      expect(
        safetyCheck!.group(1)!.contains('setTagsForTask'),
        isTrue,
        reason: 'Safety check early return must still sync tags',
      );
    });

    test('all task creation paths in marker_providers include '
        'seriesId', () {
      final content = File(
        'lib/features/marker/providers/marker_providers.dart',
      ).readAsStringSync();

      // Find all Task(...) constructors in the file.
      final taskCreations = RegExp(r'Task\(').allMatches(content);
      for (final match in taskCreations) {
        // Get the block after each Task( — look for the closing )
        final start = match.start;
        final block = content.substring(
          start,
          (start + 500).clamp(0, content.length),
        );
        // Every Task constructor that sets boardId should also
        // set seriesId (even if null).
        if (block.contains('boardId:') && block.contains('migratedFromTaskId:')) {
          expect(block.contains('seriesId:'), isTrue,
              reason: 'Task creation near offset $start must '
                  'include seriesId');
        }
      }
    });
  });

  group('Import hygiene', () {
    test('no unused dart:developer imports (debug logging)', () {
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        if (content.contains("import 'dart:developer'") &&
            !content.contains('dev.log')) {
          fail('${file.path}: imports dart:developer but does not '
              'use dev.log — leftover debug import');
        }
      }
    });

    test('no print statements in production code', () {
      for (final file in dartFiles) {
        if (file.path.contains('test/')) continue;
        final lines = file.readAsStringSync().split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('print(') &&
              !line.startsWith('//') &&
              !lines[i].contains('ignore: avoid_print')) {
            fail('${file.path}:${i + 1}: print() in production '
                'code — remove or add ignore comment');
          }
        }
      }
    });
  });

  group('Test coverage gaps', () {
    test('major features have at least one test file', () {
      final testFileNames = testFiles.map((f) => f.path).toList();

      final requiredCoverage = {
        'recurring_series': 'Recurring series (virtual instances)',
        'day_summary': 'Day summaries (monthly/yearly overview)',
        'tag_carry': 'Tag carry-over to materialized instances',
        'marker_symbol': 'Marker symbol enum',
        'task_sort': 'Task sorting',
        'week_utils': 'Week utilities',
      };

      for (final entry in requiredCoverage.entries) {
        final hasTest = testFileNames.any(
          (p) => p.contains(entry.key),
        );
        expect(hasTest, isTrue,
            reason: '${entry.value} must have a test file '
                'matching "${entry.key}"');
      }
    });
  });

  group('Schema consistency', () {
    test('database.dart schema version matches migration count', () {
      final content = File('lib/shared/database.dart').readAsStringSync();

      // Extract schema version.
      final versionMatch = RegExp(
        r'int get schemaVersion => (\d+);',
      ).firstMatch(content);
      expect(versionMatch, isNotNull);
      final version = int.parse(versionMatch!.group(1)!);

      // Count "from < N" migration blocks.
      final migrations = RegExp(r'if \(from < (\d+)\)')
          .allMatches(content)
          .map((m) => int.parse(m.group(1)!))
          .toList();

      expect(migrations.isNotEmpty, isTrue);
      expect(migrations.last, version,
          reason: 'Last migration must match schema version');
    });

    test('RecurringSeries table exists in schema', () {
      final content = File('lib/shared/database.dart').readAsStringSync();
      expect(content.contains('RecurringSeriesTable'), isTrue);
      expect(content.contains('SeriesTags'), isTrue);
    });
  });

  group('Data export completeness', () {
    test('export includes all tables', () {
      final content = File(
        'lib/features/board/data/data_export.dart',
      ).readAsStringSync();

      final requiredTables = [
        'boards',
        'columns',
        'tasks',
        'markers',
        'notes',
        'recurring_series',
        'series_tags',
      ];

      for (final table in requiredTables) {
        expect(content.contains("'$table'"), isTrue,
            reason: 'Export must include $table');
      }
    });
  });
}
