import 'package:lingualloop/ui/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/league_badge_mark.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';
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
///   * **Seri** — kaç gündür aralıksız ve bugünü kurtardım mı
///   * **Bilet** — oynayabilir miyim (girişin bedeli)
///   * **Koruma** — seri kırılırsa elimde ne var
///
/// **Seviye 4 Kasım 2026'da kalktı.** Zorluk puanından türüyordu; puan
/// emekli olunca (içerik artık Karty Yolu'nda ünitelerle açılıyor) seviye
/// hiçbir şeyi söylemez oldu.
///
/// **Seri 6 Kasım 2026'da geri geldi.** Bir dönem ana ekranda kendi kartı
/// (`StreakDayCard`) vardı ve alev aynı sayıyı tekrarlıyordu. Ana ekran
/// Karty Yolu olunca kart aleve dokununca açılan pencereye taşındı; bugünün
/// durumunu artık alevin rengi söylüyor.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.scale,
    required this.leagueKey,
    required this.leagueRank,
    required this.tickets,
    required this.freezeCount,
    required this.streakDays,
    required this.playedToday,
    this.onTicketsTap,
    this.onStreakTap,
  });

  final double scale;

  /// Rozetin hangi ligi çizeceği; bilinmezse varsayılan lig kullanılır.
  final String leagueKey;

  /// Lig içindeki sıra. Veri yoksa rozet sayısız çizilir.
  final int? leagueRank;

  final int tickets;
  final int freezeCount;

  final VoidCallback? onTicketsTap;

  final int streakDays;

  /// Bugün oynanmadıysa alev rengini bırakır (seri kartındaki reçete:
  /// beyaz siluet, %55) — "alev soluk = uyarı".
  final bool playedToday;
  final VoidCallback? onStreakTap;

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
          icon: _flame(),
          value: '$streakDays',
          onTap: onStreakTap,
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

  Widget _flame() {
    Widget flame = QuestIcon(questKey: 'streak_three', size: 60 * scale);
    if (streakDays == 0 || !playedToday) {
      flame = Opacity(
        opacity: 0.55,
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          child: flame,
        ),
      );
    }
    return flame;
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
