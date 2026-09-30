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
  static const _trackColor = Color(0xFFF4F6FB);

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
            ...List.generate(segmentCount - 1, (index) {
              final left = width * ((index + 1) / segmentCount);
              return Positioned(
                left: left - 1,
                top: height * 0.18,
                bottom: height * 0.18,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
