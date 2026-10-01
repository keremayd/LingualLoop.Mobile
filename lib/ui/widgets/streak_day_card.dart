import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';
import 'package:lingualloop/ui/widgets/streak_week_strip.dart';

/// Güne özel seri kartı — referans tasarımın uygulaması.
///
/// **Tek düzen, değişen içerik.** Kart durumdan duruma şekil değiştirmiyor.
///
/// | Sabit (kartın iskeleti) | Sahneye göre değişen |
/// |---|---|
/// | Yükseklik, sol dolgu, dikey sıra | Sahne görseli (`sceneAsset`) |
/// | Alev, sayı, hafta şeridi | Kart rengi (`cardColor`, `sceneEdgeColor`) |
/// | Üst kenardaki cam parlaması | Mesaj metni (`message`) |
/// | Metin renkleri ve puntoları | Sahnenin çerçevelenmesi (`zoom`, `anchorY`, `fadeEnd`) |
///
/// **Hafta şeridi her kartta var.** Kart "kaç gün" diyor, şerit "hangi
/// günler" diyor — iki ayrı soru, ikisi de her durumda geçerli.
///
/// **Metin görsele gömülmüyor.** Sayı, mesaj ve şerit kodla çiziliyor ki canlı
/// veriye bağlansın; üretilen görsellerin içindeki metin ne düzeltilebilir ne
/// de güncellenebilir.
///
/// ## Yeni sahne görseli için kısıt
///
/// Şerit sahnenin **üstünde** duruyor ve kartın %53'üne kadar uzanıyor.
/// Yani kaynak görselin o bölgeye denk gelen kısmı **düz** olmalı; oraya
/// özne ya da doku düşerse şerit okunmaz olur. `ritmi_koru` sahnesinin sol
/// %40'ının düz yeşil olması tesadüf değil, kullanılabilmesinin sebebi.
///
/// ## Ölçüler referanstan **ölçüldü**, göz kararı değil
///
/// Referans kart mockup'ları çözülüp kart sınırları bulundu, her öğenin
/// piksel kutusu çıkarıldı ve kart genişliğine bölünerek tasarım birimine
/// çevrildi. Aşağıdaki sabitlerin tamamı o çevrimden geliyor.
class StreakDayCard extends StatelessWidget {
  const StreakDayCard({
    super.key,
    required this.scale,
    required this.days,
    required this.message,
    required this.sceneAsset,
    required this.sceneAspect,
    required this.cardColor,
    required this.sceneEdgeColor,
    required this.faceOpacity,
    required this.sceneZoom,
    required this.sceneAnchorY,
    required this.sceneFadeEnd,
    required this.week,
    required this.playedToday,
    this.onTap,
  });

  final double scale;

  final int days;
  final String message;

  /// Güne özel sahne görseli.
  final String sceneAsset;

  /// Kaynak görselin en/boy oranı. Sahneyle birlikte gelir; her görselde
  /// farklı olduğu için kodda sabitlenemez (sabitken ikinci sahne esneyecekti).
  final double sceneAspect;

  /// Kart zemininin **sol** rengi — metnin durduğu taraf.
  final Color cardColor;

  /// Zeminin **sağ** rengi. Sahnenin sönümünün ortasında gözün gördüğü tona
  /// eşitlenir; böylece görsel karta karışırken ton sıçraması olmaz.
  final Color sceneEdgeColor;

  /// Yüzün opaklığı — sahneye göre değişir, bkz. `StreakScene.faceOpacity`.
  final double faceOpacity;

  /// Sahnenin çizim ölçeği — sahneye göre değişir, bkz. `StreakScene.zoom`.
  final double sceneZoom;

  /// Dikey kırpma noktası — sahneye göre değişir, bkz. `StreakScene.anchorY`.
  final double sceneAnchorY;

  /// Sönümün tamamlandığı nokta — sahneye göre değişir,
  /// bkz. `StreakScene.fadeEnd`.
  final double sceneFadeEnd;

  /// Son 7 gün. Sahne kartında da gösteriliyor: kart "kaç gün" diyor, şerit
  /// "hangi günler" diyor.
  final List<StreakDay> week;

  /// Bugün oynandı mı. Alevin sönük çizilip çizilmeyeceğini belirliyor.
  final bool playedToday;

  final VoidCallback? onTap;

  // --- referanstan ölçülen geometri ---------------------------------------

  static const _cardWidth = 670.0;

  /// **Bütün sahne kartları aynı yükseklikte.** Kart durumdan duruma yer
  /// değiştirmiyor; ana ekranda sabit bir blok.
  ///
  /// Referans mockup 373 birim (oran 1.795) ama o bir pazarlama render'ı:
  /// içeriğin üstünde 79, altında 86 birim boşluk var. Ana ekranda o boşluk
  /// ölü alan. Bu yüzden referansın **puntoları ve dikey sırası** korunup
  /// boşlukları kısıldı — tersi (her şeyi 236/373 ile küçültmek) mesajı
  /// 16 birime düşürüyordu, cihazda 9pt.
  static const _cardHeight = 236.0;

  /// Sol dolgu. Referansta 35.5 ölçüldü; kullanıcı sol bloğu iki tur daha
  /// sola aldırdı (46 → 36 → 26) çünkü sahnenin öznesine fazla yaklaşıyordu.
  /// Kartın köşe yarıçapı 40 ama alev y 38'de başlıyor, orada yay neredeyse
  /// kapanmış — 26 birim kesilmiyor.
  static const _padLeft = 26.0;

  static const _flameTop = 38.0;
  static const _flameSize = 40.0;

  /// Referansta metin alevden hemen sonra başlıyor; bizim alev çizimi
  /// kutusunu referanstaki emojiden daha dolu doldurduğu için birkaç birim
  /// daha pay bırakıldı (`_padLeft + _flameSize + 12`).
  static const _numberLeft = 78.0;
  static const _numberSize = 46.0;

  static const _messageTop = 92.0;
  static const _messageSize = 24.0;

  /// Metnin sağ sınırı.
  static const _contentRight = 409.0;

  // Şerit — referans karttan (253 birim yüksek) 236'ya çevrildi, çarpan 0.933.
  static const _labelTop = 148.0;
  static const _labelSize = 18.0;
  static const _dotTop = 174.0;
  static const _dotSize = 34.0;

  /// Daire merkezleri arası adım. Referansta 48.3 birim; 46'ya çekildi ki
  /// şerit `_padLeft`'ten başlayıp 348'de (kartın **%52**'si) bitsin ve
  /// sahnenin öznesine yaklaşmasın. Bu değer yukarıdaki "yeni sahne
  /// görseli" kısıtının sayısal karşılığı.
  static const _dotPitch = 46.0;

  /// Üst kenardaki cam parlaması. **Yalnız üstte**: ölçümde sol ve alt
  /// kenarlarda yüzden farklı bir ton yok, üstte 3 birimlik `#40527E` bandı
  /// var. Işık yukarıdan geliyor; dört kenarı çevreleyen bir çerçeve çizmek
  /// referansı taklit etmez, başka bir şey yapar.
  static const _rimColor = Color(0xFF40527E);

  /// Sönüm rampasının uzunluğu (kart oranı). Sabit: geçişin hızı her kartta
  /// aynı okunmalı. Kısa bir rampa görseli "kesilmiş" gösteriyor.
  static const _fadeRamp = 0.24;

  /// Sahne kutusunun sol kenarı — rampa buradan `sceneFadeEnd`'e uzanıyor.
  ///
  /// Kutu şart. Yoksa sahne genişliğini yükseklikten alıyor ve kartın çok
  /// solundan başlıyor, metnin altına girip onu okunmaz yapıyordu. Kutu
  /// soldan kırpıyor; kırpma sınırında alfa zaten sıfır olduğu için kesim
  /// görünmüyor.
  double get _sceneBoxLeft => sceneFadeEnd - _fadeRamp;

  double get _sceneHeight => _cardHeight * sceneZoom;
  double get _sceneWidth => _sceneHeight * sceneAspect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _cardWidth * scale,
        height: _cardHeight * scale,
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(AppShapeStyle.cardRadius(40 * scale)),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      // Sol taraf **saydam**: altındaki sayfa zemini mavinin
                      // içinden geçiyor. Düz opak yüz kartı sayfadan kopuk
                      // bir levha gibi gösteriyordu.
                      colors: [
                        cardColor.withValues(alpha: faceOpacity),
                        sceneEdgeColor,
                      ],
                      // Rampa sahnenin başladığı noktada bitmiyor, altına
                      // doğru devam ediyor: tam orada bitirilince eğrinin
                      // kırıldığı yer ince bir dikey çizgi (Mach bandı) gibi
                      // okunuyordu.
                      stops: [0.05, sceneFadeEnd + 0.12],
                    ),
                  ),
                ),
              ),

              _scene(),

              // Cam parlaması sahnenin de üstünde: kenar, içeriğin değil
              // kartın bir özelliği.
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _TopRimPainter(
                      color: _rimColor,
                      radius: AppShapeStyle.cardRadius(40 * scale),
                      strokeWidth: AppShapeStyle.outline(3 * scale),
                    ),
                  ),
                ),
              ),

              _flame(),
              _number(),
              _message(),
              _strip(),
            ],
          ),
        ),
      ),
    );
  }

  /// Sahne sağda, sol kenarı **kendi alfasıyla** sönüyor.
  ///
  /// Önce sahnenin üstüne kart renginde bir geçiş katmanı konmuştu; iki
  /// katmanın rengini elle eşitlemek gerektiği için sınırda ince bir çizgi
  /// kalıyordu. `dstIn` maskesi görselin kendisini şeffaflaştırıyor, yani
  /// arkasında ne varsa ona karışıyor — eşitlenecek renk kalmıyor.
  Widget _scene() {
    final boxWidth = (1 - _sceneBoxLeft) * _cardWidth;

    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: boxWidth * scale,
        height: _cardHeight * scale,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [Color(0x00FFFFFF), Color(0xFFFFFFFF)],
            stops: [
              0,
              _fadeRamp / (1 - _sceneBoxLeft),
            ],
          ).createShader(rect),
          // Görsel kutudan geniş; taşan sol taraf kırpılıyor. Orada alfa
          // sıfır olduğu için kesim görünmüyor.
          child: ClipRect(
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              alignment: Alignment(1, sceneAnchorY),
              child: SizedBox(
                width: _sceneWidth * scale,
                height: _sceneHeight * scale,
                child: Image.asset(sceneAsset, fit: BoxFit.fill),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Alev **rengini bırakır** ve kart renginin açılmış bir tonuna döner:
  /// (a) seri hiç yokken, (b) **bugün henüz oynanmamışken**.
  ///
  /// İkisi tek bir şeyi söylüyor — bugün seride sayılmıyor. §5'teki kural
  /// zaten bu: "alev soluk = uyarı", göz metni okumadan önce fark ediyor.
  /// `HomeStreakStrip` de aynı sinyali kullanıyor; iki bileşen aynı dili
  /// konuşmalı.
  ///
  /// Referans "0 Gün" kartında ölçüldü: `#D9B6FA`, mor yüzün açılmışı.
  ///
  /// **Gri kullanılamaz**: bu uygulamada gri *kilitli* demek (§2.6
  /// `lockedPalette`) ve serisi olmayan kullanıcı kilitli değil. Beyaz
  /// siluet her kart renginin üstünde o rengin açılmışını veriyor, yani tek
  /// reçete bütün sahnelerde çalışıyor.
  Widget _flame() {
    Widget flame = QuestIcon(
      questKey: 'streak_three',
      size: _flameSize * scale,
    );
    if (days == 0 || !playedToday) {
      flame = Opacity(
        opacity: 0.55,
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          child: flame,
        ),
      );
    }
    return Positioned(
      left: _padLeft * scale,
      top: _flameTop * scale,
      child: flame,
    );
  }

  Widget _number() => Positioned(
        left: _numberLeft * scale,
        // Referansta ölçülen 79 **büyük harfin tepesi**; metin kutusu
        // ondan biraz yukarıda başlıyor.
        top: (_flameTop - 6) * scale,
        child: Text(
          days == 0 ? '0 Gün' : '$days. Gün',
          style: TextStyle(
            color: Colors.white,
            fontFamily: AppTypography.displayFamily,
            fontSize: _numberSize * scale,
            fontWeight: AppTypography.heading,
            height: 1,
          ),
        ),
      );

  Widget _strip() => Positioned(
        left: _padLeft * scale,
        top: _labelTop * scale,
        width: _dotPitch * 7 * scale,
        child: _WeekRow(scale: scale, week: week, checkColor: cardColor),
      );

  Widget _message() => Positioned(
        left: _padLeft * scale,
        top: (_messageTop - 4) * scale,
        width: (_contentRight - _padLeft) * scale,
        child: Text(
          message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            // Paletin kırık beyazı (§2.2). Bir dönem gece kartından ölçülen
            // sönük lavanta (`#7B84AB`) kullanılıyordu; o ton yalnız koyu
            // lacivert bir yüzde işe yarıyor, yeşil sahnede mesaj
            // **görünmez** oluyordu. Referans yeşil kartta da ölçülen değer
            // beyaz (`#F1FAF7`): mesajın rengi sahneye göre değil, kartın
            // metin katmanına ait.
            color: const Color(0xFFE9EEF5),
            fontFamily: AppTypography.family,
            fontSize: _messageSize * scale,
            fontWeight: AppTypography.body,
            height: 1,
          ),
        ),
      );
}

/// Kartın **üst** kenarındaki cam parlaması.
///
/// Yuvarlatılmış dikdörtgen konturu, dikey bir gradyanla boyanmış fırçayla
/// çizilir: tepede `color`, kartın üçte birinde şeffaf. Böylece parlama üst
/// kenarda ve üst köşelerde görünüp yanlara doğru **kaybolur** — düz bir
/// çerçeve gibi kesilmez. §2.3'teki `_NoTopBorderPainter`'ın tersi.
///
/// Referansta ölçüldü: sol ve alt kenarlarda yüzden farklı bir ton yok,
/// üstte 3 birimlik `#40527E` bandı var. Işık yukarıdan geliyor; dört kenarı
/// çevreleyen bir çerçeve referansı taklit etmez, başka bir şey yapar.
class _TopRimPainter extends CustomPainter {
  const _TopRimPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(strokeWidth / 2),
        Radius.circular(radius),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0, 0.34],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _TopRimPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}

/// Referanstaki şerit: üstte gün adları, altta daireler.
///
/// Kart "kaç gün" diyor, şerit "hangi günler" diyor — ikisi farklı soruyu
/// cevaplıyor. Dolu gün beyaz disk + kart renginde tik; boş gün yalnızca
/// soluk bir halka, tik yok.
class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.scale,
    required this.week,
    required this.checkColor,
  });

  final double scale;

  /// Son 7 gün, **dönen** sırada (dün, evvelsi gün…). Şerit bunu Pazartesi'den
  /// başlayan sabit sıraya çeviriyor.
  final List<StreakDay> week;

  /// Tikin rengi = kartın yüzü. Referansta tik zeminin yeşiliyle aynı;
  /// beyaz diskin içinden kart "görünüyor" gibi okunuyor.
  final Color checkColor;

  /// Pazartesi'den Pazar'a. Tek harf kullanılamaz: Pazartesi, Perşembe ve
  /// Pazar aynı harfle başlıyor (§4.4). Referans set İngilizce (`Mo Tu We`)
  /// ama uygulamanın dili Türkçe.
  static const _labels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  /// Bu haftanın Pazartesi–Pazar'ı. Gelen veri **son 7 gün** olduğu için
  /// hafta sınırını aşıyor: bugün Perşembe ise listede geçen haftanın Cuma,
  /// Cumartesi ve Pazar'ı var.
  ///
  /// Bu yüzden sıralama gün adına göre yapılamaz — geçen haftanın Cuma'sı bu
  /// haftanın Cuma'sıymış gibi **dolu** görünürdü. Eşleştirme **tarihe** göre
  /// yapılıyor; bu haftanın henüz gelmemiş günleri `null` kalıyor ve boş
  /// çiziliyor.
  List<StreakDay?> get _mondayFirst {
    if (week.isEmpty) return List<StreakDay?>.filled(7, null);

    final anchor = week
        .firstWhere(
          (day) => day.isToday,
          orElse: () => week.last,
        )
        .date;
    final monday = DateTime(anchor.year, anchor.month, anchor.day)
        .subtract(Duration(days: anchor.weekday - 1));

    return [
      for (var i = 0; i < 7; i++) _dayOn(monday.add(Duration(days: i))),
    ];
  }

  StreakDay? _dayOn(DateTime date) {
    for (final day in week) {
      if (day.date.year == date.year &&
          day.date.month == date.month &&
          day.date.day == date.day) {
        return day;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dot = StreakDayCard._dotSize * scale;
    final pitch = StreakDayCard._dotPitch * scale;
    final gap = (StreakDayCard._dotTop -
            StreakDayCard._labelTop -
            StreakDayCard._labelSize) *
        scale;

    final days = _mondayFirst;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              SizedBox(
                width: pitch,
                child: Text(
                  _labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: days[i]?.isToday ?? false ? 1 : 0.8,
                    ),
                    fontFamily: AppTypography.family,
                    fontSize: StreakDayCard._labelSize * scale,
                    fontWeight: days[i]?.isToday ?? false
                        ? AppTypography.label
                        : AppTypography.caption,
                    height: 1,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: gap),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              SizedBox(
                width: pitch,
                child: Center(
                  child: _Dot(size: dot, day: days[i], checkColor: checkColor),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.size,
    required this.day,
    required this.checkColor,
  });

  final double size;

  /// `null` = bu haftanın henüz gelmemiş günü.
  final StreakDay? day;
  final Color checkColor;

  @override
  Widget build(BuildContext context) {
    // Korunan gün seride sayılır ama normal oynanmış gün değildir. Ana kartın
    // eski çizimi `active || frozen` diyerek ikisini de beyaz tik yapıyordu;
    // buzlu işaret bu ayrımı görünür tutar.
    if (day?.frozen ?? false) {
      return StreakDayMark(
        size: size,
        active: false,
        frozen: true,
      );
    }

    final active = day?.active ?? false;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.22),
      ),
      alignment: Alignment.center,
      child: active
          ? Icon(Icons.check_rounded, size: size * 0.64, color: checkColor)
          : null,
    );
  }
}
