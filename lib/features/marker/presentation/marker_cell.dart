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
  final bool isPastDay;
  final bool isLocked;

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
    this.isPastDay = false,
    this.isLocked = false,
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

    Widget child;
    if (isMigration && isEvent) {
      final iconColor = color ??
          (brightness == Brightness.dark
              ? const Color(0xFFA09A94)
              : const Color(0xFF6B6560));
      child = Icon(
        isRecurring ? Icons.event_repeat : Icons.event,
        size: 18,
        color: iconColor.withValues(alpha: symbol != null ? 1.0 : 0.4),
      );
    } else {
      child = _buildMarkerWidget(symbol, color);
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

  /// Renders the marker symbol. Dot, checkmark, and event are
  /// painted for a hand-drawn feel; text symbols use Patrick Hand.
  static Widget _buildMarkerWidget(MarkerSymbol? symbol, Color? color) {
    if (symbol == null) return const SizedBox.shrink();

    // Dot → small filled circle.
    if (symbol == MarkerSymbol.dot) {
      return CustomPaint(
        size: const Size(10, 10),
        painter: _InkDotPainter(color: color ?? Colors.grey),
      );
    }

    // Done → hand-drawn checkmark.
    if (symbol == MarkerSymbol.x) {
      return CustomPaint(
        size: const Size(16, 16),
        painter: _InkCheckPainter(color: color ?? Colors.grey),
      );
    }

    // Event → small open circle.
    if (symbol == MarkerSymbol.event) {
      return CustomPaint(
        size: const Size(14, 14),
        painter: _InkCirclePainter(color: color ?? Colors.grey),
      );
    }

    // Text symbols (/, >, <) — rendered in Patrick Hand.
    return Text(
      symbol.displayChar,
      style: TextStyle(
        fontFamily: 'PatrickHand',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color,
        decoration: TextDecoration.none,
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, Marker? marker) {
    if (isLocked) return;
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
      const Offset(cellSize / 2, cellSize / 2),
    );

    Navigator.of(context).push(
      _RadialMenuRoute(
        center: cellCenter,
        currentSymbol: currentMarker.symbol,
        isMigrationColumn: isMigration,
        isPastDay: isPastDay,
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
  final bool isPastDay;
  final ValueChanged<MarkerSymbol?> onSelected;

  _RadialMenuRoute({
    required this.center,
    required this.currentSymbol,
    required this.isMigrationColumn,
    this.isPastDay = false,
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
      isPastDay: isPastDay,
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
  final bool isPastDay;
  final ValueChanged<MarkerSymbol?> onSelected;
  final VoidCallback onDismiss;

  static const double _radius = 64.0;
  static const double _itemSize = 44.0;

  const _RadialMenuOverlay({
    required this.center,
    required this.animation,
    required this.currentSymbol,
    required this.isMigrationColumn,
    this.isPastDay = false,
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
      // Only show the manual cycle symbols (dot, slash, x).
      // Event (○), doneEarly (<), and migratedForward (>) are
      // set automatically and not offered as manual choices.
      // Dot is excluded on past days — scheduling in the past
      // doesn't make sense.
      final manualSymbols = [
        if (!isPastDay) MarkerSymbol.dot,
        MarkerSymbol.slash,
        MarkerSymbol.x,
      ];
      for (final sym in manualSymbols) {
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
            child: item.symbol != null
                ? MarkerCell._buildMarkerWidget(
                    item.symbol,
                    item.color,
                  )
                : Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'PatrickHand',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: item.color,
                      decoration: TextDecoration.none,
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

// ================================================================
// Custom painters for hand-drawn marker shapes
// ================================================================

/// Paints a filled dot with slight irregularity for a
/// hand-drawn look.
class _InkDotPainter extends CustomPainter {
  final Color color;

  _InkDotPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.9,
        height: size.height,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_InkDotPainter old) => old.color != color;
}

/// Paints a hand-drawn checkmark stroke.
class _InkCheckPainter extends CustomPainter {
  final Color color;

  _InkCheckPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      // Start at upper-left, dip to bottom-center, rise to upper-right.
      ..moveTo(size.width * 0.12, size.height * 0.52)
      ..lineTo(size.width * 0.40, size.height * 0.82)
      ..lineTo(size.width * 0.88, size.height * 0.18);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_InkCheckPainter old) => old.color != color;
}

/// Paints an open circle with a hand-drawn stroke.
class _InkCirclePainter extends CustomPainter {
  final Color color;

  _InkCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.85,
        height: size.height * 0.95,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_InkCirclePainter old) => old.color != color;
}
