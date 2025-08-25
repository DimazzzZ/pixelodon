import 'package:flutter/material.dart';

class IndentGuide extends StatelessWidget {
  final int depth;
  final Widget child;
  final double indentWidth;
  const IndentGuide({super.key, required this.depth, required this.child, this.indentWidth = 16});

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final rails = CustomPaint(
      painter: _GuidePainter(depth: depth, color: Theme.of(context).dividerColor, indentWidth: indentWidth, textDirection: direction),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: depth * indentWidth, child: rails),
        Expanded(child: child),
      ],
    );
  }
}

class _GuidePainter extends CustomPainter {
  final int depth;
  final Color color;
  final double indentWidth;
  final TextDirection textDirection;
  _GuidePainter({required this.depth, required this.color, required this.indentWidth, required this.textDirection});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1;

    for (int i = 0; i < depth; i++) {
      final double center = (i + 0.5) * indentWidth;
      final x = textDirection == TextDirection.ltr ? center : size.width - center;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GuidePainter oldDelegate) {
    // Repaint only when depth changes to avoid unnecessary repaint work
    return depth != oldDelegate.depth;
  }
}
