import 'dart:math' as math;
import 'dart:ui' show PathMetric, Tangent;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

class KartyBoostCardEffect extends StatefulWidget {
  const KartyBoostCardEffect({
    super.key,
    required this.scale,
    required this.boostProgress,
    this.isBackground = false,
    this.isReceivingEnergy = false,
  });

  final double scale;
  final ValueListenable<double> boostProgress;
  final bool isBackground;
  final bool isReceivingEnergy;

  @override
  State<KartyBoostCardEffect> createState() => _KartyBoostCardEffectState();
}

class _KartyBoostCardEffectState extends State<KartyBoostCardEffect>
    with TickerProviderStateMixin {
  late final AnimationController _cycleController;
  late final AnimationController _transferController;

  @override
  void initState() {
    super.initState();
    _cycleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _transferController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    if (widget.isReceivingEnergy || !widget.isBackground) {
      _transferController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant KartyBoostCardEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isReceivingEnergy && widget.isReceivingEnergy) {
      _transferController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _cycleController.dispose();
    _transferController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.boostProgress,
      builder: (context, progress, child) {
        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _cycleController,
              _transferController,
            ]),
            builder: (context, child) {
              return IgnorePointer(
                child: CustomPaint(
                  painter: _KartyBoostEnergyPainter(
                    phase: _cycleController.value,
                    transfer: _transferController.value,
                    boostProgress: progress.clamp(0.0, 1.0),
                    scale: widget.scale,
                    isBackground: widget.isBackground,
                  ),
                  size: Size.infinite,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _KartyBoostEnergyPainter extends CustomPainter {
  const _KartyBoostEnergyPainter({
    required this.phase,
    required this.transfer,
    required this.boostProgress,
    required this.scale,
    required this.isBackground,
  });

  final double phase;
  final double transfer;
  final double boostProgress;
  final double scale;
  final bool isBackground;

  static const _energyYellow = Color(0xFFFFD52F);
  static const _energyWhite = Color(0xFFFFF7C2);
  static const _energyOrange = Color(0xFFFF9D1C);

  double get _energyOpacity => 0.12 + (boostProgress * 0.88);
  double get _powerScale => 0.6 + (boostProgress * 0.78);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final inset = 5 * scale;
    final radius = Radius.circular(53 * scale);
    final borderPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - inset * 2,
            size.height - inset * 2,
          ),
          radius,
        ),
      );
    final metric = borderPath.computeMetrics().first;
    final rimOuterPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(58 * scale),
        ),
      );
    final rimInnerPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            27 * scale,
            27 * scale,
            size.width - 54 * scale,
            size.height - 54 * scale,
          ),
          Radius.circular(31 * scale),
        ),
      );
    final rimBand = Path.combine(
      PathOperation.difference,
      rimOuterPath,
      rimInnerPath,
    );
    final rimCenterPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            14 * scale,
            14 * scale,
            size.width - 28 * scale,
            size.height - 28 * scale,
          ),
          Radius.circular(45 * scale),
        ),
      );
    final rimMetric = rimCenterPath.computeMetrics().first;
    final backgroundOpacity = (isBackground ? 0.72 : 1.0) * _energyOpacity;

    final topLeftBolt = Offset(78 * scale, 89 * scale);
    final bottomRightBolt = Offset(
      size.width - 78 * scale,
      size.height - 89 * scale,
    );

    if (isBackground) {
      final receivedEnergy = Curves.easeOutCubic.transform(transfer);
      if (receivedEnergy > 0) {
        _drawEnergizedRim(
          canvas,
          size,
          rimBand,
          rimMetric,
          backgroundOpacity * receivedEnergy,
        );
        _drawAmbientRim(
          canvas,
          borderPath,
          backgroundOpacity * receivedEnergy,
        );
        _drawTravelingTrace(
          canvas,
          rimMetric,
          backgroundOpacity * receivedEnergy,
        );
      }
    } else {
      _drawEnergizedRim(
        canvas,
        size,
        rimBand,
        rimMetric,
        backgroundOpacity,
      );
      _drawAmbientRim(canvas, borderPath, backgroundOpacity);
      _drawTravelingTrace(canvas, rimMetric, backgroundOpacity);

      final firstDischarge = _pulseEnvelope(phase, 0.08, 0.15);
      final secondDischarge = _pulseEnvelope(phase, 0.58, 0.15);
      _drawBoltDischarge(
        canvas,
        from: topLeftBolt,
        to: Offset(inset + 4 * scale, 58 * scale),
        intensity: firstDischarge * backgroundOpacity,
        seed: 3,
      );
      _drawBoltDischarge(
        canvas,
        from: bottomRightBolt,
        to: Offset(size.width - inset - 4 * scale, size.height - 58 * scale),
        intensity: secondDischarge * backgroundOpacity,
        seed: 11,
      );

      _drawBoltHalo(canvas, topLeftBolt, firstDischarge * backgroundOpacity);
      _drawBoltHalo(
        canvas,
        bottomRightBolt,
        secondDischarge * backgroundOpacity,
      );
    }

    if (transfer > 0 && transfer < 1) {
      _drawEnergyTransfer(
        canvas,
        metric,
        topLeftBolt,
        bottomRightBolt,
      );
    }
  }

  void _drawEnergizedRim(
    Canvas canvas,
    Size size,
    Path rimBand,
    PathMetric rimMetric,
    double opacity,
  ) {
    canvas.save();
    canvas.clipPath(rimBand);

    canvas.drawPath(
      rimBand,
      Paint()
        ..color = _energyYellow.withValues(alpha: 0.1 * opacity)
        ..style = PaintingStyle.fill,
    );

    final flowRotation = phase * math.pi * 2;
    canvas.drawPath(
      rimBand,
      Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          transform: GradientRotation(flowRotation),
          colors: [
            _energyYellow.withValues(alpha: 0.05 * opacity),
            _energyWhite.withValues(alpha: 0.34 * opacity),
            _energyOrange.withValues(alpha: 0.15 * opacity),
            _energyYellow.withValues(alpha: 0.08 * opacity),
            _energyWhite.withValues(alpha: 0.28 * opacity),
            _energyYellow.withValues(alpha: 0.05 * opacity),
          ],
          stops: const [0, 0.16, 0.34, 0.57, 0.78, 1],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.fill,
    );

    final packetCount = isBackground ? 3 : 6;
    for (var index = 0; index < packetCount; index++) {
      final packetPhase =
          (phase * (0.55 + index * 0.035) + index / packetCount) % 1;
      final tangent = rimMetric.getTangentForOffset(
        rimMetric.length * packetPhase,
      );
      if (tangent == null) continue;

      final radius = (8 + (index % 3) * 3) * scale * _powerScale;
      canvas.drawCircle(
        tangent.position,
        radius,
        Paint()
          ..color = (index.isEven ? _energyYellow : _energyWhite)
              .withValues(alpha: 0.22 * opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * scale),
      );
    }

    final bubbleCount = isBackground ? 5 : 12;
    for (var index = 0; index < bubbleCount; index++) {
      final speed = 0.34 + (index % 4) * 0.055;
      final bubblePhase = (phase * speed + index / bubbleCount) % 1;
      final tangent = rimMetric.getTangentForOffset(
        rimMetric.length * bubblePhase,
      );
      if (tangent == null) continue;

      final vectorLength = tangent.vector.distance;
      if (vectorLength == 0) continue;
      final normal = Offset(
            -tangent.vector.dy,
            tangent.vector.dx,
          ) /
          vectorLength;
      final laneOffset =
          math.sin((phase * math.pi * 2) + index * 1.7) * 5 * scale;
      final center = tangent.position + normal * laneOffset;
      final radius = (2.2 + (index % 4) * 0.9) * scale * _powerScale;
      final shimmer = 0.68 + math.sin((phase * math.pi * 2) + index) * 0.2;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = _energyWhite.withValues(
            alpha: shimmer * 0.52 * opacity,
          )
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 * scale,
      );
      canvas.drawCircle(
        center - Offset(radius * 0.28, radius * 0.32),
        radius * 0.22,
        Paint()..color = Colors.white.withValues(alpha: 0.9 * opacity),
      );
    }

    canvas.restore();
  }

  void _drawAmbientRim(Canvas canvas, Path borderPath, double opacity) {
    canvas.drawPath(
      borderPath,
      Paint()
        ..color = _energyYellow.withValues(alpha: 0.1 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * scale * _powerScale
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 9 * scale),
    );
  }

  void _drawTravelingTrace(
    Canvas canvas,
    PathMetric metric,
    double opacity,
  ) {
    final start = metric.length * phase;
    final length = metric.length * (isBackground ? 0.08 : 0.16);
    final trace = _buildElectricTrace(metric, start, length);
    final flicker = 0.86 + math.sin(phase * math.pi * 18) * 0.14;

    canvas.drawPath(
      trace,
      Paint()
        ..color = _energyOrange.withValues(alpha: 0.42 * opacity * flicker)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14 * scale * _powerScale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 9 * scale),
    );
    canvas.drawPath(
      trace,
      Paint()
        ..color = _energyYellow.withValues(alpha: 0.95 * opacity * flicker)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (isBackground ? 2.8 : 4.6) * scale * _powerScale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      trace,
      Paint()
        ..color = _energyWhite.withValues(alpha: 0.94 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (isBackground ? 0.9 : 1.7) * scale * _powerScale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final head = metric.getTangentForOffset((start + length) % metric.length);
    if (head == null) return;
    canvas.drawCircle(
      head.position,
      4.5 * scale * _powerScale,
      Paint()
        ..color = _energyWhite.withValues(alpha: 0.9 * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale),
    );

    if (!isBackground) {
      _drawElectricBranches(canvas, metric, start, length, opacity);
      _drawElectricHead(canvas, head, opacity * flicker);
    }
  }

  Path _buildElectricTrace(
    PathMetric metric,
    double start,
    double length,
  ) {
    final path = Path();
    final segmentCount = isBackground ? 12 : 24;
    var hasStarted = false;

    for (var index = 0; index <= segmentCount; index++) {
      final t = index / segmentCount;
      final tangent = metric.getTangentForOffset(
        (start + length * t) % metric.length,
      );
      if (tangent == null) continue;

      final vectorLength = tangent.vector.distance;
      if (vectorLength == 0) continue;
      final normal =
          Offset(-tangent.vector.dy, tangent.vector.dx) / vectorLength;
      final envelope = math.sin(t * math.pi);
      final jitter = (math.sin(index * 4.7 + phase * math.pi * 20) * 0.68 +
          math.sin(index * 8.9 - phase * math.pi * 13) * 0.32);
      final point = tangent.position +
          normal * jitter * envelope * (isBackground ? 1.8 : 3.8) * scale;

      if (!hasStarted) {
        path.moveTo(point.dx, point.dy);
        hasStarted = true;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  void _drawElectricBranches(
    Canvas canvas,
    PathMetric metric,
    double start,
    double length,
    double opacity,
  ) {
    const branchPositions = [0.28, 0.57, 0.81];
    for (var index = 0; index < branchPositions.length; index++) {
      final t = branchPositions[index];
      final tangent = metric.getTangentForOffset(
        (start + length * t) % metric.length,
      );
      if (tangent == null || tangent.vector.distance == 0) continue;

      final normal = Offset(-tangent.vector.dy, tangent.vector.dx) /
          tangent.vector.distance;
      final direction = index.isEven ? 1.0 : -1.0;
      final branchEnd = tangent.position +
          normal * direction * (7 + index * 1.5) * scale +
          tangent.vector / tangent.vector.distance * 3 * scale;
      final branchMid = Offset.lerp(tangent.position, branchEnd, 0.52)! +
          normal * -direction * 2.2 * scale;
      final branch = Path()
        ..moveTo(tangent.position.dx, tangent.position.dy)
        ..lineTo(branchMid.dx, branchMid.dy)
        ..lineTo(branchEnd.dx, branchEnd.dy);

      canvas.drawPath(
        branch,
        Paint()
          ..color = _energyWhite.withValues(alpha: 0.7 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.15 * scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  void _drawElectricHead(Canvas canvas, Tangent head, double opacity) {
    final vectorLength = head.vector.distance;
    if (vectorLength == 0) return;
    final direction = head.vector / vectorLength;
    final normal = Offset(-direction.dy, direction.dx);

    for (var index = 0; index < 4; index++) {
      final angleOffset = (index - 1.5) * 0.56;
      final rayDirection =
          direction * math.cos(angleOffset) + normal * math.sin(angleOffset);
      canvas.drawLine(
        head.position,
        head.position + rayDirection * ((7 + index) * scale),
        Paint()
          ..color = _energyWhite.withValues(alpha: 0.62 * opacity)
          ..strokeWidth = 1.2 * scale
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  Path _extractWrappedPath(PathMetric metric, double start, double length) {
    final end = start + length;
    if (end <= metric.length) {
      return metric.extractPath(start, end);
    }

    return Path()
      ..addPath(metric.extractPath(start, metric.length), Offset.zero)
      ..addPath(metric.extractPath(0, end - metric.length), Offset.zero);
  }

  void _drawBoltDischarge(
    Canvas canvas, {
    required Offset from,
    required Offset to,
    required double intensity,
    required int seed,
  }) {
    if (intensity <= 0.01) return;

    final path = _jaggedPath(from, to, seed);
    canvas.drawPath(
      path,
      Paint()
        ..color = _energyYellow.withValues(alpha: 0.52 * intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9 * scale * _powerScale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * scale),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = _energyWhite.withValues(alpha: 0.95 * intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * scale * _powerScale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final midpoint = Offset.lerp(from, to, 0.55)!;
    final branchEnd = midpoint +
        Offset(
          (seed.isEven ? 14 : -14) * scale,
          (seed.isEven ? -24 : 24) * scale,
        );
    final branch = _jaggedPath(midpoint, branchEnd, seed + 4, segments: 3);
    canvas.drawPath(
      branch,
      Paint()
        ..color = _energyWhite.withValues(alpha: 0.7 * intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale * _powerScale
        ..strokeCap = StrokeCap.round,
    );
  }

  Path _jaggedPath(
    Offset from,
    Offset to,
    int seed, {
    int segments = 6,
  }) {
    final random = math.Random(seed);
    final direction = to - from;
    final distance = direction.distance;
    final normal = Offset(-direction.dy, direction.dx) / distance;
    final path = Path()..moveTo(from.dx, from.dy);

    for (var index = 1; index < segments; index++) {
      final t = index / segments;
      final falloff = math.sin(t * math.pi);
      final offset = (random.nextDouble() * 2 - 1) * 13 * scale * falloff;
      final point = Offset.lerp(from, to, t)! + normal * offset;
      path.lineTo(point.dx, point.dy);
    }
    path.lineTo(to.dx, to.dy);
    return path;
  }

  void _drawBoltHalo(Canvas canvas, Offset center, double intensity) {
    if (intensity <= 0.01) return;

    canvas.drawCircle(
      center,
      (30 + intensity * 8) * scale * _powerScale,
      Paint()
        ..color = _energyYellow.withValues(alpha: 0.32 * intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * scale * _powerScale
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * scale),
    );
    canvas.drawCircle(
      center,
      24 * scale * _powerScale,
      Paint()
        ..color = _energyWhite.withValues(alpha: 0.16 * intensity)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 * scale),
    );
  }

  void _drawEnergyTransfer(
    Canvas canvas,
    PathMetric metric,
    Offset topLeftBolt,
    Offset bottomRightBolt,
  ) {
    final eased = Curves.easeOutCubic.transform(transfer);
    final flash = math.sin(transfer * math.pi).clamp(0.0, 1.0);
    final poweredFlash = flash * _energyOpacity;
    final segmentLength = metric.length * 0.5 * eased;
    final first =
        _extractWrappedPath(metric, metric.length * 0.03, segmentLength);
    final second =
        _extractWrappedPath(metric, metric.length * 0.53, segmentLength);
    final transferPaint = Paint()
      ..color = (isBackground ? _energyYellow : _energyWhite)
          .withValues(alpha: 0.9 * poweredFlash)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5 * scale * _powerScale
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * scale);
    canvas.drawPath(first, transferPaint);
    canvas.drawPath(second, transferPaint);

    final firstTarget = metric.getTangentForOffset(metric.length * 0.03);
    final secondTarget = metric.getTangentForOffset(metric.length * 0.53);
    if (firstTarget != null) {
      _drawBoltDischarge(
        canvas,
        from: topLeftBolt,
        to: firstTarget.position,
        intensity: poweredFlash,
        seed: 21,
      );
    }
    if (secondTarget != null) {
      _drawBoltDischarge(
        canvas,
        from: bottomRightBolt,
        to: secondTarget.position,
        intensity: poweredFlash,
        seed: 29,
      );
    }

    _drawBoltHalo(canvas, topLeftBolt, poweredFlash);
    _drawBoltHalo(canvas, bottomRightBolt, poweredFlash);
  }

  double _pulseEnvelope(double value, double center, double width) {
    var distance = (value - center).abs();
    distance = math.min(distance, 1 - distance);
    if (distance >= width) return 0;
    return math.sin((1 - distance / width) * math.pi / 2);
  }

  @override
  bool shouldRepaint(covariant _KartyBoostEnergyPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.transfer != transfer ||
        oldDelegate.boostProgress != boostProgress ||
        oldDelegate.scale != scale ||
        oldDelegate.isBackground != isBackground;
  }
}
