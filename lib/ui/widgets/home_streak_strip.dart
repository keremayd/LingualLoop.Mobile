import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/streak_freeze_mark.dart';
import 'package:lingualloop/ui/widgets/streak_week_strip.dart';

/// Serinin kilometre taşları.
///
/// Duolingo 7/30/100/365 kullanıyor ama onların kullanıcısı yıllarca kalıyor.
/// Burada ilk rozet **3. günde** geliyor: yeni kullanıcı erken tatmin olmalı,
/// yoksa ilk haftayı görmeden bırakır.
class StreakMilestones {
  const StreakMilestones._();

  static const days = [3, 7, 14, 30, 50, 100, 200, 365];

  static bool isMilestone(int streak) => days.contains(streak);

  /// Bir sonraki hedef; hepsi geçildiyse null.
  static int? next(int streak) {
    for (final d in days) {
      if (d > streak) return d;
    }
    return null;
  }
}

/// Ana ekranın seri kartı — üç durum ve aralarındaki geçiş.
///
/// **Araştırmadan gelen kural (Duolingo tasarım yazısı):** her gün kutlanmaz.
/// Normal gün sayaç tıklaması, kilometre taşı tam kutlama. Dramatik kutlamayı
/// belirli günlere kilitlemek her birini nadir kılıyor; her gün parti yapan
/// kart bir hafta sonra görünmez oluyor. Bu yüzden üç kademe var:
///
/// | Durum | Kart |
/// |---|---|
/// | Bugün oynanmamış | Alev soluk, **hafta şeridi** görevde: "neyi kaçırdın" |
/// | Bugün oynandı | Şerit gider, sayı kahraman olur, **ileriye** bakan çubuk |
/// | Kilometre taşı | Alev büyür, arkasında ışık açılır, altın kontur |
///
/// **Hafta şeridi neden gidiyor:** şerit bir görev listesidir. Gün kapandıysa
/// sorulacak soru kalmaz; kartın işi artık tatmin etmek ve ileriye bakmak.
///
/// **Geçiş kullanıcıya gösterilir.** İstatistik oyun sırasında değişiyor ama
/// kullanıcı onu görmüyor. `doneToday` false→true olduğunda kart geçişi
/// oynatır: alev renklenir ve büyür, şerit söner, sayı yerine gelir, çubuk
/// dolar. Seri koruma penceresindeki geçişle aynı mantık.
class HomeStreakStrip extends StatefulWidget {
  const HomeStreakStrip({
    super.key,
    required this.scale,
    required this.streak,
    required this.days,
    required this.doneToday,
    this.onTap,
  });

  final double scale;
  final int streak;
  final List<StreakDay> days;
  final bool doneToday;
  final VoidCallback? onTap;

  @override
  State<HomeStreakStrip> createState() => _HomeStreakStripState();
}

class _HomeStreakStripState extends State<HomeStreakStrip>
    with TickerProviderStateMixin {
  static const _face = Color(0xFF041227);
  static const _border = Color(0xFF0B2143);
  static const _tile = Color(0xFF0C2244);
  static const _muted = Color(0xFF8FA0B5);
  static const _flame = Color(0xFFFF6536);
  static const _gold = Color(0xFFFFC93A);

  /// §2.4: kaydırılabilir sayfada basılı görünüm en az bu kadar sürer.
  static const _minPress = Duration(milliseconds: 120);

  late final AnimationController _reveal;

  /// Alevin salınımı ve hâlenin nabzı. Yerleşim geçişinden **ayrı ve daha
  /// uzun**: kart oturduktan sonra alev birkaç saniye daha yavaşlayarak
  /// hareket eder ve öyle durur. Aynı denetleyiciye bağlansaydı hareket
  /// yerleşimle birlikte aniden kesilirdi.
  late final AnimationController _settle;

  bool _pressed = false;
  DateTime? _pressStart;
  Timer? _release;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      // Ritim barın dolması kadar sakin; hızlı geçiş "bir şey kaydı" gibi
      // okunuyordu.
      duration: const Duration(milliseconds: 1600),
    );
    _settle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );
    // İlk açılışta geçiş oynatılmaz; kart zaten olması gereken hâlde doğar.
    _reveal.value = widget.doneToday ? 1 : 0;
    _settle.value = 1;
  }

  @override
  void didUpdateWidget(covariant HomeStreakStrip old) {
    super.didUpdateWidget(old);
    if (!old.doneToday && widget.doneToday) {
      // Kullanıcı oyundan döndü ve gün kapandı: geçişi göster.
      _reveal.forward(from: 0);
      _settle.forward(from: 0);
    } else if (old.doneToday && !widget.doneToday) {
      // Gün döndü; animasyonsuz geri al.
      _reveal.value = 0;
      _settle.value = 1;
    }
  }

  @override
  void dispose() {
    _release?.cancel();
    _reveal.dispose();
    _settle.dispose();
    super.dispose();
  }

  void _down() {
    _release?.cancel();
    _pressStart = DateTime.now();
    setState(() => _pressed = true);
  }

  void _up({required bool fire}) {
    final elapsed = DateTime.now().difference(_pressStart ?? DateTime.now());
    final wait = _minPress - elapsed;
    void finish() {
      if (mounted) setState(() => _pressed = false);
    }

    if (wait > Duration.zero) {
      _release = Timer(wait, finish);
    } else {
      finish();
    }
    if (fire) widget.onTap?.call();
  }

  double get scale => widget.scale;
  bool get _isMilestone =>
      widget.doneToday && StreakMilestones.isMilestone(widget.streak);

  /// Seri hiç başlamamış: bugün oynanmamış **ve** sayaç sıfır.
  ///
  /// Bu, "seri kırıldı"dan farklı bir durum. Kullanıcı henüz bir şey
  /// kaybetmedi, sadece başlamadı — bu yüzden buraya üzgün değil **teşvik
  /// eden** bir yüz konuyor. Soluk alev "kaçırdın" diyordu; oysa kaçırılan
  /// bir şey yok.
  bool get _isFreshStart => !widget.doneToday && widget.streak <= 0;

  /// Zaman aralığından 0→1 çıkarır; evrelerin üst üste binmesi için.
  double _phase(double t, double from, double to,
      {Curve curve = Curves.easeOut}) {
    return curve.transform(((t - from) / (to - from)).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final lip = AppShapeStyle.cardDepth(7 * scale);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _down(),
      onTapCancel: () => _up(fire: false),
      onTapUp: (_) => _up(fire: true),
      child: SizedBox(
        width: 670 * scale,
        child: AnimatedBuilder(
          animation: Listenable.merge([_reveal, _settle]),
          builder: (context, child) {
            final t = _reveal.value;
            return Stack(
              children: [
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 60),
                    opacity: _pressed ? 0 : 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(
                            AppShapeStyle.cardRadius(28 * scale)),
                      ),
                    ),
                  ),
                ),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 80),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(
                    top: _pressed ? lip : 0,
                    bottom: _pressed ? 0 : lip,
                  ),
                  child: _cardFace(t),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _cardFace(double t) {
    // Kilometre taşında kart altın konturla çerçevelenir; kontur geçişin
    // sonuna doğru belirir ki kutlama "varış" gibi okunsun.
    final rim = _isMilestone ? _phase(t, 0.55, 1.0) : 0.0;

    // Seri hiç başlamamışken kart ayrı bir yerleşim kullanır: solda maskot,
    // sağda metin, **hafta şeridi yok**.
    //
    // Şerit bir görev listesi — "neyi kaçırdın" diye sorar. Seri hiç
    // başlamamışken kaçırılan bir şey yok; boş yedi halka soruyu boşuna
    // soruyor. Maskotun işi de o boşluğu doldurmak değil, davet etmek.
    if (_isFreshStart) return _freshStartFace();

    return Container(
      decoration: BoxDecoration(
        color: _face,
        borderRadius:
            BorderRadius.circular(AppShapeStyle.cardRadius(28 * scale)),
        border: Border.all(
          color: Color.lerp(_border, _gold, rim)!,
          width: AppShapeStyle.outline((2 + rim) * scale),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        26 * scale,
        20 * scale,
        26 * scale,
        22 * scale,
      ),
      child: Row(
        children: [
          _flameSlot(t),
          SizedBox(width: 16 * scale),
          Expanded(child: _content(t)),
        ],
      ),
    );
  }

  /// Seri hiç başlamamış hâli: maskot solda ve **kartın tabanına basıyor.**
  ///
  /// Görsel içerik sınırlarına kırpıldı; kaynakta ayakların altında boşluk
  /// yok. Bu yüzden alt dolgu sıfır veriliyor ve maskot zemine oturuyor —
  /// ortada asılı durunca uçuyormuş gibi görünüyordu.
  Widget _freshStartFace() {
    // Maskotun oranı 198/250; yükseklik kart yüzünü belirliyor.
    const mascotHeight = 200.0;

    return Container(
      decoration: BoxDecoration(
        color: _face,
        borderRadius:
            BorderRadius.circular(AppShapeStyle.cardRadius(28 * scale)),
        border:
            Border.all(color: _border, width: AppShapeStyle.outline(2 * scale)),
      ),
      // Üstte nefes payı var, altta yok: maskot tabana basmalı ama
      // şimşeğin tepesi konturun üstüne oturmamalı.
      padding: EdgeInsets.only(
        left: 18 * scale,
        right: 26 * scale,
        top: 16 * scale,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Image.asset(
            'assets/icons/mascot_flex.png',
            height: mascotHeight * scale,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 18 * scale),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24 * scale),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Serine başla',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 30 * scale,
                      fontWeight: AppTypography.heading,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 10 * scale),
                  Text(
                    'İlk günü bugün yak',
                    style: TextStyle(
                      color: _flame,
                      fontFamily: AppTypography.family,
                      fontSize: 23 * scale,
                      fontWeight: AppTypography.caption,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Alev her üç durumda da var; değişen boyutu, rengi ve arkasındaki ışık.
  /// Aynı simgenin dönüşmesi kutlamanın aracı — yeni bir süs eklenmiyor.
  Widget _flameSlot(double t) {
    final grow = _phase(t, 0.15, 0.65, curve: Curves.easeOutBack);
    final colorIn = _phase(t, 0.0, 0.45);
    final rays = _isMilestone ? _phase(t, 0.5, 1.0) : 0.0;

    // Alev **sabit hızda** salınır: 8 saniyede iki tam tur, yani bir salınım
    // ≈ 4 saniye. `easeOutCubic` denendi ve bırakıldı — başta hızlı bitişte
    // yavaş oluyordu; istenen tempo baştan sona aynı, sakin ritim.
    //
    // Tur sayısı **tam sayı** olmak zorunda: 2.0'da salınım da nabız da
    // kendiliğinden nötr noktaya geliyor, bu yüzden hareket sönümleme
    // hilesine gerek kalmadan pürüzsüz duruyor. Yarım turda bırakılsaydı
    // alev eğik kalır, nabız da bir sıçramayla kesilirdi.
    final settle = _settle.value;
    final flamePhase = 2.0 * settle;

    // Hüzme alevin şiddetinin ışığı: aynı fazdan besleniyor, alev büyüdükçe
    // ışık genişliyor.
    final pulse = 1 + math.sin(flamePhase * 2 * math.pi) * 0.40;
    final halo = _phase(t, 0.25, 0.8) * pulse;

    final box = ui.lerpDouble(84, _isMilestone ? 128 : 106, grow)!;
    final icon = ui.lerpDouble(48, _isMilestone ? 80 : 64, grow)!;

    return SizedBox(
      width: box * scale,
      height: box * scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Karo yalnız "oynanmamış" hâlde var; gün kapanınca alev serbest
          // kalıyor ve yerini sıcak hâle alıyor.
          Opacity(
            opacity: (1 - colorIn).clamp(0.0, 1.0),
            child: Container(
              width: 84 * scale,
              height: 84 * scale,
              decoration: BoxDecoration(
                color: _tile,
                borderRadius: BorderRadius.circular(22 * scale),
              ),
            ),
          ),
          if (rays > 0)
            CustomPaint(
              size: Size.square(box * scale),
              painter: _MilestoneRays(progress: rays),
            ),
          if (halo > 0)
            CustomPaint(
              size: Size.square(box * scale),
              painter: _WarmHalo(intensity: 0.30 * halo),
            ),
          _flameIcon(icon, colorIn, flamePhase),
        ],
      ),
    );
  }

  /// Gri tonlamadan renge geçiş. Matris katsayıları kimlik matrisiyle gri
  /// matrisi arasında karıştırılıyor; iki ayrı katman çapraz geçirilseydi
  /// alev bir an çift görünürdü.
  Widget _flameIcon(double size, double colorIn, double phase) {
    final k = 1 - colorIn;
    // Aynı alev yolunu paylaşan sallanabilir sürüm; ayrı çizilmiyor.
    final flame = StreakFlameMark(
      size: size * scale,
      animated: false,
      staticPhase: phase,
    );

    if (colorIn >= 0.999) return flame;

    double m(double grey, double identity) => grey * k + identity * colorIn;
    final matrix = <double>[
      m(0.2126, 1), m(0.7152, 0), m(0.0722, 0), 0, 0, //
      m(0.2126, 0), m(0.7152, 1), m(0.0722, 0), 0, 0, //
      m(0.2126, 0), m(0.7152, 0), m(0.0722, 1), 0, 0, //
      0, 0, 0, 1, 0, //
    ];

    return Opacity(
      opacity: 0.55 + 0.45 * colorIn,
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(matrix),
        child: flame,
      ),
    );
  }

  /// Sağ taraf: şerit çıkar, sayı ve çubuk girer. İkisi çapraz geçirilir;
  /// yerinden kayarak girmesi "yeni bir şey geldi" hissini veriyor.
  Widget _content(double t) {
    final out = _phase(t, 0.0, 0.3);
    final inn = _phase(t, 0.35, 0.85, curve: Curves.easeOutCubic);

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        if (out < 1)
          Opacity(
            opacity: (1 - out).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -10 * out * scale),
              child: _riskContent(),
            ),
          ),
        if (inn > 0)
          Opacity(
            opacity: inn.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - inn) * scale),
              child: _isMilestone ? _milestoneContent(t) : _securedContent(t),
            ),
          ),
      ],
    );
  }

  Widget _riskContent() {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bugün henüz oynamadın',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 27 * scale,
                  fontWeight: AppTypography.heading,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 9 * scale),
              Text(
                '${widget.streak} günlük serini sürdür',
                style: TextStyle(
                  color: _flame,
                  fontFamily: AppTypography.family,
                  fontSize: 22 * scale,
                  fontWeight: AppTypography.caption,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12 * scale),
        SizedBox(
          width: 230 * scale,
          child: StreakWeekStrip(days: widget.days, scale: scale * 0.56),
        ),
      ],
    );
  }

  Widget _securedContent(double t) {
    final next = StreakMilestones.next(widget.streak);
    final fill = _phase(t, 0.6, 1.0, curve: Curves.easeOutCubic);
    // Çubuk **hedefe göre** dolar: 4/7 → %57. Bir ara önceki eşikten
    // hesaplanıyordu ((4-3)/(7-3) = %25) ama etiket "7 günlük rozet" diyor;
    // bar ile yazı birbirini yalanlıyordu.
    final ratio = next == null ? 1.0 : (widget.streak / next).clamp(0.0, 1.0);

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${widget.streak}',
                    style: TextStyle(
                      color: _flame,
                      fontFamily: AppTypography.family,
                      fontSize: 52 * scale,
                      fontWeight: AppTypography.number,
                      height: 1,
                    ),
                  ),
                  SizedBox(width: 10 * scale),
                  Text(
                    'günlük seri',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: AppTypography.family,
                      fontSize: 25 * scale,
                      fontWeight: AppTypography.label,
                      height: 1,
                    ),
                  ),
                ],
              ),
              if (next != null) ...[
                SizedBox(height: 12 * scale),
                _bar(ratio * fill),
                SizedBox(height: 9 * scale),
                Text(
                  '${next - widget.streak} gün sonra $next günlük rozet',
                  style: TextStyle(
                    color: _muted,
                    fontFamily: AppTypography.family,
                    fontSize: 20 * scale,
                    fontWeight: AppTypography.caption,
                    height: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _milestoneContent(double t) {
    final next = StreakMilestones.next(widget.streak);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.streak} GÜNLÜK SERİ!',
          style: TextStyle(
            color: _gold,
            fontFamily: AppTypography.displayFamily,
            fontSize: 32 * scale,
            fontWeight: AppTypography.heading,
            height: 1,
          ),
        ),
        SizedBox(height: 10 * scale),
        Text(
          _milestoneLine(widget.streak),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontFamily: AppTypography.family,
            fontSize: 21 * scale,
            fontWeight: AppTypography.body,
            height: 1.2,
          ),
        ),
        if (next != null) ...[
          SizedBox(height: 12 * scale),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 15 * scale,
              vertical: 8 * scale,
            ),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Sıradaki: $next gün',
              style: TextStyle(
                color: _gold,
                fontFamily: AppTypography.family,
                fontSize: 19 * scale,
                fontWeight: AppTypography.caption,
                height: 1,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Kilometre taşına göre tek cümle. Genel bir "tebrikler" yerine o güne
  /// özel bir söz, kutlamayı gerçek kılıyor.
  String _milestoneLine(int streak) {
    switch (streak) {
      case 3:
        return 'Üç gün üst üste — alışkanlık burada başlıyor';
      case 7:
        return 'Bir hafta boyunca hiç aksatmadın';
      case 14:
        return 'İki hafta oldu, artık bu senin rutinin';
      case 30:
        return 'Bir ay! Çoğu kişi buraya gelemiyor';
      case 50:
        return 'Elli gün — bu artık şans değil';
      case 100:
        return 'Yüz gün. Söylenecek söz kalmadı';
      default:
        return '$streak gün üst üste geldin';
    }
  }

  Widget _bar(double ratio) {
    final h = 15 * scale;
    return SizedBox(
      height: h,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: _tile,
                borderRadius: BorderRadius.circular(h / 2),
              ),
            ),
          ),
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _flame,
                  borderRadius: BorderRadius.circular(h / 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alevin arkasındaki sıcak hâle — günlük tatmin hâli için, ölçülü.
class _WarmHalo extends CustomPainter {
  const _WarmHalo({required this.intensity});

  final double intensity;
  static const _flame = Color(0xFFFF6536);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          r,
          [_flame.withValues(alpha: intensity), _flame.withValues(alpha: 0)],
          [0.0, 1.0],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _WarmHalo old) => old.intensity != intensity;
}

/// Kilometre taşı ışığı. Kutlama efektiyle **aynı reçete**: keskin kenarlı
/// dilimler + mesafeyle sönüm. İki ayrı ışık dili olmasın diye ölçüler oradan
/// alındı (10 dilim, ışık %30, krem ton).
class _MilestoneRays extends CustomPainter {
  const _MilestoneRays({required this.progress});

  final double progress;

  static const _bands = 10;
  static const _band = Color(0xFFFFE9C0);
  static const _gold = Color(0xFFFFC93A);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.01) return;
    final c = size.center(Offset.zero);
    final reach = size.width / 2 * progress;

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.saveLayer(
      Rect.fromCircle(center: Offset.zero, radius: reach),
      Paint(),
    );

    const sector = 2 * math.pi / _bands;
    const half = sector * 0.15;
    final paint = Paint()..color = _band.withValues(alpha: 0.18 * progress);
    for (var i = 0; i < _bands; i++) {
      final a = i * sector + progress * 0.4;
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(math.cos(a - half) * reach, math.sin(a - half) * reach)
          ..lineTo(math.cos(a + half) * reach, math.sin(a + half) * reach)
          ..close(),
        paint,
      );
    }

    canvas.drawCircle(
      Offset.zero,
      reach,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.radial(
          Offset.zero,
          reach,
          [
            const Color(0xFFFFFFFF),
            const Color(0xFFFFFFFF),
            const Color(0x00FFFFFF),
          ],
          [0.0, 0.55, 1.0],
        ),
    );
    canvas.restore();

    canvas.drawCircle(
      Offset.zero,
      reach * 0.62,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          reach * 0.62,
          [
            _gold.withValues(alpha: 0.26 * progress),
            _gold.withValues(alpha: 0),
          ],
          [0.0, 1.0],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MilestoneRays old) => old.progress != progress;
}
