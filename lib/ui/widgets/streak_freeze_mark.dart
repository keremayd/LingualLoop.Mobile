import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

/// Seri koruma simgesi: **buz bloğunun içinde yanan alev.**
///
/// Alev uygulamada zaten serinin simgesi (profildeki "Günlük alev",
/// `QuestIcon('streak_three')`). Buz onu sarmalıyor ama söndürmüyor — mesaj
/// tam olarak bu: seri bitmedi, **durduruldu**.
///
/// ## Neden kalkan değil
///
/// Önce kalkan çizildi ve bırakıldı: kalkan bir saldırıyı ima ediyor, oysa
/// ortada saldıran yok — kullanıcı sadece o gün gelmedi. Mekanik savunma değil
/// koruma altına almak. Ayrıca kalkan ile şeritteki buzlu tik iki ayrı dil
/// konuşuyordu.
///
/// ## Neden düzenli kristal değil
///
/// Fasetli, simetrik bir kristal da denendi ve bırakıldı: **mücevher**
/// okunuyordu. Gem geometrisi ileride açılacak markete (para birimi)
/// saklanmalı, ayrıca lig rozetleri de faset kesimli gem gövdesi kullanıyor
/// (§2.6).
///
/// Ayrım şurada: **gem kesilir, buz donar.** Gem düzenli, simetrik, her
/// yerinden cilalı. Buz düzensiz, köşeli; matı ve berrağı bir arada. Bu yüzden
/// gövde bilerek çarpık, fasetler eşit değil, altta farklı boyda saçaklar var
/// ve bir köşede kırağı lekesi duruyor. **Simetriye çeken her düzeltme onu
/// mücevhere geri götürür.**
/// Buz bloğunun gövdesi — **tek doğruluk kaynağı**.
///
/// `StreakFreezeMark` (animasyonlu sahne) ve `StreakFreezeFlake` (sayaç
/// ikonu) aynı yolu paylaşıyor. Ayrı ayrı çizilselerdi zamanla birbirinden
/// ayrılırlardı; §2.5'teki "tekrar eden simge tek bir yoldan gelir" kuralı
/// alev için olduğu kadar buz için de geçerli.
///
/// Oranlar **simetrik değil**: üstte iki farklı yükseklikte tepe ve arada
/// bir çukur var. §5'in kuralı — *gem kesilir, buz donar.* Simetriye çeken
/// her düzeltme onu lig rozetine geri götürür.
Path streakIceBlockBody(double u, {double dy = 0}) => Path()
  ..moveTo(17 * u, (36 + dy) * u)
  ..lineTo(36 * u, (20 + dy) * u)
  ..lineTo(60 * u, (26 + dy) * u)
  ..lineTo(85 * u, (18 + dy) * u)
  ..lineTo(89 * u, (62 + dy) * u)
  ..lineTo(74 * u, (84 + dy) * u)
  ..lineTo(31 * u, (81 + dy) * u)
  ..lineTo(13 * u, (63 + dy) * u)
  ..close();

/// Alttaki buz saçakları: (yatay konum, uzunluk).
///
/// Boyları ve aralıkları bilerek **eşit değil**. Eşit olduklarında taraklaşıp
/// nesneyi manüfaktür bir cisme çeviriyorlar — bir tur üç eşit konik
/// çizildi ve cihazda "uçuşa geçecek roket" olarak okundu.
const streakIceIcicles = <List<double>>[
  [38, 14],
  [52, 22],
  [64, 11],
];


class StreakFreezeMark extends StatefulWidget {
  const StreakFreezeMark({
    super.key,
    required this.size,
    this.animated = true,
    this.staticPhase = 0,
    this.sparkles = true,
  });

  final double size;
  final bool animated;

  /// Çevresindeki kırağı parıltıları.
  ///
  /// Küçük bir sayaç rozetinde kapatılır: orada blok bir envanter kalemi,
  /// sahnenin kahramanı değil — parıltı dikkati boş yere çekiyor ve rozetin
  /// dar kutusunda gürültü yapıyor.
  final bool sparkles;

  /// Küçük boyut sürümü (optik boyut).
  ///
  /// ~28pt'de tam çizim okunmuyor: düzensiz sekizgen + fasetler + içindeki
  /// alev + saçaklar o kutuda lapaya dönüyor. Ayrıca profildeki rozet, hemen
  /// solunda duran seri aleviyle aynı satırda — içindeki alev "ikinci bir
  /// alev" gibi okunuyor.
  ///
  /// Sade sürüm: saçak yok, alev yok, parıltı yok; gövde kutuyu doldurur.
  /// Silüet ve renkler aynı kaldığı için hâlâ aynı nesne, ama küçükken
  /// anlaşılıyor. Rozetin ne anlattığını bağlam zaten söylüyor.

  /// Bloğun tabanının dikey konumu, widget yüksekliğinin oranı olarak.
  ///
  /// Gövde 100 birimlik kutuda ~`y = 83`'te biter ve merkez etrafında
  /// [_IceBlockPainter._bodyScale] ile küçültülür:
  /// `50 + (83 − 50) * 0.82 ≈ 77`.
  /// Çakılma animasyonu bloğu **tabanından** hizalıyor; merkeze göre
  /// hizalansaydı taban hedefin altında kalır, "çakıldı" hissi kaybolurdu.
  static const contactFraction = 0.77;

  /// [animated] kapalıyken donacak döngü noktası (0–1).
  ///
  /// Golden önizlemesi hareketi tek karede gösteremiyor; bu parametre sayesinde
  /// döngünün farklı noktaları yan yana basılıp salınım doğrulanabiliyor.
  final double staticPhase;

  @override
  State<StreakFreezeMark> createState() => _StreakFreezeMarkState();
}

class _StreakFreezeMarkState extends State<StreakFreezeMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.animated) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant StreakFreezeMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animated && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size.square(widget.size),
            painter: _IceBlockPainter(
              phase: widget.animated ? _controller.value : widget.staticPhase,
              sparkles: widget.sparkles,
            ),
          );
        },
      ),
    );
  }
}

class _IceBlockPainter extends CustomPainter {
  const _IceBlockPainter({
    required this.phase,
    this.sparkles = true,
  });

  /// 0 → 1 arası döngü konumu.
  final double phase;

  final bool sparkles;

  static const _iceLight = Color(0xFF6BD1FF);
  static const _iceFace = Color(0xFF1CB1F5);
  static const _iceDepth = Color(0xFF0E6A98);
  static const _flameLight = Color(0xFFFF7A5C);
  static const _flameFace = Color(0xFFF52A2A);

  /// Gövdenin 100 birimlik kutu içindeki küçültme oranı.
  ///
  /// Parıltılar gövdenin **çevresinde** dönmeli. Gövde kutuyu doldurduğunda
  /// dışarıda yer kalmıyor, parıltılar ya gövdenin üstüne düşüyor (buzda çizik
  /// gibi okunuyor) ya da kutu dışına taşıp kırpılıyor. Görünen boyut çağrı
  /// yerlerinde widget ölçüsü büyütülerek korunur.
  static const _bodyScale = 0.82;

  /// Sade sürümün büyütme katsayısı. Gövde genişliği 76 birim; altta saçaklara
  /// pay bırakıldığı için tam kutuya değil `88 / 76 ≈ 1.16` oranında yayılır.

  /// Kırağı parıltıları: açı (derece) ve merkeze uzaklık (kutu oranı).
  /// Açılar bilerek köşegenlere yakın; dikey/yatay eksende yer kalmıyor.
  static const _sparkles = <List<double>>[
    [-130, 0.40],
    [-50, 0.40],
    [-8, 0.38],
    [40, 0.40],
    [140, 0.40],
    [190, 0.38],
  ];

  /// Alttaki buz saçakları: (yatay konum, uzunluk). Boyları bilerek farklı —
  /// eşit olsalardı taraklaşırdı.
  static const _icicles = streakIceIcicles;

  /// Sade sürümün saçakları: üç tanesi o boyutta birbirine giriyor.

  /// Çarpık gövde. Köşeler §2.5/1 uyarınca yuvarlak birleşimli konturla
  /// tombullaşıyor, ama oranlar simetrik değil.
  Path _body(double u, double dy) => streakIceBlockBody(u, dy: dy);

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;

    canvas.save();
    canvas.translate(50 * u, 50 * u);
    canvas.scale(_bodyScale);
    canvas.translate(-50 * u, -50 * u);
    _paintBlock(canvas, u);
    canvas.restore();

    if (sparkles) _paintSparkles(canvas, u, size);
  }

  void _paintBlock(Canvas canvas, double u) {
    // Saçaklar gövdeden önce çizilir: altından sarkarlar. "Soğuk" sinyalini
    // en çok onlar veriyor; çıkarıldıklarında geriye jenerik mavi bir çokgen
    // kalıyor.
    for (final icicle in _icicles) {
      _fillChunky(
        canvas,
        Path()
          ..moveTo((icicle[0] - 5) * u, 78 * u)
          ..lineTo((icicle[0] + 5) * u, 78 * u)
          ..lineTo(icicle[0] * u, (80 + icicle[1]) * u)
          ..close(),
        _iceDepth,
        u,
        stroke: 4,
      );
    }

    // Kalınlık bandı (§2.5/2).
    _fillChunky(canvas, _body(u, 6), _iceDepth, u);
    _fillChunky(canvas, _body(u, 0), _iceFace, u);

    canvas.save();
    canvas.clipPath(_body(u, 0));

    // Eşit olmayan iki arka faset; ışık soldan geliyor (§2.5/3-4).
    canvas.drawPath(
      Path()
        ..moveTo(17 * u, 36 * u)
        ..lineTo(36 * u, 20 * u)
        ..lineTo(44 * u, 52 * u)
        ..lineTo(13 * u, 63 * u)
        ..close(),
      Paint()..color = _iceLight,
    );
    canvas.drawPath(
      Path()
        ..moveTo(60 * u, 26 * u)
        ..lineTo(85 * u, 18 * u)
        ..lineTo(89 * u, 62 * u)
        ..lineTo(62 * u, 56 * u)
        ..close(),
      Paint()..color = _iceLight.withValues(alpha: 0.45),
    );

    _paintFlame(canvas, u);

    // Ön cam düzlemi alevin **üstünden** geçer. Şeffaflık bulanıklıkla değil
    // örtüşmeyle anlatılıyor (§2.2 gradyan bulanıklığını yasaklıyor): alev
    // yüzeyin altında kalınca göz "bu cam" diyor.
    canvas.drawPath(
      Path()
        ..moveTo(60 * u, 26 * u)
        ..lineTo(89 * u, 62 * u)
        ..lineTo(74 * u, 84 * u)
        ..lineTo(52 * u, 60 * u)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    // Kırağı lekesi: buzun mat tuttuğu köşe. Gem her yerinden cilalıdır;
    // matın ve berrağın bir arada olması buzu buz yapan şey.
    canvas.drawPath(
      Path()
        ..moveTo(13 * u, 63 * u)
        ..lineTo(30 * u, 58 * u)
        ..lineTo(31 * u, 81 * u)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.34),
    );

    canvas.restore();

    // Üst kenarda ışık hattı.
    canvas.drawLine(
      Offset(36 * u, 20 * u),
      Offset(17 * u, 36 * u),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * u
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Buzun içindeki alev — uygulamanın **kendi** alev şekli
  /// (`streakFlameBody`), bloğun içine ölçeklenmiş.
  ///
  /// Basitleştirilmiş bir damla çizilmişti; buzdan çıkan alev kullanıcının
  /// profilde gördüğü alevle aynı olmayınca bağ kurulmuyordu.
  ///
  /// Taban `y = 78`'e sabitlenir: alev kökünden değil ucundan oynar, ayrıca
  /// daha aşağıda bloğun daralan altına kırpılırdı.
  void _paintFlame(Canvas canvas, double u) {
    final w = _FlameWobble(phase);

    canvas.save();
    canvas.translate(50 * u, 78 * u);
    // 0.545 denendi: alev bloğu kenardan kenara dolduruyor ve "buz
    // çerçeveli alev" gibi okunuyordu. Alevin çevresinde buz kalmalı.
    canvas.scale(0.46 * w.breathe);
    canvas.translate(-50 * u, -94 * u);

    _fillChunkyPath(
      canvas,
      streakFlameBody(u, tipSway: w.tipSway, sway: w.sway),
      _flameFace,
      u,
      stroke: 7,
    );
    _fillChunkyPath(
      canvas,
      streakFlameInner(u, innerSway: w.innerSway),
      _flameLight,
      u,
      stroke: 5,
    );

    canvas.restore();
  }

  /// Bloğun çevresinde sırayla yanıp sönen kırağı parıltıları.
  ///
  /// Hepsi aynı anda yanmaz — sırayla, faz kaydırmalı. Aynı anda yansalardı
  /// sabit bir doku olur, "canlı" değil "yanıp sönen lamba" gibi okunurdu.
  void _paintSparkles(Canvas canvas, double u, Size size) {
    final center = Offset(50 * u, 50 * u);

    for (var index = 0; index < _sparkles.length; index++) {
      final angle = _sparkles[index][0] * math.pi / 180;
      final radius = _sparkles[index][1] * size.width;

      final local = (phase + index / _sparkles.length) % 1;
      final envelope = local < 0.45 ? math.sin(local / 0.45 * math.pi) : 0.0;
      if (envelope <= 0.02) continue;

      final position =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      final scale = (6.5 + index % 3 * 2.0) * u * envelope;

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(local * 1.2);
      canvas.drawPath(
        _sparklePath(scale),
        Paint()..color = Colors.white.withValues(alpha: 0.9 * envelope),
      );
      canvas.restore();
    }
  }

  /// Dört uçlu parıltı: kenarları içbükey olduğu için ışık gibi okunur.
  Path _sparklePath(double radius) {
    final waist = radius * 0.18;
    return Path()
      ..moveTo(0, -radius)
      ..quadraticBezierTo(waist, -waist, radius, 0)
      ..quadraticBezierTo(waist, waist, 0, radius)
      ..quadraticBezierTo(-waist, waist, -radius, 0)
      ..quadraticBezierTo(-waist, -waist, 0, -radius)
      ..close();
  }

  /// §2.5/1: aynı yolu hem doldur hem aynı renkle yuvarlak birleşimli konturla
  /// — köşeler yuvarlanır, biçim tombullaşır.
  void _fillChunky(
    Canvas canvas,
    Path path,
    Color color,
    double u, {
    double stroke = 7,
  }) {
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * u
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _IceBlockPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.sparkles != sparkles;
  }
}

/// Alevin salınımı.
///
/// **Döngü kapanma kuralı: frekans çarpanları TAM SAYI olmak zorunda.**
/// Denetleyici 0→1 dönüyor ve `t = phase * 2π`; kesirli bir çarpan sinüsü
/// tamamlanmamış bir noktada keser, döngü başa sardığında alev zıplar. Faz
/// kaydırmaları sabit oldukları için sorun değil, yalnızca çarpanlar önemli.
/// Bkz. `test/streak_freeze_preview_test.dart` içindeki döngü kapanma testi.
class _FlameWobble {
  factory _FlameWobble(double phase) {
    final t = phase * math.pi * 2;
    double wobble(double shift) =>
        math.sin(t * 2 + shift) * 0.72 + math.sin(t * 3 + shift * 1.6) * 0.28;

    return _FlameWobble._(
      breathe: 1 + math.sin(t) * 0.09,
      sway: wobble(0) * 2.6,
      tipSway: wobble(0.7) * 5.2,
      innerSway: wobble(1.4) * 3.4,
    );
  }

  const _FlameWobble._({
    required this.breathe,
    required this.sway,
    required this.tipSway,
    required this.innerSway,
  });

  final double breathe;
  final double sway;
  final double tipSway;
  final double innerSway;
}

/// §2.5/1: aynı yolu hem doldur hem aynı renkle yuvarlak birleşimli konturla —
/// köşeler yuvarlanır, biçim tombullaşır.
void _fillChunkyPath(
  Canvas canvas,
  Path path,
  Color color,
  double u, {
  double stroke = 7,
}) {
  canvas.drawPath(path, Paint()..color = color);
  canvas.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * u
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round,
  );
}

/// Buzdan çıkmış seri alevi — **buz bloğunun içindekiyle aynı alev.**
///
/// Karar penceresi sonuca döndüğünde başlıkta bu duruyor: blok harcandı ve
/// şeritteki güne gitti, alev ise kurtarıldı. Aynı yolları paylaştıkları için
/// göz ikisini tek nesne olarak bağlıyor.
///
/// Buzun içindekinden farkı: kalınlık bandı var (§2.5/2). Cam ardında gereksizdi,
/// tek başınayken gerekli.
class StreakFlameMark extends StatefulWidget {
  const StreakFlameMark({
    super.key,
    required this.size,
    this.animated = true,
    this.staticPhase = 0,
  });

  final double size;
  final bool animated;
  final double staticPhase;

  @override
  State<StreakFlameMark> createState() => _StreakFlameMarkState();
}

class _StreakFlameMarkState extends State<StreakFlameMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.animated) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          size: Size.square(widget.size),
          painter: _FreedFlamePainter(
            phase: widget.animated ? _controller.value : widget.staticPhase,
          ),
        ),
      ),
    );
  }
}

class _FreedFlamePainter extends CustomPainter {
  const _FreedFlamePainter({required this.phase});

  final double phase;

  static const _light = Color(0xFFFF7A5C);
  static const _face = Color(0xFFF52A2A);
  static const _depth = Color(0xFF9A1414);

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final w = _FlameWobble(phase);

    canvas.save();
    // Taban sabit, tepe oynar — alev kökünden sallanmaz.
    canvas.translate(50 * u, 92 * u);
    canvas.scale(0.95 * w.breathe);
    canvas.translate(-50 * u, -94 * u);

    final body = streakFlameBody(u, tipSway: w.tipSway, sway: w.sway);
    // Kalınlık bandı (§2.5/2). Cam ardında gereksizdi, tek başınayken gerekli.
    _fillChunkyPath(canvas, body.shift(Offset(0, 6 * u)), _depth, u);
    _fillChunkyPath(canvas, body, _face, u);
    _fillChunkyPath(
      canvas,
      streakFlameInner(u, innerSway: w.innerSway),
      _light,
      u,
      stroke: 5,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FreedFlamePainter oldDelegate) =>
      oldDelegate.phase != phase;
}
