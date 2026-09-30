import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_button_style.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/article_word_surface.dart';
import 'package:lingualloop/ui/widgets/pressable_layered_card.dart';

class ArticlePracticeHomeCard extends StatelessWidget {
  const ArticlePracticeHomeCard({
    super.key,
    required this.scale,
    required this.onTap,
    this.pendingCount,
    this.disabledMessage,
  });

  final double scale;
  final VoidCallback? onTap;
  final int? pendingCount;
  final String? disabledMessage;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    const baseColor = Color(0xFF628C22);
    const faceColor = Color(0xFF93D334);
    final baseOffset = AppButtonStyle.tileDepth(8 * scale);
    final radius = BorderRadius.circular(AppButtonStyle.tileRadius(28 * scale));
    return PressableLayeredCard(
      width: 307 * scale,
      height: 438 * scale,
      shadowOffset: baseOffset,
      radius: radius,
      baseColor: baseColor,
      onPressed: onTap,
      face: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB7EA55), faceColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: radius,
          border: Border.all(
            color: isEnabled
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
            width: 2 * scale,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 22 * scale,
              top: 20 * scale,
              child: Text(
                'Artikel\nPusulası',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 39 * scale,
                  fontWeight: AppTypography.heading,
                  fontFamily: AppTypography.displayFamily,
                  height: 0.95,
                ),
              ),
            ),
            Positioned(
              right: 15 * scale,
              top: 15 * scale,
              child: Image.asset(
                'assets/icons/ticket-one.png',
                width: 68 * scale,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 23 * scale,
              top: 116 * scale,
              width: 260 * scale,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                ),
                child: isEnabled && pendingCount != null
                    ? Text(
                        '$pendingCount artikel kartı\nseni bekliyor.',
                        key: ValueKey('article-practice-$pendingCount'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24 * scale,
                          fontWeight: AppTypography.body,
                          fontFamily: AppTypography.family,
                          height: 1.12,
                        ),
                      )
                    : !isEnabled && disabledMessage != null
                        ? Text(
                            disabledMessage!,
                            key: ValueKey(disabledMessage),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24 * scale,
                              fontWeight: AppTypography.body,
                              fontFamily: AppTypography.family,
                              height: 1.12,
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('article-practice-status-empty'),
                          ),
              ),
            ),
            Positioned(
              left: 61 * scale,
              top: 218 * scale,
              child: Transform.rotate(
                angle: -0.09,
                child: Container(
                  width: 185 * scale,
                  height: 145 * scale,
                  padding: EdgeInsets.all(9 * scale),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 13 * scale,
                        offset: Offset(7 * scale, 10 * scale),
                      ),
                    ],
                  ),
                  child: ArticleWordSurface(
                    borderRadius: BorderRadius.circular(17 * scale),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15 * scale,
                          vertical: 7 * scale,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF041227).withValues(alpha: 0.48),
                          borderRadius: BorderRadius.circular(20 * scale),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1 * scale,
                          ),
                        ),
                        child: Text(
                          'Haus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27 * scale,
                            fontWeight: AppTypography.word,
                            fontFamily: AppTypography.family,
                            shadows: const [
                              Shadow(
                                color: Color(0xCC041227),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 114.5 * scale,
              top: 197 * scale,
              child: _MiniDock(
                text: 'das',
                color: const Color(0xFFFFB000),
                baseColor: const Color(0xFFC97800),
                scale: scale,
              ),
            ),
            Positioned(
              left: 10 * scale,
              top: 278 * scale,
              child: _MiniDock(
                text: 'der',
                color: const Color(0xFF1CB1F5),
                baseColor: const Color(0xFF1B84B5),
                scale: scale,
              ),
            ),
            Positioned(
              right: 10 * scale,
              top: 278 * scale,
              child: _MiniDock(
                text: 'die',
                color: const Color(0xFFF52A2A),
                baseColor: const Color(0xFFAA1C1C),
                scale: scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniDock extends StatelessWidget {
  const _MiniDock({
    required this.text,
    required this.color,
    required this.baseColor,
    required this.scale,
  });

  final String text;
  final Color color;
  final Color baseColor;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14 * scale);
    return SizedBox(
      width: 78 * scale,
      height: 52 * scale,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 7 * scale,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.38),
                    blurRadius: 8 * scale,
                    offset: Offset(0, 5 * scale),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 7 * scale,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.lerp(color, Colors.white, 0.1)!, color],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: radius,
              ),
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18 * scale,
                  fontWeight: AppTypography.label,
                  fontFamily: AppTypography.family,
                  shadows: [
                    Shadow(
                      color: baseColor,
                      offset: Offset(0, 2 * scale),
                      blurRadius: 2 * scale,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
