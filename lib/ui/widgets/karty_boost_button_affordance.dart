import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Boost göstergesinin yalnız etkileşim davranışı.
///
/// Görsel malzeme çocuktan gelir; bu katman hazır olduğunda tek bir sakin
/// yükselme ve basıldığında uygulamanın ortak derinlik hareketini ekler. Glow,
/// kopya ikon veya bağımsız enerji efekti üretmez.
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
    this.base,
  });

  final double scale;
  final double width;
  final double height;
  final bool isReady;
  final bool isActive;
  final VoidCallback onTap;
  final Widget child;
  final Widget? base;

  @override
  State<KartyBoostButtonAffordance> createState() =>
      _KartyBoostButtonAffordanceState();
}

class _KartyBoostButtonAffordanceState extends State<KartyBoostButtonAffordance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _readyController;
  late final Animation<double> _readyLift;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _readyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _readyLift = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -8.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -8.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_readyController);
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
      _readyController.forward(from: 0);
      return;
    }
    _readyController
      ..stop()
      ..reset();
    _isPressed = false;
  }

  void _setPressed(bool value) {
    if (!widget.isReady || widget.isActive || _isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  void dispose() {
    _readyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.isReady && !widget.isActive;
    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled
          ? 'Boost hazır. 20 saniye 3 kat lig puanı için etkinleştir'
          : 'Boost enerjisi',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: enabled ? widget.onTap : null,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            children: [
              if (enabled && !MediaQuery.disableAnimationsOf(context))
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _readyController,
                      builder: (context, child) => CustomPaint(
                        painter: _ReadyGlints(_readyController.value),
                      ),
                    ),
                  ),
                ),
              if (enabled && widget.base != null)
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(0, 6 * widget.scale),
                    child: widget.base,
                  ),
                ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _readyLift,
                  child: widget.child,
                  builder: (context, child) {
                    final lift = MediaQuery.disableAnimationsOf(context)
                        ? 0.0
                        : _readyLift.value * widget.scale;
                    return Transform.translate(
                      offset: Offset(0, _isPressed ? 0 : lift),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 80),
                        curve: Curves.easeOut,
                        transform: Matrix4.translationValues(
                          0,
                          _isPressed ? 6 * widget.scale : 0,
                          0,
                        ),
                        child: child,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hazır olma anında iki küçük, dolu yıldız. Sürekli yanıp sönme veya glow yok.
class _ReadyGlints extends CustomPainter {
  const _ReadyGlints(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final strength = math.sin(progress * math.pi);
    if (strength <= 0.01) return;
    for (final dot in [(0.84, 0.15, 0.095), (0.15, 0.58, 0.065)]) {
      final x = size.width * dot.$1;
      final y = size.height * dot.$2;
      final r = size.width * dot.$3 * strength;
      final path = Path()
        ..moveTo(x, y - r)
        ..quadraticBezierTo(x + r * .2, y - r * .2, x + r, y)
        ..quadraticBezierTo(x + r * .2, y + r * .2, x, y + r)
        ..quadraticBezierTo(x - r * .2, y + r * .2, x - r, y)
        ..quadraticBezierTo(x - r * .2, y - r * .2, x, y - r)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFE9EEF5));
    }
  }

  @override
  bool shouldRepaint(_ReadyGlints oldDelegate) =>
      progress != oldDelegate.progress;
}
