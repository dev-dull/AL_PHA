import 'package:flutter/material.dart';
import 'package:alpha/features/task/domain/task.dart';
import 'package:alpha/features/task/domain/recurrence.dart';
import 'package:alpha/features/task/presentation/task_notes_section.dart';

enum _SeriesChoice { thisEvent, allEvents }

/// Bottom sheet for editing task details: title, description,
/// priority, deadline, event settings, and delete.
class TaskDetailSheet extends StatefulWidget {
  final Task task;

  /// Called with the updated [Task] when the user taps Save.
  final ValueChanged<Task> onSave;

  /// Called when the user confirms deletion.
  final VoidCallback onDelete;

  /// Called when the user marks the task as "Won't Do".
  final VoidCallback? onWontDo;

  const TaskDetailSheet({
    super.key,
    required this.task,
    required this.onSave,
    required this.onDelete,
    this.onWontDo,
  });

  /// Show the sheet and return the result.
  static Future<void> show({
    required BuildContext context,
    required Task task,
    required ValueChanged<Task> onSave,
    required VoidCallback onDelete,
    VoidCallback? onWontDo,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TaskDetailSheet(
        task: task,
        onSave: onSave,
        onDelete: onDelete,
        onWontDo: onWontDo,
      ),
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
  late RecurrenceFrequency _recurrence;
  late Set<int> _scheduledDays;

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

    final (freq, days) = parseRRule(widget.task.recurrenceRule);
    _recurrence = freq;
    _scheduledDays = freq == RecurrenceFrequency.daily
        ? {0, 1, 2, 3, 4, 5, 6}
        : days;
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

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final updated = widget.task.copyWith(
      title: title,
      description: _descCtrl.text.trim(),
      priority: _priority,
      deadline: _deadline,
      isEvent: _isEvent,
      scheduledTime: _isEvent ? _formatTime(_scheduledTime) : null,
      recurrenceRule:
          _isEvent ? buildRRule(_recurrence, _scheduledDays) : null,
    );

    // If the original task is a recurring event, ask whether to
    // update this single occurrence or the entire series.
    if (widget.task.isEvent && widget.task.recurrenceRule != null) {
      final choice = await _showSeriesPrompt('Edit');
      if (choice == null) return; // cancelled
      if (choice == _SeriesChoice.thisEvent) {
        // Remove frequency but keep the scheduled days.
        widget.onSave(
          updated.copyWith(
            recurrenceRule: buildByDayOnly(_scheduledDays),
          ),
        );
      } else {
        widget.onSave(updated);
      }
    } else {
      widget.onSave(updated);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    // For recurring events, ask about series scope first.
    if (widget.task.isEvent && widget.task.recurrenceRule != null) {
      final choice = await _showSeriesPrompt('Delete');
      if (choice == null) return;
      if (choice == _SeriesChoice.thisEvent) {
        // Remove frequency so migration won't recreate it, but
        // keep days for display consistency.
        final (_, days) = parseRRule(widget.task.recurrenceRule);
        widget.onSave(
          widget.task.copyWith(recurrenceRule: buildByDayOnly(days)),
        );
      }
      // Both choices ultimately delete from the current board.
    }

    if (!mounted) return;
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

  Future<_SeriesChoice?> _showSeriesPrompt(String action) {
    return showDialog<_SeriesChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Recurring Event'),
        content: const Text(
          'This event is part of a series. Do you want to '
          'update this event only, or all events in the series?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_SeriesChoice.thisEvent),
            child: const Text('This Event'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_SeriesChoice.allEvents),
            child: const Text('All Events'),
          ),
        ],
      ),
    );
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
                if (!v) {
                  _scheduledTime = null;
                  _recurrence = RecurrenceFrequency.none;
                  _scheduledDays.clear();
                }
              }),
            ),

            // Event-specific fields
            if (_isEvent) ...[
              const SizedBox(height: 4),

              // Day picker
              Text(
                'Scheduled Days',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              IgnorePointer(
                ignoring: _recurrence == RecurrenceFrequency.daily,
                child: Opacity(
                  opacity: _recurrence == RecurrenceFrequency.daily
                      ? 0.5
                      : 1.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(7, (i) {
                      final selected = _scheduledDays.contains(i);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (selected) {
                            _scheduledDays.remove(i);
                          } else {
                            _scheduledDays.add(i);
                          }
                        }),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          child: Text(
                            dayLabels[i].substring(0, 1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Time picker
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
              const SizedBox(height: 12),

              // Recurrence picker
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Repeat',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<RecurrenceFrequency>(
                    value: _recurrence,
                    isDense: true,
                    isExpanded: true,
                    items: RecurrenceFrequency.values
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(f.displayName),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _recurrence = v;
                          if (v == RecurrenceFrequency.daily) {
                            _scheduledDays
                              ..clear()
                              ..addAll({0, 1, 2, 3, 4, 5, 6});
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Notes
            Divider(
              color: theme.colorScheme.onSurface
                  .withValues(alpha: 0.12),
            ),
            const SizedBox(height: 8),
            TaskNotesSection(taskId: widget.task.id),

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
                if (widget.onWontDo != null) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      widget.onWontDo!();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.block),
                    label: const Text("Won't Do"),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
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
