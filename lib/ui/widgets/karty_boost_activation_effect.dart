import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/karty_boost_palette.dart';
import 'package:flutter/services.dart';
import 'package:lingualloop/ui/widgets/karty_boost_bolt_mark.dart';

/// A single physical gesture: wind up, collide, release, then bank the energy.
/// The quiz pauses while [KartyBoostActivationEffectState.play] is pending.
class KartyBoostActivationEffect extends StatefulWidget {
  const KartyBoostActivationEffect({
    super.key,
    required this.scale,
    this.topLeftSourceKey,
    this.bottomRightSourceKey,
    this.targetKey,
  });

  final double scale;
  final GlobalKey? topLeftSourceKey;
  final GlobalKey? bottomRightSourceKey;
  final GlobalKey? targetKey;

  @override
  State<KartyBoostActivationEffect> createState() =>
      KartyBoostActivationEffectState();
}

class KartyBoostActivationEffectState extends State<KartyBoostActivationEffect>
    with SingleTickerProviderStateMixin {
  static const duration = Duration(milliseconds: 1560);
  late final AnimationController _controller;
  Offset? _topLeftSource;
  Offset? _bottomRightSource;
  Offset? _target;
  bool _reducedMotion = false;
  bool _didImpact = false;
  int _runSerial = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: duration)
      ..addListener(_impactFeedback);
  }

  void _impactFeedback() {
    if (!_reducedMotion && !_didImpact && _controller.value >= .385) {
      _didImpact = true;
      HapticFeedback.lightImpact();
    }
  }

  Future<bool> play() async {
    final run = ++_runSerial;
    // Resolve anchors after the ready control has rebuilt, so the first frame
    // starts precisely where the user touched the existing corner bolt.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || run != _runSerial) return false;
    final ownBox = context.findRenderObject() as RenderBox?;
    _topLeftSource = _centerInLocal(widget.topLeftSourceKey, ownBox);
    _bottomRightSource = _centerInLocal(widget.bottomRightSourceKey, ownBox);
    _target = _centerInLocal(widget.targetKey, ownBox);
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _didImpact = false;
    _controller.duration =
        _reducedMotion ? const Duration(milliseconds: 280) : duration;
    try {
      await _controller.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Disposing or ending the quiz must also release the awaiting caller.
      return false;
    }
    if (mounted) _controller.reset();
    return true;
  }

  Offset? _centerInLocal(GlobalKey? key, RenderBox? ownBox) {
    if (key == null || ownBox == null || !ownBox.hasSize) return null;
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return ownBox
        .globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }

  void stop() {
    _runSerial++;
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
  Widget build(BuildContext context) => IgnorePointer(
        child: LayoutBuilder(builder: (context, constraints) {
          final size = constraints.biggest;
          if (!size.isFinite || size.isEmpty) return const SizedBox.shrink();
          return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;
                if (t == 0) return const SizedBox.shrink();
                final top = _topLeftSource ??
                    Offset(size.width * .32, size.height * .40);
                final bottom = _bottomRightSource ??
                    Offset(size.width * .68, size.height * .72);
                final target =
                    _target ?? Offset(size.width * .48, size.height * .12);
                final merge = Offset.lerp(top, bottom, .52)!;
                final motion = _BoostMotion(widget.scale, merge, target);
                return RepaintBoundary(
                    child: Stack(clipBehavior: Clip.none, children: [
                  Positioned.fill(
                      child: CustomPaint(
                          painter: KartyBoostActivationPainter(
                              progress: t,
                              scale: widget.scale,
                              topLeftSource: top,
                              bottomRightSource: bottom,
                              merge: merge,
                              target: target,
                              reducedMotion: _reducedMotion))),
                  if (!_reducedMotion) ...[
                    if (t < .395)
                      for (final source in [top, bottom])
                        _sourceBolt(motion, source, t),
                    if (t >= .385 && t < .90) _heroBolt(motion, t),
                  ],
                ]));
              });
        }),
      );

  Widget _sourceBolt(_BoostMotion motion, Offset source, double t) {
    final wind = _phase(t, 0, .13, Curves.easeOutCubic);
    final rush = _phase(t, .13, .365, Curves.easeInCubic);
    final crush = _phase(t, .35, .39);
    return _bolt(
        center: motion.gather(source, t),
        height: (127.5 - 55.5 * crush) * widget.scale,
        angle:
            (source.dy < motion.merge.dy ? -1 : 1) * (.22 * wind - .45 * rush),
        x: 1 + .12 * wind - .23 * rush + .42 * crush,
        y: 1 - .10 * wind + .32 * rush - .72 * crush,
        opacity: 1 - _phase(t, .38, .395));
  }

  Widget _heroBolt(_BoostMotion motion, double t) {
    final release = _phase(t, .385, .49, Curves.easeOutBack);
    final settle = _phase(t, .49, .59, Curves.easeInOutCubic);
    final launch = _phase(t, .60, .87, Curves.easeInOutCubic);
    final stretch = math.sin(math.pi * launch);
    final arrival = _phase(t, .82, .9, Curves.easeInCubic);
    return _bolt(
        center: motion.hero(t),
        height: (62 + 86 * release - 24 * settle - 75 * launch) * widget.scale,
        angle: -.18 * release + .25 * settle + .35 * stretch,
        x: (1.25 - .25 * release - .17 * stretch) * (1 - .55 * arrival),
        y: .48 + .52 * release + .27 * stretch,
        opacity: 1 - arrival,
        highlight: .08);
  }

  Widget _bolt({
    required Offset center,
    required double height,
    required double angle,
    required double x,
    required double y,
    required double opacity,
    double highlight = .06,
  }) =>
      Positioned(
          left: center.dx - height * .37,
          top: center.dy - height * 1.055 / 2,
          child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.rotate(
                  angle: angle,
                  child: Transform.scale(
                      scaleX: x,
                      scaleY: y,
                      child: KartyBoostBoltMark(
                          height: height,
                          face: KartyBoostPalette.blue,
                          depth: KartyBoostPalette.blueDepth,
                          highlight: highlight,
                          bubblePhase: _controller.value *
                              duration.inMilliseconds /
                              2400)))));
}

/// Shared trajectories keep the painted ribbons attached to the moving icons.
class _BoostMotion {
  const _BoostMotion(this.scale, this.merge, this.target);
  final double scale;
  final Offset merge;
  final Offset target;

  Offset gather(Offset source, double t) {
    final delta = merge - source;
    if (delta.distance < .01) return merge;
    final unit = delta / delta.distance;
    final wind = _phase(t, 0, .13, Curves.easeOutCubic);
    final start = source - unit * (24 * wind * scale);
    final rush = _phase(t, .13, .365, Curves.easeInCubic);
    final perpendicular = Offset(-unit.dy, unit.dx);
    final control =
        Offset.lerp(start, merge, .55)! + perpendicular * 75 * scale;
    return _bezier(start, control, merge, rush);
  }

  Offset hero(double t) {
    final lift = _phase(t, .385, .49, Curves.easeOutCubic);
    final wind = _phase(t, .53, .60, Curves.easeInCubic);
    final start = merge + Offset(0, (-14 * lift + 25 * wind) * scale);
    final fly = _phase(t, .60, .87, Curves.easeInOutCubic);
    final control = Offset(
        math.max(merge.dx, target.dx) + 125 * scale, merge.dy - 100 * scale);
    return _bezier(start, control, target, fly);
  }
}

double _phase(double t, double begin, double end,
    [Curve curve = Curves.linear]) {
  if (t <= begin) return 0;
  if (t >= end) return 1;
  return curve.transform((t - begin) / (end - begin));
}

double _window(double t, double a, double b, double c, double d) =>
    _phase(t, a, b, Curves.easeOutCubic) *
    (1 - _phase(t, c, d, Curves.easeInCubic));

Offset _bezier(Offset a, Offset b, Offset c, double t) =>
    a * ((1 - t) * (1 - t)) + b * (2 * t * (1 - t)) + c * (t * t);

@visibleForTesting
class KartyBoostActivationPainter extends CustomPainter {
  const KartyBoostActivationPainter({
    required this.progress,
    required this.scale,
    required this.topLeftSource,
    required this.bottomRightSource,
    required this.merge,
    required this.target,
    this.reducedMotion = false,
  });

  final double progress;
  final double scale;
  final Offset topLeftSource;
  final Offset bottomRightSource;
  final Offset merge;
  final Offset target;
  final bool reducedMotion;

  static const _blue = KartyBoostPalette.blue;
  static const _light = KartyBoostPalette.blueLight;
  static const _white = KartyBoostPalette.white;
  static const _gold = KartyBoostPalette.gold;
  static const _goldDepth = KartyBoostPalette.goldDepth;
  static const _blueDepth = KartyBoostPalette.blueDepth;

  @override
  void paint(Canvas canvas, Size size) {
    if (reducedMotion) {
      // A quiet acknowledgement at the destination; no sweep or explosion.
      final opacity = math.sin(progress * math.pi) * .55;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: target, width: 100 * scale, height: 62 * scale),
              Radius.circular(20 * scale)),
          Paint()..color = _blue.withValues(alpha: opacity));
      return;
    }
    final focus = _window(progress, 0, .17, .72, .96);
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = const Color(0xFF041227).withValues(alpha: .13 * focus));
    final motion = _BoostMotion(scale, merge, target);
    _gatherRibbons(canvas, motion);
    _collision(canvas);
    _releaseArcs(canvas);
    _particles(canvas, merge, begin: .392, end: .76, radius: 190, count: 12);
    _launchRibbon(canvas, motion);
    _landing(canvas);
  }

  void _gatherRibbons(Canvas canvas, _BoostMotion motion) {
    if (progress <= .16 || progress >= .405) return;
    final fade = 1 - _phase(progress, .365, .405);
    for (final source in [topLeftSource, bottomRightSource]) {
      final points = List.generate(22, (i) {
        final time = (progress - .085 + .085 * i / 21).clamp(.13, .365);
        return motion.gather(source, time);
      });
      _ribbon(canvas, points, 19 * scale, _blue.withValues(alpha: .85 * fade));
      _ribbon(canvas, points, 3 * scale, _light.withValues(alpha: .45 * fade));
    }
  }

  void _collision(Canvas canvas) {
    final squeeze = _window(progress, .335, .38, .388, .415);
    if (squeeze > 0) {
      // Flattened pressure pocket, then a very brief warm core. Both deform;
      // neither remains as a static badge behind the resulting bolt.
      final q = _phase(progress, .335, .39);
      final rect = Rect.fromCenter(
          center: merge,
          width: (24 + 86 * q) * scale,
          height: (52 - 32 * q) * scale);
      canvas.drawOval(rect.shift(Offset(0, 5 * scale)),
          Paint()..color = _goldDepth.withValues(alpha: squeeze));
      canvas.drawOval(rect, Paint()..color = _gold.withValues(alpha: squeeze));
    }
    final t = _phase(progress, .385, .485, Curves.easeOutCubic);
    final opacity = _window(progress, .385, .4, .415, .485);
    if (opacity <= 0) return;
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final angle = -math.pi / 2 + i * math.pi / 8 + .25 * t;
      final radius = (i.isEven ? 35 + 50 * t : 23 + 8 * t) * scale;
      final p = merge + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path.shift(Offset(0, 4 * scale)),
        Paint()..color = _goldDepth.withValues(alpha: opacity));
    canvas.drawPath(path, Paint()..color = _gold.withValues(alpha: opacity));
    canvas.drawCircle(
        merge,
        (25 + 12 * t) * scale,
        Paint()
          ..color = KartyBoostPalette.goldLight.withValues(alpha: opacity));
  }

  void _releaseArcs(Canvas canvas) {
    // Three broken, curling ribbons peel away from the impact. The leading
    // edge outruns the tail, so each shape actually unfolds and contracts.
    for (var i = 0; i < 3; i++) {
      final begin = .395 + i * .012;
      final q = _phase(progress, begin, .66 + i * .015);
      if (q <= 0 || q >= 1) continue;
      final travel = Curves.easeOutCubic.transform(q);
      final head = -2.55 + i * math.pi * 2 / 3 + 1.05 * travel;
      final sweep = math.sin(math.pi * q) * 1.20;
      final radius = (27 + 145 * travel) * scale;
      final points = List.generate(26, (n) {
        final f = n / 25;
        final angle = head - sweep * (1 - f);
        final r = radius * (.84 + .16 * f);
        return merge + Offset(math.cos(angle) * r, math.sin(angle) * r * .82);
      });
      final width = (16 * math.sin(math.pi * q) + 2) * scale;
      final opacity = (1 - _phase(q, .60, 1)) * .95;
      _ribbon(canvas, points.map((p) => p + Offset(0, 3 * scale)).toList(),
          width + 2 * scale, _blueDepth.withValues(alpha: opacity * .65));
      _ribbon(canvas, points, width, _blue.withValues(alpha: opacity));
      _ribbon(
          canvas, points, width * .18, _light.withValues(alpha: .55 * opacity));
    }
  }

  void _particles(Canvas canvas, Offset origin,
      {required double begin,
      required double end,
      required double radius,
      required int count}) {
    for (var i = 0; i < count; i++) {
      final delay = (i % 3) * .007;
      final q = _phase(progress, begin + delay, end + delay);
      if (q <= 0 || q >= 1) continue;
      final travel = Curves.easeOutCubic.transform(q);
      final angle = i * math.pi * 2 / count - 1.4 + math.sin(i * 7) * .15;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final distance = (22 + radius * (.65 + (i % 4) * .10) * travel) * scale;
      final center =
          origin + direction * distance + Offset(0, 38 * q * q * scale);
      final opacity = 1 - _phase(q, .57, 1, Curves.easeInCubic);
      final birth = _phase(q, 0, .1, Curves.easeOutCubic);
      final shrink = 1 - .72 * _phase(q, .6, 1);
      final w = (i.isEven ? 10.0 : 7.0) * scale * birth * shrink;
      final h = (i.isEven ? 23.0 : 14.0) * scale * birth * shrink;
      final gold = i % 3 == 0;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle + math.pi / 2 + q * (i.isEven ? 2.8 : -3.7));
      // A bevel and a changing cross section make these little solid chips,
      // instead of identical dots expanding as a flat starburst.
      canvas.scale(.65 + .35 * math.cos(q * math.pi * 3 + i).abs(), 1);
      final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          Radius.circular(w * .40));
      canvas.drawRRect(
          rect.shift(Offset(0, 2.5 * scale)),
          Paint()
            ..color =
                (gold ? _goldDepth : _blueDepth).withValues(alpha: opacity));
      canvas.drawRRect(
          rect,
          Paint()
            ..color = (gold ? _gold : (i.isEven ? _blue : _white))
                .withValues(alpha: opacity));
      canvas.restore();
    }
  }

  void _launchRibbon(Canvas canvas, _BoostMotion motion) {
    if (progress <= .61 || progress >= .9) return;
    final fade = 1 - _phase(progress, .855, .9);
    final points = List.generate(30,
        (i) => motion.hero((progress - .073 + .073 * i / 29).clamp(.60, .87)));
    _ribbon(canvas, points, 23 * scale, _blue.withValues(alpha: .80 * fade));
    _ribbon(canvas, points, 4 * scale, _light.withValues(alpha: .55 * fade));
  }

  void _landing(Canvas canvas) {
    final q = _phase(progress, .85, .98, Curves.easeOutCubic);
    if (q <= 0 || q >= 1) return;
    final opacity = 1 - _phase(progress, .90, .99);
    // Keep the score readable: a broken ring, not an opaque cloud over it.
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(
          Rect.fromCenter(
              center: target,
              width: (42 + 57 * q) * scale,
              height: (42 + 57 * q) * scale),
          i * math.pi * 2 / 3 + q * .4,
          .85 * (1 - .35 * q),
          false,
          Paint()
            ..color = _gold.withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = (7 - 5 * q) * scale);
    }
    _particles(canvas, target, begin: .855, end: .99, radius: 46, count: 5);
  }

  /// Filled, tapered geometry, sampled along the actual trajectory. No blur,
  /// shaders or icon afterimages, which would muddy the card illustration.
  void _ribbon(Canvas canvas, List<Offset> points, double width, Color color) {
    if ((points.last - points.first).distance < .5) return;
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final previous = points[math.max(0, i - 1)];
      final next = points[math.min(points.length - 1, i + 1)];
      final delta = next - previous;
      if (delta.distance < .001) continue;
      final normal = Offset(-delta.dy, delta.dx) / delta.distance;
      final f = i / (points.length - 1);
      final half = width * math.sin(math.pi * f * .88) * .5;
      left.add(points[i] + normal * half);
      right.add(points[i] - normal * half);
    }
    if (left.length < 2) return;
    final path = Path()..addPolygon([...left, ...right.reversed], true);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant KartyBoostActivationPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.scale != scale ||
      oldDelegate.topLeftSource != topLeftSource ||
      oldDelegate.bottomRightSource != bottomRightSource ||
      oldDelegate.merge != merge ||
      oldDelegate.target != target ||
      oldDelegate.reducedMotion != reducedMotion;
}
