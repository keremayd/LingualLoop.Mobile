import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// Karty Yolu'nda ünite nesnesinin ortak parçaları. Patikadaki ünite başlığı
// ve ünite açılış kutlaması aynı nesneyi çiziyor; ayrı ayrı çizilselerdi
// zamanla birbirinden ayrılırlardı ve kutlamadaki nesnenin patikadakiyle aynı
// olduğu anlaşılmazdı (§2.5 "tekrar eden simge tek bir yoldan gelir").

/// Renkli karonun üstündeki 3B görsel: ana ekran Karty kartındaki iki
/// katmanlı yumuşak gölgenin aynısı.
class KartyShadowedImage extends StatelessWidget {
  const KartyShadowedImage({
    super.key,
    required this.image,
    required this.size,
    required this.scale,
  });

  final ImageProvider image;
  final double size;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    Widget shadow(Offset offset, double blur, double alpha) =>
        Transform.translate(
          offset: offset,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: alpha),
                BlendMode.srcIn,
              ),
              child: Image(image: image, width: size, height: size),
            ),
          ),
        );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          shadow(Offset(7 * s, 13 * s), 12 * s, 0.28),
          shadow(Offset(3 * s, 7 * s), 5 * s, 0.2),
          Image(image: image, width: size, height: size),
        ],
      ),
    );
  }
}

/// Nesnenin tek renk silüeti: ne geleceği belli, kendisi henüz kapalı.
class KartySilhouette extends StatelessWidget {
  const KartySilhouette({
    super.key,
    required this.image,
    required this.color,
    this.size,
  });

  final ImageProvider image;
  final Color color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: Image(
        image: image,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Kilit — lig rozetinin kilitli paletiyle (§2.6): gri burada da "henüz
/// açılmadı" demek. [open] 0'da kapalı; 1'e doğru kanca yukarı kalkar, sol
/// bacak gövdede kalır, sağ bacak gövdeden çıkar (ünite açılış kutlaması).
class KartyLockMark extends StatelessWidget {
  const KartyLockMark({super.key, required this.size, this.open = 0});

  final double size;
  final double open;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _LockPainter(open));
  }
}

class _LockPainter extends CustomPainter {
  const _LockPainter(this.open);

  final double open;

  static const _light = Color(0xFFA6B0BC);
  static const _face = Color(0xFF8792A0);
  static const _depth = Color(0xFF57606C);

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final lift = 18 * u * open;
    final shackle = Path()
      ..moveTo(30 * u, 48 * u)
      ..lineTo(30 * u, 34 * u - lift)
      ..arcToPoint(Offset(70 * u, 34 * u - lift),
          radius: Radius.circular(20 * u))
      ..lineTo(70 * u, 48 * u - lift);
    canvas.drawPath(
      shackle,
      Paint()
        ..color = _face
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12 * u
        ..strokeCap = StrokeCap.round,
    );
    final body = RRect.fromLTRBR(
        14 * u, 42 * u, 86 * u, 92 * u, Radius.circular(14 * u));
    canvas.drawRRect(body.shift(Offset(0, 6 * u)), Paint()..color = _depth);
    canvas.drawRRect(body, Paint()..color = _face);
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(
        Rect.fromLTRB(14 * u, 42 * u, 86 * u, 60 * u), Paint()..color = _light);
    canvas.restore();
    canvas.drawCircle(Offset(50 * u, 66 * u), 7 * u, Paint()..color = _depth);
  }

  @override
  bool shouldRepaint(covariant _LockPainter oldDelegate) =>
      oldDelegate.open != open;
}

/// Kilidin açıldığı yerden büyüyen daire: açık yüz kilitli yüzün üstüne
/// buradan yayılır (kutlama ekranı ve patikadaki ünite başlığı).
class KartyCircleReveal extends CustomClipper<Rect> {
  const KartyCircleReveal({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Rect getClip(Size size) => Rect.fromCircle(center: center, radius: radius);

  @override
  bool shouldReclip(covariant KartyCircleReveal oldClipper) =>
      oldClipper.center != center || oldClipper.radius != radius;
}

/// Kutlama ışığının kremi (görev ödülü reçetesi): koyu zeminde doymuş sıcak
/// ton yarı saydam kirlenir, krem kirletmeden ısıtır.
const _cream = Color(0xFFFFF1DC);

/// Kilit açıldığı anın tek halkası: keskin konturlu, genişledikçe incelir ve
/// söner (bulanık parlama değil, §2.2). [radius] nesnenin yarıçapı; çizim
/// kutusu onun dört katı, nesnenin merkezine oturtulur.
class KartyUnlockRing extends StatelessWidget {
  const KartyUnlockRing({
    super.key,
    required this.progress,
    required this.radius,
    required this.scale,
  });

  final double progress;
  final double radius;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(radius * 4),
      painter: _RingPainter(progress: progress, radius: radius, scale: scale),
    );
  }
}

/// Nesnenin çevresinde sırayla parlayıp sönen dört köşeli kıvılcımlar.
/// Çizim kutusu [KartyUnlockRing] ile aynı.
class KartyUnlockSparkles extends StatelessWidget {
  const KartyUnlockSparkles({
    super.key,
    required this.progress,
    required this.radius,
    required this.scale,
  });

  final double progress;
  final double radius;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(radius * 4),
      painter:
          _SparklePainter(progress: progress, radius: radius, scale: scale),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.radius,
    required this.scale,
  });

  final double progress;
  final double radius;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      size.center(Offset.zero),
      radius * (0.75 + 0.9 * progress),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * scale * (1 - progress)
        ..color = _cream.withValues(alpha: 0.6 * (1 - progress)),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.radius != radius ||
      oldDelegate.scale != scale;
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter({
    required this.progress,
    required this.radius,
    required this.scale,
  });

  final double progress;
  final double radius;
  final double scale;

  /// (açı, nesne yarıçapına göre uzaklık); çoğu üst yarıda, metne değmez.
  static const _spots = [
    (-2.80, 1.30),
    (-2.05, 1.18),
    (-1.05, 1.36),
    (-0.35, 1.22),
    (0.45, 1.34),
    (2.70, 1.24),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()..color = _cream;
    for (final (i, (angle, distance)) in _spots.indexed) {
      final local = ((progress - i * 0.07) / 0.58).clamp(0.0, 1.0);
      final r = math.sin(math.pi * local) * (i.isEven ? 26 : 18) * scale;
      if (r <= 0.5) continue;
      final p =
          c + Offset(math.cos(angle), math.sin(angle)) * radius * distance;
      final k = r * 0.24;
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy - r)
          ..lineTo(p.dx + k, p.dy - k)
          ..lineTo(p.dx + r, p.dy)
          ..lineTo(p.dx + k, p.dy + k)
          ..lineTo(p.dx, p.dy + r)
          ..lineTo(p.dx - k, p.dy + k)
          ..lineTo(p.dx - r, p.dy)
          ..lineTo(p.dx - k, p.dy - k)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.radius != radius ||
      oldDelegate.scale != scale;
}

/// Uzay zemini: patikadaki gibi seyrek, sönük yıldızlar (ünite açılışı ve
/// oturum özeti).
class KartyStarfieldPainter extends CustomPainter {
  const KartyStarfieldPainter({required this.scale});

  final double scale;

  static const _stars = [
    (0.08, 0.06, 2.6),
    (0.27, 0.13, 1.8),
    (0.71, 0.05, 2.2),
    (0.93, 0.15, 2.8),
    (0.05, 0.33, 1.8),
    (0.95, 0.38, 2.0),
    (0.12, 0.55, 2.4),
    (0.88, 0.58, 1.8),
    (0.04, 0.78, 2.0),
    (0.96, 0.82, 2.4),
    (0.20, 0.93, 1.6),
    (0.80, 0.95, 2.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.28);
    for (final (x, y, r) in _stars) {
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
        r * scale,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant KartyStarfieldPainter oldDelegate) =>
      oldDelegate.scale != scale;
}
