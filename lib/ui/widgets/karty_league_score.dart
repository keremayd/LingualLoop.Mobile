import 'package:lingualloop/ui/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/karty_boost_palette.dart';
import 'package:lingualloop/ui/widgets/league_badge_mark.dart';

/// Üst satırdaki lig puanı. Çarpan sayının altında durur, barı daraltmaz.
class KartyLeagueScore extends StatelessWidget {
  const KartyLeagueScore({
    super.key,
    required this.scale,
    required this.leagueKey,
    required this.points,
    required this.boostActive,
    this.pointsAnchorKey,
  });

  final double scale;
  final String leagueKey;
  final int points;
  final bool boostActive;
  final GlobalKey? pointsAnchorKey;

  @override
  Widget build(BuildContext context) => Semantics(
        label: boostActive
            ? '$points lig puanı. Üç kat puan etkin.'
            : '$points lig puanı',
        excludeSemantics: true,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          LeagueBadgeMark(leagueKey: leagueKey, size: 54 * scale),
          SizedBox(width: 10.5 * scale),
          Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Text('$points',
                    key: pointsAnchorKey,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                        color: KartyBoostPalette.white,
                        fontFamily: AppTypography.family,
                        fontSize: 34.5 * scale,
                        fontWeight: AppTypography.number,
                        height: 1)),
                if (boostActive)
                  Positioned(
                    top: 41.25 * scale,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.375 * scale, vertical: 4.875 * scale),
                      decoration: BoxDecoration(
                        color: KartyBoostPalette.blue,
                        borderRadius: BorderRadius.circular(9 * scale),
                        boxShadow: [
                          BoxShadow(
                            color: KartyBoostPalette.blueDepth,
                            offset: Offset(0, 3 * scale),
                          )
                        ],
                      ),
                      child: Text('×3',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: AppTypography.family,
                            fontSize: 24.75 * scale,
                            fontWeight: AppTypography.number,
                            height: 1,
                          )),
                    ),
                  ),
              ]),
        ]),
      );
}
