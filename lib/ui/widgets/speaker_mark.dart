import 'package:flutter/material.dart';

/// Shared rounded speaker glyph for listening and sound preferences.
class SpeakerMark extends StatelessWidget {
  const SpeakerMark(
      {super.key,
      required this.size,
      this.muted = false,
      this.wave = 0,
      this.color = const Color(0xFFE9EEF5)});
  final double size;
  final bool muted;
  final double wave;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _SpeakerPainter(wave: wave, muted: muted, color: color),
      );
}

/// Hoparlör gövdesi + iki ses dalgası. 100 birimlik kutu.
class _SpeakerPainter extends CustomPainter {
  _SpeakerPainter(
      {required this.wave, required this.muted, required this.color});

  /// 0 → durgun, 1 → dalgalar tam yayılmış.
  final double wave;
  final bool muted;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final paint = Paint()..color = color;

    // Gövde: koni + kutu tek yol olarak. Yuvarlak birleşimli kontur
    // köşeleri tombullaştırıyor (§2.5/1).
    final body = Path()
      ..moveTo(52 * u, 14 * u)
      ..lineTo(28 * u, 36 * u)
      ..lineTo(12 * u, 36 * u)
      ..lineTo(12 * u, 64 * u)
      ..lineTo(28 * u, 64 * u)
      ..lineTo(52 * u, 86 * u)
      ..close();
    canvas.drawPath(body, paint);
    canvas.drawPath(
      body,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * u
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    if (muted) {
      final cross = Path()
        ..moveTo(70 * u, 39 * u)
        ..lineTo(91 * u, 61 * u)
        ..moveTo(91 * u, 39 * u)
        ..lineTo(70 * u, 61 * u);
      canvas.drawPath(
          cross,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8 * u
            ..strokeCap = StrokeCap.round);
      return;
    }

    // İki yay. Dış yay içtekinden **sonra** beliriyor: ses yayılıyor gibi
    // okunsun diye. Durgun hâlde ikisi de görünür, dalga yalnız opaklık
    // ve genişlik olarak oynuyor.
    void arc(double radius, double delay, double baseAlpha) {
      final progress = ((wave - delay) / (1 - delay)).clamp(0.0, 1.0);
      // sin eğrisi: yayıl, sön. Tam sayı frekans (§4.4) — döngü kapanıyor.
      final swell = wave == 0 ? 0.0 : (progress * (1 - progress) * 4);
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(58 * u, 50 * u),
          radius: (radius + swell * 6) * u,
        ),
        -0.85,
        1.7,
        false,
        Paint()
          ..color = color.withValues(alpha: baseAlpha + swell * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8 * u
          ..strokeCap = StrokeCap.round,
      );
    }

    arc(20, 0.0, 0.55);
    arc(34, 0.25, 0.35);
  }

  @override
  bool shouldRepaint(covariant _SpeakerPainter oldDelegate) =>
      oldDelegate.wave != wave ||
      oldDelegate.muted != muted ||
      oldDelegate.color != color;
}
