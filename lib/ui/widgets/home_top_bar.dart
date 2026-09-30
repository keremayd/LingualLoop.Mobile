import 'package:lingualloop/ui/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/league_badge_mark.dart';
import 'package:lingualloop/ui/widgets/level_bars_icon.dart';
import 'package:lingualloop/ui/widgets/streak_freeze_flake.dart';

/// Ana ekranın üst şeridi.
///
/// Duolingo'nun üst şeridi gibi: kart yok, selamlama yok, avatar yok — sayfa
/// zemininde yan yana duran **ikon + sayı** çiftleri. Selamlama ve profil
/// fotoğrafı yer kaplıyordu ama hiçbir karar verdirmiyordu; üst şerit
/// "şimdi ne yapabilirim" sorusunun cevabı olmalı.
///
/// Gösterilenler, her biri bir soruya cevap veriyor:
///   * **Lig** — sıralamada neredeyim (rekabet)
///   * **Bilet** — oynayabilir miyim (girişin bedeli)
///   * **Seviye** — hangi zorlukta oynayacağım
///   * **Koruma** — seri kırılırsa elimde ne var
///
/// **Seri buradan çıkarıldı, yerine lig kondu.** İki gerekçe:
///
/// 1. Seri artık ana ekranda kendi şeridine sahip (`HomeStreakStrip`) ve orada
///    yalnız sayıyı değil bugünün kurtarılıp kurtarılmadığını da söylüyor.
///    Üst çubuktaki alev aynı sayıyı **tekrarlıyordu**.
/// 2. Lig bir ara buraya konup çıkarılmıştı çünkü "sayısı olmayan tek öğe
///    olarak sırıtıyordu". O itiraz artık geçersiz: rozetin yanında
///    `leaderboardRank` duruyor, yani ligin de bir sayısı var.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.scale,
    required this.leagueKey,
    required this.leagueRank,
    required this.tickets,
    required this.level,
    required this.freezeCount,
    this.onTicketsTap,
  });

  final double scale;

  /// Rozetin hangi ligi çizeceği; bilinmezse varsayılan lig kullanılır.
  final String leagueKey;

  /// Lig içindeki sıra. Veri yoksa rozet sayısız çizilir.
  final int? leagueRank;

  final int tickets;
  final int level;
  final int freezeCount;

  final VoidCallback? onTicketsTap;

  static const _value = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final freezeIconSize = 70 * scale;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _item(
          icon: LeagueBadgeMark(leagueKey: leagueKey, size: 62 * scale),
          // Nokta bilinçli: "3" bir adet değil, **sıra** demek. Diğer
          // sayılarla (4 gün, 15 bilet) karışmasın.
          value: leagueRank == null ? '' : '$leagueRank.',
        ),
        _item(
          icon: Image.asset(
            'assets/icons/ticket.png',
            width: 66 * scale,
          ),
          value: '$tickets',
          onTap: onTicketsTap,
        ),
        _item(
          icon: LevelBarsIcon(size: 54 * scale),
          value: '$level',
        ),
        _item(
          // Koruma, genel bir kalkan değil: seri alevinin buzun içinde
          // güvenle beklemesi.
          //
          // Bir dönem `ice-cube.png` kullanılıyordu. Painter'a geçilmesinin
          // asıl kazancı netlik değil: çizim kaç piksele basılacağını
          // biliyor, bu boyutta ayrıntıları atlayıp kontrastı yükseltiyor.
          // PNG küçültülürken aynı ayrıntıları griye çevirip kirletiyordu.
          //
          // Profildeki koruma hapı da **aynı** widget'ı kullanıyor; ikisi de
          // "kaç korumam var" sorusunu cevaplıyor, iki ayrı çizim olmasının
          // gerekçesi yok.
          icon: StreakFreezeFlake(size: freezeIconSize),
          value: '$freezeCount',
        ),
      ],
    );
  }

  Widget _item({
    required Widget icon,
    required String value,
    VoidCallback? onTap,
  }) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 70 * scale,
          height: 70 * scale,
          child: Center(child: icon),
        ),
        if (value.isNotEmpty) ...[
          SizedBox(width: 6 * scale),
          Text(
            value,
            style: TextStyle(
              color: _value,
              fontFamily: AppTypography.family,
              fontSize: 38 * scale,
              fontWeight: AppTypography.number,
              height: 1,
            ),
          ),
        ],
      ],
    );

    if (onTap == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}
