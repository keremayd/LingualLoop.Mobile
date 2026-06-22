import 'dart:math' as math;

import 'package:flutter/material.dart';

class KartySuccessCelebration extends StatefulWidget {
  const KartySuccessCelebration({
    super.key,
    required this.scale,
  });

  final double scale;

  @override
  State<KartySuccessCelebration> createState() =>
      KartySuccessCelebrationState();
}

class KartySuccessCelebrationState extends State<KartySuccessCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _streak = 1;
  int _awardedPoints = 1;
  bool _isReviewMode = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
  }

  void play({
    required int streak,
    required int awardedPoints,
    bool isReviewMode = false,
  }) {
    setState(() {
      _streak = streak;
      _awardedPoints = awardedPoints;
      _isReviewMode = isReviewMode;
    });
    _controller.forward(from: 0).whenComplete(() {
      if (mounted) _controller.reset();
    });
  }

  void stop() {
    _controller.stop();
    _controller.reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_controller.value == 0) return const SizedBox.shrink();
          return RepaintBoundary(
            child: CustomPaint(
              painter: _KartySuccessPainter(
                progress: _controller.value,
                scale: widget.scale,
                streak: _streak,
                awardedPoints: _awardedPoints,
                isReviewMode: _isReviewMode,
              ),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}

class _KartySuccessPainter extends CustomPainter {
  const _KartySuccessPainter({
    required this.progress,
    required this.scale,
    required this.streak,
    required this.awardedPoints,
    required this.isReviewMode,
  });

  final double progress;
  final double scale;
  final int streak;
  final int awardedPoints;
  final bool isReviewMode;

  static const _yellow = Color(0xFFFFD52F);
  static const _orange = Color(0xFFFF9300);
  static const _lime = Color(0xFF93D334);
  static const _navy = Color(0xFF0B2143);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (!isReviewMode) {
      _drawScoreTransfer(
        canvas,
        size,
        Offset(size.width / 2 + 205 * scale, 535 * scale),
      );
    }
    _drawSuccessBadge(canvas, size);
  }

  void _drawScoreTransfer(Canvas canvas, Size size, Offset start) {
    final travel = _interval(progress, 0.18, 0.7, Curves.easeInOutCubic);
    if (travel <= 0) return;

    final target = Offset(size.width - 167 * scale, 187 * scale);
    final control = Offset(size.width * 0.84, start.dy * 0.58);
    final energyPosition = _quadraticBezier(start, control, target, travel);
    final previousPosition = _quadraticBezier(
      start,
      control,
      target,
      math.max(0, travel - 0.065),
    );
    final travelOpacity =
        1 - _interval(progress, 0.7, 0.82, Curves.easeInCubic);

    final trailPath = Path()..moveTo(previousPosition.dx, previousPosition.dy);
    trailPath.quadraticBezierTo(
      (previousPosition.dx + energyPosition.dx) / 2 + 7 * scale,
      (previousPosition.dy + energyPosition.dy) / 2,
      energyPosition.dx,
      energyPosition.dy,
    );
    canvas.drawPath(
      trailPath,
      Paint()
        ..color = _yellow.withValues(alpha: 0.26 * travelOpacity)
        ..strokeWidth = 15 * scale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 11 * scale),
    );
    canvas.drawPath(
      trailPath,
      Paint()
        ..shader = LinearGradient(
          colors: [_lime.withValues(alpha: 0), Colors.white, _yellow],
        ).createShader(Rect.fromPoints(previousPosition, energyPosition))
        ..strokeWidth = 4.5 * scale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    _drawEnergyComet(
      canvas,
      energyPosition,
      previousPosition,
      travelOpacity,
    );

    final arrival = _interval(progress, 0.65, 0.84, Curves.easeOutBack);
    if (arrival <= 0) return;
    final arrivalFade = 1 - _interval(progress, 0.8, 0.94, Curves.easeInCubic);
    canvas.drawCircle(
      target,
      (18 + arrival * 34) * scale,
      Paint()
        ..color = _yellow.withValues(alpha: 0.3 * arrivalFade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * scale,
    );

    final pointOpacity =
        (arrival * (1 - _interval(progress, 0.76, 0.94, Curves.easeIn)))
            .clamp(0.0, 1.0);
    _drawText(
      canvas,
      '+$awardedPoints',
      Offset(target.dx + 14 * scale, target.dy - 34 * scale),
      fontSize: 31 * scale,
      color: _yellow.withValues(alpha: pointOpacity),
      strokeColor: _navy.withValues(alpha: pointOpacity),
      strokeWidth: 5 * scale,
    );
  }

  void _drawEnergyComet(
    Canvas canvas,
    Offset center,
    Offset previous,
    double opacity,
  ) {
    final direction = center - previous;
    final length = math.max(direction.distance, 0.001);
    final unit = direction / length;
    for (var index = 4; index >= 1; index--) {
      final beadCenter = center - unit * index.toDouble() * 10 * scale;
      final beadRadius = (7 - index * 1.05) * scale;
      canvas.drawCircle(
        beadCenter,
        beadRadius,
        Paint()
          ..color = Color.lerp(_lime, _yellow, index / 4)!
              .withValues(alpha: opacity * (0.16 + index * 0.08))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale),
      );
    }
    canvas.drawCircle(
      center,
      24 * scale,
      Paint()
        ..color = _yellow.withValues(alpha: 0.22 * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 13 * scale),
    );
    canvas.drawCircle(
      center,
      9 * scale,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: opacity),
            _yellow.withValues(alpha: opacity),
            _orange.withValues(alpha: opacity * 0.72),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: 9 * scale),
        ),
    );
  }

  void _drawSuccessBadge(Canvas canvas, Size size) {
    final appear = _interval(progress, 0.08, 0.28, Curves.easeOutBack);
    final disappear = 1 - _interval(progress, 0.66, 0.9, Curves.easeInCubic);
    final opacity = (appear * disappear).clamp(0.0, 1.0);
    if (opacity <= 0) return;

    final isStreakMoment = streak >= 3;
    final title = isReviewMode
        ? 'ÖĞRENDİN!'
        : isStreakMoment
            ? 'SERİ $streak!'
            : 'HARİKA!';
    final center = Offset(size.width / 2, 270 * scale);
    final badgeRect = Rect.fromCenter(
      center: center,
      width: (isStreakMoment ? 230 : 205) * scale * appear,
      height: 58 * scale * appear,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, Radius.circular(24 * scale)),
      Paint()
        ..color = _yellow.withValues(alpha: 0.18 * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18 * scale),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, Radius.circular(24 * scale)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            _yellow.withValues(alpha: opacity),
            _orange.withValues(alpha: opacity),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(badgeRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, Radius.circular(24 * scale)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.62 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * scale,
    );
    _drawText(
      canvas,
      title,
      center,
      fontSize: 27 * scale * appear,
      color: Colors.white.withValues(alpha: opacity),
      strokeColor: _navy.withValues(alpha: 0.3 * opacity),
      strokeWidth: 2.5 * scale,
      centered: true,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position, {
    required double fontSize,
    required Color color,
    required Color strokeColor,
    required double strokeWidth,
    bool centered = false,
  }) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      fontFamily: 'Inter',
      height: 1,
    );
    final strokePainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(
          foreground: Paint()
            ..color = strokeColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final fillPainter = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = centered
        ? position - Offset(fillPainter.width / 2, fillPainter.height / 2)
        : position;
    strokePainter.paint(canvas, offset);
    fillPainter.paint(canvas, offset);
  }

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

  @override
  bool shouldRepaint(covariant _KartySuccessPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.scale != scale ||
        oldDelegate.streak != streak ||
        oldDelegate.awardedPoints != awardedPoints ||
        oldDelegate.isReviewMode != isReviewMode;
  }
}
