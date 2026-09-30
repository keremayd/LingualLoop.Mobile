import 'package:flutter/material.dart';

/// Görevler ekranının simgesi: dalgalanan altın bayrak.
///
/// Biçim dili Duolingo ikonlarından esinlenir: kalın ve tamamen yuvarlatılmış
/// formlar, tam 3D render yerine gövdenin altına inen koyu bir kalınlık bandı
/// ("vinil sticker" derinliği), aynı rengin birkaç tonu ve ince detaydan
/// kaçınma. Hacim, kumaşın dalgasından gelir: üst yüzey ışığı alır, dalganın
/// arkaya dönen alt yüzeyi bir ton koyulaşır.
class QuestFlagMark extends StatelessWidget {
  const QuestFlagMark({
    super.key,
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: QuestFlagPainter(),
    );
  }
}

/// Önizleme/karşılaştırma testlerinden de çağrılabilsin diye public.
class QuestFlagPainter extends CustomPainter {
  static const _light = Color(0xFFFFDC5C);
  static const _face = Color(0xFFFFC932);
  static const _fold = Color(0xFFF0A81C);
  static const _depth = Color(0xFFCE8409);

  Path _pole(double u) {
    return Path()
      ..addRRect(
        RRect.fromLTRBR(
          14 * u,
          6 * u,
          31 * u,
          94 * u,
          Radius.circular(8.5 * u),
        ),
      );
  }

  /// Dalgalanan flama: üst ve alt kenar aynı ritmi izler, sağ uç yuvarlatılır.
  Path _banner(double u) {
    return Path()
      ..moveTo(25 * u, 12 * u)
      ..cubicTo(48 * u, -2 * u, 72 * u, 26 * u, 93 * u, 12 * u)
      ..cubicTo(97 * u, 9 * u, 100 * u, 13 * u, 100 * u, 18 * u)
      ..lineTo(100 * u, 50 * u)
      ..cubicTo(100 * u, 55 * u, 98 * u, 58 * u, 94 * u, 61 * u)
      ..cubicTo(73 * u, 76 * u, 49 * u, 48 * u, 25 * u, 62 * u)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final body = Path.combine(PathOperation.union, _pole(u), _banner(u));

    canvas.save();
    // Gövde 15-99 aralığında; kutusunda ortalanır.
    canvas.translate(-7 * u, 0);

    canvas.drawShadow(
      body.shift(Offset(0, 7 * u)),
      Colors.black.withValues(alpha: 0.38),
      6 * u,
      false,
    );

    // Kalınlık bandı: gövdenin altına inen koyu katman.
    canvas.drawPath(body.shift(Offset(0, 6 * u)), Paint()..color = _depth);

    // Ana yüzey.
    canvas.drawPath(body, Paint()..color = _face);

    // Kumaşın iki kanadı: kat çizgisinin solundaki yüzey ışığı alır,
    // arkaya dönen sağ kanat bir ton koyulaşır. Direk kendi tonunda kalır,
    // böylece üç yüzey birbirinden net ayrılır.
    final creaseLeft = Path()
      ..moveTo(-15 * u, -15 * u)
      ..lineTo(78 * u, -15 * u)
      ..cubicTo(71 * u, 18 * u, 62 * u, 42 * u, 57 * u, 85 * u)
      ..lineTo(-15 * u, 85 * u)
      ..close();
    final creaseRight = Path()
      ..moveTo(78 * u, -15 * u)
      ..lineTo(115 * u, -15 * u)
      ..lineTo(115 * u, 85 * u)
      ..lineTo(57 * u, 85 * u)
      ..cubicTo(62 * u, 42 * u, 71 * u, 18 * u, 78 * u, -15 * u)
      ..close();

    canvas.save();
    canvas.clipPath(_banner(u));
    canvas.drawPath(creaseLeft, Paint()..color = _light);
    canvas.drawPath(creaseRight, Paint()..color = _fold);
    canvas.restore();

    canvas.save();
    canvas.clipPath(body);

    // Sol üst kenarda yumuşak parlama.
    canvas.drawPath(
      body.shift(Offset(-1.5 * u, -2 * u)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * u
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * u),
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant QuestFlagPainter oldDelegate) => false;
}
