import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alpha/features/task/domain/task.dart';
import 'package:alpha/features/task/presentation/task_detail_sheet.dart';

import '../helpers/test_data.dart';

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

    Widget buildSubject({ValueChanged<Task>? onSave, VoidCallback? onDelete}) {
      return MaterialApp(
        home: Scaffold(
          body: TaskDetailSheet(
            task: task,
            onSave: onSave ?? (_) {},
            onDelete: onDelete ?? () {},
          ),
        ),
      );
    }

    testWidgets('renders pre-filled fields', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Milk, eggs, bread'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget); // priority 2
      expect(find.text('2026-03-20'), findsOneWidget);
    });

    testWidgets('save calls onSave with updated task', (tester) async {
      Task? saved;
      await tester.pumpWidget(buildSubject(onSave: (t) => saved = t));

      // Edit title
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
      await tester.pumpWidget(buildSubject(onSave: (t) => saved = t));

      final titleField = find.widgetWithText(TextField, 'Buy groceries');
      await tester.enterText(titleField, '');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saved, isNull);
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildSubject());

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
      await tester.pumpWidget(buildSubject(onDelete: () => deleted = true));

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Tap the confirmation Delete button (in the dialog)
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });

    testWidgets('cancelling delete does not call onDelete', (tester) async {
      bool deleted = false;
      await tester.pumpWidget(buildSubject(onDelete: () => deleted = true));

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(deleted, isFalse);
    });

    testWidgets('priority dropdown changes value', (tester) async {
      Task? saved;
      await tester.pumpWidget(buildSubject(onSave: (t) => saved = t));

      // Open dropdown
      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();

      // Select High (priority 3)
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
      await tester.pumpWidget(buildSubject());

      expect(find.text('No deadline'), findsOneWidget);
    });
  });
}
