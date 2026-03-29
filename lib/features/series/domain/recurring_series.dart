import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurring_series.freezed.dart';
part 'recurring_series.g.dart';

@freezed
abstract class RecurringSeries with _$RecurringSeries {
  const RecurringSeries._();

  const factory RecurringSeries({
    required String id,
    required String title,
    @Default('') String description,
    @Default(0) int priority,
    required String recurrenceRule,
    @Default(false) bool isEvent,
    String? scheduledTime,
    required DateTime createdAt,
    DateTime? endedAt,
  }) = _RecurringSeries;

  bool get isActive => endedAt == null;

  factory RecurringSeries.fromJson(Map<String, dynamic> json) =>
      _$RecurringSeriesFromJson(json);
}
