import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:alpha/app/theme.dart';
import 'package:alpha/features/marker/domain/marker.dart';
import 'package:alpha/features/marker/domain/marker_symbol.dart';
import 'package:alpha/features/marker/providers/marker_providers.dart';
import 'package:alpha/shared/providers.dart';

/// A single cell in the board grid matrix.
///
/// Displays the current marker symbol (or empty) at the
/// intersection of a task row and a column. Supports
/// tap-to-cycle and long-press to pick any symbol.
class MarkerCell extends ConsumerWidget {
  final String boardId;
  final String taskId;
  final String columnId;

  /// Cell dimensions in logical pixels.
  static const double cellSize = 48;

  static const _uuid = Uuid();

  const MarkerCell({
    super.key,
    required this.boardId,
    required this.taskId,
    required this.columnId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marker = ref.watch(
      markerFromBoardProvider(boardId, taskId, columnId),
    );

    final symbol = marker?.symbol;
    final brightness = Theme.of(context).brightness;
    final color = symbol != null
        ? AlphaTheme.markerColor(symbol, brightness)
        : null;

    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => _onTap(ref),
          onLongPress: () => _onLongPress(context, ref, marker),
          child: Center(
            child: Text(
              symbol?.displayChar ?? '',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(WidgetRef ref) {
    ref.read(markerActionsProvider).cycleMarker(
          boardId: boardId,
          taskId: taskId,
          columnId: columnId,
        );
  }

  void _onLongPress(
    BuildContext context,
    WidgetRef ref,
    Marker? currentMarker,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _MarkerPickerSheet(
        currentSymbol: currentMarker?.symbol,
        onSelected: (symbol) async {
          Navigator.of(ctx).pop();
          final repo = ref.read(markerRepositoryProvider);

          if (symbol == null) {
            // Clear
            await repo.remove(taskId, columnId);
          } else {
            if (currentMarker != null) {
              await repo.set(currentMarker.copyWith(
                symbol: symbol,
                updatedAt: DateTime.now(),
              ));
            } else {
              await repo.set(Marker(
                id: _uuid.v4(),
                taskId: taskId,
                columnId: columnId,
                boardId: boardId,
                symbol: symbol,
                updatedAt: DateTime.now(),
              ));
            }
          }
        },
      ),
    );
  }
}

/// Bottom sheet listing all marker symbols plus a Clear option.
class _MarkerPickerSheet extends StatelessWidget {
  final MarkerSymbol? currentSymbol;
  final ValueChanged<MarkerSymbol?> onSelected;

  const _MarkerPickerSheet({
    required this.currentSymbol,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Set Marker',
              style: theme.textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          ...MarkerSymbol.values.map((symbol) {
            final color =
                AlphaTheme.markerColor(symbol, theme.brightness);
            final isSelected = symbol == currentSymbol;
            return ListTile(
              leading: Text(
                symbol.displayChar,
                style: TextStyle(
                  fontSize: 22,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              title: Text(symbol.displayName),
              trailing: isSelected
                  ? Icon(
                      Icons.check,
                      color: theme.colorScheme.primary,
                    )
                  : null,
              onTap: () => onSelected(symbol),
            );
          }),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.clear,
              color: theme.colorScheme.error,
            ),
            title: const Text('Clear'),
            onTap: () => onSelected(null),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
