import 'package:lingualloop/ui/app_typography.dart';
import 'learning_card_gradient.dart';

import 'package:flutter/material.dart';

class ArticleWordSurface extends StatefulWidget {
  const ArticleWordSurface({
    super.key,
    required this.borderRadius,
    this.highlightedArticle,
    this.child,
  });

  final BorderRadius borderRadius;
  final String? highlightedArticle;
  final Widget? child;

  @override
  State<ArticleWordSurface> createState() => _ArticleWordSurfaceState();
}

class _ArticleWordSurfaceState extends State<ArticleWordSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.highlightedArticle != null) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ArticleWordSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightedArticle != null && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (widget.highlightedArticle == null && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _ArticleWordSurfacePainter(
                highlightedArticle: widget.highlightedArticle,
                pulse: _controller.value,
              ),
              child: child,
            );
          },
          child: widget.child ?? const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ArticleWordSurfacePainter extends CustomPainter {
  const _ArticleWordSurfacePainter({
    required this.highlightedArticle,
    required this.pulse,
  });

  final String? highlightedArticle;
  final double pulse;

  static const _navy = Color(0xFF041227);
  static const _der = Color(0xFF1CB1F5);
  static const _das = Color(0xFFFFB000);
  static const _die = Color(0xFFF52A2A);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = learningCardGradient(size).createShader(rect),
    );
    _drawArticlePattern(canvas, size);
  }

  void _drawArticlePattern(Canvas canvas, Size size) {
    const rows = [
      ['der', 'das', 'die'],
      ['die', 'der', 'das'],
      ['das', 'die', 'der'],
      ['der', 'das', 'die'],
    ];
    final fontSize = size.width * 0.105;
    final rowGap = size.height / 4.25;
    final cellWidth = size.width / 2.35;

    for (var row = 0; row < rows.length; row++) {
      final y = size.height * 0.085 + row * rowGap;
      final startX = row.isEven ? -size.width * 0.09 : -size.width * 0.28;
      for (var column = 0; column < rows[row].length; column++) {
        final article = rows[row][column];
        final x = startX + column * cellWidth;
        _paintEmbossedWord(
          canvas,
          article,
          Offset(x, y),
          fontSize,
          article == highlightedArticle,
        );
      }
    }
  }

  void _paintEmbossedWord(
    Canvas canvas,
    String article,
    Offset offset,
    double fontSize,
    bool highlighted,
  ) {
    final color = switch (article) {
      'der' => _der,
      'das' => _das,
      'die' => _die,
      _ => Colors.white,
    };

    if (highlighted) {
      final glowPainter = TextPainter(
        text: TextSpan(
          text: article,
          style: TextStyle(
            color: color.withValues(alpha: 0.85 + pulse * 0.15),
            fontSize: fontSize,
            fontWeight: AppTypography.word,
            fontFamily: AppTypography.family,
            shadows: [
              Shadow(
                color: _navy.withValues(alpha: 0.55),
                blurRadius: fontSize * 0.06,
                offset: Offset(0, fontSize * 0.04),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      glowPainter.paint(canvas, offset);
      return;
    }

    final shadowPainter = TextPainter(
      text: TextSpan(
        text: article,
        style: TextStyle(
          color: _navy.withValues(alpha: 0.045),
          fontSize: fontSize,
          fontWeight: AppTypography.word,
          fontFamily: AppTypography.family,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    shadowPainter.paint(
      canvas,
      offset.translate(fontSize * 0.045, fontSize * 0.055),
    );

    final facePainter = TextPainter(
      text: TextSpan(
        text: article,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.07),
          fontSize: fontSize,
          fontWeight: AppTypography.word,
          fontFamily: AppTypography.family,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    facePainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ArticleWordSurfacePainter oldDelegate) {
    return oldDelegate.highlightedArticle != highlightedArticle ||
        oldDelegate.pulse != pulse;
  }
}
