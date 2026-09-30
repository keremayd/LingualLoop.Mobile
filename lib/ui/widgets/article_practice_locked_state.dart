import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/article_target.dart';

class ArticlePracticeLockedState extends StatelessWidget {
  const ArticlePracticeLockedState({
    super.key,
    required this.scale,
    required this.learnedCount,
    required this.requiredCount,
    required this.onClose,
    required this.onOpenKarty,
  });

  final double scale;
  final int learnedCount;
  final int requiredCount;
  final VoidCallback onClose;
  final VoidCallback onOpenKarty;

  @override
  Widget build(BuildContext context) {
    final progress = requiredCount == 0
        ? 0.0
        : (learnedCount / requiredCount).clamp(0.0, 1.0);
    return Stack(
      children: [
        Positioned(
          left: 40 * scale,
          top: 70 * scale,
          child: GestureDetector(
            onTap: onClose,
            child: Container(
              width: 58 * scale,
              height: 58 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFF0B2143),
                borderRadius: BorderRadius.circular(10 * scale),
              ),
              child: Icon(Icons.close_rounded,
                  color: Colors.white, size: 48 * scale),
            ),
          ),
        ),
        Positioned(
          left: 60 * scale,
          right: 60 * scale,
          top: 260 * scale,
          child: Column(
            children: [
              SizedBox(
                width: 500 * scale,
                height: 300 * scale,
                child: Stack(
                  children: [
                    Positioned(
                      left: 155 * scale,
                      top: 0,
                      child: ArticleTarget(
                        article: 'das',
                        color: const Color(0xFF93D334),
                        baseColor: const Color(0xFF628C22),
                        scale: scale,
                      ),
                    ),
                    Positioned(
                      left: 10 * scale,
                      top: 145 * scale,
                      child: ArticleTarget(
                        article: 'der',
                        color: const Color(0xFF1CB1F5),
                        baseColor: const Color(0xFF1B84B5),
                        scale: scale,
                      ),
                    ),
                    Positioned(
                      right: 10 * scale,
                      top: 145 * scale,
                      child: ArticleTarget(
                        article: 'die',
                        color: const Color(0xFFF52A2A),
                        baseColor: const Color(0xFFAA1C1C),
                        scale: scale,
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.lock_rounded,
                        size: 100 * scale,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 45 * scale),
              Text(
                'Artikel Pusulası hazırlanıyor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 43 * scale,
                  fontWeight: AppTypography.heading,
                  fontFamily: AppTypography.displayFamily,
                ),
              ),
              SizedBox(height: 20 * scale),
              Text(
                '$requiredCount farklı Karty öğrenince açılır',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 27 * scale,
                  fontWeight: AppTypography.body,
                  fontFamily: AppTypography.family,
                ),
              ),
              SizedBox(height: 42 * scale),
              ClipRRect(
                borderRadius: BorderRadius.circular(16 * scale),
                child: SizedBox(
                  width: 480 * scale,
                  height: 24 * scale,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.13),
                    color: const Color(0xFF93D334),
                  ),
                ),
              ),
              SizedBox(height: 14 * scale),
              Text(
                '$learnedCount / $requiredCount',
                style: TextStyle(
                  color: const Color(0xFFFFD52F),
                  fontSize: 25 * scale,
                  fontWeight: AppTypography.number,
                  fontFamily: AppTypography.family,
                ),
              ),
              SizedBox(height: 90 * scale),
              DepthPressableButton(
                text: 'KARTY OYNA',
                width: 500 * scale,
                height: 110 * scale,
                radius: 32 * scale,
                shadowOffset: 10 * scale,
                backgroundColor: const Color(0xFF93D334),
                shadowColor: const Color(0xFF628C22),
                fontSize: 34 * scale,
                fontWeight: AppTypography.action,
                onPressed: onOpenKarty,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
