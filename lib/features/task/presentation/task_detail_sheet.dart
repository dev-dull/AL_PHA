import 'package:flutter/material.dart';
import 'package:planyr/features/task/domain/task.dart';
import 'package:planyr/features/task/domain/recurrence.dart';
import 'package:planyr/features/tag/domain/tag.dart';
import 'package:planyr/features/tag/domain/tag_palette.dart';
import 'package:planyr/features/task/presentation/task_notes_section.dart';

enum _SeriesChoice { thisOne, all }

/// Bottom sheet for editing task details: title, description,
/// priority, deadline, event settings, and delete.
class TaskDetailSheet extends StatefulWidget {
  final Task task;

  /// Called with the updated [Task] when the user saves.
  final Future<void> Function(Task) onSave;

  /// Called when the user confirms deletion.
  final VoidCallback onDelete;

  /// Called when the user marks the task as "Won't Do".
  final VoidCallback? onWontDo;

  /// Called when the user reopens a won't-do or cancelled task.
  final VoidCallback? onReopen;

  /// Column positions (0–6) where the task currently has markers
  /// on the board. Used to pre-populate the day picker when
  /// no recurrence rule exists yet.
  final Set<int> markerPositions;

  /// The board's week-start, when known. Used to translate
  /// [markerPositions] into actual dates so a monthly/yearly
  /// recurrence rule can anchor on the day-of-month the user
  /// dotted (e.g. dot on May 15 → `BYMONTHDAY=15`). Falls back
  /// to [task.createdAt] if absent.
  final DateTime? boardWeekStart;

  /// Called when "All" is chosen for a series edit.
  final Future<void> Function(Task)? onSaveAll;

  /// Called when "All" is chosen for a series delete.
  final VoidCallback? onDeleteAll;

  /// Tags currently assigned to this task.
  final List<Tag> currentTags;

  /// All available tags the user has created.
  final List<Tag> availableTags;

  /// Called when the user changes tag assignments.
  final Future<void> Function(List<String>)? onTagsChanged;

  const TaskDetailSheet({
    super.key,
    required this.task,
    required this.onSave,
    required this.onDelete,
    this.onWontDo,
    this.onReopen,
    this.markerPositions = const {},
    this.boardWeekStart,
    this.onSaveAll,
    this.onDeleteAll,
    this.currentTags = const [],
    this.availableTags = const [],
    this.onTagsChanged,
  });

  /// Show the sheet and return the result.
  static Future<void> show({
    required BuildContext context,
    required Task task,
    required Future<void> Function(Task) onSave,
    required VoidCallback onDelete,
    VoidCallback? onWontDo,
    VoidCallback? onReopen,
    Set<int> markerPositions = const {},
    DateTime? boardWeekStart,
    Future<void> Function(Task)? onSaveAll,
    VoidCallback? onDeleteAll,
    List<Tag> currentTags = const [],
    List<Tag> availableTags = const [],
    Future<void> Function(List<String>)? onTagsChanged,
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
        onReopen: onReopen,
        markerPositions: markerPositions,
        boardWeekStart: boardWeekStart,
        onSaveAll: onSaveAll,
        onDeleteAll: onDeleteAll,
        currentTags: currentTags,
        availableTags: availableTags,
        onTagsChanged: onTagsChanged,
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
  late List<String> _selectedTagIds;
  bool _cancelled = false;
  bool _saved = false;

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
        : days.isNotEmpty
            ? days
            : Set<int>.from(widget.markerPositions);
    _selectedTagIds = widget.currentTags.map((t) => t.id).toList();
  }

  /// Parse a stored UTC "HH:mm" string to a local TimeOfDay.
  static TimeOfDay? _parseTime(String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final utcHour = int.parse(parts[0]);
    final utcMinute = int.parse(parts[1]);
    // Convert UTC time to local for display.
    final now = DateTime.now();
    final utcDt = DateTime.utc(
      now.year, now.month, now.day, utcHour, utcMinute,
    );
    final local = utcDt.toLocal();
    return TimeOfDay(hour: local.hour, minute: local.minute);
  }

  /// Convert a local TimeOfDay to a UTC "HH:mm" string for storage.
  static String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    final now = DateTime.now();
    final localDt = DateTime(
      now.year, now.month, now.day, time.hour, time.minute,
    );
    final utc = localDt.toUtc();
    return '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  /// Translate every ticked day in the picker (`_scheduledDays`)
  /// through [widget.boardWeekStart] into an actual `DateTime`.
  /// Each one becomes a `BYMONTHDAY` entry, so a user ticking
  /// Wed + Fri on the week-of-May-11 board produces
  /// `BYMONTHDAY=13,15` — the rule fires twice a month from then on.
  ///
  /// Falls back to [resolveRecurrenceAnchor] (a single date) when
  /// the picker is empty or we don't have a board reference, so the
  /// behaviour is never worse than the single-anchor path.
  List<DateTime> _resolveMonthlyAnchors() {
    final ws = widget.boardWeekStart;
    if (ws != null && _scheduledDays.isNotEmpty) {
      return _scheduledDays
          .map((pos) => ws.add(Duration(days: pos)))
          .toList()
        ..sort((a, b) => a.compareTo(b));
    }
    return [
      resolveRecurrenceAnchor(
        recurrenceRule: widget.task.recurrenceRule,
        createdAt: widget.task.createdAt,
        markerPositions: widget.markerPositions,
        boardWeekStart: ws,
      ),
    ];
  }

  /// Saves the task. Called explicitly via the series prompt or
  /// automatically when the sheet is dismissed.
  /// Does NOT pop — the caller handles navigation.
  Future<void> _save({bool promptSeries = true}) async {
    if (_saved || _cancelled) return;

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    _saved = true;

    final updated = widget.task.copyWith(
      title: title,
      description: _descCtrl.text.trim(),
      priority: _priority,
      deadline: _deadline,
      isEvent: _isEvent,
      scheduledTime: _isEvent ? _formatTime(_scheduledTime) : null,
      // Monthly: every ticked day translates through boardWeekStart
      // into a date — that becomes a BYMONTHDAY entry. So ticking
      // Wed+Fri on the May 11 board produces BYMONTHDAY=13,15.
      // Yearly + others fall back to the single-anchor resolution.
      recurrenceRule: resolveRecurrenceRuleForSave(
        isEvent: _isEvent,
        recurrence: _recurrence,
        scheduledDays: _scheduledDays,
        existingRule: widget.task.recurrenceRule,
        anchorDates: _recurrence == RecurrenceFrequency.monthly
            ? _resolveMonthlyAnchors()
            : null,
        anchorDate: _recurrence == RecurrenceFrequency.monthly
            ? null
            : resolveRecurrenceAnchor(
                recurrenceRule: widget.task.recurrenceRule,
                createdAt: widget.task.createdAt,
                markerPositions: widget.markerPositions,
                boardWeekStart: widget.boardWeekStart,
              ),
      ),
    );

    // If the recurrence rule changed on a recurring task,
    // automatically propagate to the whole series (changing
    // the repeat schedule is always a series-level change).
    final recurrenceChanged = widget.task.isRecurring &&
        updated.recurrenceRule != widget.task.recurrenceRule;

    if (recurrenceChanged && widget.onSaveAll != null) {
      await widget.onSaveAll!(updated);
      await widget.onTagsChanged?.call(_selectedTagIds);
      if (promptSeries && mounted) Navigator.of(context).pop();
      return;
    }

    // For other changes on a recurring task, prompt.
    if (promptSeries && widget.task.isRecurring) {
      final choice = await _showSeriesPrompt('Edit');
      if (choice == null) {
        _saved = false; // allow retry
        return;
      }
      if (choice == _SeriesChoice.thisOne) {
        await widget.onSave(
          updated.copyWith(
            recurrenceRule: buildByDayOnly(_scheduledDays),
          ),
        );
      } else {
        if (widget.onSaveAll != null) {
          await widget.onSaveAll!(updated);
        } else {
          await widget.onSave(updated);
        }
        await widget.onTagsChanged?.call(_selectedTagIds);
        if (mounted) Navigator.of(context).pop();
        return;
      }
    } else {
      await widget.onSave(updated);
    }

    await widget.onTagsChanged?.call(_selectedTagIds);
  }

  /// Called when the sheet is dismissed (swipe, tap outside).
  /// Auto-saves this instance without the series prompt.
  void _onDismissed(bool didPop, Object? result) {
    if (didPop && !_cancelled && !_saved) {
      _save(promptSeries: false);
    }
  }

  Future<void> _confirmDelete() async {
    _saved = true; // prevent auto-save on dismiss
    // Show series prompt only for tasks that genuinely belong to a
    // recurring series — series instances (seriesId set) or tasks
    // carrying an rrule (FREQ-bearing or the BYDAY-only remnant
    // left behind by "End Series"). A `migratedFromTaskId` alone
    // does NOT make a task a series — a one-off carried forward
    // via the `>` migration column is still a one-off.
    final isPartOfSeries = widget.task.isSeriesInstance ||
        widget.task.recurrenceRule != null;
    if (isPartOfSeries && widget.onDeleteAll != null) {
      final choice = await _showSeriesPrompt('Delete');
      if (choice == null) return;
      if (choice == _SeriesChoice.thisOne) {
        // Remove frequency so migration won't recreate it, but
        // keep days for display consistency.
        final (_, days) = parseRRule(widget.task.recurrenceRule);
        await widget.onSave(
          widget.task.copyWith(recurrenceRule: buildByDayOnly(days)),
        );
        // Continue to delete just this instance below.
      } else {
        // Delete all instances in the series.
        if (widget.onDeleteAll != null) {
          widget.onDeleteAll!();
          if (mounted) Navigator.of(context).pop();
          return;
        }
      }
    }

    if (!mounted) return;
    final label = _isEvent ? 'event' : 'task';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_isEvent ? 'Event' : 'Task'}'),
        content: Text(
          'Are you sure you want to delete this $label? '
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
    final itemLabel = _isEvent ? 'event' : 'task';
    return showDialog<_SeriesChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Series'),
        content: Text(
          'This is part of a recurring series. Do you want to '
          '$action this $itemLabel only, or the entire series?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_SeriesChoice.thisOne),
            child: Text('This ${_isEvent ? 'Event' : 'Task'}'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_SeriesChoice.all),
            child: const Text('Entire Series'),
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

  Widget _buildDayPicker(ThemeData theme) {
    // Daily is auto-locked to all 7 days. Monthly / yearly anchor
    // on a day-of-month; their picker selections don't change the
    // saved BYMONTHDAY/BYMONTH but the picker stays interactive
    // because users still expect to tap days to modify a recurring
    // task — same UX as weekly. (Monthly's anchor moves implicitly
    // when the user dots a different day on the board grid.)
    final pickerLocked = _recurrence == RecurrenceFrequency.daily;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Scheduled Days', style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        IgnorePointer(
          ignoring: pickerLocked,
          child: Opacity(
            opacity: pickerLocked ? 0.5 : 1.0,
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
      ],
    );
  }

  Widget _buildTimePicker(ThemeData theme) {
    return InkWell(
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
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.5),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFrequencyDropdown() {
    // Tasks (and events) can pick any frequency. Monthly / yearly
    // anchor on the task's own [createdAt] date — the materializer
    // computes per-week scheduled days from that anchor.
    const frequencies = RecurrenceFrequency.values;

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Repeat',
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RecurrenceFrequency>(
          value: frequencies.contains(_recurrence)
              ? _recurrence
              : RecurrenceFrequency.none,
          isDense: true,
          isExpanded: true,
          items: frequencies
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      onPopInvokedWithResult: _onDismissed,
      child: Padding(
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

            // Tags
            if (widget.availableTags.isNotEmpty) ...[
              Text('Tags', style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.availableTags.map((tag) {
                  final selected = _selectedTagIds.contains(tag.id);
                  final atMax = _selectedTagIds.length >= 4;
                  return FilterChip(
                    label: Text(tag.name),
                    selected: selected,
                    showCheckmark: false,
                    avatar: CircleAvatar(
                      backgroundColor:
                          TagPalette.colorFromValue(tag.color),
                      radius: 6,
                    ),
                    onSelected: (!selected && atMax)
                        ? null
                        : (v) => setState(() {
                              if (v) {
                                _selectedTagIds.add(tag.id);
                              } else {
                                _selectedTagIds.remove(tag.id);
                              }
                            }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

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
              _buildDayPicker(theme),
              const SizedBox(height: 12),
              _buildTimePicker(theme),
              const SizedBox(height: 12),
              _buildFrequencyDropdown(),
            ],

            // Recurrence fields for non-event tasks.
            if (!_isEvent) ...[
              const SizedBox(height: 4),
              _buildDayPicker(theme),
              const SizedBox(height: 12),
              _buildFrequencyDropdown(),
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
                      _saved = true;
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
                if (widget.onReopen != null) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      _saved = true;
                      widget.onReopen!();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('Reopen'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ],
                const Spacer(),
                // Cancel button — discards changes.
                OutlinedButton(
                  onPressed: () {
                    _cancelled = true;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      ),
    );
  }
}
