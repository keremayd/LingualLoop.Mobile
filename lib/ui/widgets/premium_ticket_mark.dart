import 'package:flutter/material.dart';

/// Premium biletin simgesi: normal biletin **birebir silueti**, Karty'nin
/// gökkuşağı geçişiyle dolu ve ortasında yıldız yerine sonsuzluk işareti.
///
/// Silüet yeniden çizilmiyor, `ticket.png`'nin kendisi maske olarak
/// kullanılıyor (`ShaderMask` + `BlendMode.srcIn`): gradyan yalnızca biletin
/// opak pikselleri üzerinde görünür. Köşe yayları, kenardaki çentikler,
/// oranlar — hepsi asıl biletin aynısı olmak zorunda değil, **aynısı**.
///
/// Siluet elle çizilmişti ve dış hatlar tutmuyordu: köşe yarıçapı ve çentik
/// geometrisi piksellerden ölçülse bile küçük sapmalar kalıyor, iki bilet yan
/// yana konunca fark ediliyordu. Maskeleme bu sapma sınıfını tamamen kaldırır.
///
/// Gradyan uydurulmadı — `SwipableCard`'daki Karty kart gradyanının aynısı.
/// Uygulamada "özel/değerli" olanın rengi zaten o.
class PremiumTicketMark extends StatelessWidget {
  const PremiumTicketMark({super.key, required this.width});

  final double width;

  static const _asset = 'assets/icons/ticket.png';

  /// Biletin en/boy oranı: 516×331 asset'ten.
  static const aspectRatio = 516 / 331;

  /// Karty kart gradyanı (`SwipableCard`).
  static const _cardGradient = LinearGradient(
    colors: [
      Color(0xFF68D73D),
      Color(0xFF56BEEA),
      Color(0xFFA647F0),
      Color(0xFFFDC041),
    ],
    stops: [0.02, 0.38, 0.68, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final height = width / aspectRatio;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Siluet: biletin alfası, gradyanla boyanmış.
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (rect) => _cardGradient.createShader(rect),
            child: Image.asset(
              _asset,
              width: width,
              height: height,
              fit: BoxFit.contain,
            ),
          ),
          // 2. İç panel ve sonsuzluk işareti. Panel geometrisi `ticket.png`
          //    piksellerinden ölçüldü; asıl bilette orada koyu turuncu bir
          //    alan var, burada gradyanı koyulaştıran bir katman kullanılıyor
          //    ki geçiş içeriden de görünmeye devam etsin.
          Positioned.fill(
            child: CustomPaint(painter: const _TicketFacePainter()),
          ),
        ],
      ),
    );
  }
}

class _TicketFacePainter extends CustomPainter {
  const _TicketFacePainter();

  /// İç panelin `ticket.png` üzerindeki ölçülmüş sınırları (oransal).
  static const _panelLeft = 0.187;
  static const _panelRight = 0.811;
  static const _panelTop = 0.139;
  static const _panelBottom = 0.879;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          w * _panelLeft,
          h * _panelTop,
          w * _panelRight,
          h * _panelBottom,
        ),
        Radius.circular(w * 0.072),
      ),
      Paint()..color = const Color(0xFF041227).withValues(alpha: 0.30),
    );

    _paintInfinity(canvas, size);
  }

  /// Sonsuzluk işareti: tek parça lemniskat, yuvarlak uçlu kalın konturla.
  /// İki ayrı daire çizmek yerine tek yol kullanılır ki ortada gerçek bir
  /// kesişim olsun — ayrık iki halka "sonsuz" değil "gözlük" gibi okunur.
  void _paintInfinity(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    // Yıldız iç panelin tamamını doldurmuyor; sonsuzluk işareti de
    // doldurmamalı ki bilet "sembolle tıkalı" görünmesin.
    final lobe = w * 0.125;
    final rise = h * 0.185;

    final path = Path()
      ..moveTo(cx, cy)
      ..cubicTo(cx - lobe * 0.5, cy - rise, cx - lobe * 1.6, cy - rise,
          cx - lobe * 1.6, cy)
      ..cubicTo(cx - lobe * 1.6, cy + rise, cx - lobe * 0.5, cy + rise, cx, cy)
      ..cubicTo(cx + lobe * 0.5, cy - rise, cx + lobe * 1.6, cy - rise,
          cx + lobe * 1.6, cy)
      ..cubicTo(cx + lobe * 1.6, cy + rise, cx + lobe * 0.5, cy + rise, cx, cy);

    // Altta koyu bir kopya: §2.5'teki kalınlık bandı, işarete gövde verir.
    canvas.drawPath(
      path.shift(Offset(0, h * 0.035)),
      Paint()
        ..color = const Color(0xFF041227).withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.062
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.062
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TicketFacePainter oldDelegate) => false;
}
