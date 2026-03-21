import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alpha/app/theme.dart';
import 'package:alpha/features/column/domain/column_type.dart';
import 'package:alpha/features/marker/domain/marker.dart';
import 'package:alpha/features/marker/domain/marker_symbol.dart';
import 'package:alpha/features/marker/providers/marker_providers.dart';

/// A single cell in the board grid matrix.
///
/// Tap an empty cell → sets a dot immediately.
/// Tap a cell with a symbol → shows a radial menu to pick
/// any symbol or clear.
class MarkerCell extends ConsumerWidget {
  final String boardId;
  final String taskId;
  final String columnId;
  final ColumnType columnType;
  final bool isEvent;

  /// Whether the event has a recurring schedule (FREQ= in RRULE).
  final bool isRecurring;

  /// Called when an event cell is tapped on a day column, so the
  /// parent can open the task detail sheet instead of toggling markers.
  final VoidCallback? onEventTap;

  /// Cell dimensions in logical pixels.
  static const double cellSize = 48;

  const MarkerCell({
    super.key,
    required this.boardId,
    required this.taskId,
    required this.columnId,
    this.columnType = ColumnType.date,
    this.isEvent = false,
    this.isRecurring = false,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marker = ref.watch(
      markerFromBoardProvider(boardId, taskId, columnId),
    );

    final symbol = marker?.symbol;
    final brightness = Theme.of(context).brightness;
    final isMigration = columnType != ColumnType.date;
    final color = symbol != null
        ? (isMigration
            ? (brightness == Brightness.dark
                ? const Color(0xFFA09A94)
                : const Color(0xFF6B6560))
            : AlphaTheme.markerColor(symbol, brightness))
        : null;

    // Migration column for events: show calendar/repeat icon.
    Widget child;
    if (isMigration && isEvent && symbol != null) {
      child = Icon(
        isRecurring ? Icons.event_repeat : Icons.event,
        size: 18,
        color: color,
      );
    } else {
      child = Text(
        symbol?.displayChar ?? '',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      );
    }

    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => _onTap(context, ref, marker),
          child: Center(child: child),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, Marker? marker) {
    final isMigration = columnType != ColumnType.date;

    if (isMigration) {
      // Migration column: simple toggle > ↔ empty.
      ref.read(markerActionsProvider).cycleMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: columnId,
      );
    } else if (isEvent && onEventTap != null) {
      // Event on a day column — open the edit sheet.
      onEventTap!();
    } else if (marker == null) {
      // Empty day cell — set dot for tasks, circle for events.
      ref.read(markerActionsProvider).setMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: columnId,
        symbol: isEvent ? MarkerSymbol.event : MarkerSymbol.dot,
      );
    } else {
      // Has a symbol — show radial menu.
      _showRadialMenu(context, ref, marker);
    }
  }

  void _showRadialMenu(
    BuildContext context,
    WidgetRef ref,
    Marker currentMarker,
  ) {
    final isMigration = columnType != ColumnType.date;
    final renderBox = context.findRenderObject() as RenderBox;
    final cellCenter = renderBox.localToGlobal(
      Offset(cellSize / 2, cellSize / 2),
    );

    Navigator.of(context).push(
      _RadialMenuRoute(
        center: cellCenter,
        currentSymbol: currentMarker.symbol,
        isMigrationColumn: isMigration,
        onSelected: (symbol) {
          ref.read(markerActionsProvider).setMarker(
            boardId: boardId,
            taskId: taskId,
            columnId: columnId,
            symbol: symbol,
          );
        },
      ),
    );
  }
}

// ================================================================
// Radial menu overlay
// ================================================================

class _RadialMenuRoute extends PopupRoute<void> {
  final Offset center;
  final MarkerSymbol currentSymbol;
  final bool isMigrationColumn;
  final ValueChanged<MarkerSymbol?> onSelected;

  _RadialMenuRoute({
    required this.center,
    required this.currentSymbol,
    required this.isMigrationColumn,
    required this.onSelected,
  });

  @override
  Color? get barrierColor => Colors.black26;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _RadialMenuOverlay(
      center: center,
      animation: animation,
      currentSymbol: currentSymbol,
      isMigrationColumn: isMigrationColumn,
      onSelected: (symbol) {
        onSelected(symbol);
        Navigator.of(context).pop();
      },
      onDismiss: () => Navigator.of(context).pop(),
    );
  }
}

class _RadialMenuOverlay extends StatelessWidget {
  final Offset center;
  final Animation<double> animation;
  final MarkerSymbol currentSymbol;
  final bool isMigrationColumn;
  final ValueChanged<MarkerSymbol?> onSelected;
  final VoidCallback onDismiss;

  static const double _radius = 64.0;
  static const double _itemSize = 44.0;

  const _RadialMenuOverlay({
    required this.center,
    required this.animation,
    required this.currentSymbol,
    required this.isMigrationColumn,
    required this.onSelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    // Build the list of menu items.
    final items = <_RadialItem>[];

    if (isMigrationColumn) {
      items.add(_RadialItem(
        symbol: MarkerSymbol.migratedForward,
        label: '>',
        color: AlphaTheme.markerColor(
          MarkerSymbol.migratedForward,
          brightness,
        ),
      ));
    } else {
      for (final sym in MarkerSymbol.values) {
        items.add(_RadialItem(
          symbol: sym,
          label: sym.displayChar,
          color: AlphaTheme.markerColor(sym, brightness),
        ));
      }
    }

    // Add clear option.
    items.add(_RadialItem(
      symbol: null,
      label: '∅',
      color: theme.colorScheme.error,
    ));

    final itemCount = items.length;
    final angleStep = 2 * math.pi / itemCount;
    // Start from the top (-π/2).
    const startAngle = -math.pi / 2;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      child: Stack(
        children: [
          for (var i = 0; i < itemCount; i++)
            _buildItem(
              context,
              items[i],
              startAngle + angleStep * i,
              brightness,
            ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    _RadialItem item,
    double angle,
    Brightness brightness,
  ) {
    final theme = Theme.of(context);
    final isSelected = item.symbol == currentSymbol;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = Curves.easeOutBack.transform(animation.value);
        final dx = math.cos(angle) * _radius * progress;
        final dy = math.sin(angle) * _radius * progress;

        return Positioned(
          left: center.dx + dx - _itemSize / 2,
          top: center.dy + dy - _itemSize / 2,
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => onSelected(item.symbol),
        child: Container(
          width: _itemSize,
          height: _itemSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : (brightness == Brightness.dark
                    ? AlphaTheme.paperDarkVariant
                    : AlphaTheme.paperLightVariant),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: item.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadialItem {
  final MarkerSymbol? symbol;
  final String label;
  final Color color;

  const _RadialItem({
    required this.symbol,
    required this.label,
    required this.color,
  });
}
