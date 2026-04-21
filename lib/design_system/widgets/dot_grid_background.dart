import 'package:flutter/material.dart';
import 'package:planyr/app/theme.dart';

/// Paints a subtle dot grid behind the board, evoking a bullet
/// journal page. The dots are spaced at [PlanyrTheme.cellSize] intervals.
class DotGridBackground extends StatelessWidget {
  final Widget child;

  const DotGridBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dotColor = brightness == Brightness.dark
        ? PlanyrTheme.dotGridDark
        : PlanyrTheme.dotGridLight;

    return CustomPaint(
      painter: _DotGridPainter(dotColor: dotColor),
      child: child,
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color dotColor;
  static const double _spacing = PlanyrTheme.cellSize;
  static const double _dotRadius = 1.2;

  _DotGridPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;

    for (double y = _spacing; y < size.height; y += _spacing) {
      for (double x = _spacing; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), _dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor;
}
