import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class ArticleTarget extends StatefulWidget {
  const ArticleTarget({
    super.key,
    required this.article,
    required this.color,
    required this.baseColor,
    required this.scale,
    this.isNear = false,
    this.isCorrectHint = false,
    this.isReceiving = false,
  });

  final String article;
  final Color color;
  final Color baseColor;
  final double scale;
  final bool isNear;
  final bool isCorrectHint;
  final bool isReceiving;

  @override
  State<ArticleTarget> createState() => _ArticleTargetState();
}

class _ArticleTargetState extends State<ArticleTarget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  bool get _isActive =>
      widget.isNear || widget.isCorrectHint || widget.isReceiving;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    if (_isActive) _pulseController.repeat();
  }

  @override
  void didUpdateWidget(covariant ArticleTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isActive && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!_isActive && _pulseController.isAnimating) {
      _pulseController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final icon = switch (widget.article) {
      'der' => Icons.arrow_forward_rounded,
      'die' => Icons.arrow_back_rounded,
      _ => Icons.arrow_upward_rounded,
    };
    final showIconFirst = widget.article == 'die';
    final label = switch (widget.article) {
      'der' => 'Der',
      'die' => 'Die',
      _ => 'Das',
    };
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final wave = math.sin(_pulseController.value * math.pi);
        return SizedBox(
          width: 216 * scale,
          height: 136 * scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isActive)
                Container(
                  width: (174 + 18 * wave) * scale,
                  height: (100 + 18 * wave) * scale,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                        AppShapeStyle.cardRadius(36 * scale)),
                    border: Border.all(
                      color: widget.color.withValues(alpha: 0.34 - wave * 0.2),
                      width: 5 * scale,
                    ),
                  ),
                ),
              AnimatedScale(
                scale: _isActive ? 1.05 + wave * 0.025 : 1,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: 196 * scale,
                  height: 104 * scale,
                  padding: EdgeInsets.only(
                      bottom: AppShapeStyle.cardDepth(10 * scale)),
                  decoration: BoxDecoration(
                    color: widget.baseColor,
                    borderRadius: BorderRadius.circular(
                        AppShapeStyle.cardRadius(28 * scale)),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(
                          alpha: _isActive ? 0.48 : 0.24,
                        ),
                        blurRadius: (_isActive ? 26 : 14) * scale,
                        spreadRadius: (_isActive ? 5 : 0) * scale,
                        offset: Offset(0, (_isActive ? 5 : 7) * scale),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.lerp(widget.color, Colors.white, 0.1)!,
                          widget.color,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(
                          AppShapeStyle.cardRadius(27 * scale)),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showIconFirst)
                          _TargetArrow(
                            icon: icon,
                            color: widget.baseColor,
                            scale: scale,
                          ),
                        if (showIconFirst) SizedBox(width: 7 * scale),
                        Text(
                          label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 39 * scale,
                            fontWeight: AppTypography.action,
                            fontFamily: AppTypography.family,
                            shadows: [
                              Shadow(
                                color: widget.baseColor,
                                offset: Offset(0, 3 * scale),
                                blurRadius: 3 * scale,
                              ),
                            ],
                          ),
                        ),
                        if (!showIconFirst) SizedBox(width: 7 * scale),
                        if (!showIconFirst)
                          _TargetArrow(
                            icon: icon,
                            color: widget.baseColor,
                            scale: scale,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TargetArrow extends StatelessWidget {
  const _TargetArrow({
    required this.icon,
    required this.color,
    required this.scale,
  });

  final IconData icon;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: Colors.white.withValues(alpha: 0.92),
      size: 34 * scale,
      shadows: [
        Shadow(
          color: color,
          offset: Offset(0, 2.5 * scale),
          blurRadius: 3 * scale,
        ),
      ],
    );
  }
}
