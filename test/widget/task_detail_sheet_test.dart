import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alpha/features/task/domain/task.dart';
import 'package:alpha/features/task/data/task_note_repository.dart';
import 'package:alpha/features/task/domain/task_note.dart';
import 'package:alpha/features/task/presentation/task_detail_sheet.dart';
import 'package:alpha/shared/providers.dart';

import '../helpers/test_data.dart';

/// Minimal in-memory note repository that avoids Drift streams.
class _FakeTaskNoteRepository implements TaskNoteRepository {
  @override
  Future<TaskNote> create(TaskNote note) async => note;
  @override
  Future<TaskNote> update(TaskNote note) async => note;
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> deleteByTask(String taskId) async {}
  @override
  Future<List<TaskNote>> getByTask(String taskId) async => [];
  @override
  Stream<List<TaskNote>> watchByTask(String taskId) =>
      Stream.value(<TaskNote>[]);
}

void main() {
  group('TaskDetailSheet', () {
    late Task task;

    setUp(() {
      task = makeTask(
        title: 'Buy groceries',
        description: 'Milk, eggs, bread',
        priority: 2,
        deadline: DateTime(2026, 3, 20),
      );
    });

    Widget buildSubject(
      WidgetTester tester, {
      ValueChanged<Task>? onSave,
      VoidCallback? onDelete,
    }) {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      return ProviderScope(
        overrides: [
          taskNoteRepositoryProvider
              .overrideWithValue(_FakeTaskNoteRepository()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TaskDetailSheet(
              task: task,
              onSave: onSave ?? (_) {},
              onDelete: onDelete ?? () {},
            ),
          ),
        ),
      );
    }

    testWidgets('renders pre-filled fields', (tester) async {
      await tester.pumpWidget(buildSubject(tester));
      await tester.pumpAndSettle();

      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Milk, eggs, bread'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('2026-03-20'), findsOneWidget);
    });

    testWidgets('save calls onSave with updated task', (tester) async {
      Task? saved;
      await tester.pumpWidget(
        buildSubject(tester, onSave: (t) => saved = t),
      );
      await tester.pumpAndSettle();

      final titleField = find.widgetWithText(TextField, 'Buy groceries');
      await tester.enterText(titleField, 'Buy snacks');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.title, 'Buy snacks');
      expect(saved!.description, 'Milk, eggs, bread');
      expect(saved!.priority, 2);
    });

    testWidgets('save is no-op when title is empty', (tester) async {
      Task? saved;
      await tester.pumpWidget(
        buildSubject(tester, onSave: (t) => saved = t),
      );
      await tester.pumpAndSettle();

      final titleField = find.widgetWithText(TextField, 'Buy groceries');
      await tester.enterText(titleField, '');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saved, isNull);
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildSubject(tester));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Task'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete this task? '
          'This cannot be undone.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('confirming delete calls onDelete', (tester) async {
      bool deleted = false;
      await tester.pumpWidget(
        buildSubject(tester, onDelete: () => deleted = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });

    testWidgets('cancelling delete does not call onDelete', (tester) async {
      bool deleted = false;
      await tester.pumpWidget(
        buildSubject(tester, onDelete: () => deleted = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(deleted, isFalse);
    });

    testWidgets('priority dropdown changes value', (tester) async {
      Task? saved;
      await tester.pumpWidget(
        buildSubject(tester, onSave: (t) => saved = t),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('High').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saved!.priority, 3);
    });

    testWidgets('renders no deadline text when deadline is null', (
      tester,
    ) async {
      task = makeTask(title: 'No deadline task');
      await tester.pumpWidget(buildSubject(tester));
      await tester.pumpAndSettle();

      expect(find.text('No deadline'), findsOneWidget);
    });
  });
}
