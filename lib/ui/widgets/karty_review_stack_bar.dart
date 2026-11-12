import 'dart:math' as math;

import 'package:flutter/material.dart';

class KartyReviewStackBar extends StatelessWidget {
  const KartyReviewStackBar({
    super.key,
    required this.width,
    required this.height,
    required this.completedStack,
    required this.totalStack,
  });

  static const _fillColor = Color(0xFF93D334);
  // Süre çubuğuyla aynı yuva (patikadaki boş taşların laciverti).
  static const _trackColor = Color(0xFF163258);

  final double width;
  final double height;
  final int completedStack;
  final int totalStack;

  @override
  Widget build(BuildContext context) {
    final safeTotal = math.max(totalStack, 1);
    final safeCompleted = completedStack.clamp(0, safeTotal);
    final progress = safeCompleted / safeTotal;
    final segmentCount = safeTotal <= 12 ? safeTotal : 0;
    final radius = BorderRadius.circular(height / 2);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.centerLeft,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: _trackColor,
              borderRadius: radius,
            ),
          ),
          ClipRRect(
            borderRadius: radius,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              width: width * progress,
              height: height,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_fillColor, Color(0xFFA7E33F)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _fillColor.withValues(alpha: 0.28),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: EdgeInsets.only(
                    left: height * 0.34,
                    right: height * 0.34,
                    top: height * 0.12,
                  ),
                  height: height * 0.22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ),
          ),
          if (segmentCount > 1)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SegmentDividerPainter(count: segmentCount),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bölme çizgileri dolgunun yuvarlak ucuyla aynı biçimde: ")". Her yay,
/// dolgu o sınırda bitseydi oluşacak uçla aynı merkezde; dolgu bir sınırda
/// durduğunda yay ucun içinde onu tekrarlar ve bölüm tamamlanmış okunur.
/// Düz çizgi ucun hemen içinde "sınırı henüz geçmedi" gibi duruyordu.
class _SegmentDividerPainter extends CustomPainter {
  const _SegmentDividerPainter({required this.count});

  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    // Eski düz çizginin üst ve alt payı.
    final inset = height * 0.18;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var index = 1; index < count; index++) {
      final boundary = size.width * index / count;
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(boundary - height / 2, height / 2),
          radius: height / 2 - inset,
        ),
        -math.pi / 2,
        math.pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentDividerPainter oldDelegate) =>
      oldDelegate.count != count;
}
