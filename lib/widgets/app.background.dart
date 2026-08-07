import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget? child;
  const AppBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _GridPainter()),
        ?child,
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  static const double _spacing = 16;
  static const int _majorEvery = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 0.7;
    final major = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.1;

    for (var i = 0; i * _spacing <= size.width; i++) {
      final paint = i % _majorEvery == 0 ? major : minor;
      final x = i * _spacing;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var i = 0; i * _spacing <= size.height; i++) {
      final paint = i % _majorEvery == 0 ? major : minor;
      final y = i * _spacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}
