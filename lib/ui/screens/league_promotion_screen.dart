import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingualloop/models/responses/LeagueProgressResponse.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/league_badge_mark.dart';

class LeaguePromotionScreen extends StatefulWidget {
  const LeaguePromotionScreen({
    super.key,
    required this.promotion,
    required this.onContinue,
  });

  final LeaguePromotionResponse promotion;
  final Future<bool> Function() onContinue;

  @override
  State<LeaguePromotionScreen> createState() => _LeaguePromotionScreenState();
}

class _LeaguePromotionScreenState extends State<LeaguePromotionScreen>
    with TickerProviderStateMixin {
  static const _backgroundColor = Color(0xFF041227);
  static const _green = Color(0xFF93D334);
  static const _greenDepth = Color(0xFF628C22);

  late final AnimationController _entranceController;
  late final AnimationController _floatController;
  bool _isEntranceComplete = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _entranceController.addStatusListener(_handleEntranceStatus);
    _entranceController.forward();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _entranceController.removeStatusListener(_handleEntranceStatus);
    _entranceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _handleEntranceStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _isEntranceComplete = true);
    }
  }

  Future<void> _continue() async {
    if (!_isEntranceComplete || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    var acknowledged = false;
    try {
      acknowledged = await widget.onContinue();
    } catch (_) {
      acknowledged = false;
    }

    if (!mounted) return;
    if (acknowledged) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lig bilgisi kaydedilemedi. Tekrar dene.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height - media.padding.vertical;
    final scale = math.min(width / 430, height / 860).clamp(0.78, 1.12);
    final targetPalette =
        LeagueVisuals.paletteFor(widget.promotion.toLeagueKey);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _PromotionBackdropPainter(
                  accent: targetPalette.base,
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _PromotionHero(
                          scale: scale,
                          promotion: widget.promotion,
                          controller: _entranceController,
                          floatController: _floatController,
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: media.padding.top + 18 * scale,
                          child: Center(
                            child: _Entrance(
                              controller: _entranceController,
                              interval: const Interval(0, 0.52),
                              offset: const Offset(0, -0.12),
                              child: _Eyebrow(scale: scale),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22 * scale),
                    child: _Entrance(
                      controller: _entranceController,
                      interval: const Interval(0.35, 0.78),
                      offset: const Offset(0, 0.14),
                      child: Column(
                        children: [
                          Text(
                            'Lig atladın!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: AppTypography.displayFamily,
                              fontSize: 38 * scale,
                              fontWeight: AppTypography.heading,
                              height: 1.04,
                              letterSpacing: -1.1 * scale,
                            ),
                          ),
                          SizedBox(height: 12 * scale),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: widget.promotion.toLeagueName,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const TextSpan(text: ' Ligi’ne yükseldin.'),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF9DACC0),
                              fontFamily: AppTypography.family,
                              fontSize: 19 * scale,
                              fontWeight: AppTypography.body,
                              height: 1.28,
                            ),
                          ),
                          SizedBox(height: 20 * scale),
                          _LeagueStepPill(
                            scale: scale,
                            promotion: widget.promotion,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 27 * scale),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      22 * scale,
                      0,
                      22 * scale,
                      22 * scale + media.padding.bottom,
                    ),
                    child: _Entrance(
                      controller: _entranceController,
                      interval: const Interval(0.58, 1),
                      offset: const Offset(0, 0.16),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 386 * scale,
                              height: 66 * scale,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: _green,
                                ),
                              ),
                            )
                          : DepthPressableButton(
                              key: const Key('league-promotion-continue'),
                              text: 'DEVAM ET',
                              width: math.min(386 * scale, width - 44 * scale),
                              height: 66 * scale,
                              radius: 18 * scale,
                              shadowOffset: 7 * scale,
                              backgroundColor: _green,
                              shadowColor: _greenDepth,
                              fontSize: 22 * scale,
                              fontWeight: AppTypography.action,
                              enabled: _isEntranceComplete,
                              onPressed: _continue,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 15 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2143),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: const Color(0xFF1CB1F5).withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: const Color(0xFFFFD52F),
            size: 17 * scale,
          ),
          SizedBox(width: 7 * scale),
          Text(
            'YENİ LİG AÇILDI',
            style: TextStyle(
              color: const Color(0xFFB9C7D9),
              fontFamily: AppTypography.family,
              fontSize: 12 * scale,
              fontWeight: AppTypography.label,
              letterSpacing: 1.25 * scale,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionHero extends StatelessWidget {
  const _PromotionHero({
    required this.scale,
    required this.promotion,
    required this.controller,
    required this.floatController,
  });

  final double scale;
  final LeaguePromotionResponse promotion;
  final AnimationController controller;
  final AnimationController floatController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heroWidth = MediaQuery.sizeOf(context).width;
        final heroHeight = constraints.maxHeight;
        final fittedWidth = heroWidth;
        final badgeSize = math.min(fittedWidth * 0.32, heroHeight * 0.25);
        final oldBadgeSize = fittedWidth * 0.18;

        return Center(
          child: OverflowBox(
            minWidth: fittedWidth,
            maxWidth: fittedWidth,
            minHeight: heroHeight,
            maxHeight: heroHeight,
            child: SizedBox(
              width: fittedWidth,
              height: heroHeight,
              child: AnimatedBuilder(
                animation: Listenable.merge([controller, floatController]),
                builder: (context, child) {
                  final sceneT = CurvedAnimation(
                    parent: controller,
                    curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
                  ).value;
                  final badgeT = CurvedAnimation(
                    parent: controller,
                    curve: const Interval(0.38, 1, curve: Curves.easeOutBack),
                  ).value;
                  final oldIntroT = CurvedAnimation(
                    parent: controller,
                    curve:
                        const Interval(0.02, 0.18, curve: Curves.easeOutBack),
                  ).value;
                  final oldRetreatT = CurvedAnimation(
                    parent: controller,
                    curve: const Interval(
                      0.32,
                      0.70,
                      curve: Curves.easeInOutCubic,
                    ),
                  ).value;
                  final arrivalRingT = const Interval(
                    0.54,
                    0.90,
                    curve: Curves.easeOutCubic,
                  ).transform(controller.value);
                  final focalCenterX = fittedWidth * 0.52;
                  final focalCenterY = heroHeight * 0.30;

                  final oldEndCenterX = fittedWidth * 0.18;
                  final oldEndCenterY = heroHeight * 0.68;
                  final oldArc =
                      math.sin(oldRetreatT * math.pi) * heroHeight * 0.055;
                  final oldCenterX = focalCenterX +
                      (oldEndCenterX - focalCenterX) * oldRetreatT;
                  final oldCenterY = focalCenterY +
                      (oldEndCenterY - focalCenterY) * oldRetreatT -
                      oldArc;
                  final oldFinalScale = oldBadgeSize / badgeSize;
                  final oldScale = (0.86 + oldIntroT * 0.14) *
                      (1 + (oldFinalScale - 1) * oldRetreatT);

                  final badgeStartCenterX = fittedWidth * 1.08;
                  final badgeEndCenterX = fittedWidth * 0.52;
                  final badgeCenterX = badgeStartCenterX +
                      (badgeEndCenterX - badgeStartCenterX) * badgeT;
                  final badgeStartCenterY = heroHeight * 0.16;
                  final badgeEndCenterY = heroHeight * 0.30;
                  final badgeArc =
                      math.sin(badgeT * math.pi) * heroHeight * 0.035;
                  final hover = math.sin(floatController.value * math.pi * 2);
                  final pulse = (hover + 1) / 2;
                  final badgeCenterY = badgeStartCenterY +
                      (badgeEndCenterY - badgeStartCenterY) * badgeT +
                      badgeArc +
                      hover * 3.2 * scale * badgeT;
                  final targetPalette = LeagueVisuals.paletteFor(
                    promotion.toLeagueKey,
                  );

                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: sceneT,
                          child: ShaderMask(
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white,
                                Colors.white,
                                Colors.transparent,
                              ],
                              stops: [0, 0.88, 1],
                            ).createShader(bounds),
                            child: Image.asset(
                              'assets/scenes/league_promotion_steps.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: oldCenterX - badgeSize * 0.635,
                        top: oldCenterY - badgeSize * 0.635,
                        child: Opacity(
                          opacity: (oldIntroT * (1 - oldRetreatT * 0.43))
                              .clamp(0.0, 1.0),
                          child: Transform.rotate(
                            angle: -0.10 * oldRetreatT,
                            child: Transform.scale(
                              scale: oldScale,
                              child: _NewLeagueHalo(
                                leagueKey: promotion.fromLeagueKey,
                                size: badgeSize,
                                pulse: 0.12 * (1 - oldRetreatT),
                                strength: 1 - oldRetreatT,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: badgeCenterX - badgeSize * 0.78,
                        top: badgeCenterY - badgeSize * 0.78,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: math.sin(arrivalRingT * math.pi) * 0.74,
                            child: Transform.scale(
                              scale: 0.62 + arrivalRingT * 0.72,
                              child: Container(
                                width: badgeSize * 1.56,
                                height: badgeSize * 1.56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: targetPalette.light,
                                    width: 3 * scale,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: targetPalette.base
                                          .withValues(alpha: 0.38),
                                      blurRadius: 20 * scale,
                                      spreadRadius: 3 * scale,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: badgeCenterX - badgeSize * 0.635,
                        top: badgeCenterY - badgeSize * 0.635,
                        child: Opacity(
                          opacity: badgeT.clamp(0, 1),
                          child: Transform.rotate(
                            angle: hover * 0.012 * badgeT,
                            child: Transform.scale(
                              scale: (0.70 + badgeT * 0.30) *
                                  (1 + pulse * 0.025 * badgeT),
                              child: _NewLeagueHalo(
                                size: badgeSize,
                                leagueKey: promotion.toLeagueKey,
                                pulse: pulse,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NewLeagueHalo extends StatelessWidget {
  const _NewLeagueHalo({
    required this.size,
    required this.leagueKey,
    required this.pulse,
    this.strength = 1,
  });

  final double size;
  final String leagueKey;
  final double pulse;
  final double strength;

  @override
  Widget build(BuildContext context) {
    final palette = LeagueVisuals.paletteFor(leagueKey);
    return Container(
      width: size * 1.27,
      height: size * 1.27,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            palette.light.withValues(
              alpha: (0.38 + pulse * 0.10) * strength,
            ),
            palette.base.withValues(
              alpha: (0.18 + pulse * 0.08) * strength,
            ),
            Colors.transparent,
          ],
          stops: const [0, 0.55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.base.withValues(
              alpha: (0.20 + pulse * 0.14) * strength,
            ),
            blurRadius: size * (0.22 + pulse * 0.10),
            spreadRadius: size * (0.015 + pulse * 0.018),
          ),
        ],
      ),
      child: LeagueBadgeMark(leagueKey: leagueKey, size: size),
    );
  }
}

class _LeagueStepPill extends StatelessWidget {
  const _LeagueStepPill({required this.scale, required this.promotion});

  final double scale;
  final LeaguePromotionResponse promotion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 10 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2143),
        borderRadius:
            BorderRadius.circular(AppShapeStyle.cardRadius(15 * scale)),
        border: Border.all(color: const Color(0xFF173A66)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            promotion.fromLeagueName,
            style: TextStyle(
              color: const Color(0xFF8395AC),
              fontFamily: AppTypography.family,
              fontSize: 13 * scale,
              fontWeight: AppTypography.label,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 9 * scale),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: const Color(0xFF1CB1F5),
              size: 18 * scale,
            ),
          ),
          Text(
            promotion.toLeagueName,
            style: TextStyle(
              color: Colors.white,
              fontFamily: AppTypography.family,
              fontSize: 13 * scale,
              fontWeight: AppTypography.label,
            ),
          ),
        ],
      ),
    );
  }
}

class _Entrance extends StatelessWidget {
  const _Entrance({
    required this.controller,
    required this.interval,
    required this.offset,
    required this.child,
  });

  final AnimationController controller;
  final Interval interval;
  final Offset offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: controller, curve: interval);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position:
            Tween<Offset>(begin: offset, end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

class _PromotionBackdropPainter extends CustomPainter {
  const _PromotionBackdropPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.70, size.height * 0.31);
    final radius = math.max(size.width, size.height) * 0.62;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.45, -0.42),
          radius: 0.92,
          colors: [
            accent.withValues(alpha: 0.16),
            const Color(0xFF071A36).withValues(alpha: 0.56),
            const Color(0xFF041227),
          ],
          stops: const [0, 0.38, 1],
        ).createShader(Offset.zero & size),
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = accent.withValues(alpha: 0.08);
    for (final factor in const [0.22, 0.34, 0.48]) {
      canvas.drawCircle(center, radius * factor, ringPaint);
    }

    final sparklePaint = Paint()..color = Colors.white.withValues(alpha: 0.36);
    for (final point in const [
      Offset(0.12, 0.18),
      Offset(0.86, 0.16),
      Offset(0.17, 0.39),
      Offset(0.91, 0.46),
      Offset(0.11, 0.64),
    ]) {
      final c = Offset(size.width * point.dx, size.height * point.dy);
      canvas.drawCircle(c, 1.6, sparklePaint);
      canvas.drawLine(
        Offset(c.dx - 5, c.dy),
        Offset(c.dx + 5, c.dy),
        sparklePaint..strokeWidth = 0.8,
      );
      canvas.drawLine(
        Offset(c.dx, c.dy - 5),
        Offset(c.dx, c.dy + 5),
        sparklePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PromotionBackdropPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
