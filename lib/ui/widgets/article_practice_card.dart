import 'learning_card_frame.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lingualloop/models/ArticlePractice.dart';
import 'package:lingualloop/ui/widgets/article_word_surface.dart';

class ArticlePracticeCard extends StatelessWidget {
  const ArticlePracticeCard({
    super.key,
    required this.task,
    required this.scale,
    this.isDragging = false,
    this.highlightedArticle,
  });

  final ArticlePracticeTask task;
  final double scale;
  final bool isDragging;
  final String? highlightedArticle;

  @override
  Widget build(BuildContext context) {
    final radius = AppShapeStyle.cardRadius(48 * scale);
    final border = AppShapeStyle.outline(15 * scale);
    return AnimatedScale(
      scale: isDragging ? 1.025 : 1,
      duration: const Duration(milliseconds: 130),
      child: LearningCardFrame(
        width: 560 * scale,
        height: 860 * scale,
        radius: radius,
        borderWidth: border,
        scale: scale,
        isRaised: isDragging,
        child: ArticleWordSurface(
          borderRadius: BorderRadius.circular(radius - border),
          highlightedArticle: highlightedArticle,
          child: Stack(
            children: [
              Positioned(
                left: 76 * scale,
                right: 76 * scale,
                top: 185 * scale,
                height: 310 * scale,
                child: _TaskImageStage(task: task, scale: scale),
              ),
              Positioned(
                left: 24 * scale,
                right: 24 * scale,
                bottom: 120 * scale,
                child: Container(
                  height: 84 * scale,
                  padding: EdgeInsets.symmetric(horizontal: 18 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0xFF041227).withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(
                        AppShapeStyle.cardRadius(22 * scale)),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.11),
                      width: AppShapeStyle.outline(2 * scale),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF041227).withValues(alpha: 0.28),
                        blurRadius: 10 * scale,
                        offset: Offset(0, 6 * scale),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    task.nounText,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48 * scale,
                      fontWeight: AppTypography.word,
                      fontFamily: AppTypography.family,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 67 * scale,
                right: 67 * scale,
                bottom: 68 * scale,
                child: _LearningStackBar(
                  current: task.learningStack,
                  goal: task.learningGoal,
                  scale: scale,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArticlePracticeDeckBackdrop extends StatelessWidget {
  const ArticlePracticeDeckBackdrop({
    super.key,
    required this.scale,
    required this.nextTask,
  });

  final double scale;
  final ArticlePracticeTask? nextTask;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 560 * scale,
      height: 986 * scale,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          _DeckLayer(scale: scale, width: 465, top: 122),
          if (nextTask == null)
            _DeckLayer(scale: scale, width: 503, top: 61)
          else
            Positioned(
              top: 61 * scale,
              child: IgnorePointer(
                child: Transform(
                  alignment: Alignment.topCenter,
                  transform: Matrix4.diagonal3Values(503 / 560, 1, 1),
                  child: ArticlePracticeCard(
                    key: ValueKey('preview-${nextTask!.kartyId}'),
                    task: nextTask!,
                    scale: scale,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeckLayer extends StatelessWidget {
  const _DeckLayer({
    required this.scale,
    required this.width,
    required this.top,
  });

  final double scale;
  final double width;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top * scale,
      child: LearningCardFrame(
        width: width * scale,
        height: 860 * scale,
        radius: AppShapeStyle.cardRadius(48 * scale),
        borderWidth: AppShapeStyle.outline(15 * scale),
        scale: scale,
        child: ArticleWordSurface(
          borderRadius: BorderRadius.circular(
            AppShapeStyle.cardRadius(48 * scale) -
                AppShapeStyle.outline(15 * scale),
          ),
        ),
      ),
    );
  }
}

class _LearningStackBar extends StatelessWidget {
  const _LearningStackBar({
    required this.current,
    required this.goal,
    required this.scale,
  });

  final int current;
  final int goal;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final safeGoal = goal <= 0 ? 5 : goal;
    return Row(
      children: List.generate(safeGoal, (index) {
        final isFilled = index < current.clamp(0, safeGoal);
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            height: (isFilled ? 11 : 8) * scale,
            margin: EdgeInsets.symmetric(horizontal: 4 * scale),
            decoration: BoxDecoration(
              color: isFilled
                  ? const Color(0xFFFFD52F)
                  : const Color(0xFF041227).withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(20 * scale),
              boxShadow: isFilled
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD52F).withValues(alpha: 0.5),
                        blurRadius: 8 * scale,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class _TaskImage extends StatelessWidget {
  const _TaskImage({required this.task});

  final ArticlePracticeTask task;

  @override
  Widget build(BuildContext context) {
    if (task.localImagePath.isNotEmpty) {
      return Image.file(File(task.localImagePath), fit: BoxFit.contain);
    }
    if (task.kartyUrl.isNotEmpty) {
      return Image.network(task.kartyUrl, fit: BoxFit.contain);
    }
    return const Icon(Icons.image_rounded, color: Colors.white, size: 90);
  }
}

class _TaskImageStage extends StatelessWidget {
  const _TaskImageStage({required this.task, required this.scale});

  final ArticlePracticeTask task;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.translate(
          offset: Offset(0, 12 * scale),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: 10 * scale,
              sigmaY: 10 * scale,
            ),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                const Color(0xFF041227).withValues(alpha: 0.38),
                BlendMode.srcIn,
              ),
              child: _TaskImage(task: task),
            ),
          ),
        ),
        _TaskImage(task: task),
      ],
    );
  }
}
