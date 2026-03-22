import 'dart:convert';
import 'dart:io';

import 'package:alpha/shared/database.dart';
import 'package:path_provider/path_provider.dart';

/// Exports all app data as a JSON file and returns the file path.
Future<String> exportDataAsJson(AlphaDatabase db) async {
  final boards = await db.select(db.boards).get();
  final columns = await db.select(db.boardColumns).get();
  final tasks = await db.select(db.tasks).get();
  final markers = await db.select(db.markers).get();
  final notes = await db.select(db.taskNotes).get();

  final data = {
    'exportedAt': DateTime.now().toIso8601String(),
    'version': db.schemaVersion,
    'boards': boards
        .map((b) => {
              'id': b.id,
              'name': b.name,
              'type': b.type,
              'createdAt': b.createdAt.toIso8601String(),
              'updatedAt': b.updatedAt.toIso8601String(),
              'archived': b.archived,
              'weekStart': b.weekStart?.toIso8601String(),
            })
        .toList(),
    'columns': columns
        .map((c) => {
              'id': c.id,
              'boardId': c.boardId,
              'label': c.label,
              'position': c.position,
              'type': c.type,
            })
        .toList(),
    'tasks': tasks
        .map((t) => {
              'id': t.id,
              'boardId': t.boardId,
              'title': t.title,
              'description': t.description,
              'state': t.state,
              'priority': t.priority,
              'position': t.position,
              'createdAt': t.createdAt.toIso8601String(),
              'completedAt': t.completedAt?.toIso8601String(),
              'deadline': t.deadline?.toIso8601String(),
              'migratedFromBoardId': t.migratedFromBoardId,
              'migratedFromTaskId': t.migratedFromTaskId,
              'isEvent': t.isEvent,
              'scheduledTime': t.scheduledTime,
              'recurrenceRule': t.recurrenceRule,
            })
        .toList(),
    'markers': markers
        .map((m) => {
              'id': m.id,
              'taskId': m.taskId,
              'columnId': m.columnId,
              'boardId': m.boardId,
              'symbol': m.symbol,
              'updatedAt': m.updatedAt.toIso8601String(),
            })
        .toList(),
    'notes': notes
        .map((n) => {
              'id': n.id,
              'taskId': n.taskId,
              'content': n.content,
              'createdAt': n.createdAt.toIso8601String(),
              'updatedAt': n.updatedAt.toIso8601String(),
            })
        .toList(),
  };

  final dir = await getApplicationDocumentsDirectory();
  final timestamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .split('.')
      .first;
  final file = File('${dir.path}/alpha_export_$timestamp.json');
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(data),
  );
  return file.path;
}
