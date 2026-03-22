import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:alpha/features/board/providers/day_summary_provider.dart';
import 'package:alpha/features/preferences/providers/preferences_providers.dart';
import 'package:alpha/shared/period_utils.dart';
import 'package:alpha/shared/week_utils.dart';

/// Yearly overview showing 12 mini-month calendars.
/// Each day is a small colored square based on task activity.
/// Tapping a day jumps to the weekly view for that week.
class YearlyViewScreen extends ConsumerStatefulWidget {
  final void Function(DateTime monday) onDayTap;

  const YearlyViewScreen({super.key, required this.onDayTap});

  @override
  ConsumerState<YearlyViewScreen> createState() =>
      _YearlyViewScreenState();
}

class _YearlyViewScreenState
    extends ConsumerState<YearlyViewScreen> {
  late DateTime _currentYear;

  @override
  void initState() {
    super.initState();
    _currentYear = firstOfYear(DateTime.now());
  }

  void _goToPrevious() =>
      setState(() => _currentYear = previousYear(_currentYear));
  void _goToNext() =>
      setState(() => _currentYear = nextYear(_currentYear));
  void _goToCurrent() =>
      setState(() => _currentYear = firstOfYear(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final title = yearBoardName(_currentYear);
    final isCurrent =
        _currentYear == firstOfYear(DateTime.now());

    final rangeEnd = nextYear(_currentYear);
    final summariesAsync = ref.watch(
      daySummariesProvider(_currentYear, rangeEnd),
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
            tooltip: 'Previous year',
            onPressed: _goToPrevious,
          ),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'This year',
            onPressed: isCurrent ? null : _goToCurrent,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next year',
            onPressed: _goToNext,
          ),
        ],
      ),
      body: summariesAsync.when(
        data: (summaries) => _YearGrid(
          year: _currentYear,
          summaries: summaries,
          onDayTap: widget.onDayTap,
          firstDay: ref.watch(preferencesProvider).firstDayOfWeek,
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _YearGrid extends StatelessWidget {
  final DateTime year;
  final Map<DateTime, DaySummary> summaries;
  final void Function(DateTime weekStart) onDayTap;
  final int firstDay;

  const _YearGrid({
    required this.year,
    required this.summaries,
    required this.onDayTap,
    required this.firstDay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.85,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 12,
        itemBuilder: (context, monthIndex) {
          final monthStart =
              DateTime(year.year, monthIndex + 1);
          return _MiniMonth(
            monthStart: monthStart,
            summaries: summaries,
            onDayTap: onDayTap,
            firstDay: firstDay,
          );
        },
      ),
    );
  }
}

class _MiniMonth extends StatelessWidget {
  final DateTime monthStart;
  final Map<DateTime, DaySummary> summaries;
  final void Function(DateTime weekStart) onDayTap;
  final int firstDay;

  const _MiniMonth({
    required this.monthStart,
    required this.summaries,
    required this.onDayTap,
    required this.firstDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final numDays = daysInMonth(monthStart);
    final startOffset =
        firstWeekdayOffset(monthStart, firstDay: firstDay);
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final monthName = DateFormat.MMM().format(monthStart);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Text(
            monthName,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
            ),
            itemCount: startOffset + numDays,
            itemBuilder: (context, index) {
              if (index < startOffset) {
                return const SizedBox.shrink();
              }
              final day = index - startOffset + 1;
              final date =
                  DateTime(monthStart.year, monthStart.month, day);
              final dateKey =
                  DateTime(date.year, date.month, date.day);
              final summary = summaries[dateKey];
              final isToday = dateKey == todayKey;

              return _MiniDayCell(
                day: day,
                summary: summary,
                isToday: isToday,
                isPast: dateKey.isBefore(todayKey),
                brightness: brightness,
                onTap: () => onDayTap(
                    startOfWeek(date, firstDay: firstDay)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniDayCell extends StatelessWidget {
  final int day;
  final DaySummary? summary;
  final bool isToday;
  final bool isPast;
  final Brightness brightness;
  final VoidCallback onTap;

  const _MiniDayCell({
    required this.day,
    this.summary,
    required this.isToday,
    required this.isPast,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = summary;
    final hasData = s != null && !s.isEmpty;

    Color bgColor;
    if (hasData) {
      final rate = s.completionRate;
      final red = brightness == Brightness.dark
          ? const Color(0xFFE57373)
          : const Color(0xFFC0392B);
      final green = brightness == Brightness.dark
          ? const Color(0xFF8FC4A0)
          : const Color(0xFF3D7A55);
      bgColor = Color.lerp(red, green, rate)!;
    } else {
      bgColor = isPast
          ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
          : Colors.transparent;
    }

    // Pick a legible text color against the background.
    final textColor = hasData
        ? (ThemeData.estimateBrightnessForColor(bgColor) ==
                Brightness.dark
            ? Colors.white70
            : Colors.black54)
        : theme.colorScheme.onSurface.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: bgColor,
          border: isToday
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 7,
            height: 1,
            fontWeight:
                isToday ? FontWeight.bold : FontWeight.normal,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
