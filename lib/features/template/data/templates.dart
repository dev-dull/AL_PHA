import 'package:alpha/features/board/domain/board_type.dart';
import 'package:alpha/features/column/domain/column_type.dart';
import 'package:alpha/features/template/domain/board_template.dart';

final defaultTemplates = [
  BoardTemplate(
    id: 'weekly',
    name: 'Weekly',
    description: 'Track tasks across days of the week',
    boardType: BoardType.weekly,
    columns: [
      for (final (i, day) in [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ].indexed)
        TemplateColumn(label: day, position: i, type: ColumnType.date),
    ],
  ),
  BoardTemplate(
    id: 'monthly',
    name: 'Monthly',
    description: 'Track tasks across days of the month',
    boardType: BoardType.monthly,
    columns: [
      for (var i = 1; i <= 31; i++)
        TemplateColumn(
          label: i.toString(),
          position: i - 1,
          type: ColumnType.date,
        ),
    ],
  ),
  BoardTemplate(
    id: 'gtd-contexts',
    name: 'GTD Contexts',
    description: 'Organize tasks by context (phone, computer, errands, etc.)',
    boardType: BoardType.custom,
    columns: [
      for (final (i, ctx) in [
        '@Phone',
        '@Computer',
        '@Errands',
        '@Home',
        '@Office',
        '@Waiting For',
        '@Agenda',
      ].indexed)
        TemplateColumn(label: ctx, position: i, type: ColumnType.context),
    ],
  ),
  BoardTemplate(
    id: 'daily-hourly',
    name: 'Daily Hourly',
    description: 'Plan tasks across hours of the day',
    boardType: BoardType.daily,
    columns: [
      for (var h = 6; h <= 22; h++)
        TemplateColumn(
          label: '${h > 12 ? h - 12 : h}${h >= 12 ? 'PM' : 'AM'}',
          position: h - 6,
          type: ColumnType.date,
        ),
    ],
  ),
  BoardTemplate(
    id: 'project-tracker',
    name: 'Project Tracker',
    description: 'Kanban-style project tracking',
    boardType: BoardType.custom,
    columns: [
      for (final (i, stage) in [
        'To Do',
        'In Progress',
        'Review',
        'Done',
      ].indexed)
        TemplateColumn(label: stage, position: i, type: ColumnType.custom),
    ],
  ),
];
