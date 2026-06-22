import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/karty_ice_particle_field.dart';

class KartyTimeBar extends StatefulWidget {
  const KartyTimeBar({
    super.key,
    required this.width,
    required this.height,
    required this.duration,
    required this.onReset,
    required this.isFinished,
    required this.isPaused,
    required this.isBoostActive,
  });

  final double width;
  final double height;
  final ValueNotifier<int> duration;
  final ValueNotifier<int> onReset;
  final ValueNotifier<bool> isFinished;
  final ValueNotifier<bool> isPaused;
  final bool isBoostActive;

  @override
  State<KartyTimeBar> createState() => _KartyTimeBarState();
}

class _KartyTimeBarState extends State<KartyTimeBar>
    with SingleTickerProviderStateMixin {
  static const _progressColor = Color(0xFF93D334);
  static const _progressTrackColor = Color(0xFFF4F6FB);

  double _progress = 0;
  Timer? _timer;
  late final AnimationController _iceParticleController;

  @override
  void initState() {
    super.initState();
    _iceParticleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    if (widget.isBoostActive) {
      _iceParticleController.repeat();
    }
    _startTimer();
    widget.onReset.addListener(_resetProgress);
    widget.isPaused.addListener(_onPauseChanged);
  }

  @override
  void didUpdateWidget(covariant KartyTimeBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isBoostActive == widget.isBoostActive) return;

    if (widget.isBoostActive) {
      _iceParticleController.repeat();
    } else {
      _iceParticleController
        ..stop()
        ..reset();
    }

    if (!widget.isPaused.value && _progress < 1) {
      _startTimer();
    }
  }

  Color _currentBarColor() {
    if (_progress < 0.6) {
      return Color.lerp(
            _progressColor,
            const Color(0xFFFDC041),
            _progress / 0.6,
          ) ??
          _progressColor;
    }

    return Color.lerp(
          const Color(0xFFFDC041),
          const Color(0xFFF52A2A),
          (_progress - 0.6) / 0.4,
        ) ??
        const Color(0xFFF52A2A);
  }

  void _startTimer() {
    _timer?.cancel();
    final speedFactor = widget.isBoostActive ? 0.75 : 1.0;
    final intervalMilliseconds =
        ((widget.duration.value * 10) / speedFactor).round();

    _timer = Timer.periodic(
      Duration(milliseconds: intervalMilliseconds),
      (timer) {
        setState(() {
          _progress += 0.01;
          if (_progress >= 1) {
            timer.cancel();
            widget.isFinished.value = true;
          }
        });
      },
    );
  }

  void _onPauseChanged() {
    if (widget.isPaused.value) {
      _timer?.cancel();
      _iceParticleController.stop();
      return;
    }

    if (_progress < 1) {
      if (widget.isBoostActive) {
        _iceParticleController.repeat();
      }
      _startTimer();
    }
  }

  void _resetProgress() {
    setState(() {
      _progress = 0;
      _timer?.cancel();
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _iceParticleController.dispose();
    widget.onReset.removeListener(_resetProgress);
    widget.isPaused.removeListener(_onPauseChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIcy = widget.isBoostActive;
    final barColor = _currentBarColor();
    final glowColor = isIcy ? const Color(0xFF74DFFF) : barColor;
    final barHeight = widget.height;
    final barRadius = BorderRadius.circular(barHeight / 2);
    final particlePadding = barHeight * 3.2;
    final particleFieldWidth = widget.width + particlePadding * 2;
    final particleFieldHeight = barHeight * 7;

    return SizedBox(
      width: widget.width,
      height: barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          ClipRRect(
            borderRadius: barRadius,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  width: widget.width,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color:
                        isIcy ? const Color(0xFFDDF8FF) : _progressTrackColor,
                    borderRadius: barRadius,
                    border: isIcy
                        ? Border.all(
                            color:
                                const Color(0xFF74DFFF).withValues(alpha: 0.42),
                            width: 2,
                          )
                        : null,
                  ),
                ),
                ClipPath(
                  clipper: isIcy ? const _IceFillEdgeClipper() : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: widget.width * _progress,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: isIcy ? null : barColor,
                      gradient: isIcy
                          ? const LinearGradient(
                              colors: [
                                Color(0xFFE9FCFF),
                                Color(0xFF74DFFF),
                                Color(0xFF1CB1F5),
                              ],
                            )
                          : null,
                      borderRadius: barRadius,
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withValues(
                            alpha: isIcy ? 0.58 : 0.28,
                          ),
                          blurRadius: isIcy ? 16 : 10,
                          spreadRadius: isIcy ? 2 : 1,
                        ),
                      ],
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: EdgeInsets.only(
                          left: barHeight * 0.34,
                          right: barHeight * 0.34,
                          top: barHeight * 0.12,
                        ),
                        height: barHeight * 0.22,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(barHeight),
                        ),
                      ),
                    ),
                  ),
                ),
                if (isIcy && _progress > 0.04 && _progress < 0.99)
                  Positioned(
                    left: (widget.width * _progress - (barHeight * 0.7)).clamp(
                      0.0,
                      widget.width - (barHeight * 1.45),
                    ),
                    top: 0,
                    width: barHeight * 1.45,
                    height: barHeight,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _IceBreakPainter(_progress),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isIcy && _progress > 0.04 && _progress < 0.99)
            Positioned(
              left: -particlePadding,
              top: -(barHeight * 3),
              width: particleFieldWidth,
              height: particleFieldHeight,
              child: KartyIceParticleField(
                width: particleFieldWidth,
                height: particleFieldHeight,
                barWidth: widget.width,
                barHeight: barHeight,
                horizontalPadding: particlePadding,
                progress: _progress,
                animation: _iceParticleController,
              ),
            ),
        ],
      ),
    );
  }
}

class _IceFillEdgeClipper extends CustomClipper<Path> {
  const _IceFillEdgeClipper();

  @override
  Path getClip(Size size) {
    if (size.width <= size.height * 1.2) {
      return Path()..addRect(Offset.zero & size);
    }

    final depth = size.height * 0.24;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - depth * 0.4, 0)
      ..lineTo(size.width - depth, size.height * 0.22)
      ..lineTo(size.width - depth * 0.28, size.height * 0.43)
      ..lineTo(size.width - depth * 0.85, size.height * 0.68)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant _IceFillEdgeClipper oldClipper) => false;
}

class _IceBreakPainter extends CustomPainter {
  const _IceBreakPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final edgeX = size.width * 0.48;
    final crackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final mainCrack = Path()
      ..moveTo(edgeX + size.width * 0.06, 0)
      ..lineTo(edgeX - size.width * 0.08, size.height * 0.2)
      ..lineTo(edgeX + size.width * 0.03, size.height * 0.39)
      ..lineTo(edgeX - size.width * 0.1, size.height * 0.62)
      ..lineTo(edgeX + size.width * 0.07, size.height);
    canvas.drawPath(mainCrack, crackPaint);

    final branches = Path()
      ..moveTo(edgeX, size.height * 0.39)
      ..lineTo(edgeX - size.width * 0.25, size.height * 0.24)
      ..moveTo(edgeX - size.width * 0.06, size.height * 0.62)
      ..lineTo(edgeX - size.width * 0.28, size.height * 0.79);
    canvas.drawPath(
      branches,
      crackPaint..color = Colors.white.withValues(alpha: 0.68),
    );
  }

  @override
  bool shouldRepaint(covariant _IceBreakPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
