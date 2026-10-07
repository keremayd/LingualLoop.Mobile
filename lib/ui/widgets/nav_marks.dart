import 'package:flutter/material.dart';

/// Alt menüdeki yeni simgeler, görev ikonlarıyla aynı dolu gövde/alt katman
/// dilini kullanır. Profil bir kişi siluetidir; maskot illüstrasyonlara aittir.
class NavMark extends StatelessWidget {
  const NavMark({super.key, required this.kind, required this.size});

  final NavMarkKind kind;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _NavMarkPainter(kind),
      );
}

enum NavMarkKind { home, profile }

class _NavMarkPainter extends CustomPainter {
  const _NavMarkPainter(this.kind);

  final NavMarkKind kind;

  void _fill(Canvas canvas, Path path, Color color, double u) {
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * u
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  Path _home(double u) => Path()
    ..moveTo(9 * u, 46 * u)
    ..lineTo(46 * u, 12 * u)
    ..quadraticBezierTo(50 * u, 9 * u, 54 * u, 12 * u)
    ..lineTo(91 * u, 46 * u)
    ..lineTo(84 * u, 53 * u)
    ..lineTo(84 * u, 85 * u)
    ..quadraticBezierTo(84 * u, 91 * u, 78 * u, 91 * u)
    ..lineTo(22 * u, 91 * u)
    ..quadraticBezierTo(16 * u, 91 * u, 16 * u, 85 * u)
    ..lineTo(16 * u, 53 * u)
    ..close();

  Path _shoulders(double u) => Path()
    ..moveTo(17 * u, 82 * u)
    ..cubicTo(18 * u, 64 * u, 28 * u, 56 * u, 42 * u, 56 * u)
    ..lineTo(58 * u, 56 * u)
    ..cubicTo(72 * u, 56 * u, 82 * u, 64 * u, 83 * u, 82 * u)
    ..quadraticBezierTo(83 * u, 90 * u, 76 * u, 90 * u)
    ..lineTo(24 * u, 90 * u)
    ..quadraticBezierTo(17 * u, 90 * u, 17 * u, 82 * u)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    if (kind == NavMarkKind.home) {
      final body = _home(u);
      const face = Color(0xFF1CB1F5);
      const light = Color(0xFF6BD1FF);
      const depth = Color(0xFF0E6A98);
      _fill(canvas, body.shift(Offset(0, 6 * u)), depth, u);
      _fill(canvas, body, face, u);
      canvas.save();
      canvas.clipPath(body);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(53 * u, 0)
          ..lineTo(51 * u, 67 * u)
          ..lineTo(0, 82 * u)
          ..close(),
        Paint()..color = light,
      );
      canvas.restore();
      // Tek koyu kapı, küçük boyutta evin okunmasını sağlar.
      canvas.drawRRect(
        RRect.fromLTRBR(41 * u, 61 * u, 59 * u, 93 * u, Radius.circular(8 * u)),
        Paint()..color = const Color(0xFF0B2143),
      );
    } else {
      const face = Color(0xFFF6EDE4);
      const light = Color(0xFFFFFFFF);
      const depth = Color(0xFFBCAB9E);
      final head = Path()
        ..addOval(Rect.fromLTWH(31 * u, 9 * u, 38 * u, 38 * u));
      final shoulders = _shoulders(u);
      _fill(canvas, head.shift(Offset(0, 6 * u)), depth, u);
      _fill(canvas, shoulders.shift(Offset(0, 6 * u)), depth, u);
      _fill(canvas, head, face, u);
      _fill(canvas, shoulders, face, u);
      canvas.save();
      canvas.clipPath(head);
      canvas.drawOval(
        Rect.fromLTWH(31 * u, 6 * u, 23 * u, 38 * u),
        Paint()..color = light,
      );
      canvas.restore();
      canvas.save();
      canvas.clipPath(shoulders);
      canvas.drawRect(
        Rect.fromLTWH(17 * u, 54 * u, 33 * u, 36 * u),
        Paint()..color = light,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _NavMarkPainter oldDelegate) =>
      oldDelegate.kind != kind;
}
