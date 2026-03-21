import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alpha/features/board/providers/day_summary_provider.dart';
import 'package:alpha/shared/period_utils.dart';
import 'package:alpha/shared/week_utils.dart';

/// Monthly calendar overview. Shows daily activity as colored
/// dots. Tapping a day jumps to the weekly view for that week.
class MonthlyViewScreen extends ConsumerStatefulWidget {
  final void Function(DateTime monday) onDayTap;

  const MonthlyViewScreen({super.key, required this.onDayTap});

  @override
  ConsumerState<MonthlyViewScreen> createState() =>
      _MonthlyViewScreenState();
}

class _MonthlyViewScreenState
    extends ConsumerState<MonthlyViewScreen> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = firstOfMonth(DateTime.now());
  }

  void _goToPrevious() =>
      setState(() => _currentMonth = previousMonth(_currentMonth));
  void _goToNext() =>
      setState(() => _currentMonth = nextMonth(_currentMonth));
  void _goToCurrent() =>
      setState(() => _currentMonth = firstOfMonth(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final title = monthBoardName(_currentMonth);
    final isCurrent =
        _currentMonth == firstOfMonth(DateTime.now());

    final rangeEnd = nextMonth(_currentMonth);
    final summariesAsync = ref.watch(
      daySummariesProvider(_currentMonth, rangeEnd),
    );

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: isCurrent ? null : _goToCurrent,
          child: Text(title),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous month',
            onPressed: _goToPrevious,
          ),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'This month',
            onPressed: isCurrent ? null : _goToCurrent,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next month',
            onPressed: _goToNext,
          ),
        ],
      ),
      body: summariesAsync.when(
        data: (summaries) => _MonthGrid(
          month: _currentMonth,
          summaries: summaries,
          onDayTap: widget.onDayTap,
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final Map<DateTime, DaySummary> summaries;
  final void Function(DateTime monday) onDayTap;

  const _MonthGrid({
    required this.month,
    required this.summaries,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final numDays = daysInMonth(month);
    // weekday: 1=Mon..7=Sun → offset for grid
    final startOffset = firstWeekdayOfMonth(month) - 1;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Day-of-week header row.
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid.
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              itemCount: startOffset + numDays,
              itemBuilder: (context, index) {
                if (index < startOffset) {
                  return const SizedBox.shrink();
                }
                final day = index - startOffset + 1;
                final date = DateTime(month.year, month.month, day);
                final dateKey =
                    DateTime(date.year, date.month, date.day);
                final summary = summaries[dateKey];
                final isToday = dateKey == todayKey;
                final isPast = dateKey.isBefore(todayKey);
                final isFuture = dateKey.isAfter(todayKey);

                return _DayCell(
                  day: day,
                  summary: summary,
                  isToday: isToday,
                  isPast: isPast,
                  isFuture: isFuture,
                  brightness: brightness,
                  onTap: () => onDayTap(mondayOfWeek(date)),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _Legend(brightness: brightness),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final DaySummary? summary;
  final bool isToday;
  final bool isPast;
  final bool isFuture;
  final Brightness brightness;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    this.summary,
    required this.isToday,
    required this.isPast,
    required this.isFuture,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = summary;
    final hasData = s != null && !s.isEmpty;

    // Determine indicator color based on activity.
    Color? indicatorColor;
    if (hasData) {
      if (s.completed > 0 && s.missed == 0) {
        // All good — green.
        indicatorColor = brightness == Brightness.dark
            ? const Color(0xFF8FC4A0)
            : const Color(0xFF3D7A55);
      } else if (s.missed > 0 && s.completed == 0) {
        // All missed — red.
        indicatorColor = brightness == Brightness.dark
            ? const Color(0xFFE57373)
            : const Color(0xFFC0392B);
      } else if (s.missed > 0 && s.completed > 0) {
        // Mixed — orange/amber.
        indicatorColor = brightness == Brightness.dark
            ? const Color(0xFFFFB74D)
            : const Color(0xFFE65100);
      } else if (s.inProgress > 0 || s.scheduled > 0) {
        // Scheduled or in progress — blue.
        indicatorColor = brightness == Brightness.dark
            ? const Color(0xFF6CA6E0)
            : const Color(0xFF2B5E9E);
      } else if (s.events > 0) {
        // Events only — purple.
        indicatorColor = brightness == Brightness.dark
            ? const Color(0xFFC4A0D4)
            : const Color(0xFF5C3A6E);
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          decoration: isToday
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      isToday ? FontWeight.bold : FontWeight.normal,
                  color: isFuture
                      ? theme.colorScheme.onSurface
                          .withValues(alpha: 0.4)
                      : null,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: indicatorColor ??
                      (isPast
                          ? theme.colorScheme.onSurface
                              .withValues(alpha: 0.08)
                          : Colors.transparent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Brightness brightness;

  const _Legend({required this.brightness});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      (
        'Completed',
        brightness == Brightness.dark
            ? const Color(0xFF8FC4A0)
            : const Color(0xFF3D7A55),
      ),
      (
        'Missed',
        brightness == Brightness.dark
            ? const Color(0xFFE57373)
            : const Color(0xFFC0392B),
      ),
      (
        'Mixed',
        brightness == Brightness.dark
            ? const Color(0xFFFFB74D)
            : const Color(0xFFE65100),
      ),
      (
        'Scheduled',
        brightness == Brightness.dark
            ? const Color(0xFF6CA6E0)
            : const Color(0xFF2B5E9E),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.$2,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                item.$1,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
