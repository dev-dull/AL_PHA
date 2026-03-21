import 'package:alpha/features/task/domain/task.dart';

/// Builds an iCal (.ics) string from a list of event [Task]s.
String exportTasksToICal(List<Task> tasks) {
  final buf = StringBuffer()
    ..writeln('BEGIN:VCALENDAR')
    ..writeln('VERSION:2.0')
    ..writeln('PRODID:-//AlPHA//Alastair Method//EN')
    ..writeln('CALSCALE:GREGORIAN');

  for (final task in tasks) {
    if (!task.isEvent) continue;

    buf.writeln('BEGIN:VEVENT');
    buf.writeln('UID:${task.id}');
    buf.writeln(
      'DTSTAMP:${_formatDateTime(task.createdAt)}',
    );

    // DTSTART — use scheduled time if available, otherwise all-day.
    final start = task.createdAt;
    if (task.scheduledTime != null) {
      final parts = task.scheduledTime!.split(':');
      final dt = DateTime(
        start.year,
        start.month,
        start.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      buf.writeln('DTSTART:${_formatDateTime(dt)}');
      // Default 1-hour duration.
      buf.writeln(
        'DTEND:${_formatDateTime(dt.add(const Duration(hours: 1)))}',
      );
    } else {
      // All-day event.
      buf.writeln('DTSTART;VALUE=DATE:${_formatDate(start)}');
    }

    buf.writeln('SUMMARY:${_escapeText(task.title)}');
    if (task.description.isNotEmpty) {
      buf.writeln(
        'DESCRIPTION:${_escapeText(task.description)}',
      );
    }

    if (task.recurrenceRule != null) {
      buf.writeln('RRULE:${task.recurrenceRule}');
    }

    if (task.priority > 0) {
      // Map app priority (1=Low,2=Med,3=High) → iCal (7,5,1).
      const mapping = {1: 7, 2: 5, 3: 1};
      buf.writeln('PRIORITY:${mapping[task.priority] ?? 0}');
    }

    buf.writeln('END:VEVENT');
  }

  buf.writeln('END:VCALENDAR');
  return buf.toString();
}

/// Format DateTime as iCal UTC timestamp: 20260321T143000Z.
String _formatDateTime(DateTime dt) {
  final utc = dt.toUtc();
  return '${utc.year}'
      '${utc.month.toString().padLeft(2, '0')}'
      '${utc.day.toString().padLeft(2, '0')}'
      'T${utc.hour.toString().padLeft(2, '0')}'
      '${utc.minute.toString().padLeft(2, '0')}'
      '${utc.second.toString().padLeft(2, '0')}Z';
}

/// Format DateTime as iCal date: 20260321.
String _formatDate(DateTime dt) {
  return '${dt.year}'
      '${dt.month.toString().padLeft(2, '0')}'
      '${dt.day.toString().padLeft(2, '0')}';
}

/// Escape special characters for iCal text values.
String _escapeText(String text) {
  return text
      .replaceAll(r'\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll('\n', r'\n');
}
