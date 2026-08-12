import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

/// Full-bleed background: a faint orange grid with a warm radial glow at the
/// top and low-key corner brackets. Keeps the app's tool-like identity without
/// the harsh high-contrast lines of the old theme.
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

  static const double _spacing = 18;
  static const int _majorEvery = 4;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGlow(canvas, size);
    _paintCheckerboard(canvas, size);

    final minor = Paint()
      ..color = AppColors.primaryColor.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    final major = Paint()
      ..color = AppColors.primaryColor.withValues(alpha: 0.05)
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

  /// Alternating check cells at a very low alpha - a quiet "tech" checkerboard
  /// that reads as texture rather than noise.
  void _paintCheckerboard(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = AppColors.primaryColor.withValues(alpha: 0.028);

    for (var row = 0; row * _spacing <= size.height; row++) {
      for (var col = 0; col * _spacing <= size.width; col++) {
        // Alternate like a chessboard; also brighten cells that sit at a
        // major grid intersection for a subtle depth boost.
        final isMajor = (row % _majorEvery == 0) || (col % _majorEvery == 0);
        if ((row + col).isEven) {
          fill.color = AppColors.primaryColor.withValues(
            alpha: isMajor ? 0.05 : 0.028,
          );
          canvas.drawRect(
            Rect.fromLTWH(
              col * _spacing,
              row * _spacing,
              _spacing,
              _spacing,
            ),
            fill,
          );
        }
      }
    }
  }

  void _paintGlow(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryColor.withValues(alpha: 0.09),
          AppColors.primaryColor.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        radius: 0.75,
        stops: const [0.0, 0.45, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, -size.height * 0.15),
          radius: size.height,
        ),
      );
    canvas.drawRect(Offset.zero & size, glow);
  }

  void _paintCornerBrackets(Canvas canvas, Size size) {
    final bracket = Paint()
      ..color = AppColors.primaryColor.withValues(alpha: 0.16)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const inset = 14.0;
    const length = 24.0;

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
