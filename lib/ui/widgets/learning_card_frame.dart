import 'package:flutter/material.dart';
import 'karty_card_rim.dart';

/// Karty'nin beyaz üst/sol kenarı, serin sağ kenarı ve katı alt dudağı.
class LearningCardFrame extends StatelessWidget {
  const LearningCardFrame({
    super.key,
    required this.width,
    required this.height,
    required this.radius,
    required this.borderWidth,
    required this.scale,
    required this.child,
    this.isRaised = false,
  });

  final double width;
  final double height;
  final double radius;
  final double borderWidth;
  final double scale;
  final Widget child;
  final bool isRaised;

  @override
  Widget build(BuildContext context) {
    final innerRadius = BorderRadius.circular(radius - borderWidth);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .267),
            blurRadius: (isRaised ? 34 : 22.5) * scale,
            offset: Offset(0, (isRaised ? 24 : 18.75) * scale),
          ),
          BoxShadow(
            color: const Color(0xFFBDC5D0),
            offset: Offset(0, 7.5 * scale),
          ),
        ],
      ),
      child: CustomPaint(
        painter: KartyCardRimPainter(radius: radius),
        child: Padding(
          padding: EdgeInsets.all(borderWidth),
          child: ClipRRect(
            borderRadius: innerRadius,
            child: Container(
              foregroundDecoration: BoxDecoration(
                borderRadius: innerRadius,
                border: Border.all(
                  color: const Color(0x25041227),
                  width: 3.75 * scale,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
