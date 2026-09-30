import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lingualloop/models/responses/DailyActivityResponse.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/ui/widgets/home_streak_strip.dart';
import 'package:lingualloop/ui/widgets/league_badge_mark.dart';
import 'package:lingualloop/ui/widgets/level_bars_icon.dart';
import 'package:lingualloop/ui/widgets/points_star_icon.dart';
import 'package:lingualloop/ui/widgets/Popups/streak_at_risk_popup.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';
import 'package:lingualloop/ui/widgets/streak_freeze_flake.dart';
import 'package:lingualloop/ui/widgets/streak_week_strip.dart';
import 'package:provider/provider.dart';

/// Profilin omurgası: **"neye ne kadar kaldın".**
///
/// Ekran eskiden yalnızca güncel değer döküyordu (puan 105, seviye 2, lig
/// Supernova) ve hiçbir yere yönlendirmiyordu. Duolingo profilinde
/// "Personal Records", Busuu'da ders yolu aynı işi görüyor: kullanıcıya
/// **nerede olduğunu ve sırada ne olduğunu** söylemek.
///
/// Üç satırın üçü de aynı kalıpta: hedefin adı + kalan mesafe + ilerleme.
/// Çıplak bir dolum çubuğu yerine "4. seviyeye ulaş · 45 puan
/// kaldı" — bar bir şey vaat ediyor ve mevcut seviye sanılmıyor.
class ProfileGoalsCard extends StatelessWidget {
  const ProfileGoalsCard({
    super.key,
    required this.level,
    required this.levelProgress,
    required this.levelBandSize,
    required this.leagueKey,
    required this.pointsToNextLeague,
    required this.leagueProgressRatio,
    required this.currentStreak,
  });

  final int level;
  final int levelProgress;
  final int levelBandSize;

  final String leagueKey;

  /// Bir üst lige kalan puan; en üst ligde null.
  final int? pointsToNextLeague;
  final double leagueProgressRatio;

  final int currentStreak;

  static const _backgroundColor = Color(0xFF041227);
  static const _borderColor = Color(0xFF0B2143);
  static const _track = Color(0xFF0C2244);
  static const _blue = Color(0xFF1CB1F5);
  static const _gold = Color(0xFFFFC93A);
  static const _flame = Color(0xFFFF6536);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 750;
    final nextMilestone = StreakMilestones.next(currentStreak);

    final rows = <Widget>[
      _goalRow(
        scale: scale,
        icon: LevelBarsIcon(size: 52 * scale),
        // `level` mevcut seviyedir; bu bölüm ise sonraki hedefi anlatır.
        // Yalnızca "Seviye 4" yazmak topbardaki mevcut "3" ile veri
        // tutarsızlığı gibi okunuyordu.
        title: '${level + 1}. seviyeye ulaş',
        hint:
            '${(levelBandSize - levelProgress).clamp(0, levelBandSize)} puan kaldı',
        fraction: levelBandSize == 0
            ? 0
            : (levelProgress / levelBandSize).clamp(0.0, 1.0),
        color: _blue,
      ),
      _goalRow(
        scale: scale,
        icon: LeagueBadgeMark(size: 52 * scale, leagueKey: leagueKey),
        title: pointsToNextLeague == null ? 'En üst lig' : 'Bir üst lig',
        // Üst ligin **adı** gösterilmiyor: lig sırası `LeagueRules` ile
        // backend'de tanımlı (tek doğruluk kaynağı) ve yanıt bir sonraki
        // ligin adını taşımıyor. İstemcide ikinci bir lig listesi tutmak
        // ikisinin zamanla ayrışması demek olurdu.
        hint: pointsToNextLeague == null
            ? 'Zirvedesin'
            : '$pointsToNextLeague puan kaldı',
        fraction: pointsToNextLeague == null
            ? 1
            : leagueProgressRatio.clamp(0.0, 1.0),
        color: _gold,
      ),
      if (nextMilestone != null)
        _goalRow(
          scale: scale,
          icon: QuestIcon(questKey: 'streak_three', size: 52 * scale),
          title: '$nextMilestone günlük rozet',
          hint: '${nextMilestone - currentStreak} gün kaldı',
          // Bar **hedefe göre** dolar; bir önceki eşikten değil. Etiket
          // "$nextMilestone günlük rozet" diyorsa bar da onu ölçmeli.
          fraction: (currentStreak / nextMilestone).clamp(0.0, 1.0),
          color: _flame,
          last: true,
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius:
            BorderRadius.circular(AppShapeStyle.cardRadius(24 * scale)),
        boxShadow: [
          BoxShadow(
              color: _borderColor,
              offset: Offset(0, AppShapeStyle.cardDepth(6 * scale))),
        ],
      ),
      child: Stack(
        children: [
          Column(children: rows),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _NoTopBorderPainter(
                  color: _borderColor,
                  strokeWidth: AppShapeStyle.outline(2 * scale),
                  radius: AppShapeStyle.cardRadius(24 * scale),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalRow({
    required double scale,
    required Widget icon,
    required String title,
    required String hint,
    required double fraction,
    required Color color,
    bool last = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            24 * scale,
            22 * scale,
            24 * scale,
            22 * scale,
          ),
          child: Row(
            children: [
              SizedBox(width: 52 * scale, height: 52 * scale, child: icon),
              SizedBox(width: 20 * scale),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: AppTypography.family,
                              fontSize: 26 * scale,
                              fontWeight: AppTypography.label,
                              height: 1,
                            ),
                          ),
                        ),
                        SizedBox(width: 10 * scale),
                        Text(
                          hint,
                          style: TextStyle(
                            color: color,
                            fontFamily: AppTypography.family,
                            fontSize: 22 * scale,
                            fontWeight: AppTypography.caption,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12 * scale),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: SizedBox(
                        height: 14 * scale,
                        child: Stack(
                          children: [
                            const Positioned.fill(
                              child: ColoredBox(color: _track),
                            ),
                            if (fraction > 0)
                              Positioned.fill(
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: fraction,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(color: color),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!last)
          Padding(
            padding: EdgeInsets.only(left: 96 * scale),
            child: Container(height: 2 * scale, color: _borderColor),
          ),
      ],
    );
  }
}

/// "TOPLAM" satırı: değişmeyen referans sayılar, tek biçimde.
///
/// Eskiden bunlar iki ayrı düzende çiziliyordu (üstteki üçlü dikey, alttaki
/// ikili yatay) ve aynı ekranda iki istatistik dili doğuyordu.
class ProfileTotalsRow extends StatelessWidget {
  const ProfileTotalsRow({
    super.key,
    required this.experience,
    required this.learnedWords,
    required this.learnedArticles,
    required this.leaderboardRank,
  });

  final int experience;
  final int learnedWords;
  final int learnedArticles;
  final int? leaderboardRank;

  static const _backgroundColor = Color(0xFF041227);
  static const _borderColor = Color(0xFF0B2143);
  static const _muted = Color(0xFF8FA0B5);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 750;

    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius:
            BorderRadius.circular(AppShapeStyle.cardRadius(24 * scale)),
        boxShadow: [
          BoxShadow(
              color: _borderColor,
              offset: Offset(0, AppShapeStyle.cardDepth(6 * scale))),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: 24 * scale,
              horizontal: 10 * scale,
            ),
            child: Row(
              children: [
                _cell(scale, PointsStarIcon(size: 48 * scale), '$experience',
                    'PUAN'),
                _cell(scale, _WhiteBoostBoltIcon(size: 48 * scale),
                    '$learnedWords', 'KELİME'),
                _cell(scale, ArticleLearnedIcon(size: 48 * scale),
                    '$learnedArticles', 'ARTİKEL'),
                _cell(
                  scale,
                  TrophyIcon(size: 44 * scale),
                  leaderboardRank == null ? '—' : '$leaderboardRank.',
                  'LİDERLİK',
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _NoTopBorderPainter(
                  color: _borderColor,
                  strokeWidth: AppShapeStyle.outline(2 * scale),
                  radius: AppShapeStyle.cardRadius(24 * scale),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(double scale, Widget icon, String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 48 * scale, child: Center(child: icon)),
          SizedBox(height: 10 * scale),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontFamily: AppTypography.family,
              fontSize: 30 * scale,
              fontWeight: AppTypography.number,
              height: 1,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            label,
            style: TextStyle(
              color: _muted,
              fontFamily: AppTypography.family,
              fontSize: 18 * scale,
              fontWeight: AppTypography.caption,
              letterSpacing: 0.5 * scale,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// "BUGÜN" bölümü: bugüne ait olan iki şey — seri ve bekleyen rövanş.
///
/// Eskiden burada kelime/artikel sayaçları da vardı; onlar değişmeyen
/// referans bilgisi olduğu için "TOPLAM" satırına taşındı. Bugüne ait
/// olmayan bir sayı "bugün" başlığının altında durmamalı.
class ProfileLearningStatsCard extends StatelessWidget {
  const ProfileLearningStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 750;

    return Consumer<ProfileLearningStatsProvider>(
      builder: (context, provider, child) {
        final stats = provider.stats;
        final reviewCount = stats?.reviewPendingCount ?? 0;

        return Column(
          children: [
            const ProfileStreakCard(),
            SizedBox(height: 15 * scale),
            _ReviewActionCard(scale: scale, reviewCount: reviewCount),
          ],
        );
      },
    );
  }
}

/// Profildeki tek dokunulabilir öğe. Eskiden sayfanın en altındaydı ve
/// kullanıcı oraya inmeden görmüyordu; artık "BUGÜN" bölümünde.
class _ReviewActionCard extends StatelessWidget {
  const _ReviewActionCard({required this.scale, required this.reviewCount});

  final double scale;
  final int reviewCount;

  static const _green = Color(0xFF93D334);
  static const _muted = Color(0xFF8FA0B5);

  @override
  Widget build(BuildContext context) {
    final waiting = reviewCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: ProfileGoalsCard._backgroundColor,
        borderRadius:
            BorderRadius.circular(AppShapeStyle.cardRadius(24 * scale)),
        border: Border.all(
          color: waiting ? _green : ProfileGoalsCard._borderColor,
          width: AppShapeStyle.outline(2 * scale),
        ),
        boxShadow: waiting
            ? null
            : [
                BoxShadow(
                  color: ProfileGoalsCard._borderColor,
                  offset: Offset(0, AppShapeStyle.cardDepth(6 * scale)),
                ),
              ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 24 * scale,
        vertical: 22 * scale,
      ),
      child: Row(
        children: [
          QuestIcon(questKey: 'review_two', size: 52 * scale),
          SizedBox(width: 20 * scale),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  waiting
                      ? '$reviewCount rövanş kartı seni bekliyor'
                      : 'Rövanş kartın yok',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 26 * scale,
                    fontWeight: AppTypography.heading,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 5 * scale),
                Text(
                  waiting
                      ? 'Yanlış bildiklerini geri kazan'
                      : 'Yanlış cevapladıkların burada birikir',
                  style: TextStyle(
                    color: _muted,
                    fontFamily: AppTypography.family,
                    fontSize: 20 * scale,
                    fontWeight: AppTypography.body,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          if (waiting)
            Icon(Icons.chevron_right, color: _green, size: 40 * scale),
        ],
      ),
    );
  }
}

class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle({
    super.key,
    required this.text,
    required this.scale,
  });

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF8FA0B5),
          fontFamily: AppTypography.family,
          fontSize: 22 * scale,
          fontWeight: AppTypography.label,
          letterSpacing: 1.6 * scale,
          height: 1,
        ),
      ),
    );
  }
}

class _WhiteBoostBoltIcon extends StatelessWidget {
  const _WhiteBoostBoltIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/icons/boost-bolt.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class ArticleLearnedIcon extends StatelessWidget {
  const ArticleLearnedIcon({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ArticleLearnedIconPainter(),
    );
  }
}

class _ArticleLearnedIconPainter extends CustomPainter {
  // Artikel Pusulası'nın hedef renkleri: der mavisi, die kırmızısı,
  // das altını. İkon üç artikel kartını yelpaze gibi gösterir.
  static const _der = Color(0xFF1CB1F5);
  static const _derDepth = Color(0xFF13648B);
  static const _die = Color(0xFFF52A2A);
  static const _dieDepth = Color(0xFF8E1414);
  static const _das = Color(0xFFFFB000);
  static const _dasDepth = Color(0xFFB06C00);
  static const _dasLight = Color(0xFFFFD35C);

  /// Döndürülmüş, köşeleri yuvarlatılmış kart yolu.
  Path _card(
    double u, {
    required Offset center,
    required double width,
    required double height,
    required double angle,
  }) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: width * u,
            height: height * u,
          ),
          Radius.circular(8 * u),
        ),
      );
    final transform = Matrix4.identity()
      ..translateByDouble(center.dx * u, center.dy * u, 0, 1)
      ..rotateZ(angle * math.pi / 180);
    return path.transform(transform.storage);
  }

  /// Görev ikonlarıyla aynı reçete: altta kalınlık bandı, üstte ana yüzey.
  void _drawCard(Canvas canvas, Path card, Color face, Color depth, double u) {
    canvas.drawPath(card.shift(Offset(0, 6 * u)), Paint()..color = depth);
    canvas.drawPath(card, Paint()..color = face);
    // Kartlar üst üste bindiği için kendi koyu tonunda ince kenar:
    // üç kart birbirinden net ayrılır.
    canvas.drawPath(
      card,
      Paint()
        ..color = depth
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * u,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;

    final left = _card(u,
        center: const Offset(29, 55), width: 36, height: 46, angle: -17);
    final right = _card(u,
        center: const Offset(71, 55), width: 36, height: 46, angle: 17);
    final front =
        _card(u, center: const Offset(50, 54), width: 40, height: 52, angle: 0);

    canvas.drawShadow(
      front.shift(Offset(0, 8 * u)),
      Colors.black.withValues(alpha: 0.32),
      5 * u,
      false,
    );

    _drawCard(canvas, left, _der, _derDepth, u);
    _drawCard(canvas, right, _die, _dieDepth, u);
    _drawCard(canvas, front, _das, _dasDepth, u);

    // Öndeki kartın sol üst yüzeyi ışıkta.
    canvas.save();
    canvas.clipPath(front);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(78 * u, 0)
        ..lineTo(0, 78 * u)
        ..close(),
      Paint()..color = _dasLight,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArticleLearnedIconPainter oldDelegate) => false;
}

class _NoTopBorderPainter extends CustomPainter {
  const _NoTopBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final usableRadius = radius.clamp(0, size.shortestSide / 2).toDouble();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(inset, usableRadius)
      ..lineTo(inset, size.height - usableRadius)
      ..quadraticBezierTo(
        inset,
        size.height - inset,
        usableRadius,
        size.height - inset,
      )
      ..lineTo(size.width - usableRadius, size.height - inset)
      ..quadraticBezierTo(
        size.width - inset,
        size.height - inset,
        size.width - inset,
        size.height - usableRadius,
      )
      ..lineTo(size.width - inset, usableRadius);

    canvas.drawPath(path, paint);

    final leftCorner = Path()
      ..moveTo(usableRadius, inset)
      ..quadraticBezierTo(inset, inset, inset, usableRadius);
    final rightCorner = Path()
      ..moveTo(size.width - usableRadius, inset)
      ..quadraticBezierTo(
        size.width - inset,
        inset,
        size.width - inset,
        usableRadius,
      );

    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      leftCorner,
      cornerPaint
        ..shader = ui.Gradient.linear(
          Offset(usableRadius, inset),
          Offset(inset, usableRadius),
          [color.withValues(alpha: 0), color],
        ),
    );
    canvas.drawPath(
      rightCorner,
      cornerPaint
        ..shader = ui.Gradient.linear(
          Offset(size.width - usableRadius, inset),
          Offset(size.width - inset, usableRadius),
          [color.withValues(alpha: 0), color],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _NoTopBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}

/// Profildeki günlük seri şeridi.
///
/// "Günlük alev" karosu seriyi tek bir sayı olarak söylüyor; bu kart onun
/// **nasıl** oluştuğunu gösteriyor. Kullanıcı hangi gün girdiğini, hangi günü
/// kaçırdığını ve hangi günün korumayla kurtulduğunu görmeden serisinin
/// kırılganlığını hissedemiyor — sayı tek başına soyut kalıyor.
class ProfileStreakCard extends StatelessWidget {
  const ProfileStreakCard({super.key});

  static const _flame = Color(0xFFFF6536);
  static const _ice = Color(0xFF1CB1F5);
  static const _muted = Color(0xFF8FA0B5);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 750;

    return Consumer<ProfileLearningStatsProvider>(
      builder: (context, provider, child) {
        final stats = provider.stats;
        final week = stats?.week ?? const <DailyActivityDay>[];

        // Veri gelmeden boş bir kutu göstermek, kartın "bozuk" görünmesine yol
        // açıyor; şerit yoksa bölüm hiç çizilmiyor.
        if (week.isEmpty) return const SizedBox.shrink();

        return _streakSurface(
          scale: scale,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 26 * scale,
              vertical: 24 * scale,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(
                  scale: scale,
                  currentStreak: stats?.currentStreak ?? 0,
                  freezeCount: stats?.freezeCount ?? 0,
                ),
                SizedBox(height: 22 * scale),
                StreakWeekStrip(days: week.toStrip(), scale: scale),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header({
    required double scale,
    required int currentStreak,
    required int freezeCount,
  }) {
    return Row(
      children: [
        QuestIcon(questKey: 'streak_three', size: 62 * scale),
        SizedBox(width: 14 * scale),
        Text(
          '$currentStreak',
          style: TextStyle(
            color: _flame,
            fontFamily: AppTypography.family,
            fontSize: 42 * scale,
            fontWeight: AppTypography.number,
            height: 1,
          ),
        ),
        SizedBox(width: 8 * scale),
        Text(
          'günlük seri',
          style: TextStyle(
            color: _muted,
            fontFamily: AppTypography.family,
            fontSize: 25 * scale,
            fontWeight: AppTypography.caption,
            height: 1,
          ),
        ),
        const Spacer(),
        // Koruma sayısı seriyle aynı satırda: ikisi aynı hikâyenin parçası —
        // biri riskteki değer, diğeri onu kurtaracak kaynak.
        _freezePill(scale: scale, freezeCount: freezeCount),
      ],
    );
  }

  Widget _freezePill({required double scale, required int freezeCount}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C2244),
        borderRadius:
            BorderRadius.circular(AppShapeStyle.cardRadius(18 * scale)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 10 * scale,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Elde tutulan şey bloğun **kendisi** — güne çakılan da o. Kar
          // tanesi soyut bir "buz" fikriydi, nesneyi göstermiyordu.
          StreakFreezeFlake(size: 44 * scale),
          SizedBox(width: 9 * scale),
          Text(
            '$freezeCount',
            style: TextStyle(
              color: _ice,
              fontFamily: AppTypography.family,
              fontSize: 26 * scale,
              fontWeight: AppTypography.number,
              height: 1,
            ),
          ),
          SizedBox(width: 6 * scale),
          // Etiket olmadan ikon anlamı tek başına taşımak zorunda kalıyordu ve
          // 21pt'de taşıyamıyor. Satırın solu da böyle çalışmıyor zaten:
          // orada da "13" değil "13 günlük seri" yazıyor.
          Text(
            'koruma',
            style: TextStyle(
              color: _muted,
              fontFamily: AppTypography.family,
              fontSize: 22 * scale,
              fontWeight: AppTypography.caption,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// §2.3 kart dili: yüz sayfa zemini, üstsüz kontur, altta taban dudağı.
  Widget _streakSurface({required double scale, required Widget child}) {
    final radius = BorderRadius.circular(AppShapeStyle.cardRadius(28 * scale));

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: AppShapeStyle.cardDepth(7 * scale),
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ProfileGoalsCard._borderColor,
              borderRadius: radius,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: AppShapeStyle.cardDepth(7 * scale)),
          child: Container(
            decoration: BoxDecoration(
              color: ProfileGoalsCard._backgroundColor,
              borderRadius: radius,
            ),
            child: Stack(
              children: [
                child,
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _NoTopBorderPainter(
                        color: ProfileGoalsCard._borderColor,
                        strokeWidth: AppShapeStyle.outline(2 * scale),
                        radius: AppShapeStyle.cardRadius(28 * scale),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
