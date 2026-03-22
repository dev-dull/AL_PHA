import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:alpha/features/board/domain/board.dart';
import 'package:alpha/features/board/domain/board_type.dart';
import 'package:alpha/features/board/providers/board_providers.dart';
import 'package:alpha/features/column/domain/board_column.dart';
import 'package:alpha/features/column/domain/weekly_columns.dart';
import 'package:alpha/features/column/providers/column_providers.dart';
import 'package:alpha/features/preferences/providers/preferences_providers.dart';
import 'package:alpha/shared/week_utils.dart';

class BoardCreateScreen extends ConsumerStatefulWidget {
  const BoardCreateScreen({super.key});

  @override
  ConsumerState<BoardCreateScreen> createState() => _BoardCreateScreenState();
}

class _BoardCreateScreenState extends ConsumerState<BoardCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final formatted = DateFormat('MMMM d').format(now);
    _nameController = TextEditingController(text: 'Week of $formatted');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createBoard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final firstDay =
          ref.read(preferencesProvider).firstDayOfWeek;
      const uuid = Uuid();
      final now = DateTime.now();
      final boardId = uuid.v4();
      final weekStart =
          startOfWeek(now, firstDay: firstDay);

      final board = Board(
        id: boardId,
        name: _nameController.text.trim(),
        type: BoardType.weekly,
        weekStart: weekStart,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(boardActionsProvider).create(board);

      final columnActions = ref.read(columnActionsProvider);
      for (final col in weeklyColumnDefs(firstDay: firstDay)) {
        await columnActions.create(
          BoardColumn(
            id: uuid.v4(),
            boardId: boardId,
            label: col.label,
            position: col.position,
            type: col.type,
          ),
        );
      }

      if (mounted) {
        context.goNamed('boardDetail', pathParameters: {'id': boardId});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create board: $e')));
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Board')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Board name'),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a board name';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isCreating ? null : _createBoard,
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
