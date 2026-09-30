import 'package:lingualloop/ui/app_typography.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/karty_boost_palette.dart';
import 'package:lingualloop/ui/widgets/karty_boost_bolt_mark.dart';

/// Aktif boost sırasında üç puanın lig sayacına aktarıldığını gösterir.
///
/// Sağ-alt köşeden kopan küçük şimşek üst satırdaki lig puanına gider.
/// Temasta yalnız üç iri kırık ve `+3` kalır; genel halka, nokta yağmuru,
/// "Harika" metni veya ikinci bir kutlama sistemi üretilmez.
class KartySuccessCelebration extends StatefulWidget {
  const KartySuccessCelebration({
    super.key,
    required this.scale,
    this.sourceKey,
    this.targetKey,
  });

  final double scale;
  final GlobalKey? sourceKey;
  final GlobalKey? targetKey;

  @override
  State<KartySuccessCelebration> createState() =>
      KartySuccessCelebrationState();
}

class KartySuccessCelebrationState extends State<KartySuccessCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _awardedPoints = 1;
  bool _isReviewMode = false;
  Offset? _source;
  Offset? _target;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
  }

  void play({
    required int streak,
    required int awardedPoints,
    bool isReviewMode = false,
  }) {
    _awardedPoints = awardedPoints;
    _isReviewMode = isReviewMode;
    if (isReviewMode || awardedPoints <= 1) return;

    final ownBox = context.findRenderObject() as RenderBox?;
    _source = _centerInLocal(widget.sourceKey, ownBox);
    _target = _centerInLocal(widget.targetKey, ownBox);
    _controller.forward(from: 0).whenComplete(() {
      if (mounted) _controller.reset();
    });
  }

  Offset? _centerInLocal(GlobalKey? key, RenderBox? ownBox) {
    if (key == null || ownBox == null || !ownBox.hasSize) return null;
    final targetBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (targetBox == null || !targetBox.hasSize) return null;
    final globalCenter =
        targetBox.localToGlobal(targetBox.size.center(Offset.zero));
    return ownBox.globalToLocal(globalCenter);
  }

  void stop() {
    _controller
      ..stop()
      ..reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (!size.isFinite || size.isEmpty) return const SizedBox.shrink();

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              if (_controller.value == 0 ||
                  _isReviewMode ||
                  _awardedPoints <= 1) {
                return const SizedBox.shrink();
              }

              final progress = _controller.value;
              final source =
                  _source ?? Offset(size.width * 0.73, size.height * 0.43);
              final target =
                  _target ?? Offset(size.width * 0.78, size.height * 0.12);
              final control = Offset(
                math.max(source.dx, target.dx) + 54 * widget.scale,
                (source.dy + target.dy) * 0.50,
              );
              final travel =
                  _interval(progress, 0, 0.68, Curves.easeInOutCubic);
              final projectileFade =
                  1 - _interval(progress, 0.66, 0.76, Curves.easeIn);
              final arrival =
                  _interval(progress, 0.61, 0.82, Curves.easeOutBack);
              final arrivalFade =
                  1 - _interval(progress, 0.84, 1, Curves.easeInCubic);

              return RepaintBoundary(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BoostArrivalPainter(
                          progress: progress,
                          scale: widget.scale,
                          target: target,
                        ),
                      ),
                    ),
                    for (var trail = 2; trail >= 0; trail--)
                      _projectile(
                        start: source,
                        control: control,
                        target: target,
                        travel: (travel - trail * 0.075).clamp(0.0, 1.0),
                        opacity: projectileFade *
                            (trail == 0 ? 1 : 0.12 * (3 - trail)),
                        height:
                            (trail == 0 ? 54 : 43 - trail * 4) * widget.scale,
                        bubblePhase: trail == 0 ? progress * 760 / 2400 : null,
                      ),
                    if (arrival > 0)
                      Positioned(
                        left: target.dx + 15 * widget.scale,
                        top: target.dy - 43 * widget.scale,
                        child: Opacity(
                          opacity: arrivalFade,
                          child: Transform.scale(
                            scale: arrival,
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              '+$_awardedPoints',
                              style: TextStyle(
                                color: KartyBoostPalette.blue,
                                fontFamily: AppTypography.family,
                                fontSize: 28 * widget.scale,
                                fontWeight: AppTypography.number,
                                height: 1,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF041227)
                                        .withValues(alpha: 0.82),
                                    blurRadius: 2 * widget.scale,
                                    offset: Offset(0, 2 * widget.scale),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _projectile({
    required Offset start,
    required Offset control,
    required Offset target,
    required double travel,
    required double opacity,
    required double height,
    double? bubblePhase,
  }) {
    final position = _quadraticBezier(start, control, target, travel);
    final ahead = _quadraticBezier(
      start,
      control,
      target,
      (travel + 0.015).clamp(0.0, 1.0),
    );
    final angle = math.atan2(ahead.dy - position.dy, ahead.dx - position.dx) +
        math.pi / 2;
    final width = height * 0.74;

    return Positioned(
      left: position.dx - width / 2,
      top: position.dy - height / 2,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: angle,
          child: KartyBoostBoltMark(
            height: height,
            face: KartyBoostPalette.blue,
            depth: KartyBoostPalette.blueDepth,
            highlight: trailHighlight(opacity),
            bubblePhase: bubblePhase,
          ),
        ),
      ),
    );
  }

  double trailHighlight(double opacity) => opacity > 0.6 ? 0.08 : 0.02;

  Offset _quadraticBezier(Offset start, Offset control, Offset end, double t) {
    final inverse = 1 - t;
    return Offset(
      inverse * inverse * start.dx +
          2 * inverse * t * control.dx +
          t * t * end.dx,
      inverse * inverse * start.dy +
          2 * inverse * t * control.dy +
          t * t * end.dy,
    );
  }

  double _interval(double value, double begin, double end, Curve curve) {
    if (value <= begin) return 0;
    if (value >= end) return 1;
    return curve.transform((value - begin) / (end - begin));
  }
}

class _BoostArrivalPainter extends CustomPainter {
  const _BoostArrivalPainter({
    required this.progress,
    required this.scale,
    required this.target,
  });

  final double progress;
  final double scale;
  final Offset target;

  @override
  void paint(Canvas canvas, Size size) {
    final fly = _interval(progress, 0.63, 0.84, Curves.easeOutCubic);
    final fade = 1 - _interval(progress, 0.82, 1, Curves.easeInCubic);
    if (fly <= 0 || fade <= 0) return;

    const data = [
      (-2.55, 35.0, -0.25),
      (-1.47, 42.0, 0.35),
      (-0.37, 37.0, -0.42),
    ];
    for (var index = 0; index < data.length; index++) {
      final item = data[index];
      final direction = Offset(math.cos(item.$1), math.sin(item.$1));
      final center = target +
          direction * item.$2 * fly * scale +
          Offset(0, 8 * fly * fly * scale);
      final shard = Path()
        ..moveTo(0, -11 * scale)
        ..lineTo(7 * scale, -1 * scale)
        ..lineTo(-1 * scale, 13 * scale)
        ..lineTo(-6 * scale, 2 * scale)
        ..close();
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(item.$1 + item.$3 * fly);
      canvas.drawPath(
        shard,
        Paint()
          ..color =
              (index == 1 ? KartyBoostPalette.white : KartyBoostPalette.blue)
                  .withValues(alpha: 0.92 * fade),
      );
      canvas.restore();
    }

    final snap = _interval(progress, 0.62, 0.72, Curves.easeOutBack) * fade;
    if (snap > 0) {
      final burst = Path();
      const points = 7;
      for (var index = 0; index < points * 2; index++) {
        final angle = math.pi * index / points;
        final radius = (index.isEven ? 18 : 8) * snap * scale;
        final point =
            target + Offset(math.cos(angle), math.sin(angle)) * radius;
        if (index == 0) {
          burst.moveTo(point.dx, point.dy);
        } else {
          burst.lineTo(point.dx, point.dy);
        }
      }
      burst.close();
      canvas.drawPath(
        burst,
        Paint()..color = KartyBoostPalette.white.withValues(alpha: fade),
      );
    }
  }

  double _interval(double value, double begin, double end, Curve curve) {
    if (value <= begin) return 0;
    if (value >= end) return 1;
    return curve.transform((value - begin) / (end - begin));
  }

  @override
  bool shouldRepaint(covariant _BoostArrivalPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.scale != scale ||
        oldDelegate.target != target;
  }
}
