import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// Yüzey parlamaları tek yerde: patikadaki düğüm ve durak karoları, seri
// kartı ve Karty kartları aynı ışığı paylaşır. Ayrı ayrı çizilselerdi zamanla
// birbirinden ayrılırlardı (§2.5 "tekrar eden simge tek bir yoldan gelir").

/// Karo yüzünün üst kenarında ince cam parlaması ve sol üstte küçük
/// parlama — seri kartının üst kenar parlamasıyla aynı aile, bulanıklık yok.
///
/// Ölçü karonun genişliğinden gelir. Büyük karoda parlama düğümünkinden
/// iri durmasın diye [unitWidth] ile sınırlanabilir.
class FaceGlossPainter extends CustomPainter {
  const FaceGlossPainter({required this.radius, this.unitWidth});

  final double radius;
  final double? unitWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final width =
        unitWidth == null ? size.width : math.min(size.width, unitWidth!);
    final stroke = width * 0.03;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.5));
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(stroke * 1.2),
          Radius.circular(math.max(0, radius - stroke * 1.2))),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          Offset(rect.center.dx, size.height * 0.5),
          [
            Colors.white.withValues(alpha: 0.34),
            Colors.white.withValues(alpha: 0),
          ],
        ),
    );
    canvas.restore();
    final u = width / 100;
    canvas.save();
    canvas.translate(22 * u, 19 * u);
    canvas.rotate(-0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 16 * u, height: 6.5 * u),
        Radius.circular(3.25 * u),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.38),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FaceGlossPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.unitWidth != unitWidth;
}

/// Kartın **üst** kenarındaki cam parlaması.
///
/// Yuvarlatılmış dikdörtgen konturu, dikey bir gradyanla boyanmış fırçayla
/// çizilir: tepede `color`, kartın üçte birinde şeffaf. Böylece parlama üst
/// kenarda ve üst köşelerde görünüp yanlara doğru **kaybolur** — düz bir
/// çerçeve gibi kesilmez. §2.3'teki `_NoTopBorderPainter`'ın tersi.
///
/// Referansta ölçüldü: sol ve alt kenarlarda yüzden farklı bir ton yok,
/// üstte 3 birimlik `#40527E` bandı var. Işık yukarıdan geliyor; dört kenarı
/// çevreleyen bir çerçeve referansı taklit etmez, başka bir şey yapar.
class TopRimPainter extends CustomPainter {
  const TopRimPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(strokeWidth / 2),
        Radius.circular(radius),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0, 0.34],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant TopRimPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}
