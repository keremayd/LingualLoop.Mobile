import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_button_style.dart';
import 'package:flutter/material.dart';

class BattleFeatureHomeCard extends StatefulWidget {
  const BattleFeatureHomeCard({
    super.key,
    required this.scale,
    required this.onTap,
  });

  final double scale;
  final VoidCallback onTap;

  @override
  State<BattleFeatureHomeCard> createState() => _BattleFeatureHomeCardState();
}

class _BattleFeatureHomeCardState extends State<BattleFeatureHomeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    const faceColor = Color(0xFFF52A2A);
    const baseColor = Color(0xFFAA1C1C);
    final offset = AppButtonStyle.tileDepth(10 * scale);
    final radius = BorderRadius.circular(AppButtonStyle.tileRadius(28 * scale));

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: SizedBox(
        width: 670 * scale,
        height: 275 * scale,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: offset,
              bottom: 0,
              child: DecoratedBox(
                decoration:
                    BoxDecoration(color: baseColor, borderRadius: radius),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 70),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              top: _pressed ? offset : 0,
              bottom: _pressed ? 0 : offset,
              child: Container(
                decoration:
                    BoxDecoration(color: faceColor, borderRadius: radius),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned(
                      left: 28 * scale,
                      top: 25 * scale,
                      child: Text(
                        'Battle',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 47 * scale,
                          fontWeight: AppTypography.heading,
                          fontFamily: AppTypography.displayFamily,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 31 * scale,
                      top: 83 * scale,
                      child: Text(
                        '1v1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26 * scale,
                          fontWeight: AppTypography.label,
                          fontFamily: AppTypography.family,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 31 * scale,
                      top: 126 * scale,
                      child: Text(
                        'Rakiplerinle 10\nsoruda kapış!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27 * scale,
                          fontWeight: AppTypography.body,
                          fontFamily: AppTypography.family,
                          height: 1.12,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 23 * scale,
                      bottom: 8 * scale,
                      child: Image.asset(
                        'assets/images/catsbattle.png',
                        width: 325 * scale,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      right: 20 * scale,
                      top: 18 * scale,
                      child: Image.asset(
                        'assets/icons/ticket-one.png',
                        width: 68 * scale,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
