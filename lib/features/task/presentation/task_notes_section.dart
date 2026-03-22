import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alpha/features/task/domain/task_note.dart';
import 'package:alpha/features/task/providers/task_note_providers.dart';
import 'package:intl/intl.dart';

/// Displays a list of timestamped notes for a task, with an
/// inline text field to add new notes.
class TaskNotesSection extends ConsumerStatefulWidget {
  final String taskId;

  const TaskNotesSection({super.key, required this.taskId});

  @override
  ConsumerState<TaskNotesSection> createState() => _TaskNotesSectionState();
}

class _TaskNotesSectionState extends ConsumerState<TaskNotesSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await ref.read(taskNoteActionsProvider).create(
      taskId: widget.taskId,
      content: text,
    );
    _controller.clear();
  }

  Future<void> _deleteNote(TaskNote note) async {
    await ref.read(taskNoteActionsProvider).delete(note.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notesAsync = ref.watch(taskNoteListProvider(widget.taskId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        // Add note field
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Add a note...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _addNote,
              tooltip: 'Add note',
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Notes list
        notesAsync.when(
          data: (notes) {
            if (notes.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No notes yet.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              );
            }
            return Column(
              children: notes.map((note) => _NoteItem(
                note: note,
                onDelete: () => _deleteNote(note),
              )).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }
}

class _NoteItem extends StatelessWidget {
  final TaskNote note;
  final VoidCallback onDelete;

  const _NoteItem({required this.note, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = DateFormat.MMMd().add_jm().format(note.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.content,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  timestamp,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              icon: const Icon(Icons.close, size: 14),
              padding: EdgeInsets.zero,
              onPressed: onDelete,
              tooltip: 'Delete note',
              color: theme.colorScheme.onSurface
                  .withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
