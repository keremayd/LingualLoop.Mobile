import 'dart:math' as math;

import 'package:provider/provider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/ui/widgets/karty_league_score.dart';

import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/karty_control_glyphs.dart';
import 'package:lingualloop/ui/widgets/karty_review_stack_bar.dart';
import 'package:lingualloop/ui/widgets/karty_sound_button.dart';
import 'package:lingualloop/ui/widgets/karty_time_bar.dart';

/// Tek kontrol satırı: duraklatma, süre / rövanş ilerlemesi, lig puanı ve ses.
class KartyTopBar extends StatelessWidget {
  const KartyTopBar({
    super.key,
    required this.scale,
    required this.duration,
    required this.timeBarResetNotifier,
    required this.isFinished,
    required this.isPaused,
    required this.isBoostActive,
    required this.isIntroducing,
    required this.reviewMode,
    required this.reviewTotalStack,
    required this.reviewCompletedStack,
    required this.muted,
    required this.onToggleSound,
    required this.onPause,
    this.pauseEnabled = true,
    this.leaguePointsAnchorKey,
  });

  final double scale;
  final GlobalKey? leaguePointsAnchorKey;
  final ValueNotifier<int> duration;
  final ValueNotifier<int> timeBarResetNotifier;
  final ValueNotifier<bool> isFinished;
  final ValueNotifier<bool> isPaused;
  final bool isBoostActive;
  final bool isIntroducing;
  final bool reviewMode;
  final int reviewTotalStack;
  final int reviewCompletedStack;
  final bool muted;
  final bool pauseEnabled;
  final VoidCallback onToggleSound;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final size = math.max(44.0, 84.75 * scale);
    return Consumer<ScoreWithLivesProvider>(builder: (context, scores, _) {
      final league = scores.scoreWithLives?.league;
      return Row(children: [
        Semantics(
          label: 'Oyunu duraklat',
          child: DepthPressableButton(
            width: size,
            height: size - 3.125 * scale,
            radius: 24 * scale,
            shadowOffset: 8 * scale,
            backgroundColor: const Color(0xFF163258),
            shadowColor: const Color(0xFF0B2143),
            fontSize: 24 * scale,
            enabled: pauseEnabled,
            onPressed: onPause,
            child: KartyControlMark(
              glyph: KartyControlGlyph.pause,
              size: 50.25 * scale,
            ),
          ),
        ),
        SizedBox(width: 21 * scale),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            if (isIntroducing) return const SizedBox.shrink();
            if (reviewMode) {
              return KartyReviewStackBar(
                width: constraints.maxWidth,
                height: 28 * scale,
                completedStack: reviewCompletedStack,
                totalStack: reviewTotalStack,
              );
            }
            return ValueListenableBuilder<int>(
              valueListenable: duration,
              builder: (context, seconds, child) => seconds == 0
                  ? const SizedBox.shrink()
                  : KartyTimeBar(
                      width: constraints.maxWidth,
                      height: 28 * scale,
                      duration: duration,
                      onReset: timeBarResetNotifier,
                      isFinished: isFinished,
                      isPaused: isPaused,
                      isBoostActive: isBoostActive,
                    ),
            );
          }),
        ),
        if (league != null) ...[
          SizedBox(width: 21 * scale),
          ValueListenableBuilder<bool>(
            valueListenable: isFinished,
            builder: (context, finished, _) => KartyLeagueScore(
              scale: scale,
              leagueKey: league.leagueKey,
              points: league.points,
              boostActive:
                  isBoostActive && !finished && !isIntroducing && !reviewMode,
              pointsAnchorKey: leaguePointsAnchorKey,
            ),
          ),
        ],
        SizedBox(width: 21 * scale),
        KartySoundButton(scale: scale, muted: muted, onToggle: onToggleSound),
      ]);
    });
  }
}
