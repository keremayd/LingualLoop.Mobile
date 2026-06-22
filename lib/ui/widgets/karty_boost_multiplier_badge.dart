import 'package:flutter/material.dart';

class KartyBoostMultiplierBadge extends StatefulWidget {
  const KartyBoostMultiplierBadge({super.key, required this.scale});

  final double scale;

  @override
  State<KartyBoostMultiplierBadge> createState() =>
      _KartyBoostMultiplierBadgeState();
}

class _KartyBoostMultiplierBadgeState extends State<KartyBoostMultiplierBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          width: 34 * widget.scale,
          height: 20 * widget.scale,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD52F),
            borderRadius: BorderRadius.circular(8 * widget.scale),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.5 * widget.scale,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB000).withValues(
                  alpha: 0.35 + (_glowController.value * 0.35),
                ),
                blurRadius: (5 + _glowController.value * 5) * widget.scale,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '×3',
            style: TextStyle(
              color: const Color(0xFF07182F),
              fontSize: 12 * widget.scale,
              fontWeight: FontWeight.w900,
              fontFamily: 'Inter',
              height: 1,
            ),
          ),
        );
      },
    );
  }
}
