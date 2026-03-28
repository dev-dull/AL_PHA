import 'package:enough_icalendar/enough_icalendar.dart';
import 'package:alpha/features/task/domain/task.dart';
import 'package:uuid/uuid.dart';

/// Represents a parsed event from an iCal file.
class ParsedEvent {
  final String title;
  final String description;
  final String? scheduledTime;
  final String? recurrenceRule;
  final Set<int> scheduledDays;
  final DateTime? startDate;
  final int? priority;

  const ParsedEvent({
    required this.title,
    this.description = '',
    this.scheduledTime,
    this.recurrenceRule,
    this.scheduledDays = const {},
    this.startDate,
    this.priority,
  });
}

const _uuid = Uuid();

/// Parses an iCal (.ics) string and returns a list of events.
List<ParsedEvent> parseICalString(String icsContent) {
  final calendar = VComponent.parse(icsContent);
  final events = <ParsedEvent>[];

  final components = calendar is VCalendar
      ? calendar.children
      : [calendar];

  for (final component in components) {
    if (component is! VEvent) continue;

    final summary = component.summary ?? 'Untitled Event';
    final rawDescription = component.description ?? '';
    // Strip HTML tags if the description contains them.
    final description = rawDescription.contains('<')
        ? rawDescription
            .replaceAll(RegExp(r'<br\s*/?>'), '\n')
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'&nbsp;'), ' ')
            .replaceAll(RegExp(r'&amp;'), '&')
            .replaceAll(RegExp(r'&lt;'), '<')
            .replaceAll(RegExp(r'&gt;'), '>')
            .replaceAll(RegExp(r'&quot;'), '"')
            .replaceAll(RegExp(r'&#39;'), "'")
            .trim()
        : rawDescription;

    // Extract time from DTSTART.
    String? scheduledTime;
    DateTime? startDate;
    final dtStart = component.start;
    if (dtStart != null) {
      startDate = dtStart;
      final hour = dtStart.hour.toString().padLeft(2, '0');
      final minute = dtStart.minute.toString().padLeft(2, '0');
      // Only set time if it's not midnight (all-day events).
      if (dtStart.hour != 0 || dtStart.minute != 0) {
        scheduledTime = '$hour:$minute';
      }
    }

    // Extract recurrence rule.
    String? rrule;
    final rruleProp = component.getProperty('RRULE');
    if (rruleProp != null) {
      rrule = rruleProp.textValue;
    }

    // Determine scheduled days from RRULE BYDAY or from start date.
    final days = <int>{};
    if (rrule != null && rrule.contains('BYDAY=')) {
      final match = RegExp(r'BYDAY=([A-Z,]+)').firstMatch(rrule);
      if (match != null) {
        const icalDays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
        for (final d in match.group(1)!.split(',')) {
          // Strip numeric prefix (e.g., "1MO" → "MO").
          final cleaned = d.replaceAll(RegExp(r'[^A-Z]'), '');
          final idx = icalDays.indexOf(cleaned);
          if (idx >= 0) days.add(idx);
        }
      }
    } else if (startDate != null) {
      // No BYDAY — use the start date's weekday.
      // DateTime.weekday: 1=Mon..7=Sun → column position 0-6.
      days.add(startDate.weekday - 1);
    }

    // Map iCal priority (1=highest, 9=lowest) to app priority (0-3).
    int? priority;
    final priProp = component.getProperty('PRIORITY');
    if (priProp != null) {
      final icalPri = int.tryParse(priProp.textValue) ?? 0;
      if (icalPri >= 1 && icalPri <= 3) {
        priority = 3; // High
      } else if (icalPri >= 4 && icalPri <= 6) {
        priority = 2; // Medium
      } else if (icalPri >= 7) {
        priority = 1; // Low
      }
    }

    events.add(ParsedEvent(
      title: summary,
      description: description,
      scheduledTime: scheduledTime,
      recurrenceRule: rrule,
      scheduledDays: days,
      startDate: startDate,
      priority: priority,
    ));
  }

  return events;
}

/// Converts a ParsedEvent to a Task domain object.
Task parsedEventToTask({
  required ParsedEvent event,
  required String boardId,
  required int position,
}) {
  return Task(
    id: _uuid.v4(),
    boardId: boardId,
    title: event.title,
    description: event.description,
    position: position,
    createdAt: DateTime.now(),
    isEvent: true,
    scheduledTime: event.scheduledTime,
    recurrenceRule: event.recurrenceRule,
    priority: event.priority ?? 0,
  );
}
