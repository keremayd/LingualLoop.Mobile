import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:lingualloop/models/Karty.dart';
import 'package:lingualloop/ui/widgets/karty_answer_feedback_effect.dart';
import 'package:lingualloop/ui/widgets/karty_boost_button_affordance.dart';
import 'package:lingualloop/ui/widgets/karty_boost_card_effect.dart';

class SwipableCard extends StatefulWidget {
  final Karty karty;
  final Offset position;
  final double rotation;
  final bool showRestartState;
  final bool isAdvancingDeck;
  final bool isBoostEnergyTransferring;
  final bool boostEnabled;
  final int boostCharge;
  final int boostChargeGoal;
  final bool isBoostReady;
  final bool isBoostActive;
  final ValueListenable<double> boostProgress;
  final VoidCallback onRestart;
  final VoidCallback onBoostTap;
  final ValueNotifier<bool> isTrueAnswerBlurActive;
  final ValueNotifier<bool> isFalseAnswerBlurActive;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;

  SwipableCard({
    Key? key,
    required this.karty,
    required this.position,
    required this.rotation,
    required this.showRestartState,
    required this.isAdvancingDeck,
    required this.isBoostEnergyTransferring,
    required this.boostEnabled,
    required this.boostCharge,
    required this.boostChargeGoal,
    required this.isBoostReady,
    required this.isBoostActive,
    required this.boostProgress,
    required this.onRestart,
    required this.onBoostTap,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.isTrueAnswerBlurActive,
    required this.isFalseAnswerBlurActive,
  }) : super(key: key);

  @override
  _SwipableCardState createState() => _SwipableCardState();
}

class _SwipableCardState extends State<SwipableCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;
  late AnimationController _shrinkController;
  late Animation<double> _shrinkAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _addBlurListeners();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _rotationAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.1), weight: 50),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.1, end: -0.1), weight: 50),
      TweenSequenceItem(
          tween: Tween<double>(begin: -0.1, end: 0.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 10), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: -10), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 0), weight: 20),
    ]).animate(_shakeController);

    _colorController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.redAccent.withOpacity(0.8),
    ).animate(_colorController);

    _shrinkController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _shrinkAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _shrinkController, curve: Curves.easeInOut),
    );
  }

  void _addBlurListeners() {
    widget.isTrueAnswerBlurActive.addListener(_handleTrueAnswerBlur);
    widget.isFalseAnswerBlurActive.addListener(_handleFalseAnswerBlur);
  }

  void _handleTrueAnswerBlur() {
    if (widget.isTrueAnswerBlurActive.value) {
      _scaleController.forward(from: 0);
      _rotationController.forward(from: 0);
    } else {
      _scaleController.reverse(from: 1.1);
      _rotationController.reverse(from: 0);
    }
  }

  void _handleFalseAnswerBlur() {
    if (widget.isFalseAnswerBlurActive.value) {
      _shakeController.forward(from: 0);
      _colorController.forward(from: 0);
      _shrinkController.forward(from: 0);
    } else {
      _colorController.reverse(from: 1.0);
      _shrinkController.reverse(from: 0.9);
    }
  }

  @override
  void dispose() {
    widget.isTrueAnswerBlurActive.removeListener(_handleTrueAnswerBlur);
    widget.isFalseAnswerBlurActive.removeListener(_handleFalseAnswerBlur);
    _scaleController.dispose();
    _rotationController.dispose();
    _shakeController.dispose();
    _colorController.dispose();
    _shrinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 750;
    final cardWidth = 535 * scale;
    final cardHeight = 802 * scale;
    final layerOffset = 44 * scale;
    final borderWidth = 28 * scale;
    final borderRadius = BorderRadius.circular(58 * scale);
    final innerBorderRadius = BorderRadius.circular(30 * scale);
    const deckAnimationDuration = Duration(milliseconds: 280);
    const cardGradient = LinearGradient(
      colors: [
        Color(0xFF68D73D),
        Color(0xFF56BEEA),
        Color(0xFFA647F0),
        Color(0xFFFDC041),
      ],
      stops: [0.02, 0.38, 0.68, 1],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    const rimLighting = LinearGradient(
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFF7F8FA),
        Color(0xFFD7DAE2),
        Color(0xFFF4F5F8),
      ],
      stops: [0, 0.34, 0.78, 1],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    const surfaceLighting = LinearGradient(
      colors: [
        Color(0x28FFFFFF),
        Color(0x00FFFFFF),
        Color(0x1A041227),
      ],
      stops: [0, 0.5, 1],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    double layerWidth(int level) {
      if (level == 0) {
        return cardWidth;
      }

      return cardWidth - ((level * 30 + 15) * scale);
    }

    return GestureDetector(
      onPanUpdate: widget.onPanUpdate,
      onPanEnd: widget.onPanEnd,
      child: SizedBox(
        width: 750 * scale,
        height: 990 * scale,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: widget.isFalseAnswerBlurActive,
              builder: (context, isFalseActive, _) {
                return Positioned(
                  top: isFalseActive ? -58 * scale : -34 * scale,
                  child: AnimatedOpacity(
                    opacity: isFalseActive ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: AnimatedSlide(
                      offset:
                          isFalseActive ? Offset.zero : const Offset(0, 0.7),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      child: Text(
                        widget.karty.correctText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF93D334),
                          fontSize: 38 * scale,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 0,
              left: 30 * scale,
              right: 30 * scale,
              child: KartyFeedbackWord(
                text: widget.karty.questionText,
                scale: scale,
                isCorrectActive: widget.isTrueAnswerBlurActive,
                isWrongActive: widget.isFalseAnswerBlurActive,
              ),
            ),
            Positioned(
              top: 120 * scale,
              child: SizedBox(
                width: cardWidth,
                height: cardHeight + (layerOffset * 2),
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 2; i >= 1; i--)
                      AnimatedPositioned(
                        duration: deckAnimationDuration,
                        curve: Curves.easeOutCubic,
                        top: widget.isAdvancingDeck
                            ? layerOffset * (i - 1)
                            : layerOffset * i,
                        child: AnimatedContainer(
                          duration: deckAnimationDuration,
                          curve: Curves.easeOutCubic,
                          width: widget.isAdvancingDeck
                              ? layerWidth(i - 1)
                              : layerWidth(i),
                          height: cardHeight,
                          decoration: BoxDecoration(
                            gradient: rimLighting,
                            borderRadius: borderRadius,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 16 * scale,
                                offset: Offset(4 * scale, 10 * scale),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(borderWidth),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: cardGradient,
                                    borderRadius: innerBorderRadius,
                                    border: Border.all(
                                      color:
                                          Colors.black.withValues(alpha: 0.16),
                                      width: 2.5 * scale,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.34),
                                        blurRadius: 7 * scale,
                                        offset: Offset(0, 4 * scale),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    children: [
                                      const Positioned.fill(
                                        child: IgnorePointer(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: surfaceLighting,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (i == 1 && widget.boostEnabled) ...[
                                        Positioned(
                                          left: 16 * scale,
                                          top: 16 * scale,
                                          child: IgnorePointer(
                                            child: _KartyBoostBolt(
                                              scale: scale,
                                              charge: widget.boostCharge,
                                              chargeGoal:
                                                  widget.boostChargeGoal,
                                              boostProgress:
                                                  widget.boostProgress,
                                              isReady: widget.isBoostReady,
                                              isActive: widget.isBoostActive,
                                              onTap: () {},
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 16 * scale,
                                          bottom: 16 * scale,
                                          child: IgnorePointer(
                                            child: _KartyBoostBolt(
                                              scale: scale,
                                              charge: widget.boostCharge,
                                              chargeGoal:
                                                  widget.boostChargeGoal,
                                              boostProgress:
                                                  widget.boostProgress,
                                              isReady: widget.isBoostReady,
                                              isActive: widget.isBoostActive,
                                              onTap: () {},
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              if (i == 1 &&
                                  (widget.isBoostEnergyTransferring ||
                                      widget.isAdvancingDeck) &&
                                  widget.isBoostActive)
                                Positioned.fill(
                                  child: KartyBoostCardEffect(
                                    scale: scale,
                                    boostProgress: widget.boostProgress,
                                    isBackground: true,
                                    isReceivingEnergy:
                                        widget.isBoostEnergyTransferring,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    AnimatedPositioned(
                      duration: deckAnimationDuration,
                      curve: Curves.easeOutCubic,
                      top: widget.isAdvancingDeck ? 0 : layerOffset,
                      left: widget.isAdvancingDeck
                          ? 0
                          : (cardWidth - layerWidth(1)) / 2,
                      width: widget.isAdvancingDeck ? cardWidth : layerWidth(1),
                      height: cardHeight,
                      child: KartyCardFeedbackEffect(
                        scale: scale,
                        isCorrectActive: widget.isTrueAnswerBlurActive,
                        isWrongActive: widget.isFalseAnswerBlurActive,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _scaleController,
                        _rotationController,
                        _shakeController,
                        _colorController,
                        _shrinkController,
                      ]),
                      builder: (context, child) {
                        return Transform.translate(
                          offset: widget.position +
                              Offset(_shakeAnimation.value, 0),
                          child: Transform.scale(
                            scale:
                                _scaleAnimation.value * _shrinkAnimation.value,
                            child: Transform.rotate(
                              angle: widget.rotation + _rotationAnimation.value,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: cardWidth,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.lerp(
                                _colorAnimation.value!,
                                Colors.white,
                                0.34,
                              )!,
                              _colorAnimation.value!,
                              Color.lerp(
                                _colorAnimation.value!,
                                const Color(0xFFBFC4CE),
                                0.3,
                              )!,
                            ],
                            stops: const [0, 0.48, 1],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: borderRadius,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.34),
                              blurRadius: 26 * scale,
                              spreadRadius: 1 * scale,
                              offset: Offset(8 * scale, 17 * scale),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(borderWidth),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: cardGradient,
                                  borderRadius: innerBorderRadius,
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.17),
                                    width: 2.5 * scale,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 7 * scale,
                                      offset: Offset(0, 4 * scale),
                                    ),
                                    BoxShadow(
                                      color:
                                          Colors.white.withValues(alpha: 0.32),
                                      blurRadius: 2 * scale,
                                      offset: Offset(-1 * scale, -1 * scale),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  children: [
                                    const Positioned.fill(
                                      child: IgnorePointer(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: surfaceLighting,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        switchInCurve: Curves.easeOut,
                                        switchOutCurve: Curves.easeOut,
                                        transitionBuilder: (child, animation) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: ScaleTransition(
                                              scale: Tween<double>(
                                                begin: 0.94,
                                                end: 1,
                                              ).animate(animation),
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: widget.showRestartState
                                            ? GestureDetector(
                                                key: const ValueKey(
                                                    'restart-icon'),
                                                onTap: widget.onRestart,
                                                child: Container(
                                                  width: 220 * scale,
                                                  height: 220 * scale,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.18),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.refresh_rounded,
                                                    color: Colors.white,
                                                    size: 132 * scale,
                                                  ),
                                                ),
                                              )
                                            : Image.file(
                                                File(widget.karty.kartyUrl),
                                                key: ValueKey(
                                                    widget.karty.kartyUrl),
                                                fit: BoxFit.contain,
                                                width: 455 * scale,
                                              ),
                                      ),
                                    ),
                                    if (widget.boostEnabled &&
                                        !widget.showRestartState) ...[
                                      Positioned(
                                        left: 16 * scale,
                                        top: 16 * scale,
                                        child: _KartyBoostBolt(
                                          scale: scale,
                                          charge: widget.boostCharge,
                                          chargeGoal: widget.boostChargeGoal,
                                          boostProgress: widget.boostProgress,
                                          isReady: widget.isBoostReady,
                                          isActive: widget.isBoostActive,
                                          onTap: widget.onBoostTap,
                                        ),
                                      ),
                                      Positioned(
                                        right: 16 * scale,
                                        bottom: 16 * scale,
                                        child: _KartyBoostBolt(
                                          scale: scale,
                                          charge: widget.boostCharge,
                                          chargeGoal: widget.boostChargeGoal,
                                          boostProgress: widget.boostProgress,
                                          isReady: widget.isBoostReady,
                                          isActive: widget.isBoostActive,
                                          onTap: widget.onBoostTap,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (widget.isBoostActive &&
                                !widget.showRestartState)
                              Positioned.fill(
                                child: KartyBoostCardEffect(
                                  scale: scale,
                                  boostProgress: widget.boostProgress,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartyBoostBolt extends StatelessWidget {
  const _KartyBoostBolt({
    required this.scale,
    required this.charge,
    required this.chargeGoal,
    required this.boostProgress,
    required this.isReady,
    required this.isActive,
    required this.onTap,
  });

  final double scale;
  final int charge;
  final int chargeGoal;
  final ValueListenable<double> boostProgress;
  final bool isReady;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = 68 * scale;
    final height = 90 * scale;

    return ValueListenableBuilder<double>(
      valueListenable: boostProgress,
      builder: (context, remainingBoost, child) {
        final fill = isActive
            ? remainingBoost.clamp(0.0, 1.0)
            : isReady
                ? 1.0
                : (charge / chargeGoal).clamp(0.0, 1.0);

        return KartyBoostButtonAffordance(
          scale: scale,
          width: width,
          height: height,
          isReady: isReady,
          isActive: isActive,
          onTap: onTap,
          child: SizedBox(
            width: width,
            height: height,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: fill),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              builder: (context, animatedFill, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.translate(
                      offset: Offset(3 * scale, 5 * scale),
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: 4 * scale,
                          sigmaY: 4 * scale,
                        ),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.32),
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/icons/boost-bolt.png',
                            width: width,
                            height: height,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    if (isReady || isActive)
                      ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: 7 * scale,
                          sigmaY: 7 * scale,
                        ),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            const Color(0xFFFFB000).withValues(alpha: 0.72),
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/icons/boost-bolt.png',
                            width: width,
                            height: height,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    _BoltLiquidLayer(
                      fill: animatedFill,
                      width: width,
                      height: height,
                      isFull: isReady || isActive,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _BoltLiquidLayer extends StatefulWidget {
  const _BoltLiquidLayer({
    required this.fill,
    required this.width,
    required this.height,
    required this.isFull,
  });

  final double fill;
  final double width;
  final double height;
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
      duration: const Duration(milliseconds: 2100),
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
        final phase = _controller.value;
        final liquidColor =
            widget.isFull ? const Color(0xFFFFD52F) : const Color(0xFFFFB817);

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0xFF253143),
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/icons/boost-bolt.png',
                  width: widget.width,
                  height: widget.height,
                  fit: BoxFit.contain,
                ),
              ),
              ClipPath(
                clipper: _BoltLiquidClipper(
                  fill: widget.fill,
                  phase: phase,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        liquidColor,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        'assets/icons/boost-bolt.png',
                        width: widget.width,
                        height: widget.height,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (widget.fill > 0)
                      CustomPaint(
                        size: Size(widget.width, widget.height),
                        painter: _BoltBubblePainter(
                          phase: phase,
                          intensity: widget.isFull ? 1 : 0.62,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BoltLiquidClipper extends CustomClipper<Path> {
  const _BoltLiquidClipper({
    required this.fill,
    required this.phase,
  });

  final double fill;
  final double phase;

  @override
  Path getClip(Size size) {
    final clampedFill = fill.clamp(0.0, 1.0);
    final surfaceY = size.height * (1 - clampedFill);
    final amplitude = size.height * 0.025;
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, surfaceY);

    const steps = 18;
    for (var index = 0; index <= steps; index++) {
      final x = size.width * index / steps;
      final wave =
          math.sin((index / steps * math.pi * 2) + phase * math.pi * 2);
      path.lineTo(x, surfaceY + wave * amplitude);
    }

    path
      ..lineTo(size.width, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _BoltLiquidClipper oldClipper) {
    return oldClipper.fill != fill || oldClipper.phase != phase;
  }
}

class _BoltBubblePainter extends CustomPainter {
  const _BoltBubblePainter({
    required this.phase,
    required this.intensity,
  });

  final double phase;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    const bubbles = [
      (0.38, 0.79, 0.036, 0.0),
      (0.53, 0.72, 0.027, 0.18),
      (0.45, 0.61, 0.042, 0.36),
      (0.61, 0.53, 0.023, 0.55),
      (0.49, 0.43, 0.032, 0.72),
      (0.57, 0.33, 0.02, 0.87),
    ];

    for (var index = 0; index < bubbles.length; index++) {
      final bubble = bubbles[index];
      final travel = (phase + bubble.$4) % 1;
      final opacity = math.sin(travel * math.pi).clamp(0.0, 1.0);
      final sway =
          math.sin((travel * math.pi * 2) + index) * size.width * 0.025;
      final center = Offset(
        size.width * bubble.$1 + sway,
        size.height * (bubble.$2 - travel * 0.24),
      );
      final radius = size.width * bubble.$3 * (1 - travel * 0.2);
      final fillPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.3 * intensity)
        ..style = PaintingStyle.fill;
      final rimPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.82 * intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, size.width * 0.012);

      canvas.drawCircle(center, radius, fillPaint);
      canvas.drawCircle(center, radius, rimPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoltBubblePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.intensity != intensity;
  }
}
