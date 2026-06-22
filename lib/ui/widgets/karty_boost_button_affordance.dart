import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class KartyBoostButtonAffordance extends StatefulWidget {
  const KartyBoostButtonAffordance({
    super.key,
    required this.scale,
    required this.width,
    required this.height,
    required this.isReady,
    required this.isActive,
    required this.onTap,
    required this.child,
  });

  final double scale;
  final double width;
  final double height;
  final bool isReady;
  final bool isActive;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<KartyBoostButtonAffordance> createState() =>
      _KartyBoostButtonAffordanceState();
}

class _KartyBoostButtonAffordanceState extends State<KartyBoostButtonAffordance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _readyController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _readyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _syncReadyAnimation();
  }

  @override
  void didUpdateWidget(covariant KartyBoostButtonAffordance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isReady != widget.isReady ||
        oldWidget.isActive != widget.isActive) {
      _syncReadyAnimation();
    }
  }

  void _syncReadyAnimation() {
    if (widget.isReady && !widget.isActive) {
      if (!_readyController.isAnimating) {
        _readyController.repeat();
      }
      return;
    }

    _readyController
      ..stop()
      ..reset();
    _isPressed = false;
  }

  void _setPressed(bool value) {
    if (!widget.isReady || _isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  void dispose() {
    _readyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.isReady,
      label: widget.isReady ? 'Boost hazır, etkinleştir' : 'Boost enerjisi',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.isReady ? (_) => _setPressed(true) : null,
        onTapUp: widget.isReady ? (_) => _setPressed(false) : null,
        onTapCancel: widget.isReady ? () => _setPressed(false) : null,
        onTap: widget.isReady ? widget.onTap : null,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: AnimatedBuilder(
            animation: _readyController,
            builder: (context, child) {
              final pulseWindow = _readyController.value < 0.38
                  ? math.sin(_readyController.value / 0.38 * math.pi)
                  : 0.0;
              final lift = pulseWindow * 2.4 * widget.scale;

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (widget.isReady && !widget.isActive)
                    Transform.scale(
                      scale: 1 + pulseWindow * 0.2,
                      child: Opacity(
                        opacity: pulseWindow * 0.52,
                        child: ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: (3 + pulseWindow * 5) * widget.scale,
                            sigmaY: (3 + pulseWindow * 5) * widget.scale,
                          ),
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFFFD52F),
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              'assets/icons/boost-bolt.png',
                              width: widget.width,
                              height: widget.height,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (widget.isReady && !widget.isActive && pulseWindow > 0.28)
                    Transform.scale(
                      scale: 1 + pulseWindow * 0.105,
                      child: Opacity(
                        opacity: pulseWindow * 0.34,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Color(0xFFFFF3A3),
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/icons/boost-bolt.png',
                            width: widget.width,
                            height: widget.height,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 90),
                    curve: Curves.easeOut,
                    transform: Matrix4.translationValues(
                      0,
                      _isPressed ? 4 * widget.scale : -lift,
                      0,
                    ),
                    transformAlignment: Alignment.center,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 90),
                      curve: Curves.easeOut,
                      scale: _isPressed ? 0.94 : 1 + pulseWindow * 0.045,
                      child: child,
                    ),
                  ),
                ],
              );
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
