import 'package:flutter/material.dart';
import 'package:lingualloop/models/responses/LeagueProgressResponse.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';

Future<void> showLeagueInfoPopup(
  BuildContext context, {
  required LeagueProgressResponse league,
  required String? nextLeagueName,
}) =>
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xFF041227).withValues(alpha: 0.86),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(dialogContext).width * 0.06,
        ),
        child: SingleChildScrollView(
          child: LeagueInfoCard(
            league: league,
            nextLeagueName: nextLeagueName,
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ),
    );

/// Lig kartındaki bilgi düğmesinin ayrıntıları. Ayrı widget olduğu için ekran
/// düzenini büyütmeden ve gerçek sezon verisini sahtelemeden önizlenebilir.
class LeagueInfoCard extends StatelessWidget {
  const LeagueInfoCard({
    super.key,
    required this.league,
    required this.nextLeagueName,
    required this.onClose,
    this.now,
  });

  final LeagueProgressResponse league;
  final String? nextLeagueName;
  final VoidCallback onClose;
  final DateTime? now;

  static const _background = Color(0xFF041227);
  static const _border = Color(0xFF0B2143);
  static const _panel = Color(0xFF0C2244);
  static const _muted = Color(0xFF8FA0B5);
  static const _accent = Color(0xFF1CB1F5);
  static const _accentDepth = Color(0xFF1B84B5);
  static const _months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  String get _seasonLabel {
    final month = league.seasonKey % 100;
    final year = league.seasonKey ~/ 100;
    if (month < 1 || month > 12) return 'Aylık sezon';
    return '${_months[month - 1]} $year sezonu';
  }

  String get _remainingLabel {
    final remaining =
        league.seasonEndsAtUtc.difference((now ?? DateTime.now()).toUtc());
    if (remaining <= Duration.zero) return 'Sezon yenileniyor';
    if (remaining.inDays > 0) {
      final hours = remaining.inHours - remaining.inDays * 24;
      return 'Sezon bitimine ${remaining.inDays} gün $hours saat';
    }
    if (remaining.inHours > 0) {
      final minutes = remaining.inMinutes - remaining.inHours * 60;
      return 'Sezon bitimine ${remaining.inHours} saat $minutes dk';
    }
    return 'Sezon bitimine ${remaining.inMinutes} dk';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 750;
    final radius = BorderRadius.circular(AppShapeStyle.cardRadius(34 * scale));
    final nextThreshold = league.maxPoints;
    final hasNext = nextThreshold != null && nextLeagueName != null;
    final pointsLeft = league.pointsToNextLeague ??
        (nextThreshold == null ? 0 : nextThreshold - league.points);

    return Container(
      width: 662 * scale,
      decoration: BoxDecoration(color: _border, borderRadius: radius),
      padding: EdgeInsets.only(bottom: AppShapeStyle.cardDepth(8 * scale)),
      child: Container(
        decoration: BoxDecoration(
          color: _background,
          borderRadius: radius,
          border: Border.all(
            color: _border,
            width: AppShapeStyle.outline(2 * scale),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          34 * scale,
          38 * scale,
          34 * scale,
          34 * scale,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${league.leagueName} Ligi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontFamily: AppTypography.displayFamily,
                fontSize: 46 * scale,
                fontWeight: AppTypography.heading,
                height: 1,
              ),
            ),
            SizedBox(height: 12 * scale),
            Text(
              _seasonLabel,
              style: TextStyle(
                color: _muted,
                fontFamily: AppTypography.family,
                fontSize: 25 * scale,
                fontWeight: AppTypography.label,
              ),
            ),
            SizedBox(height: 30 * scale),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(26 * scale),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius:
                    BorderRadius.circular(AppShapeStyle.cardRadius(22 * scale)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Lig puanın',
                          style: _bodyStyle(scale, color: _muted)),
                      Text(
                        '${league.points}',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: AppTypography.family,
                          fontSize: 43 * scale,
                          fontWeight: AppTypography.number,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20 * scale),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20 * scale),
                    child: LinearProgressIndicator(
                      value: league.progressRatio.clamp(0.0, 1.0),
                      minHeight: 16 * scale,
                      backgroundColor: _border,
                      valueColor: const AlwaysStoppedAnimation(_accent),
                    ),
                  ),
                  SizedBox(height: 18 * scale),
                  Text(
                    hasNext
                        ? '$nextLeagueName için $nextThreshold puan · $pointsLeft puan kaldı'
                        : 'En üst ligdesin',
                    style: _bodyStyle(scale, color: Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24 * scale),
            Text(_remainingLabel, style: _bodyStyle(scale, color: _muted)),
            SizedBox(height: 30 * scale),
            _rule(
              scale,
              title: 'Puan nasıl kazanılır?',
              body:
                  'Karty’de doğru cevap +1, Boost ile doğru cevap +3 puan verir.',
            ),
            SizedBox(height: 24 * scale),
            _rule(
              scale,
              title: 'Yeni sezonda ne olur?',
              body:
                  'Her ay yeni sezon başlar. Son liginden bir kademe aşağıdan başlarsın; ara verdiğin her ek ay için bir kademe daha düşersin (en az Merkür).',
            ),
            SizedBox(height: 36 * scale),
            DepthPressableButton(
              text: 'ANLADIM',
              width: 594 * scale,
              height: 96 * scale,
              radius: 24 * scale,
              shadowOffset: 8 * scale,
              backgroundColor: _accent,
              shadowColor: _accentDepth,
              fontSize: 28 * scale,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }

  Widget _rule(double scale, {required String title, required String body}) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontFamily: AppTypography.family,
              fontSize: 28 * scale,
              fontWeight: AppTypography.label,
            ),
          ),
          SizedBox(height: 6 * scale),
          Text(body, style: _bodyStyle(scale, color: _muted)),
        ],
      ),
    );
  }

  TextStyle _bodyStyle(double scale, {required Color color}) => TextStyle(
        color: color,
        fontFamily: AppTypography.family,
        fontSize: 25 * scale,
        fontWeight: AppTypography.body,
        height: 1.35,
      );
}
