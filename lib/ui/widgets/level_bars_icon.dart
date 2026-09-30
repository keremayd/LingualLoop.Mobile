import 'package:flutter/material.dart';

/// Seviye simgesi: yükselen üç çubuk.
///
/// Uygulamadaki hiçbir ikonla çakışmaz — şimşek (boost/lig/görev), alev
/// (seri), kitap, güneş, bilet ve kupa zaten dolu. Yükselen çubuk evrensel
/// olarak "kademe" okunur ve seviyenin ne olduğunu etiketsiz de anlatır.
///
/// §2.5 reçetesi: dolu ve tombul gövde (aynı yol `StrokeJoin.round` ile
/// konturlanarak yuvarlatılır), altında kalınlık bandı, net iki ton, sol
/// üstte ince beyaz parlama. 100 birimlik kutuda tanımlıdır.
class LevelBarsIcon extends StatelessWidget {
  const LevelBarsIcon({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _LevelBarsPainter(),
    );
  }
}

class _LevelBarsPainter extends CustomPainter {
  const _LevelBarsPainter();

  static const _light = Color(0xFF6BD1FF);
  static const _face = Color(0xFF1CB1F5);
  static const _depth = Color(0xFF0E6A98);

  /// Çubukların 100 birimlik kutudaki yerleşimi: sol, üst, genişlik.
  /// Yükseklik alt hizadan (82) hesaplanır.
  static const _bars = <List<double>>[
    [16, 54, 20],
    [40, 36, 20],
    [64, 18, 20],
  ];

  static const _baseline = 82.0;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;

    for (final bar in _bars) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          bar[0] * u,
          bar[1] * u,
          (bar[0] + bar[2]) * u,
          _baseline * u,
        ),
        Radius.circular(6 * u),
      );

      // Kalınlık bandı: gövdenin kopyası aşağı kaydırılıp koyu tonda.
      _fillChunky(canvas, rect.shift(Offset(0, 6 * u)), _depth, u);
      // Tombul gövde.
      _fillChunky(canvas, rect, _face, u);

      // Işık üstten geliyor: her çubuğun tepesi açık tonda.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            bar[0] * u,
            bar[1] * u,
            (bar[0] + bar[2]) * u,
            (bar[1] + 13) * u,
          ),
          Radius.circular(6 * u),
        ),
        Paint()..color = _light,
      );
    }

    // Sol üstte ince beyaz parlama (§2.5/5).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20 * u, 58 * u, 6 * u, 12 * u),
        Radius.circular(3 * u),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.42),
    );
  }

  /// §2.5/1: aynı yolu hem doldur hem aynı renkle yuvarlak birleşimli
  /// konturla — köşeler yuvarlanır, biçim tombullaşır.
  void _fillChunky(Canvas canvas, RRect rect, Color color, double u) {
    canvas.drawRRect(rect, Paint()..color = color);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * u
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LevelBarsPainter oldDelegate) => false;
}
