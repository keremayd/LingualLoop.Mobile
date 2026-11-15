import 'package:lingualloop/ui/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

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
    required this.streakDays,
    required this.playedToday,
    this.onTicketsTap,
    this.onStreakTap,
    this.ticketIconKey,
  });

  final double scale;

  final int tickets;

  /// Bilet simgesinin yeri: harcanan bilet buradan kalkar.
  final GlobalKey? ticketIconKey;

  final VoidCallback? onTicketsTap;

  final int streakDays;

  /// Bugün oynanmadıysa alev rengini bırakır (seri kartındaki reçete:
  /// beyaz siluet, %55) — "alev soluk = uyarı".
  final bool playedToday;
  final VoidCallback? onStreakTap;

  static const _value = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    // İki uçta: seri eski lig rozetinin, bilet eski korumanın yerinde.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _item(
          icon: _flame(),
          value: '$streakDays',
          onTap: onStreakTap,
        ),
        _item(
          icon: KeyedSubtree(
            key: ticketIconKey,
            child: Image.asset(
              'assets/icons/ticket.png',
              width: 66 * scale,
            ),
          ),
          value: '$tickets',
          rollingCount: tickets,
          onTap: onTicketsTap,
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
    int? rollingCount,
    VoidCallback? onTap,
  }) {
    final style = TextStyle(
      color: _value,
      fontFamily: AppTypography.family,
      fontSize: 38 * scale,
      fontWeight: AppTypography.number,
      height: 1,
    );
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
          if (rollingCount != null)
            _RollingCount(value: rollingCount, style: style)
          else
            Text(value, style: style),
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

/// Sayı değişince yenisine kayarak döner: azalırken düşer, artarken yükselir.
/// Bedel yolda yazmadığı için bilet harcandığını bu söylüyor.
class _RollingCount extends StatefulWidget {
  const _RollingCount({required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  State<_RollingCount> createState() => _RollingCountState();
}

class _RollingCountState extends State<_RollingCount> {
  bool _falling = true;

  @override
  void didUpdateWidget(covariant _RollingCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _falling = widget.value < oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(widget.value);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, incoming == _falling ? -0.8 : 0.8),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(
        '${widget.value}',
        key: ValueKey(widget.value),
        style: widget.style,
      ),
    );
  }
}
