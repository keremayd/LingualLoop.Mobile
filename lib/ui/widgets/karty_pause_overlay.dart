import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/Buttons/secondary_action_button.dart';
import 'package:lingualloop/ui/widgets/karty_control_glyphs.dart';
import 'package:lingualloop/ui/widgets/level_bars_icon.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

class KartyPauseOverlay extends StatelessWidget {
  const KartyPauseOverlay({
    super.key,
    required this.scale,
    required this.level,
    required this.streak,
    required this.onResume,
    required this.onExit,
  });

  final double scale;
  final int level;
  final int streak;
  final VoidCallback onResume;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    Widget statistic(Widget icon, int value, String label, Color color) =>
        Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            icon,
            SizedBox(width: 12 * scale),
            Text('$value',
                style: TextStyle(
                    color: color,
                    fontFamily: AppTypography.family,
                    fontSize: 34 * scale,
                    fontWeight: AppTypography.number)),
          ]),
          SizedBox(height: 12 * scale),
          Text(label,
              style: TextStyle(
                  color: const Color(0xFF8FA0B5),
                  fontFamily: AppTypography.family,
                  fontSize: 24 * scale,
                  fontWeight: AppTypography.caption)),
        ]);
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: 'Oyun duraklatıldı',
      child: Stack(children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: const ModalBarrier(
                dismissible: false, color: Color(0xBB041227)),
          ),
        ),
        Center(
          child: Container(
            width: 638 * scale,
            padding: EdgeInsets.fromLTRB(
                52 * scale, 58 * scale, 52 * scale, 30 * scale),
            decoration: BoxDecoration(
                color: const Color(0xFF0B2143),
                borderRadius: BorderRadius.circular(
                    AppShapeStyle.cardRadius(52 * scale))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              KartyControlMark(
                  glyph: KartyControlGlyph.pause,
                  size: 76 * scale,
                  color: const Color(0xFF1CB1F5)),
              SizedBox(height: 32 * scale),
              Text('Duraklatıldı',
                  style: TextStyle(
                      color: const Color(0xFFE9EEF5),
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 48 * scale,
                      fontWeight: AppTypography.heading)),
              SizedBox(height: 48 * scale),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                statistic(LevelBarsIcon(size: 48 * scale), level, 'Seviye',
                    const Color(0xFF1CB1F5)),
                statistic(QuestIcon(questKey: 'streak_three', size: 48 * scale),
                    streak, 'Doğru serisi', const Color(0xFFF52A2A)),
              ]),
              SizedBox(height: 52 * scale),
              DepthPressableButton(
                text: 'DEVAM ET',
                width: 534 * scale,
                height: 110 * scale,
                radius: 30 * scale,
                shadowOffset: 10 * scale,
                backgroundColor: const Color(0xFF1CB1F5),
                shadowColor: const Color(0xFF1B84B5),
                fontSize: 32 * scale,
                onPressed: onResume,
              ),
              SizedBox(height: 22 * scale),
              SecondaryActionButton(
                text: 'Oyundan çık',
                scale: scale,
                width: 534 * scale,
                onPressed: onExit,
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
