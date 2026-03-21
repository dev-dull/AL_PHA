import 'package:flutter/material.dart';
import 'package:alpha/features/task/domain/task.dart';

/// Bottom sheet for editing task details: title, description,
/// priority, deadline, and delete.
class TaskDetailSheet extends StatefulWidget {
  final Task task;

  /// Called with the updated [Task] when the user taps Save.
  final ValueChanged<Task> onSave;

  /// Called when the user confirms deletion.
  final VoidCallback onDelete;

  const TaskDetailSheet({
    super.key,
    required this.task,
    required this.onSave,
    required this.onDelete,
  });

  /// Show the sheet and return the result.
  static Future<void> show({
    required BuildContext context,
    required Task task,
    required ValueChanged<Task> onSave,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          TaskDetailSheet(task: task, onSave: onSave, onDelete: onDelete),
    );
  }

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late int _priority;
  late DateTime? _deadline;
  late bool _isEvent;
  late TimeOfDay? _scheduledTime;

  static const _priorityLabels = ['None', 'Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description);
    _priority = widget.task.priority;
    _deadline = widget.task.deadline;
    _isEvent = widget.task.isEvent;
    _scheduledTime = _parseTime(widget.task.scheduledTime);
  }

  static TimeOfDay? _parseTime(String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final updated = widget.task.copyWith(
      title: title,
      description: _descCtrl.text.trim(),
      priority: _priority,
      deadline: _deadline,
      isEvent: _isEvent,
      scheduledTime: _isEvent ? _formatTime(_scheduledTime) : null,
    );
    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text(
          'Are you sure you want to delete this task? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.onDelete();
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            TextField(
              controller: _titleCtrl,
              autofocus: false,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            // Priority selector
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _priority,
                  isDense: true,
                  isExpanded: true,
                  items: List.generate(
                    _priorityLabels.length,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(_priorityLabels[i]),
                    ),
                  ),
                  onChanged: (v) {
                    if (v != null) setState(() => _priority = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Deadline picker
            InkWell(
              onTap: _pickDeadline,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Deadline',
                  border: const OutlineInputBorder(),
                  suffixIcon: _deadline != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _deadline = null),
                        )
                      : const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _deadline != null
                      ? '${_deadline!.year}-'
                            '${_deadline!.month.toString().padLeft(2, '0')}-'
                            '${_deadline!.day.toString().padLeft(2, '0')}'
                      : 'No deadline',
                  style: _deadline == null
                      ? theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Event toggle
            SwitchListTile(
              title: const Text('Event'),
              subtitle: const Text('Mark as an event with a scheduled time'),
              value: _isEvent,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() {
                _isEvent = v;
                if (!v) _scheduledTime = null;
              }),
            ),

            // Scheduled time picker (only shown for events)
            if (_isEvent) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        _scheduledTime ?? const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (picked != null) {
                    setState(() => _scheduledTime = picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Scheduled Time',
                    border: const OutlineInputBorder(),
                    suffixIcon: _scheduledTime != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _scheduledTime = null),
                          )
                        : const Icon(Icons.access_time),
                  ),
                  child: Text(
                    _scheduledTime != null
                        ? _scheduledTime!.format(context)
                        : 'No time set',
                    style: _scheduledTime == null
                        ? theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                // Delete button
                TextButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
                const Spacer(),
                // Save button
                FilledButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
