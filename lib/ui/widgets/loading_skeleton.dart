import 'package:flutter/material.dart';

/// Yükleme sürerken spinner yerine ekranın kendi düzeni, içleri boş
/// (iskelet). Ekran geçişlerindeki yeşil/mavi spinner "uygulama takıldı"
/// gibi okunuyordu (kullanıcı, 12 Kas 2026).
///
/// İskelet hemen değil, bekleme [delay]'i geçerse belirir: NN/g'ye göre
/// bir saniyenin altındaki beklemede yanıp sönen gösterge dikkat dağıtıyor,
/// hızlı yüklemede ekran hiçbir şey göstermeden dolsun. Durağandır; nabız ve
/// parıltı dikkat dağıtıyor, uygulamada bulanık geçiş de yasak (§2.2).
class SkeletonReveal extends StatefulWidget {
  const SkeletonReveal({super.key, required this.child});

  final Widget child;

  static const delay = Duration(milliseconds: 500);
  static const fade = Duration(milliseconds: 200);

  @override
  State<SkeletonReveal> createState() => _SkeletonRevealState();
}

class _SkeletonRevealState extends State<SkeletonReveal>
    with SingleTickerProviderStateMixin {
  static final _total = SkeletonReveal.delay + SkeletonReveal.fade;

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _total)..forward();

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      SkeletonReveal.delay.inMilliseconds / _total.inMilliseconds,
      1,
      curve: Curves.easeOut,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Yükleniyor',
        child: ExcludeSemantics(
          child: FadeTransition(opacity: _opacity, child: widget.child),
        ),
      );
}

/// İskeletin içerik yeri: yazının, simgenin ya da görselin durduğu yerde
/// düz lacivert blok (§2.2 iç panel).
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    required this.radius,
    this.color = tone,
  });

  static const tone = Color(0xFF0C2244);

  final double? width;
  final double height;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
