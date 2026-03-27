import 'package:flutter/material.dart';
import 'package:alpha/features/tag/domain/tag.dart';
import 'package:alpha/features/tag/domain/tag_palette.dart';

/// A 2x2 grid of colored quadrants showing up to 4 tag colors.
/// Empty slots are transparent. Renders nothing if no tags.
class TagBadge extends StatelessWidget {
  final List<Tag> tags;
  final double size;

  const TagBadge({super.key, required this.tags, this.size = 16});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TagBadgePainter(
          colors: tags
              .map((t) => TagPalette.colorFromValue(t.color))
              .toList(),
        ),
      ),
    );
  }
}

class _TagBadgePainter extends CustomPainter {
  final List<Color> colors;

  _TagBadgePainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 1.0;
    final quadW = (size.width - gap) / 2;
    final quadH = (size.height - gap) / 2;

    // Slots: 0=top-left, 1=top-right, 2=bottom-left, 3=bottom-right
    final offsets = [
      const Offset(0, 0),
      Offset(quadW + gap, 0),
      Offset(0, quadH + gap),
      Offset(quadW + gap, quadH + gap),
    ];

    for (var i = 0; i < 4; i++) {
      if (i < colors.length) {
        final paint = Paint()..color = colors[i];
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            offsets[i] & Size(quadW, quadH),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TagBadgePainter old) {
    if (old.colors.length != colors.length) return true;
    for (var i = 0; i < colors.length; i++) {
      if (old.colors[i] != colors[i]) return true;
    }
    return false;
  }
}
