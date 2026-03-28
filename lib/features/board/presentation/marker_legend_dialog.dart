import 'package:flutter/material.dart';
import 'package:alpha/app/theme.dart';
import 'package:alpha/features/marker/domain/marker_symbol.dart';
import 'package:alpha/features/marker/presentation/marker_cell.dart';

/// Shows a dialog explaining the app's features and workflow.
Future<void> showMarkerLegend(BuildContext context) {
  return showDialog(
    context: context,
    builder: (ctx) => const _MarkerLegendDialog(),
  );
}

class _MarkerLegendDialog extends StatelessWidget {
  const _MarkerLegendDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final migrationColor = brightness == Brightness.dark
        ? const Color(0xFFA09A94)
        : const Color(0xFF6B6560);

    return AlertDialog(
      title: const Text('How It Works'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Markers ──────────────────────────────
            Text(
              'Plan your week by placing dots on the days you '
              'intend to work on each task, then update them '
              'as you go.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('Markers', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _MarkerRow(
              symbol: MarkerSymbol.dot,
              brightness: brightness,
              label: 'Scheduled',
              description: 'Tap an empty cell to schedule',
            ),
            _MarkerRow(
              symbol: MarkerSymbol.slash,
              brightness: brightness,
              label: 'In Progress',
              description: 'Started but not finished',
            ),
            _MarkerRow(
              symbol: MarkerSymbol.x,
              brightness: brightness,
              label: 'Done',
              description: 'Task completed',
            ),
            _MarkerRow(
              symbol: MarkerSymbol.migratedForward,
              brightness: brightness,
              label: 'Migrated',
              description: 'Missed day, auto-filled',
            ),
            _MarkerRow(
              symbol: MarkerSymbol.doneEarly,
              brightness: brightness,
              label: 'Done Early',
              description: 'Auto-filled after marking done',
            ),
            _MarkerRow(
              symbol: MarkerSymbol.event,
              brightness: brightness,
              label: 'Event',
              description: 'Scheduled event or appointment',
            ),

            // ── Migration column ─────────────────────
            const SizedBox(height: 12),
            Text('Migration Column',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _IconRow(
              icon: Text(
                '>',
                style: TextStyle(
                  fontFamily: 'PatrickHand',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: migrationColor,
                ),
              ),
              label: 'Migrate',
              description: 'Tap to push a task to next week',
            ),
            _IconRow(
              icon: Icon(
                Icons.event,
                size: 18,
                color: migrationColor,
              ),
              label: 'Event',
              description: 'One-time event or appointment',
            ),
            _IconRow(
              icon: Icon(
                Icons.autorenew,
                size: 18,
                color: migrationColor,
              ),
              label: 'Recurring Task',
              description: 'Auto-migrates each week',
            ),
            _IconRow(
              icon: Icon(
                Icons.event_repeat,
                size: 18,
                color: migrationColor,
              ),
              label: 'Recurring Event',
              description: 'Auto-migrates each week',
            ),

            // ── Features ─────────────────────────────
            const SizedBox(height: 12),
            Text('Features', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              '\u2022 Tap a marker to cycle or pick from '
              'the radial menu\n'
              '\u2022 Tap a task name to edit details, add '
              'notes, or set tags\n'
              '\u2022 Set a repeat schedule to make tasks '
              'recur weekly\n'
              "\u2022 Mark tasks as \"Won't Do\" from the "
              'edit sheet\n'
              '\u2022 Color-coded tags \u2014 create in '
              'Settings, assign up to 4 per task\n'
              '\u2022 Sort tasks via the button in the '
              'header row\n'
              '\u2022 Tasks auto-migrate when the week ends\n'
              '\u2022 Monthly and yearly views show '
              'completion at a glance',
              style: theme.textTheme.bodySmall,
            ),

            // ── Settings ─────────────────────────────
            const SizedBox(height: 12),
            Text('Settings', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              '\u2022 Font: handwritten or system default\n'
              '\u2022 Appearance: light, dark, or system\n'
              '\u2022 First day of week: Monday or Sunday\n'
              '\u2022 Tag management: create, edit, delete\n'
              '\u2022 Export data as JSON from the \u22EE menu',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}

/// Renders a marker symbol + label + description row.
/// Uses the same hand-drawn rendering as MarkerCell.
class _MarkerRow extends StatelessWidget {
  final MarkerSymbol symbol;
  final Brightness brightness;
  final String label;
  final String description;

  const _MarkerRow({
    required this.symbol,
    required this.brightness,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AlphaTheme.markerColor(symbol, brightness);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: MarkerCell.cellSize * 0.6,
            child: Center(
              child: MarkerCell.buildMarkerWidget(symbol, color),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic row with a custom icon widget + label + description.
class _IconRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String description;

  const _IconRow({
    required this.icon,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: MarkerCell.cellSize * 0.6,
            child: Center(child: icon),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
