import 'package:flutter/material.dart';

/// Directional edge lighting from the approved drawing: white top/left,
/// cool right face and a distinct bottom face, joined at the rounded corners.
class KartyCardRimPainter extends CustomPainter {
  const KartyCardRimPainter({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = radius;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(r),
    ));
    canvas.drawPaint(Paint()..color = Colors.white);
    canvas.drawPath(
      Path()
        ..moveTo(w, 0)
        ..lineTo(w, h)
        ..lineTo(w - r, h - r)
        ..lineTo(w - r, r)
        ..close(),
      Paint()..color = const Color(0xFFE9EEF5),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(w, h)
        ..lineTo(w - r, h - r)
        ..lineTo(r, h - r)
        ..close(),
      Paint()..color = const Color(0xFFD8DCE4),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant KartyCardRimPainter oldDelegate) =>
      oldDelegate.radius != radius;
}
