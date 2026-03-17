import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:alpha/features/board/domain/board.dart';
import 'package:alpha/features/board/providers/board_providers.dart';
import 'package:alpha/features/column/domain/board_column.dart';
import 'package:alpha/features/column/providers/column_providers.dart';
import 'package:alpha/features/template/data/templates.dart';
import 'package:alpha/features/template/domain/board_template.dart';

class BoardCreateScreen extends ConsumerStatefulWidget {
  const BoardCreateScreen({super.key});

  @override
  ConsumerState<BoardCreateScreen> createState() => _BoardCreateScreenState();
}

class _BoardCreateScreenState extends ConsumerState<BoardCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _selectedTemplateIndex = 0;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  BoardTemplate get _selectedTemplate =>
      defaultTemplates[_selectedTemplateIndex];

  Future<void> _createBoard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      const uuid = Uuid();
      final template = _selectedTemplate;
      final now = DateTime.now();
      final boardId = uuid.v4();

      final board = Board(
        id: boardId,
        name: _nameController.text.trim(),
        type: template.boardType,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(boardActionsProvider).create(board);

      // Create columns from the template
      final columnActions = ref.read(columnActionsProvider);
      for (final col in template.columns) {
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Board')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Board name',
                hintText: 'e.g. Week of March 16',
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a board name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('Choose a template', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _TemplateGrid(
              templates: defaultTemplates,
              selectedIndex: _selectedTemplateIndex,
              onSelected: (index) {
                setState(() => _selectedTemplateIndex = index);
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

class _TemplateGrid extends StatelessWidget {
  const _TemplateGrid({
    required this.templates,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<BoardTemplate> templates;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final isSelected = index == selectedIndex;
        return _TemplateCard(
          template: template,
          isSelected: isSelected,
          onTap: () => onSelected(index),
        );
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  final BoardTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isSelected ? colorScheme.primary : null,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  template.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${template.columns.length} columns',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
