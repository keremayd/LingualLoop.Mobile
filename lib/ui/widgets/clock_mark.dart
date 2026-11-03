import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Kalan süre simgesi — §2.5 "chunky sticker" reçetesiyle çizilmiş saat.
///
/// Material'ın hazır kum saati yerine geçti: hazır ikon bu uygulamada
/// reddedilen dil (§2.5) ve yanındaki çizilmiş simgelerin (koruma, lig
/// rozeti) arasında düz ve sönük kalıyordu.
///
/// Palet, kitap görev ikonunun belgeli mavi üçlüsü (`6BD1FF / 1CB1F5 /
/// 0E6A98`); kadran beyaz, akrep–yelkovan sayfa lacivertinde. [urgent]
/// iken çerçeve sıcak tona geçer (§2.10: renk aciliyet sinyalidir).
class ClockMark extends StatelessWidget {
  const ClockMark({super.key, required this.size, this.urgent = false});

  final double size;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ClockMarkPainter(urgent: urgent),
    );
  }
}

class _ClockMarkPainter extends CustomPainter {
  const _ClockMarkPainter({required this.urgent});

  final bool urgent;

  static const _light = Color(0xFF6BD1FF);
  static const _face = Color(0xFF1CB1F5);
  static const _depth = Color(0xFF0E6A98);
  static const _urgentLight = Color(0xFFFFA07F);
  static const _urgentFace = Color(0xFFFF6B3D);
  static const _urgentDepth = Color(0xFFB53F1C);
  static const _dial = Color(0xFFF7F9FC);
  static const _hands = Color(0xFF0B2143);

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final center = Offset(50 * u, 47 * u);
    final light = urgent ? _urgentLight : _light;
    final face = urgent ? _urgentFace : _face;
    final depth = urgent ? _urgentDepth : _depth;

    // 1) Kalınlık bandı önce: gövdenin aşağı kaydırılmış kopyası.
    canvas.drawCircle(
        center + Offset(0, 6 * u), 44 * u, Paint()..color = depth);

    // 2) Ana gövde (çerçeve).
    final body = Path()
      ..addOval(Rect.fromCircle(center: center, radius: 44 * u));
    canvas.drawPath(body, Paint()..color = face);

    // 3) Işık bölgesi: çerçevenin sol üst yarısı açık ton, keskin sınırla.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawCircle(
      center + Offset(-9 * u, -9 * u),
      40 * u,
      Paint()..color = light,
    );
    canvas.drawCircle(
        center + Offset(4 * u, 4 * u), 40 * u, Paint()..color = face);
    canvas.restore();

    // Kadran.
    canvas.drawCircle(center, 30 * u, Paint()..color = _dial);

    // Akrep ve yelkovan: 12 ve 3 yönü — küçük boyutta en okunur açı.
    final hand = Paint()
      ..color = _hands
      ..strokeWidth = 8 * u
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, center + Offset(0, -19 * u), hand);
    canvas.drawLine(center, center + Offset(14 * u, 0), hand);
    canvas.drawCircle(center, 6 * u, Paint()..color = _hands);

    // 4) Sol üstte ince parlama.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 37 * u),
      math.pi * 1.08,
      math.pi * 0.36,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * u
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5 * u),
    );
  }

  @override
  bool shouldRepaint(_ClockMarkPainter oldDelegate) =>
      oldDelegate.urgent != urgent;
}
