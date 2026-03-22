import 'package:flutter/material.dart';
import 'package:alpha/app/theme.dart';
import 'package:alpha/features/marker/domain/marker_symbol.dart';
import 'package:alpha/features/marker/presentation/marker_cell.dart';

/// Shows a dialog explaining the Alastair Method marker symbols
/// and basic workflow.
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

    return AlertDialog(
      title: const Text('The Alastair Method'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan your week by scheduling dots on the days '
              'you intend to work on each task. Update markers '
              'as you go.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _LegendRow(
              symbol: MarkerSymbol.dot,
              brightness: brightness,
              label: 'Scheduled',
              description: 'Tap an empty cell to schedule',
            ),
            _LegendRow(
              symbol: MarkerSymbol.slash,
              brightness: brightness,
              label: 'In Progress',
              description: 'Started but not finished',
            ),
            _LegendRow(
              symbol: MarkerSymbol.x,
              brightness: brightness,
              label: 'Done',
              description: 'Task completed',
            ),
            _LegendRow(
              symbol: MarkerSymbol.migratedForward,
              brightness: brightness,
              label: 'Migrated',
              description: 'Pushed to next week',
            ),
            _LegendRow(
              symbol: MarkerSymbol.doneEarly,
              brightness: brightness,
              label: 'Done Early',
              description: 'Auto-filled after completion',
            ),
            _LegendRow(
              symbol: MarkerSymbol.event,
              brightness: brightness,
              label: 'Event',
              description: 'Scheduled event or appointment',
            ),
            const SizedBox(height: 12),
            Text(
              'Tips',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '\u2022 Tap a marker to cycle or pick from the radial menu\n'
              '\u2022 Tasks auto-migrate when the week ends\n'
              '\u2022 Tap the > column to manually push a task forward\n'
              '\u2022 Use the sort button in the header to reorder',
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

class _LegendRow extends StatelessWidget {
  final MarkerSymbol symbol;
  final Brightness brightness;
  final String label;
  final String description;

  const _LegendRow({
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
              child: Text(
                symbol.displayChar,
                style: TextStyle(
                  fontFamily: 'PatrickHand',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
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
