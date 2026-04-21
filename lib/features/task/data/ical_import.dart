import 'package:enough_icalendar/enough_icalendar.dart';
import 'package:planyr/features/task/domain/task.dart';
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

/// Converts an HTML string to readable plain text.
///
/// Handles block elements (p, div, h1-h6), line breaks (br),
/// lists (ul/ol with li → bullet points), horizontal rules,
/// inline formatting (stripped), and common HTML entities.
/// Collapses excessive whitespace.
String _htmlToPlainText(String html) {
  if (!html.contains('<')) return html;

  var text = html;

  // Block elements → double newline.
  text = text.replaceAll(
      RegExp(r'</(p|div|h[1-6]|blockquote)>', caseSensitive: false), '\n\n');
  text = text.replaceAll(
      RegExp(r'<(p|div|h[1-6]|blockquote)\b[^>]*>', caseSensitive: false), '');

  // Horizontal rules.
  text = text.replaceAll(RegExp(r'<hr\s*/?>',caseSensitive: false), '\n---\n');

  // Line breaks.
  text = text.replaceAll(RegExp(r'<br\s*/?>',caseSensitive: false), '\n');

  // List items → bullet points.
  text = text.replaceAll(
      RegExp(r'<li\b[^>]*>', caseSensitive: false), '\n\u2022 ');
  text = text.replaceAll(RegExp(r'</li>', caseSensitive: false), '');

  // List containers → newline.
  text = text.replaceAll(
      RegExp(r'</?[ou]l\b[^>]*>', caseSensitive: false), '\n');

  // Strip all remaining tags.
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');

  // Decode common HTML entities.
  text = text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&#x27;', "'")
      .replaceAll('&mdash;', '\u2014')
      .replaceAll('&ndash;', '\u2013')
      .replaceAll('&hellip;', '\u2026')
      .replaceAll('&copy;', '\u00A9')
      .replaceAll('&reg;', '\u00AE')
      .replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
        final code = int.tryParse(m.group(1)!);
        return code != null ? String.fromCharCode(code) : m.group(0)!;
      })
      .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
        final code = int.tryParse(m.group(1)!, radix: 16);
        return code != null ? String.fromCharCode(code) : m.group(0)!;
      });

  // Collapse whitespace: 3+ newlines → 2, trailing spaces per line.
  text = text.replaceAll(RegExp(r' +'), ' ');
  text = text.replaceAll(RegExp(r'\n '), '\n');
  text = text.replaceAll(RegExp(r' \n'), '\n');
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  return text.trim();
}

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
    // Convert HTML to readable plain text. If a second use-case
    // for HTML rendering arises, consider a proper widget instead.
    // See: https://github.com/dev-dull/AL_PHA/issues/34
    final description = _htmlToPlainText(rawDescription);

    // Extract time from DTSTART.
    String? scheduledTime;
    DateTime? startDate;
    final dtStart = component.start;
    if (dtStart != null) {
      startDate = dtStart;
      // Convert to UTC for storage.
      final utc = dtStart.toUtc();
      final hour = utc.hour.toString().padLeft(2, '0');
      final minute = utc.minute.toString().padLeft(2, '0');
      // Only set time if it's not midnight (all-day events).
      if (utc.hour != 0 || utc.minute != 0) {
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
    createdAt: DateTime.now().toUtc(),
    isEvent: true,
    scheduledTime: event.scheduledTime,
    recurrenceRule: event.recurrenceRule,
    priority: event.priority ?? 0,
  );
}
