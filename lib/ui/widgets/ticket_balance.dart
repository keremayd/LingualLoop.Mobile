import 'package:flutter/material.dart';
import 'package:lingualloop/ui/app_typography.dart';

/// Bilet bakiyesi: kalınlık bantlı yıldızlı bilet, yanında sayı ve soluk
/// "/tavan". Görevler başlığında doğdu; ana ekranın üst şeridi de aynı
/// parçayı kullanır (16 Kas 2026, kullanıcı: "görevler ekranındaki gibi,
/// daha güzel"). İki yerde ayrı çizilseydi zamanla birbirinden ayrılırlardı.
///
/// Ölçüler biletin enine ve sayının boyuna oranlı; Görevler'de bilet 84,
/// sayı 40 (670 ölçeği). Ana ekranda sayı şeritteki seri sayısıyla aynı
/// boyda, bilet ve kesir aynı oranlarla ona göre.
class TicketBalance extends StatelessWidget {
  const TicketBalance({
    super.key,
    required this.scale,
    required this.count,
    required this.max,
    required this.ticketWidth,
    required this.numberSize,
    this.iconKey,
    this.rolling = false,
  });

  final double scale;
  final int count;

  /// Tavan kullanıcı bazında değişebiliyor (premium `max_lives`'ı
  /// yükseltecek), bu yüzden sabit 15 değil satırdan okunur. Yüklenmediyse
  /// (0) kesir hiç çizilmez: "13/0" bakiyeyi yalanlar.
  ///
  /// Tavan **yazıyla** gösteriliyor. Kesir yerine kap çizmek (çubuk, bölmeli
  /// kap) denendi, hepsi başka sebeplerden elendi; tavanın anlaşılması
  /// önceliklendi. Tavandayken renk değişmez: dolu olmak iyi bir durum,
  /// aciliyet tonu (§2.10) onu cezaya çevirirdi.
  final int max;

  /// Biletin eni ve sayının boyu, tasarım birimi.
  final double ticketWidth;
  final double numberSize;

  /// Biletin yeri: uçan biletler buraya iner, harcanan bilet buradan kalkar.
  /// Sayı değil, biletin kendisi.
  final Key? iconKey;

  /// Sayı değişince yenisine kayarak döner: azalırken düşer, artarken
  /// yükselir. Ana ekranda bedel yolda yazmadığı için harcamayı bu söylüyor.
  final bool rolling;

  /// Kalınlık bandı: §2.6 `yildiz` taşının koyusu, ödül biletlerinin
  /// sönük tonu (§5 "Sönükten parlağa").
  static const _band = Color(0xFFB87E00);
  static const _muted = Color(0xFF8FA0B5);

  @override
  Widget build(BuildContext context) {
    final width = ticketWidth * scale;
    final depth = ticketWidth * 6 / 84 * scale;
    final number = TextStyle(
      color: Colors.white,
      fontFamily: AppTypography.family,
      fontSize: numberSize * scale,
      fontWeight: AppTypography.number,
      height: 1,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Kalınlık bandı (§2.5): biletin kendi silüeti, koyu altınla biraz
        // aşağıda. Gölgesiz PNG ekranda işlenmemiş görünüyordu. ShaderMask
        // değil renkli Image: ayrı katman açmaz, büyüyüp küçülen bilette
        // takılmaz (§4.4).
        SizedBox(
          width: width,
          height: width * 110 / 172 + depth,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: depth,
                child: Image.asset(
                  'assets/icons/ticket.png',
                  width: width,
                  fit: BoxFit.contain,
                  color: _band,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: Image.asset(
                  'assets/icons/ticket.png',
                  key: iconKey,
                  width: width,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: ticketWidth * 10 / 84 * scale),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (rolling)
              _RollingCount(value: count, style: number)
            else
              Text('$count', style: number),
            if (max > 0)
              Text(
                '/$max',
                style: TextStyle(
                  color: _muted,
                  fontFamily: AppTypography.family,
                  fontSize: numberSize * 0.6 * scale,
                  fontWeight: AppTypography.caption,
                  height: 1,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

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
