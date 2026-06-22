import 'dart:math' as math;

import 'package:flutter/material.dart';

class KartyIceParticleField extends StatefulWidget {
  const KartyIceParticleField({
    super.key,
    required this.width,
    required this.height,
    required this.barWidth,
    required this.barHeight,
    required this.horizontalPadding,
    required this.progress,
    required this.animation,
  });

  final double width;
  final double height;
  final double barWidth;
  final double barHeight;
  final double horizontalPadding;
  final double progress;
  final Animation<double> animation;

  @override
  State<KartyIceParticleField> createState() => _KartyIceParticleFieldState();
}

class _KartyIceParticleFieldState extends State<KartyIceParticleField> {
  final List<_IceParticle> _particles = [];
  final math.Random _random = math.Random();
  double _lastAnimationValue = 0;
  double _spawnAccumulator = 0;

  @override
  void initState() {
    super.initState();
    _lastAnimationValue = widget.animation.value;
    widget.animation.addListener(_tick);
  }

  @override
  void didUpdateWidget(covariant KartyIceParticleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeListener(_tick);
      _lastAnimationValue = widget.animation.value;
      widget.animation.addListener(_tick);
    }
  }

  void _tick() {
    final currentValue = widget.animation.value;
    var normalizedDelta = currentValue - _lastAnimationValue;
    if (normalizedDelta < 0) normalizedDelta += 1;
    _lastAnimationValue = currentValue;

    final deltaSeconds = (normalizedDelta * 0.76).clamp(0.0, 0.05);
    if (deltaSeconds <= 0) return;

    _spawnAccumulator += deltaSeconds;
    while (_spawnAccumulator >= 0.19) {
      _spawnAccumulator -= 0.19;
      _spawnParticle();
    }

    for (final particle in _particles) {
      particle
        ..age += deltaSeconds
        ..x += particle.velocityX * deltaSeconds
        ..y += particle.velocityY * deltaSeconds
        ..velocityY += particle.gravity * deltaSeconds
        ..rotation += particle.spin * deltaSeconds;
    }
    _particles.removeWhere((particle) => particle.age >= particle.lifetime);
  }

  void _spawnParticle() {
    if (widget.progress <= 0.04 || widget.progress >= 0.99) return;

    final upward = _random.nextBool();
    final horizontalDirection = _random.nextBool() ? -1.0 : 1.0;
    final emitterX =
        widget.horizontalPadding + widget.barWidth * widget.progress;
    final emitterY = widget.height / 2;
    final scale = widget.barHeight / 28.16;

    _particles.add(
      _IceParticle(
        x: emitterX + (_random.nextDouble() - 0.5) * 3.5 * scale,
        y: emitterY + (upward ? -1 : 1) * widget.barHeight * 0.22,
        velocityX:
            horizontalDirection * (34 + _random.nextDouble() * 78) * scale,
        velocityY: (upward ? -1 : 1) * (58 + _random.nextDouble() * 86) * scale,
        gravity: (upward ? 54 : 22) * scale,
        rotation: _random.nextDouble() * math.pi * 2,
        spin: (_random.nextDouble() - 0.5) * 5.2,
        size: (3.2 + _random.nextDouble() * 3.4) * scale,
        lifetime: 0.68 + _random.nextDouble() * 0.34,
        shapeSeed: _random.nextInt(1000),
      ),
    );

    if (_particles.length > 7) {
      _particles.removeAt(0);
    }
  }

  @override
  void dispose() {
    widget.animation.removeListener(_tick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _NaturalIceParticlePainter(
          particles: _particles,
          animation: widget.animation,
        ),
        size: Size(widget.width, widget.height),
      ),
    );
  }
}

class _IceParticle {
  _IceParticle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.gravity,
    required this.rotation,
    required this.spin,
    required this.size,
    required this.lifetime,
    required this.shapeSeed,
  });

  double x;
  double y;
  double velocityX;
  double velocityY;
  final double gravity;
  double rotation;
  final double spin;
  final double size;
  final double lifetime;
  final int shapeSeed;
  double age = 0;
}

class _NaturalIceParticlePainter extends CustomPainter {
  _NaturalIceParticlePainter({
    required this.particles,
    required Animation<double> animation,
  }) : super(repaint: animation);

  final List<_IceParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final lifeProgress = (particle.age / particle.lifetime).clamp(0.0, 1.0);
      final appear = (lifeProgress / 0.12).clamp(0.0, 1.0);
      final disappear = (1 - ((lifeProgress - 0.52) / 0.48).clamp(0.0, 1.0));
      final opacity =
          Curves.easeOut.transform(appear) * Curves.easeIn.transform(disappear);
      if (opacity <= 0) continue;

      final erosion = 1 - lifeProgress * 0.32;
      final widthVariation = 0.7 + (particle.shapeSeed % 5) * 0.08;
      final heightVariation = 0.58 + (particle.shapeSeed % 7) * 0.055;
      final width = particle.size * widthVariation * erosion;
      final height = particle.size * heightVariation * erosion;

      final grain = Path()
        ..moveTo(-width * 0.62, -height * 0.05)
        ..cubicTo(
          -width * 0.5,
          -height * 0.66,
          -width * 0.06,
          -height * 0.76,
          width * 0.25,
          -height * 0.43,
        )
        ..cubicTo(
          width * 0.67,
          -height * 0.17,
          width * 0.54,
          height * 0.42,
          width * 0.14,
          height * 0.58,
        )
        ..cubicTo(
          -width * 0.21,
          height * 0.71,
          -width * 0.72,
          height * 0.37,
          -width * 0.62,
          -height * 0.05,
        )
        ..close();

      canvas.save();
      canvas.translate(particle.x, particle.y);
      canvas.rotate(particle.rotation);
      canvas.drawPath(
        grain,
        Paint()
          ..color = const Color(0xFFBDEFFF).withValues(alpha: opacity * 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.35),
      );
      canvas.drawPath(
        grain,
        Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.35, particle.size * 0.1),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _NaturalIceParticlePainter oldDelegate) => true;
}
