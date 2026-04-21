import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:planyr/features/column/domain/column_type.dart';
import 'package:planyr/features/column/providers/column_providers.dart';
import 'package:planyr/features/marker/domain/marker_symbol.dart';
import 'package:planyr/features/marker/providers/marker_providers.dart';
import 'package:planyr/features/task/data/ical_export.dart';
import 'package:planyr/features/task/data/ical_import.dart';
import 'package:planyr/features/task/domain/recurrence.dart';
import 'package:planyr/features/task/domain/task.dart';
import 'package:planyr/features/task/providers/task_providers.dart';

/// Full-page screen for creating events, importing, and exporting
/// iCal files. Navigated to from the board grid.
class EventScreen extends ConsumerStatefulWidget {
  final String boardId;

  const EventScreen({super.key, required this.boardId});

  @override
  ConsumerState<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends ConsumerState<EventScreen> {
  static const _uuid = Uuid();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _selectedDays = <int>{};
  TimeOfDay? _scheduledTime;
  RecurrenceFrequency _recurrence = RecurrenceFrequency.none;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // Create event
  // ----------------------------------------------------------

  Future<void> _createEvent() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final tasks = ref.read(taskListProvider(widget.boardId));
    final currentCount = tasks.valueOrNull?.length ?? 0;

    String? timeStr;
    if (_scheduledTime != null) {
      // Convert local TimeOfDay to UTC for storage.
      final now = DateTime.now();
      final localDt = DateTime(
        now.year, now.month, now.day,
        _scheduledTime!.hour, _scheduledTime!.minute,
      );
      final utc = localDt.toUtc();
      timeStr = '${utc.hour.toString().padLeft(2, '0')}:'
          '${utc.minute.toString().padLeft(2, '0')}';
    }

    final rrule = buildRRule(_recurrence, _selectedDays);
    final taskId = _uuid.v4();

    await ref.read(taskActionsProvider).create(
          Task(
            id: taskId,
            boardId: widget.boardId,
            title: title,
            description: _descCtrl.text.trim(),
            position: currentCount,
            createdAt: DateTime.now().toUtc(),
            isEvent: true,
            scheduledTime: timeStr,
            recurrenceRule: rrule,
          ),
        );

    if (_selectedDays.isNotEmpty) {
      await _placeEventMarkers(taskId, _selectedDays);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$title" created')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _placeEventMarkers(
    String taskId,
    Set<int> dayPositions,
  ) async {
    final columnsAsync = ref.read(columnListProvider(widget.boardId));
    final columns = columnsAsync.valueOrNull;
    if (columns == null) return;

    final markerActions = ref.read(markerActionsProvider);
    for (final col in columns) {
      if (col.type == ColumnType.date &&
          dayPositions.contains(col.position)) {
        await markerActions.setMarker(
          boardId: widget.boardId,
          taskId: taskId,
          columnId: col.id,
          symbol: MarkerSymbol.event,
        );
      }
    }
  }

  // ----------------------------------------------------------
  // Import
  // ----------------------------------------------------------

  Future<void> _importICalFile() async {
    final messenger = ScaffoldMessenger.of(context);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ics', 'ical'],
    );
    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    try {
      final content = await File(filePath).readAsString();
      final events = parseICalString(content);

      if (events.isEmpty) {
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('No events found in file')),
          );
        }
        return;
      }

      if (events.length == 1) {
        // Single event — populate the form for review/editing.
        final event = events.first;
        setState(() {
          _titleCtrl.text = event.title;
          _descCtrl.text = event.description;
          _selectedDays
            ..clear()
            ..addAll(event.scheduledDays);
          if (event.scheduledTime != null) {
            final parts = event.scheduledTime!.split(':');
            if (parts.length == 2) {
              // Convert stored UTC time to local for the picker.
              final now = DateTime.now();
              final utcDt = DateTime.utc(
                now.year, now.month, now.day,
                int.parse(parts[0]),
                int.parse(parts[1]),
              );
              final local = utcDt.toLocal();
              _scheduledTime = TimeOfDay(
                hour: local.hour,
                minute: local.minute,
              );
            }
          }
          if (event.recurrenceRule != null &&
              event.recurrenceRule!.contains('FREQ=')) {
            final (freq, _) = parseRRule(event.recurrenceRule);
            _recurrence = freq;
          }
        });
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Event loaded — review and tap Create'),
            ),
          );
        }
        return;
      }

      // Multiple events — import all directly.
      final tasks = ref.read(taskListProvider(widget.boardId));
      var position = tasks.valueOrNull?.length ?? 0;

      for (final event in events) {
        final taskId = _uuid.v4();

        await ref.read(taskActionsProvider).create(
              Task(
                id: taskId,
                boardId: widget.boardId,
                title: event.title,
                description: event.description,
                position: position++,
                createdAt: DateTime.now().toUtc(),
                isEvent: true,
                scheduledTime: event.scheduledTime,
                recurrenceRule: event.recurrenceRule,
                priority: event.priority ?? 0,
              ),
            );

        if (event.scheduledDays.isNotEmpty) {
          await _placeEventMarkers(taskId, event.scheduledDays);
        }
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Imported ${events.length} events — '
              'tap any to edit',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to import: $e')),
        );
      }
    }
  }

  // ----------------------------------------------------------
  // Export
  // ----------------------------------------------------------

  Future<void> _exportICalFile() async {
    final messenger = ScaffoldMessenger.of(context);

    final tasks = ref.read(taskListProvider(widget.boardId));
    final allTasks = tasks.valueOrNull ?? [];
    final eventTasks = allTasks.where((t) => t.isEvent).toList();

    if (eventTasks.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No events to export')),
      );
      return;
    }

    final icsContent = exportTasksToICal(eventTasks);

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Events',
      fileName: 'alpha-events.ics',
      allowedExtensions: ['ics'],
      type: FileType.custom,
    );

    if (outputPath == null) return;

    try {
      await File(outputPath).writeAsString(icsContent);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Exported ${eventTasks.length} event'
              '${eventTasks.length == 1 ? '' : 's'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to export: $e')),
        );
      }
    }
  }

  // ----------------------------------------------------------
  // Build
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open),
            tooltip: 'Import iCal',
            onPressed: _importICalFile,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export iCal',
            onPressed: _exportICalFile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Event title',
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
            const SizedBox(height: 20),

            // Day picker
            Text('Days', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            IgnorePointer(
              ignoring: _recurrence == RecurrenceFrequency.daily,
              child: Opacity(
                opacity:
                    _recurrence == RecurrenceFrequency.daily ? 0.5 : 1.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (i) {
                    final selected = _selectedDays.contains(i);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) {
                          _selectedDays.remove(i);
                        } else {
                          _selectedDays.add(i);
                        }
                      }),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Text(
                          dayLabels[i].substring(0, 1),
                          style: TextStyle(
                            fontSize: 14,
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
            const SizedBox(height: 20),

            // Time picker
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _scheduledTime ??
                      const TimeOfDay(hour: 9, minute: 0),
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
            ),
            const SizedBox(height: 16),

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
                          _selectedDays
                            ..clear()
                            ..addAll({0, 1, 2, 3, 4, 5, 6});
                        }
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Create button
            FilledButton.icon(
              onPressed: _createEvent,
              icon: const Icon(Icons.event),
              label: const Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }
}
