import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

class KartyFeedbackWord extends StatefulWidget {
  const KartyFeedbackWord({
    super.key,
    required this.text,
    required this.scale,
    required this.isCorrectActive,
    required this.isWrongActive,
  });

  final String text;
  final double scale;
  final ValueListenable<bool> isCorrectActive;
  final ValueListenable<bool> isWrongActive;

  @override
  State<KartyFeedbackWord> createState() => _KartyFeedbackWordState();
}

class _KartyFeedbackWordState extends State<KartyFeedbackWord>
    with TickerProviderStateMixin {
  late final AnimationController _correctController;
  late final AnimationController _wrongController;

  @override
  void initState() {
    super.initState();
    _correctController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _wrongController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    widget.isCorrectActive.addListener(_handleCorrectState);
    widget.isWrongActive.addListener(_handleWrongState);
  }

  void _handleCorrectState() {
    widget.isCorrectActive.value
        ? _correctController.forward(from: 0)
        : _correctController.reset();
  }

  void _handleWrongState() {
    widget.isWrongActive.value
        ? _wrongController.forward(from: 0)
        : _wrongController.reset();
  }

  @override
  void didUpdateWidget(covariant KartyFeedbackWord oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCorrectActive != widget.isCorrectActive) {
      oldWidget.isCorrectActive.removeListener(_handleCorrectState);
      widget.isCorrectActive.addListener(_handleCorrectState);
    }
    if (oldWidget.isWrongActive != widget.isWrongActive) {
      oldWidget.isWrongActive.removeListener(_handleWrongState);
      widget.isWrongActive.addListener(_handleWrongState);
    }
  }

  @override
  void dispose() {
    widget.isCorrectActive.removeListener(_handleCorrectState);
    widget.isWrongActive.removeListener(_handleWrongState);
    _correctController.dispose();
    _wrongController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_correctController, _wrongController]),
      builder: (context, child) {
        final correct = _correctController.value;
        final wrong = _wrongController.value;
        final correctEnvelope = math.sin(correct * math.pi).clamp(0.0, 1.0);
        final wrongEnvelope = math.sin(wrong * math.pi).clamp(0.0, 1.0);
        final shake =
            math.sin(wrong * math.pi * 10) * 7 * widget.scale * wrongEnvelope;
        final textColor = Color.lerp(
          Colors.white,
          const Color(0xFFFF6A55),
          wrongEnvelope * 0.85,
        )!;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(
            scale: 1 + correctEnvelope * 0.035 - wrongEnvelope * 0.018,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (correctEnvelope > 0)
                  Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle.copyWith(
                      foreground: Paint()
                        ..color = const Color(0xFFFFD52F).withValues(
                          alpha: 0.45 * correctEnvelope,
                        )
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 9 * widget.scale
                        ..maskFilter = MaskFilter.blur(
                          BlurStyle.normal,
                          (7 + correct * 5) * widget.scale,
                        ),
                    ),
                  ),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) {
                    if (correctEnvelope == 0) {
                      return LinearGradient(colors: [textColor, textColor])
                          .createShader(bounds);
                    }
                    return LinearGradient(
                      begin: Alignment(-1.8 + correct * 3.6, -1),
                      end: Alignment(-0.6 + correct * 3.6, 1),
                      colors: const [
                        Colors.white,
                        Color(0xFFFFF3A3),
                        Colors.white,
                      ],
                      stops: const [0, 0.5, 1],
                    ).createShader(bounds);
                  },
                  child: Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  TextStyle get _textStyle => TextStyle(
        color: Colors.white,
        fontSize: 78 * widget.scale,
        fontWeight: FontWeight.w900,
        fontFamily: 'Inter',
        height: 1.05,
      );
}

class KartyCardFeedbackEffect extends StatefulWidget {
  const KartyCardFeedbackEffect({
    super.key,
    required this.scale,
    required this.isCorrectActive,
    required this.isWrongActive,
  });

  final double scale;
  final ValueListenable<bool> isCorrectActive;
  final ValueListenable<bool> isWrongActive;

  @override
  State<KartyCardFeedbackEffect> createState() =>
      _KartyCardFeedbackEffectState();
}

class _KartyCardFeedbackEffectState extends State<KartyCardFeedbackEffect>
    with TickerProviderStateMixin {
  late final AnimationController _correctController;
  late final AnimationController _wrongController;

  @override
  void initState() {
    super.initState();
    _correctController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _wrongController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );
    widget.isCorrectActive.addListener(_handleCorrectState);
    widget.isWrongActive.addListener(_handleWrongState);
  }

  void _handleCorrectState() {
    widget.isCorrectActive.value
        ? _correctController.forward(from: 0)
        : _correctController.reset();
  }

  void _handleWrongState() {
    widget.isWrongActive.value
        ? _wrongController.forward(from: 0)
        : _wrongController.reset();
  }

  @override
  void didUpdateWidget(covariant KartyCardFeedbackEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCorrectActive != widget.isCorrectActive) {
      oldWidget.isCorrectActive.removeListener(_handleCorrectState);
      widget.isCorrectActive.addListener(_handleCorrectState);
    }
    if (oldWidget.isWrongActive != widget.isWrongActive) {
      oldWidget.isWrongActive.removeListener(_handleWrongState);
      widget.isWrongActive.addListener(_handleWrongState);
    }
  }

  @override
  void dispose() {
    widget.isCorrectActive.removeListener(_handleCorrectState);
    widget.isWrongActive.removeListener(_handleWrongState);
    _correctController.dispose();
    _wrongController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_correctController, _wrongController]),
          builder: (context, child) {
            if (_correctController.value == 0 && _wrongController.value == 0) {
              return const SizedBox.shrink();
            }
            return CustomPaint(
              painter: _KartyCardFeedbackPainter(
                correctProgress: _correctController.value,
                wrongProgress: _wrongController.value,
                scale: widget.scale,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _KartyCardFeedbackPainter extends CustomPainter {
  const _KartyCardFeedbackPainter({
    required this.correctProgress,
    required this.wrongProgress,
    required this.scale,
  });

  final double correctProgress;
  final double wrongProgress;
  final double scale;

  static const _yellow = Color(0xFFFFD52F);
  static const _lime = Color(0xFF93D334);
  static const _deepGreen = Color(0xFF659D22);
  static const _wrongRed = Color(0xFFFF4D3D);
  static const _wrongOrange = Color(0xFFFF7A38);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final inset = 3 * scale;
    final rimRect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final rimPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rimRect, Radius.circular(56 * scale)),
      );
    final metric = rimPath.computeMetrics().first;

    if (correctProgress > 0) {
      _drawCorrectEnergy(canvas, rimRect, rimPath, metric);
    }
    if (wrongProgress > 0) {
      _drawWrongDrain(canvas, size, rimPath, metric);
    }
  }

  void _drawCorrectEnergy(
    Canvas canvas,
    Rect rimRect,
    Path rimPath,
    PathMetric metric,
  ) {
    final rise = Curves.easeOutCubic.transform(
      (correctProgress / 0.28).clamp(0.0, 1.0),
    );
    final fade = 1 -
        Curves.easeInCubic.transform(
          ((correctProgress - 0.7) / 0.3).clamp(0.0, 1.0),
        );
    final opacity = rise * fade;

    canvas.drawPath(
      rimPath,
      Paint()
        ..color = _yellow.withValues(alpha: 0.32 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20 * scale
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 * scale),
    );
    canvas.drawPath(
      rimPath,
      Paint()
        ..shader = SweepGradient(
          transform: GradientRotation(correctProgress * math.pi * 4.8),
          colors: [
            _lime.withValues(alpha: 0.12 * opacity),
            Colors.white.withValues(alpha: 0.98 * opacity),
            _yellow.withValues(alpha: opacity),
            _deepGreen.withValues(alpha: 0.72 * opacity),
            _lime.withValues(alpha: 0.12 * opacity),
          ],
          stops: const [0, 0.18, 0.36, 0.58, 1],
        ).createShader(rimRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * scale
        ..strokeCap = StrokeCap.round,
    );

    for (var index = 0; index < 8; index++) {
      final travel = (correctProgress * 1.35 + index / 8) % 1;
      final tangent = metric.getTangentForOffset(metric.length * travel);
      if (tangent == null) continue;
      final radius = (4 + index % 3 * 2) * scale;
      canvas.drawCircle(
        tangent.position,
        radius * 2.2,
        Paint()
          ..color = _yellow.withValues(alpha: 0.2 * opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * scale),
      );
      canvas.drawCircle(
        tangent.position,
        radius,
        Paint()
          ..color = (index.isEven ? Colors.white : _yellow)
              .withValues(alpha: 0.92 * opacity),
      );
    }
  }

  void _drawWrongDrain(
    Canvas canvas,
    Size size,
    Path rimPath,
    PathMetric metric,
  ) {
    final strike = math.sin(
      (wrongProgress / 0.42).clamp(0.0, 1.0) * math.pi,
    );
    final fade = 1 -
        Curves.easeInCubic.transform(
          ((wrongProgress - 0.62) / 0.38).clamp(0.0, 1.0),
        );

    canvas.drawPath(
      rimPath,
      Paint()
        ..color = _wrongRed.withValues(alpha: 0.42 * strike * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18 * scale
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * scale),
    );
    canvas.drawPath(
      rimPath,
      Paint()
        ..shader = SweepGradient(
          transform: GradientRotation(-wrongProgress * math.pi * 2.2),
          colors: [
            _wrongRed.withValues(alpha: 0.05 * fade),
            _wrongOrange.withValues(alpha: 0.88 * fade),
            _wrongRed.withValues(alpha: 0.68 * fade),
            _wrongRed.withValues(alpha: 0.05 * fade),
          ],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * scale,
    );

    for (var index = 0; index < 11; index++) {
      final delay = index * 0.035;
      final particleProgress =
          ((wrongProgress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (particleProgress <= 0 || particleProgress >= 1) continue;
      final tangent = metric.getTangentForOffset(
        ((index * 0.137) % 1) * metric.length,
      );
      if (tangent == null) continue;

      final direction = tangent.position - size.center(Offset.zero);
      final normalized = direction.distance == 0
          ? const Offset(0, 1)
          : direction / direction.distance;
      final drift = Offset(
        math.sin(index * 2.1) * 28 * scale,
        (24 + index % 4 * 13) * scale,
      );
      final position = tangent.position +
          normalized * (particleProgress * 64 * scale) +
          drift * particleProgress;
      final particleOpacity =
          math.sin(particleProgress * math.pi).clamp(0.0, 1.0) * fade;
      _drawEnergyDroplet(
        canvas,
        position,
        (7 + index % 3 * 3) * scale * (1 - particleProgress * 0.35),
        math.atan2(normalized.dy, normalized.dx) + particleProgress,
        Color.lerp(_wrongOrange, _wrongRed, index / 11)!
            .withValues(alpha: particleOpacity),
      );
    }
  }

  void _drawEnergyDroplet(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    Color color,
  ) {
    final path = Path()
      ..moveTo(0, -radius * 1.4)
      ..cubicTo(
          radius * 0.9, -radius * 0.45, radius * 0.75, radius * 0.8, 0, radius)
      ..cubicTo(-radius * 0.75, radius * 0.8, -radius * 0.9, -radius * 0.45, 0,
          -radius * 1.4)
      ..close();
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: color.a * 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * scale),
    );
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KartyCardFeedbackPainter oldDelegate) {
    return oldDelegate.correctProgress != correctProgress ||
        oldDelegate.wrongProgress != wrongProgress ||
        oldDelegate.scale != scale;
  }
}
