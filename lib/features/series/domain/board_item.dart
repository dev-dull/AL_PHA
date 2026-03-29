import 'package:alpha/features/series/domain/recurring_series.dart';
import 'package:alpha/features/tag/domain/tag.dart';
import 'package:alpha/features/task/domain/task.dart';

/// A row displayed on the board grid — either a real task from
/// the DB or a virtual instance of a recurring series.
sealed class BoardItem {
  String get displayId;
  String get title;
  String get description;
  int get priority;
  bool get isEvent;
  String? get scheduledTime;
  String? get recurrenceRule;
  bool get isRecurring;
  bool get isVirtual;
}

class RealTask implements BoardItem {
  final Task task;

  const RealTask(this.task);

  @override
  String get displayId => task.id;
  @override
  String get title => task.title;
  @override
  String get description => task.description;
  @override
  int get priority => task.priority;
  @override
  bool get isEvent => task.isEvent;
  @override
  String? get scheduledTime => task.scheduledTime;
  @override
  String? get recurrenceRule => task.recurrenceRule;
  @override
  bool get isRecurring => task.isRecurring;
  @override
  bool get isVirtual => false;
}

class VirtualTask implements BoardItem {
  final RecurringSeries series;
  final Set<int> scheduledDays;
  final List<Tag> tags;

  const VirtualTask({
    required this.series,
    required this.scheduledDays,
    this.tags = const [],
  });

  @override
  String get displayId => 'virtual_${series.id}';
  @override
  String get title => series.title;
  @override
  String get description => series.description;
  @override
  int get priority => series.priority;
  @override
  bool get isEvent => series.isEvent;
  @override
  String? get scheduledTime => series.scheduledTime;
  @override
  String? get recurrenceRule => series.recurrenceRule;
  @override
  bool get isRecurring => true;
  @override
  bool get isVirtual => true;
}
