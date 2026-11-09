import 'package:flutter/material.dart';
import 'package:lingualloop/models/responses/DailyActivityResponse.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/ui/widgets/NavbarWidget.dart';
import 'package:lingualloop/ui/widgets/Popups/streak_at_risk_popup.dart';
import 'package:lingualloop/ui/widgets/streak_day_card.dart';
import 'package:lingualloop/ui/widgets/streak_day_scenes.dart';
import 'package:provider/provider.dart';

/// Seri penceresi: üst şeritteki aleve dokununca ve günün ilk oyunundan
/// dönünce alttan açılır. İçinde ana ekrandan taşınan görselli seri kartı var;
/// hangi sahnenin görüneceğine kural listesi karar veriyor (`StreakScene`).
///
/// [sceneKey] yalnız debug'daki sahne denemesi için. Veri yoksa açılmaz.
Future<void> showStreakSheet(BuildContext context, {String? sceneKey}) async {
  final data = context.read<ScoreWithLivesProvider>().scoreWithLives;
  if (data == null || data.streakWeek.isEmpty) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    isScrollControlled: true,
    builder: (_) => _StreakSheet(sceneKey: sceneKey),
  );
}

class _StreakSheet extends StatelessWidget {
  const _StreakSheet({this.sceneKey});

  final String? sceneKey;

  static const _bg = Color(0xFF041227);
  static const _panel = Color(0xFF0B2143);
  static const _handle = Color(0xFF163258);

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 750;
    final radius = Radius.circular(56 * s);
    final data = context.watch<ScoreWithLivesProvider>().scoreWithLives!;
    final List<DailyActivityDay> week = data.streakWeek;
    final scene = sceneKey != null
        ? StreakScene.byKey(sceneKey!)
        : StreakScene.resolve(StreakSceneContext.fromScore(
            data,
            freezeUsedRecently: week.freezeUsedRecently,
          ));

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.vertical(top: radius),
        ),
        padding: EdgeInsets.only(top: 10 * s),
        child: Container(
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.vertical(top: radius),
          ),
          padding: EdgeInsets.fromLTRB(40 * s, 22 * s, 40 * s, 64 * s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96 * s,
                height: 10 * s,
                decoration: BoxDecoration(
                  color: _handle,
                  borderRadius: BorderRadius.circular(5 * s),
                ),
              ),
              SizedBox(height: 34 * s),
              StreakDayCard(
                scale: s,
                days: data.streak,
                message: scene.message,
                sceneAsset: scene.asset,
                sceneAspect: scene.aspect,
                cardColor: scene.cardColor,
                sceneEdgeColor: scene.sceneEdgeColor,
                faceOpacity: scene.faceOpacity,
                sceneZoom: scene.zoom,
                sceneAnchorY: scene.anchorY,
                sceneFadeEnd: scene.fadeEnd,
                animateScene: scene.animateOnEnter,
                week: week.toStrip(),
                playedToday: data.playedToday,
                onTap: () {
                  Navigator.of(context).pop();
                  NavbarWidget.requestedTab.value =
                      NavbarWidget.profileTabIndex;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
