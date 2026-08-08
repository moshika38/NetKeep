import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

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
      ..color = AppColors.primaryColor.withValues(alpha: 0.035)
      ..strokeWidth = 0.5;
    final major = Paint()
      ..color = AppColors.primaryColor.withValues(alpha: 0.07)
      ..strokeWidth = 1;

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

    _paintCornerBrackets(canvas, size);
  }

  void _paintCornerBrackets(Canvas canvas, Size size) {
    final bracket = Paint()
      ..color = AppColors.primaryColor.withValues(alpha: 0.28)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const inset = 12.0;
    const length = 26.0;

    canvas.drawPath(
      Path()
        ..moveTo(inset, inset + length)
        ..lineTo(inset, inset)
        ..lineTo(inset + length, inset),
      bracket,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - inset - length, inset)
        ..lineTo(size.width - inset, inset)
        ..lineTo(size.width - inset, inset + length),
      bracket,
    );
    canvas.drawPath(
      Path()
        ..moveTo(inset, size.height - inset - length)
        ..lineTo(inset, size.height - inset)
        ..lineTo(inset + length, size.height - inset),
      bracket,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - inset - length, size.height - inset)
        ..lineTo(size.width - inset, size.height - inset)
        ..lineTo(size.width - inset, size.height - inset - length),
      bracket,
    );
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}
