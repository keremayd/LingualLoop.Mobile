import 'package:lingualloop/ui/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';
import 'package:lingualloop/ui/widgets/ticket_balance.dart';

/// Ana ekranın üst şeridi.
///
/// Duolingo'nun üst şeridi gibi: kart yok, selamlama yok, avatar yok — sayfa
/// zemininde duran **ikon + sayı** çiftleri. Selamlama ve profil fotoğrafı
/// yer kaplıyordu ama hiçbir karar verdirmiyordu; üst şerit "şimdi ne
/// yapabilirim" sorusunun cevabı olmalı.
///
/// Gösterilenler, her biri bir soruya cevap veriyor:
///   * **Seri** (sol uç) — kaç gündür aralıksız ve bugünü kurtardım mı
///   * **Bilet** (sağ uç) — oynayabilir miyim (girişin bedeli)
///
/// **Bilet Görevler başlığındaki sayaçla aynı** (16 Kas 2026, kullanıcı):
/// kalınlık bantlı bilet ve "15/15" kesri, ortak [TicketBalance]. Sayı
/// seri sayısıyla aynı boyda kalır.
///
/// **Lig ve koruma 16 Kasım 2026'da kalktı** (kullanıcı kararı). Seri lig
/// rozetinin yerine, bilet korumanın yerine geçti. Lig Ligler sekmesinde,
/// koruma sayısı profilde görünüyor.
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
    required this.tickets,
    required this.maxTickets,
    required this.streakDays,
    required this.playedToday,
    this.onTicketsTap,
    this.onStreakTap,
    this.ticketIconKey,
  });

  final double scale;

  final int tickets;

  /// Bilet tavanı (`maxLives`); yüklenmediyse 0 ve kesir çizilmez.
  final int maxTickets;

  /// Bilet simgesinin yeri: harcanan bilet buradan kalkar.
  final GlobalKey? ticketIconKey;

  final VoidCallback? onTicketsTap;

  final int streakDays;

  /// Bugün oynanmadıysa alev rengini bırakır (seri kartındaki reçete:
  /// beyaz siluet, %55) — "alev soluk = uyarı".
  final bool playedToday;
  final VoidCallback? onStreakTap;

  /// Şeritteki sayıların boyu: seri ve bilet aynı.
  static const _numberSize = 38.0;

  @override
  Widget build(BuildContext context) {
    // İki uçta: seri eski lig rozetinin, bilet eski korumanın yerinde.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _tappable(
          onTap: onStreakTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 70 * scale,
                height: 70 * scale,
                child: Center(child: _flame()),
              ),
              SizedBox(width: 6 * scale),
              Text(
                '$streakDays',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: AppTypography.family,
                  fontSize: _numberSize * scale,
                  fontWeight: AppTypography.number,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        _tappable(
          onTap: onTicketsTap,
          // Görevler'deki oranlar (bilet 84 : sayı 40) şeridin sayı boyuna
          // göre: bilet 80.
          child: TicketBalance(
            scale: scale,
            count: tickets,
            max: maxTickets,
            ticketWidth: 80,
            numberSize: _numberSize,
            iconKey: ticketIconKey,
            rolling: true,
          ),
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

  Widget _tappable({required Widget child, VoidCallback? onTap}) {
    if (onTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}
