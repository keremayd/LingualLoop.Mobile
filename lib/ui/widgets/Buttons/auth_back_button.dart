import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({
    super.key,
    required this.scale,
    required this.onPressed,
  });

  final double scale;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final size = math.max(44.0, 84.75 * scale);

    return Semantics(
      label: 'Geri',
      child: DepthPressableButton(
        width: size,
        height: size - 8 * scale,
        radius: 24 * scale,
        shadowOffset: 8 * scale,
        backgroundColor: const Color(0xFF163258),
        shadowColor: const Color(0xFF0B2143),
        fontSize: 0,
        onPressed: onPressed,
        child: CustomPaint(
          size: Size.square(50.25 * scale),
          painter: _BackArrowPainter(strokeWidth: 6.6 * scale),
        ),
      ),
    );
  }
}

class _BackArrowPainter extends CustomPainter {
  const _BackArrowPainter({required this.strokeWidth});

  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE9EEF5)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.56, size.height * 0.14)
      ..lineTo(size.width * 0.16, size.height * 0.50)
      ..lineTo(size.width * 0.56, size.height * 0.86)
      ..moveTo(size.width * 0.18, size.height * 0.50)
      ..lineTo(size.width * 0.90, size.height * 0.50);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BackArrowPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth;
}
