import 'package:flutter/material.dart';

/// Kum saati — §2.5 "chunky sticker" reçetesi.
///
/// Kartın zaman aşımı hâli için çizildi. Orada bir dönem Material'ın hazır
/// `Icons.refresh_rounded` ikonu yarı saydam bir dairenin içinde duruyordu;
/// reçete hazır ikonu da daireyi de reddediyor, ayrıca "yeniden yükle" gibi
/// okunuyordu — oysa anlatılmak istenen şey **sürenin dolduğu**.
///
/// Kum bilerek **altta**: üst hazne boş olduğu için simge tek başına "bitti"
/// diyor, metne yaslanmıyor.
///
/// Palet, güneş ikonununkiyle aynı altın üçlü (§2.5 `checkin`) — uygulamada
/// zaman/altın zaten o tonlarla yaşıyor, yeni bir ton uydurulmadı.
class HourglassMark extends StatelessWidget {
  const HourglassMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HourglassPainter(),
    );
  }
}

class _HourglassPainter extends CustomPainter {
  static const _light = Color(0xFFFFE071);
  static const _face = Color(0xFFFFC932);
  static const _depth = Color(0xFFCE8409);

  /// Gövde 100 birimlik kutuda; [dy] kalınlık bandı için aşağı kaydırma.
  Path _body(double u, double dy) {
    return Path()
      ..moveTo(22 * u, 10 * u + dy)
      ..lineTo(78 * u, 10 * u + dy)
      ..lineTo(78 * u, 26 * u + dy)
      ..lineTo(54 * u, 50 * u + dy)
      ..lineTo(78 * u, 74 * u + dy)
      ..lineTo(78 * u, 90 * u + dy)
      ..lineTo(22 * u, 90 * u + dy)
      ..lineTo(22 * u, 74 * u + dy)
      ..lineTo(46 * u, 50 * u + dy)
      ..lineTo(22 * u, 26 * u + dy)
      ..close();
  }

  /// Aynı yolu hem doldur hem **aynı renkle** konturla: köşeler böyle
  /// yuvarlanıyor (§2.5).
  void _fillChunky(Canvas canvas, Path path, Color color, double u) {
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * u
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;

    // Sıra önemli: kalınlık bandı → yüz → açık bölge → parlama.
    _fillChunky(canvas, _body(u, 6 * u), _depth, u);
    _fillChunky(canvas, _body(u, 0), _face, u);

    canvas.save();
    canvas.clipPath(_body(u, 0));

    // Alt hazneyi dolduran kum.
    canvas.drawRect(
      Rect.fromLTWH(0, 62 * u, 100 * u, 38 * u),
      Paint()..color = _light,
    );
    // Boğazdan akan son huni.
    canvas.drawPath(
      Path()
        ..moveTo(50 * u, 50 * u)
        ..lineTo(56 * u, 66 * u)
        ..lineTo(44 * u, 66 * u)
        ..close(),
      Paint()..color = _light,
    );
    // Üst hazne boş: içeride gölge kalıyor.
    canvas.drawPath(
      Path()
        ..moveTo(26 * u, 14 * u)
        ..lineTo(74 * u, 14 * u)
        ..lineTo(50 * u, 42 * u)
        ..close(),
      Paint()..color = _depth.withValues(alpha: 0.35),
    );
    // Sol üstte ince parlama.
    canvas.drawCircle(
      Offset(33 * u, 22 * u),
      5 * u,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
