import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/karty_boost_palette.dart';
import 'package:lingualloop/ui/widgets/karty_boost_bolt_mark.dart';
import 'package:lingualloop/ui/widgets/karty_boost_button_affordance.dart';

/// Boost'un kart üzerindeki tek kalıcı göstergesi.
///
/// Sol üst ve sağ alttaki iki hacimli şimşek hem ön kartta hem de hemen
/// arkasındaki kart katmanında bulunur. Bu tekrar, desteyle birlikte hareket
/// ederek kullanıcının beğendiği köşe "stack"ini oluşturur. Dolum, hazır
/// kontrolü ve aktif sürenin azalması aynı iki nesne üzerinden okunur.
class KartyBoostEdgeMeter extends StatefulWidget {
  const KartyBoostEdgeMeter({
    super.key,
    required this.scale,
    required this.charge,
    required this.chargeGoal,
    required this.isReady,
    required this.isActive,
    required this.boostProgress,
    required this.onTap,
    this.isActivating = false,
    this.interactive = true,
    this.topLeftAnchorKey,
    this.bottomRightAnchorKey,
  });

  final double scale;
  final int charge;
  final int chargeGoal;
  final bool isReady;
  final bool isActive;
  final bool isActivating;
  final ValueListenable<double> boostProgress;
  final VoidCallback onTap;
  final bool interactive;

  /// Tam-ekran efektlerinin sabit koordinat uydurmak yerine gerçek köşe
  /// nesnelerinden çıkabilmesi için yalnız ön kartta verilir.
  final GlobalKey? topLeftAnchorKey;
  final GlobalKey? bottomRightAnchorKey;

  @override
  State<KartyBoostEdgeMeter> createState() => _KartyBoostEdgeMeterState();
}

class _KartyBoostEdgeMeterState extends State<KartyBoostEdgeMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popController;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didUpdateWidget(covariant KartyBoostEdgeMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.charge > oldWidget.charge && !widget.isReady) {
      _popController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  double _popScale() {
    if (!_popController.isAnimating) return 1;
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.86, end: 1.11)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 62,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.11, end: 1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 38,
      ),
    ]).transform(_popController.value);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.boostProgress,
      builder: (context, remaining, child) {
        final fill = widget.isActive
            ? remaining.clamp(0.0, 1.0)
            : widget.isReady || widget.isActivating
                ? 1.0
                : widget.chargeGoal <= 0
                    ? 0.0
                    : (widget.charge / widget.chargeGoal).clamp(0.0, 1.0);

        return AnimatedBuilder(
          animation: _popController,
          builder: (context, child) {
            final bolt = _KartyLiquidBolt(
              scale: widget.scale,
              fill: fill,
              isEnergized: widget.isReady || widget.isActive,
              popScale: _popScale(),
            );

            return Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeIn,
                  opacity: widget.isActivating ? 0 : 1,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 40 * widget.scale,
                        top: 38 * widget.scale,
                        child: SizedBox(
                          key: widget.topLeftAnchorKey,
                          child: bolt,
                        ),
                      ),
                      Positioned(
                        // Dokunma alanı büyür; şimşeğin merkezi ve efekt
                        // bağlantısı dolumun bütün durumlarında sabit kalır.
                        right: (40 - (142.5 - 127.5 * 0.74) / 2) * widget.scale,
                        bottom:
                            (38 - (142.5 - 127.5 * 1.055) / 2) * widget.scale,
                        child: KartyBoostButtonAffordance(
                          scale: widget.scale,
                          width: 142.5 * widget.scale,
                          height: 142.5 * widget.scale,
                          isReady: widget.isReady &&
                              widget.interactive &&
                              !widget.isActivating,
                          isActive: widget.isActive,
                          onTap: widget.onTap,
                          base: Center(
                            child: KartyBoostBoltMark(
                              height: 127.5 * widget.scale,
                              face: KartyBoostPalette.blueDepth,
                              depth: KartyBoostPalette.blueDepth,
                              highlight: 0,
                            ),
                          ),
                          child: Center(
                            child: SizedBox(
                              key: widget.bottomRightAnchorKey,
                              child: bolt,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Köşedeki şimşeğin mat gövdesi ve içeride yükselen enerji sıvısı.
class _KartyLiquidBolt extends StatelessWidget {
  const _KartyLiquidBolt({
    required this.scale,
    required this.fill,
    required this.isEnergized,
    required this.popScale,
  });

  final double scale;
  final double fill;
  final bool isEnergized;
  final double popScale;

  @override
  Widget build(BuildContext context) {
    final height = 127.5 * scale;
    final width = height * 0.74;
    final totalHeight = height * 1.055;

    return AnimatedScale(
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      scale: popScale,
      child: SizedBox(
        width: width,
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            KartyBoostBoltMark(
              height: height,
              face: KartyBoostPalette.empty,
              depth: KartyBoostPalette.emptyDepth,
              highlight: 0.02,
            ),
            _BoltLiquidLayer(
              fill: fill,
              width: width,
              height: totalHeight,
              boltHeight: height,
              isFull: isEnergized,
            ),
            if (isEnergized)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.16,
                    child: Transform.scale(
                      scale: 1.045,
                      child: KartyBoostBoltMark(
                        height: height,
                        face: KartyBoostPalette.blueLight,
                        depth: KartyBoostPalette.blueDepth,
                        highlight: 0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BoltLiquidLayer extends StatefulWidget {
  const _BoltLiquidLayer({
    required this.fill,
    required this.width,
    required this.height,
    required this.boltHeight,
    required this.isFull,
  });

  final double fill;
  final double width;
  final double height;
  final double boltHeight;
  final bool isFull;

  @override
  State<_BoltLiquidLayer> createState() => _BoltLiquidLayerState();
}

class _BoltLiquidLayerState extends State<_BoltLiquidLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipPath(
          clipper: _BoltLiquidClipper(
            fill: widget.fill,
            phase: _controller.value,
          ),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              KartyBoostBoltMark(
                height: widget.boltHeight,
                face: widget.isFull
                    ? KartyBoostPalette.blue
                    : KartyBoostPalette.blueDepth,
                depth: KartyBoostPalette.blueDepth,
                highlight: widget.isFull ? 0.08 : 0.04,
                bubblePhase: widget.fill > 0.08 ? _controller.value : null,
                bubbleIntensity: widget.isFull ? 1 : 0.58,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BoltLiquidClipper extends CustomClipper<Path> {
  const _BoltLiquidClipper({required this.fill, required this.phase});

  final double fill;
  final double phase;

  @override
  Path getClip(Size size) {
    final clampedFill = fill.clamp(0.0, 1.0);
    final surfaceY = size.height * (1 - clampedFill);
    final amplitude = size.height * 0.022;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, surfaceY);

    const steps = 18;
    for (var index = 0; index <= steps; index++) {
      final x = size.width * index / steps;
      final wave = math.sin(index / steps * math.pi * 2 + phase * math.pi * 2);
      path.lineTo(x, surfaceY + wave * amplitude);
    }

    return path
      ..lineTo(size.width, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant _BoltLiquidClipper oldClipper) {
    return oldClipper.fill != fill || oldClipper.phase != phase;
  }
}
