import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';

class KartyReviewCompleteState extends StatefulWidget {
  const KartyReviewCompleteState({
    super.key,
    required this.scale,
    required this.rewardTickets,
    required this.onClose,
  });

  final double scale;
  final int rewardTickets;
  final VoidCallback onClose;

  @override
  State<KartyReviewCompleteState> createState() =>
      _KartyReviewCompleteStateState();
}

class _KartyReviewCompleteStateState extends State<KartyReviewCompleteState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 58 * scale,
          child: _ReviewEntrance(
            controller: _entranceController,
            interval: const Interval(0, 0.62),
            offset: const Offset(0, 0.035),
            child: _KartyReviewCompleteScene(scale: scale),
          ),
        ),
        Positioned(
          left: 40 * scale,
          top: 155 * scale,
          child: _ReviewEntrance(
            controller: _entranceController,
            interval: const Interval(0.28, 0.58),
            offset: const Offset(-0.08, 0),
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(
                width: 56 * scale,
                height: 56 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2143),
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 48 * scale,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 50 * scale,
          right: 50 * scale,
          top: 792 * scale,
          child: Column(
            children: [
              _ReviewEntrance(
                controller: _entranceController,
                interval: const Interval(0.30, 0.60),
                offset: const Offset(0, 0.22),
                child: Text(
                  'Rövanşı tamamladın!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 52 * scale,
                    fontWeight: AppTypography.heading,
                    fontFamily: AppTypography.displayFamily,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(height: 18 * scale),
              _ReviewEntrance(
                controller: _entranceController,
                interval: const Interval(0.40, 0.70),
                offset: const Offset(0, 0.20),
                child: Text(
                  'Karty\'lerle yeniden karşılaştın ve öğrendiklerini güçlendirdin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 27 * scale,
                    fontWeight: AppTypography.body,
                    fontFamily: AppTypography.family,
                    height: 1.25,
                  ),
                ),
              ),
              SizedBox(height: 30 * scale),
              _ReviewEntrance(
                controller: _entranceController,
                interval: const Interval(0.52, 0.82),
                offset: const Offset(0, 0.20),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24 * scale,
                    vertical: 12 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2143),
                    borderRadius: BorderRadius.circular(
                        AppShapeStyle.cardRadius(22 * scale)),
                    border: Border.all(
                      color: const Color(0xFF93D334).withValues(alpha: 0.48),
                      width: AppShapeStyle.outline(2 * scale),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.rewardTickets > 0)
                        Image.asset(
                          'assets/icons/ticket-one.png',
                          width: 37 * scale,
                          fit: BoxFit.contain,
                        )
                      else
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: const Color(0xFFFFD52F),
                          size: 27 * scale,
                        ),
                      SizedBox(width: 10 * scale),
                      Text(
                        widget.rewardTickets > 0
                            ? '+${widget.rewardTickets} bilet kazandın'
                            : 'Bilgilerin güçlendi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23 * scale,
                          fontWeight: AppTypography.label,
                          fontFamily: AppTypography.family,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 46 * scale),
              _ReviewEntrance(
                controller: _entranceController,
                interval: const Interval(0.68, 1),
                offset: const Offset(0, 0.18),
                child: DepthPressableButton(
                  text: 'ANA MENÜYE DÖN',
                  width: 410 * scale,
                  height: 82 * scale,
                  radius: 22 * scale,
                  shadowOffset: 8 * scale,
                  backgroundColor: const Color(0xFF93D334),
                  shadowColor: const Color(0xFF628C22),
                  fontSize: 27 * scale,
                  fontWeight: AppTypography.action,
                  onPressed: widget.onClose,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewEntrance extends StatelessWidget {
  const _ReviewEntrance({
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
    final animation = CurvedAnimation(
      parent: controller,
      curve: interval,
    );

    return AnimatedBuilder(
      animation: controller,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: offset, end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
      builder: (context, animatedChild) => IgnorePointer(
        ignoring: controller.value < interval.end,
        child: animatedChild,
      ),
    );
  }
}

class _KartyReviewCompleteScene extends StatelessWidget {
  const _KartyReviewCompleteScene({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: [0, 0.09, 0.20, 0.70, 0.98],
      ).createShader(bounds),
      child: SizedBox(
        width: 750 * scale,
        height: 1002 * scale,
        child: Image.asset(
          'assets/scenes/karty_review_complete.png',
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
