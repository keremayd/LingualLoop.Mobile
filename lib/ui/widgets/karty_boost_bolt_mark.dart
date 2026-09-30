import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/karty_boost_palette.dart';

/// Karty boost'un ortak, hacimli enerji parçası.
///
/// Kaynak PNG'nin kendi yumuşak yüzey ve gölge ayrıntısı korunur; yalnız renk
/// ailesi değiştirilir. Önceki düz `CustomPainter` şekli küçük ölçekte bir UI
/// çentiği gibi kalıyordu. Bu parça kart köşesinde, hazır kontrolünde, üst
/// çarpanda ve puan aktarımında aynı fiziksel nesne olarak kullanılır.
class KartyBoostBoltMark extends StatelessWidget {
  const KartyBoostBoltMark({
    super.key,
    required this.height,
    this.face = KartyBoostPalette.blue,
    this.depth = KartyBoostPalette.blueDepth,
    this.highlight = 0.06,
    this.bubblePhase,
    this.bubbleIntensity = 1,
  });

  final double height;
  final Color face;
  final Color depth;
  final double highlight;

  /// Null for empty/base silhouettes. The caller supplies its existing clock
  /// so bubbles move with the bolt without introducing another ticker.
  final double? bubblePhase;
  final double bubbleIntensity;

  @override
  Widget build(BuildContext context) {
    final width = height * 0.74;
    final depthOffset = height * 0.055;

    Widget tintedBolt(Color color, {bool preserveShading = false}) {
      return Image.asset(
        'assets/icons/boost-bolt.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
        cacheHeight: 270,
        color: color,
        colorBlendMode: preserveShading ? BlendMode.modulate : BlendMode.srcIn,
        filterQuality: FilterQuality.high,
      );
    }

    return SizedBox(
      width: width,
      height: height + depthOffset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Transform.translate(
            offset: Offset(0, depthOffset),
            child: tintedBolt(depth),
          ),
          // Multiply the existing sculpted shading into the brand blue; a
          // white overlay alone would bleach the face into cyan.
          tintedBolt(face, preserveShading: true),
          if (highlight > 0)
            Opacity(
              opacity: highlight.clamp(0.0, 1.0),
              child: Image.asset(
                'assets/icons/boost-bolt.png',
                width: width,
                height: height,
                fit: BoxFit.contain,
                cacheHeight: 270,
                filterQuality: FilterQuality.high,
              ),
            ),
          if (bubblePhase != null && bubbleIntensity > 0)
            CustomPaint(
              size: Size(width, height + depthOffset),
              painter: KartyBoostBubblePainter(
                phase: bubblePhase!,
                intensity: bubbleIntensity,
              ),
            ),
        ],
      ),
    );
  }
}

/// Shared liquid bubbles for the corner meter and every moving energy bolt.
class KartyBoostBubblePainter extends CustomPainter {
  const KartyBoostBubblePainter({required this.phase, required this.intensity});

  final double phase;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    const bubbles = [
      (0.39, 0.78, 0.035, 0.0),
      (0.55, 0.66, 0.026, 0.24),
      (0.45, 0.53, 0.033, 0.51),
      (0.57, 0.39, 0.022, 0.76),
    ];

    for (var index = 0; index < bubbles.length; index++) {
      final bubble = bubbles[index];
      final travel = (phase + bubble.$4) % 1;
      final opacity = math.sin(travel * math.pi).clamp(0.0, 1.0);
      final sway = math.sin(travel * math.pi * 2 + index) * size.width * 0.025;
      final center = Offset(
        size.width * bubble.$1 + sway,
        size.height * (bubble.$2 - travel * 0.23),
      );
      final radius = size.width * bubble.$3 * (1 - travel * 0.18);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = KartyBoostPalette.white.withValues(
            alpha: opacity * 0.30 * intensity,
          ),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = KartyBoostPalette.white.withValues(
            alpha: opacity * 0.78 * intensity,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.7, size.width * 0.012),
      );
    }
  }

  @override
  bool shouldRepaint(covariant KartyBoostBubblePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.intensity != intensity;
  }
}
