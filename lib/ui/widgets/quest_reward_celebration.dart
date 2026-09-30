import 'package:lingualloop/ui/app_typography.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Görev ödülü alındığında sahnenin ortasında oynayan kutlama.
///
/// Önceki tasarım efekti kartın konturunda gezdiriyordu; teknik bir tarama
/// gibi okunuyor, sevinç vermiyordu. Duolingo'nun kutlama dili kenarda değil
/// **sahnenin ortasında** kurulur: perde iner, ödül elastik bir aşımla
/// patlar, arkasında ışın çelengi döner, konfeti yerçekimiyle dağılır.
///
/// Palet dışına çıkılmaz; ışınlar ve konfeti keskin kenarlıdır (bulanık
/// gradyan ve neon yasak, §2.2). Konfeti şekilleri yassı ve kalın —
/// "chunky sticker" diliyle aynı ailede.
class QuestRewardCelebration extends StatelessWidget {
  const QuestRewardCelebration({
    super.key,
    required this.progress,
    required this.scale,
    required this.rewardTickets,
    required this.questTitle,
  });

  /// 0 → 1 arası kutlama ilerlemesi.
  final double progress;
  final double scale;
  final int rewardTickets;
  final String questTitle;

  static const _backdrop = Color(0xFF041227);
  static const _gold = Color(0xFFFFC93A);
  static const _muted = Color(0xFF8FA0B5);

  /// Çelenk ve konfetinin çizildiği kare kutu; biletin merkezine oturur ve
  /// konfetinin ekran dışına kadar savrulmasına yer bırakır.
  static const _burstBox = 1400.0;

  /// Bilet kutusu ile metinler arasındaki boşluk.
  ///
  /// **Metinler ışığın dışında durur.** Bir ara hüzmelerin metnin üstünden
  /// geçmesi "istenen şey" sanılmıştı; öyle olunca yazılar parlamanın içinde
  /// kalıp okunaksızlaştı ve efektin çerçevesini bozdu. Işık kendi dairesinde
  /// kalmalı, metinler onun üstünde ve altında.
  ///
  /// Değer göz kararı değil: ışık merkezden [_LightRaysPainter.reach] birim
  /// gidiyor, biletin yarısı 141/2 ≈ 71 birim. Metnin başlangıcı en az
  /// `reach − 71` olmalı; üstüne küçük bir nefes payı ekleniyor.
  static const _textGap = _LightRaysPainter.reach - 141 / 2 + 8; // ≈ 222

  /// Perde: 0–0.10 arasında iner, 0.82–1 arasında kalkar.
  double get _curtain {
    final rise = (progress / 0.10).clamp(0.0, 1.0);
    final fall = 1 - ((progress - 0.82) / 0.18).clamp(0.0, 1.0);
    return rise * fall;
  }

  /// Ödül: 0.06'da doğar, aşımla oturur, sonunda hafifçe küçülerek çekilir.
  double get _rewardScale {
    final t = ((progress - 0.06) / 0.26).clamp(0.0, 1.0);
    if (t <= 0) return 0;
    final settle = Curves.easeOutBack.transform(t);
    final exit = 1 - ((progress - 0.86) / 0.14).clamp(0.0, 1.0) * 0.14;
    return settle * exit;
  }

  /// Sayı ödül oturduktan sonra ayrı bir vuruşla girer.
  double get _numberScale {
    final t = ((progress - 0.26) / 0.20).clamp(0.0, 1.0);
    return t <= 0 ? 0 : Curves.easeOutBack.transform(t);
  }

  double get _textOpacity {
    final rise = ((progress - 0.16) / 0.14).clamp(0.0, 1.0);
    final fall = 1 - ((progress - 0.84) / 0.16).clamp(0.0, 1.0);
    return rise * fall;
  }

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();

    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: _backdrop.withValues(alpha: 0.86 * _curtain),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: _textOpacity.clamp(0.0, 1.0),
                  child: Text(
                    'Görev tamamlandı!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44 * scale,
                      fontWeight: AppTypography.heading,
                      fontFamily: AppTypography.displayFamily,
                      height: 1,
                    ),
                  ),
                ),
                SizedBox(height: _textGap * scale),
                // Çelenk ve konfeti biletin merkezine kilitlenir. Ekranın
                // ortasına göre hizalansalardı kolonun metinleri değiştikçe
                // kayarlardı; ödül nerede patlıyorsa ışık oradan çıkmalı.
                SizedBox(
                  width: 220 * scale,
                  height: 141 * scale,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      OverflowBox(
                        maxWidth: _burstBox * scale,
                        maxHeight: _burstBox * scale,
                        child: CustomPaint(
                          size: Size.square(_burstBox * scale),
                          painter: _LightRaysPainter(
                            progress: progress,
                            scale: scale,
                          ),
                        ),
                      ),
                      // Hüzmeler ödülün **arkasında** kalır; önüne geçen
                      // hiçbir katman yok. Konfeti kaldırıldı: sahneyi
                      // kalabalıklaştırıp dikkati ödülden koparıyordu.
                      Transform.scale(
                        scale: _rewardScale.clamp(0.0, 1.4),
                        child: _TicketWithShadow(scale: scale),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: _textGap * scale),
                Transform.scale(
                  scale: _numberScale.clamp(0.0, 1.4),
                  child: Text(
                    '+$rewardTickets bilet',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 54 * scale,
                      fontWeight: AppTypography.number,
                      fontFamily: AppTypography.family,
                      height: 1,
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),
                Opacity(
                  opacity: _textOpacity.clamp(0.0, 1.0),
                  child: Text(
                    questTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _muted,
                      fontSize: 26 * scale,
                      fontWeight: AppTypography.caption,
                      fontFamily: AppTypography.family,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bilet ve altındaki iki katmanlı gölgesi.
///
/// Gölge olmadan ödül ile çelenk aynı düzlemde duruyor, biletin nerede bitip
/// ışığın nerede başladığı okunmuyordu. Gölge bileti çelengin **üstüne
/// kaldırır**: çelenk üstüne düşen gölgeyi görürüz, ödül de havada durur.
///
/// İki katman kullanılır, gerçek gölgelerin çalıştığı gibi:
///   * **Yayılma** — biletten belirgin geniş, çok yumuşak. Çelengin beyaz
///     çekirdeğini biletin arkasında karartan perde budur. Tek katmanlı dar
///     bir gölge yalnızca biletin çevresinde ince bir hat bırakıyordu.
///   * **Temas** — bilet boyutunda, az yumuşak. Ödülün kenarını netleştirir;
///     yalnız yayılma kalsaydı bilet dumanın üstünde yüzer gibi olurdu.
///
/// İkisi de dikdörtgen kutu değil biletin kendi siluetidir: PNG'nin alfası
/// korunup rengi koyulaştırılır (`BlendMode.srcIn`). Kutu gölgesi biletin
/// çentikli kenarlarını yalanlardı.
class _TicketWithShadow extends StatelessWidget {
  const _TicketWithShadow({required this.scale});

  final double scale;

  static const _asset = 'assets/icons/ticket.png';
  static const _width = 220.0;

  /// Gölge rengi sayfa zemininden alınır: sahneye yeni bir siyah girmez,
  /// gölge yalnızca altındakini koyulaştırır.
  static const _shadowColor = Color(0xFF041227);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        _shadow(spread: 1.46, blur: 30, offsetY: 12, alpha: 0.58),
        _shadow(spread: 1.00, blur: 8, offsetY: 14, alpha: 0.55),
        Image.asset(
          _asset,
          width: _width * scale,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  Widget _shadow({
    required double spread,
    required double blur,
    required double offsetY,
    required double alpha,
  }) {
    return Transform.translate(
      offset: Offset(0, offsetY * scale),
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blur * scale,
          sigmaY: blur * scale,
        ),
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            _shadowColor.withValues(alpha: alpha),
            BlendMode.srcIn,
          ),
          child: Image.asset(
            _asset,
            width: _width * spread * scale,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// Ödülün arkasındaki ışın çelengi.
///
/// Tek parça, sürekli bir yıldız gövdesidir — ayrı ayrı ışınlar değil.
/// Işınlar tek tek çizildiğinde ne kadar yuvarlatılırsa yuvarlatılsın biletin
/// etrafına saçılmış çubuklar gibi okunuyordu; bütünlüğü veren şey kenarların
/// birbirine bağlı olması.
///
/// Renk kökten uca geçer. Geçiş bulanık gradyanla değil (§2.2 yasak), aynı
/// yıldızın küçülen kopyalarıyla kurulur: katmanlar iç içe geçtiği için her
/// diken boyunca merkezden uca beyaz → altın → turuncu bandı belirir.
/// Bilete değen katman beyaz olduğundan altın ödül ışığın içinde erimez.
///
/// Köşeler §2.5'in kendi reçetesiyle yuvarlatılır: aynı yol hem doldurulur
/// hem de aynı renkle `StrokeJoin.round` konturlanır.
/// Yalnızca **ölçüm** için: ışık dilimlerini bilet ve metin olmadan çizer.
///
/// Referans görselle aynı araçla (şerit sayısı / ışık oranı / kontrast /
/// kenar keskinliği) karşılaştırılabilsin diye açıldı. Ödülün ve metinlerin
/// parlaklığı ölçümü ele geçiriyordu.
@visibleForTesting
class LightRaysOnly extends StatelessWidget {
  const LightRaysOnly({super.key, required this.box, required this.progress});

  final double box;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(box),
      painter: _LightRaysPainter(progress: progress, scale: 1),
    );
  }
}

/// Ödülün arkasındaki **ışıltı**: yumuşak sıcak hâle ve çok sönük, ağır ağır
/// sürüklenen ışık dilimleri.
///
/// Referans videodan (kullanıcı sağladı) çıkarılan asıl ders **kavramsal**:
/// oradaki ışık bir **olay değil ortamdır.** Ödül öznedir; ışık yalnızca
/// arkadaki odayı ısıtır. Önceki iki deneme bunu kaçırdı — diken çelengi ve
/// ardından sert kenarlı dönen hüzmeler sahneyi ele geçirip ödülle yarıştı.
///
/// Referansın ölçülen değil **gözlenen** karakteri (kaynak bir telefonun
/// ekranı filme çektiği kayıt; moiré ve otomatik pozlama yüzünden piksel
/// ölçümü sahte kesinlik olurdu):
///
/// | Özellik | Karar |
/// |---|---|
/// | Kontrast | Fısıltı gibi — dilimler zor seçilir |
/// | Kenar | Yumuşak geçişli, üçgen değil |
/// | Yayılım | Merkezde güçlü, kenara doğru **söner** |
/// | Hareket | Dönme değil, ağır **sürüklenme** |
/// | Renk | Sıcak krem; merkez hâlesi baskın |
///
/// Teknik: dilimler üçgen çizilerek değil **sweep gradyanla** yapılır —
/// gradyan ara renkleri yumuşattığı için kenar kendiliğinden geçişli olur.
/// Sonra `BlendMode.dstIn` ile radyal bir maske uygulanır; ışık böylece
/// kenara doğru söner ve "fırıldak" değil "ışık" okunur.
class _LightRaysPainter extends CustomPainter {
  const _LightRaysPainter({required this.progress, required this.scale});

  final double progress;
  final double scale;

  /// Dilim sayısı. Referans görselde (Finch seri kartı) 360 derecede
  /// **10 şerit** sayıldı — kullanıcı saydı, göz kararı değil.
  /// 18 ve 12 denendi, ikisi de fazla dilimlenmiş göründü.
  static const _bandCount = 10;

  /// Işığın tamamen söndüğü yarıçap.
  ///
  /// Referansta ışık **özne yarıçapının ~2 katında** bitiyor (yıldız yarıçapı
  /// ≈175px, dilimler ≈368px'te yok oluyor). Bilet 220 birim geniş, yani
  /// yarıçapı 110 → erişim ≈ 270. Önceki 620 değeri efekti tüm ekrana
  /// yayıyordu; referansta efekt dairesel ve sınırlı.
  static const reach = 285.0;

  /// Merkez hâlesinin yarıçapı; o da özneye göre ölçekli.
  static const _glow = 215.0;

  /// Dilim rengi. Doymuş sıcak ton **kullanılamaz**: koyu lacivert üstünde
  /// yarı saydam sarı zeytine döner (bu tuzağa bu dosyada iki kez düşüldü).
  /// Krem beyaza yakın olduğu için kirletmeden ısıtır.
  static const _band = Color(0xFFFFF1DC);

  @override
  void paint(Canvas canvas, Size size) {
    // Işık ödülle birlikte yumuşakça açılır; çıkış alfa ile değil geri
    // çekilerek yapılır (alfa düşünce sıcak ton kirleniyor).
    final open = Curves.easeOutCubic.transform(
      ((progress - 0.02) / 0.32).clamp(0.0, 1.0),
    );
    final retract = 1 - ((progress - 0.82) / 0.18).clamp(0.0, 1.0);
    final grow = open * retract;
    if (grow <= 0.01) return;

    final center = size.center(Offset.zero);
    final r = reach * scale * grow;
    final glow = _glow * scale * grow;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Dilimler **keskin kenarlı üçgen** olarak çizilir. Sweep gradyan
    // denendi ve bırakıldı: ara renkleri harmanladığı için kenarlar
    // bulanıklaşıyordu. Referanstaki (Finch seri kartı) dilimler net —
    // videodaki yumuşaklık efektin tasarımı değil, kaydın kalitesiydi.
    canvas.saveLayer(Rect.fromCircle(center: Offset.zero, radius: r), Paint());

    const sector = 2 * math.pi / _bandCount;
    // Işık dilimi sektörün **%30'u**, boşluk %70. Ölçüldü: referansta
    // ışık payı %28–32 arasında (r=0.36/0.40/0.44). Önceki %50 değeri
    // şeritleri gereğinden kalın gösteriyordu.
    const halfWidth = sector * 0.15; // ışık %30, boşluk %70
    // Alfa, referansın **algısal parlaklık farkına** (CIE L*) göre çevrildi.
    //
    // Ham Weber kontrastını kopyalamak yanlış olurdu: referansın zemini açık
    // turuncu (L≈172), bizimki koyu lacivert (L≈16). Aynı yüzdelik fark koyu
    // zeminde görünmez olur. Referansta ΔL* ≈ 5.9; aynı ΔL*'i bizim zeminde
    // vermek için gereken alfa ≈ 0.03. Merkeze yakın biraz daha güçlü olsun
    // diye biraz yükseltilip radyal maskeyle söndürülüyor.
    final paint = Paint()..color = _band.withValues(alpha: 0.055);

    for (var i = 0; i < _bandCount; i++) {
      // Ağır sürüklenme: dönme hissi değil, ışığın canlı olduğu hissi.
      final a = i * sector + progress * 0.42;
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(math.cos(a - halfWidth) * r, math.sin(a - halfWidth) * r)
          ..lineTo(math.cos(a + halfWidth) * r, math.sin(a + halfWidth) * r)
          ..close(),
        paint,
      );
    }

    // Mesafe sönümü: dilimlerin **kenarları keskin kalır**, yalnızca uzakta
    // biterler. Bu olmadan hüzmeler ekranın kenarında kesilmiş görünüyordu.
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.radial(
          Offset.zero,
          r,
          [
            const Color(0xFFFFFFFF),
            const Color(0xFFFFFFFF).withValues(alpha: 0.62),
            const Color(0x00FFFFFF),
          ],
          // Referansta kontrast yarıçapla sürekli düşüyor (%18.6 → %10.8 →
          // %6.8). Geç başlayan bir sönüm yerine baştan itibaren azalıyor.
          [0.0, 0.34, 1.0],
        ),
    );
    canvas.restore();

    // Sıcak merkez hâlesi: ışığın kaynağı. Sahnenin baskın öğesi bu,
    // dilimler yalnız ona eşlik ediyor.
    canvas.drawCircle(
      Offset.zero,
      glow,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          glow,
          [
            const Color(0xFFFFC93A).withValues(alpha: 0.30 * grow),
            const Color(0xFFFFC93A).withValues(alpha: 0.10 * grow),
            const Color(0x00FFC93A),
          ],
          [0.0, 0.45, 1.0],
        ),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LightRaysPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.scale != scale;
  }
}
