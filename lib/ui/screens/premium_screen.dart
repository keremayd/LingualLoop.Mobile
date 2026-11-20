import 'package:flutter/material.dart';
import 'package:stelinda/Utils/AppNotifier.dart';
import 'package:stelinda/ui/app_typography.dart';
import 'package:stelinda/ui/screens/legal_document_screen.dart';
import 'package:stelinda/ui/widgets/Buttons/app_button_style.dart';
import 'package:stelinda/ui/widgets/Buttons/app_icon_control_button.dart';
import 'package:stelinda/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:stelinda/ui/widgets/karty_control_glyphs.dart';
import 'package:stelinda/ui/widgets/premium_ticket_mark.dart';

/// Kullanıcı premium ekranına nereden geldi. Tablodaki ilk premium satırı
/// ona göre sıralanır: bileti biten önce sınırsız bileti, serisi tehlikede
/// olan önce korumayı görür.
enum PremiumEntry { tickets, streak }

enum PremiumPlan { yearly, monthly }

/// Akışın adımı. Duolingo Super'in Türkiye ekranlarındaki gibi iki ekran:
/// önce Ücretsiz ile Premium'un farkı, sonra plan seçimi ve deneme.
enum PremiumStep { benefits, plans }

/// Mağazanın verdiği, yerelleştirilmiş fiyatlar. Ekran fiyat hesaplamaz.
class PremiumOffer {
  const PremiumOffer({
    required this.yearlyPrice,
    required this.yearlyPerMonth,
    required this.monthlyPrice,
    required this.yearlySavingPercent,
    this.trialDays = 7,
  });

  final String yearlyPrice;
  final String yearlyPerMonth;
  final String monthlyPrice;
  final int yearlySavingPercent;
  final int trialDays;
}

const _bg = Color(0xFF041227);
const _muted = Color(0xFF8FA0B5);
const _accent = Color(0xFF1CB1F5);
const _accentDepth = Color(0xFF1B84B5);
const _green = Color(0xFF93D334);
// Bulutların açık zemini: Satürn ligi açığından (`BFB3FF`) türedi.
const _ground = Color(0xFFF3F1FF);
// Satürn ligi moru: başlık vurgusu ve Premium onayı.
const _violet = Color(0xFF4536A4);

/// Premium akışı. İlk adım premium maskot ve karşılaştırma tablosu; tablo
/// öğrenme içeriğinin iki tarafta da aynı olduğunu söyler. İkinci adım iki
/// plan (yıllık seçili), mağaza iptal cümlesi, düğme ve yenilenme metni.
/// Adımlar aynı rotada; geri hareketi plan adımında tabloya döner.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({
    super.key,
    required this.offer,
    required this.onPurchase,
    required this.onRestore,
    required this.onTerms,
    required this.onPrivacy,
    this.entry = PremiumEntry.tickets,
    this.initialPlan = PremiumPlan.yearly,
    this.initialStep = PremiumStep.benefits,
    this.onClose,
  });

  final PremiumOffer offer;
  final ValueChanged<PremiumPlan> onPurchase;
  final VoidCallback onRestore;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;
  final PremiumEntry entry;
  final PremiumPlan initialPlan;
  final PremiumStep initialStep;
  final VoidCallback? onClose;

  /// Premium akışını tam ekran açar: alt menüdeki ∞ bilet ve bilet bitti
  /// penceresi. Alt menü ekranın altında kalır; çarpı kullanıcıyı kaldığı
  /// ekrana döndürür. Seri koruması girişi (`PremiumEntry.streak`) sonra.
  /// Mağaza bağlantısı (Apple Developer onayı, StoreKit) gelene kadar fiyatlar
  /// yer tutucu, satın alma ve geri yükleme yalnız haber verir.
  static Future<void> open(
    BuildContext context, {
    PremiumEntry entry = PremiumEntry.tickets,
  }) {
    void soon() => AppNotifier.showMessage(
          'Satın alma yakında açılacak.',
          color: const Color(0xFF163258),
        );
    return Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => PremiumScreen(
        offer: placeholderOffer,
        entry: entry,
        onPurchase: (_) => soon(),
        onRestore: soon,
        onTerms: () => LegalDocumentScreen.open(context, LegalDocument.terms),
        onPrivacy: () =>
            LegalDocumentScreen.open(context, LegalDocument.privacy),
      ),
    ));
  }

  /// Yer tutucu fiyatlar. Gerçekleri App Store Connect'ten, mağazanın
  /// yerelleştirdiği biçimde ("₺1.209,99") gelecek.
  static const placeholderOffer = PremiumOffer(
    yearlyPrice: '899,99 TL',
    yearlyPerMonth: '75 TL',
    monthlyPrice: '149,99 TL',
    yearlySavingPercent: 50,
  );

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  late PremiumPlan _plan = widget.initialPlan;
  late PremiumStep _step = widget.initialStep;
  late final PageController _pages = PageController(initialPage: _step.index);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(PremiumStep step) {
    if (step == _step) return;
    setState(() => _step = step);
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(step.index);
    } else {
      _pages.animateToPage(
        step.index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 750;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: _step == PremiumStep.benefits,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(PremiumStep.benefits);
      },
      child: Scaffold(
        backgroundColor: _bg,
        // Adımlar düğmeyle geçer; parmakla kaydırılınca plan adımına
        // tablonun düğmesine basmadan varılırdı.
        body: PageView(
          controller: _pages,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // İki adımın gökyüzü de durum çubuğunun arkasından başlar.
            PremiumBenefitsView(
              ctaText: 'DEVAM ET',
              entry: widget.entry,
              onContinue: () => _goTo(PremiumStep.plans),
              onClose: widget.onClose ?? () => Navigator.of(context).maybePop(),
            ),
            _plansPage(s, bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _plansPage(double s, double bottomInset) {
    final offer = widget.offer;
    final width = MediaQuery.sizeOf(context).width;
    final top = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: _ground,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        // Kartlar bulutlarla panel arasında ortalanır.
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tablo adımının gökyüzü ve bulutları, maskotsuz: iki
                          // adım aynı sahnede.
                          Container(
                            width: width,
                            color: _bg,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _StarsPainter(scale: s, top: top),
                                  ),
                                ),
                                Column(
                                  children: [
                                    SizedBox(height: top + 130 * s),
                                    Text(
                                      'Planını seç',
                                      style: _title(s, Colors.white),
                                    ),
                                    Text(
                                      '${offer.trialDays} gün ücretsiz',
                                      style: _title(s, _green),
                                    ),
                                    SizedBox(height: 10 * s),
                                    CustomPaint(
                                      size: Size(width, 300 * s),
                                      painter: _CloudLayersPainter(
                                        [
                                          ..._CloudLayer.back,
                                          ..._CloudLayer.front
                                        ],
                                        scale: s,
                                        bleed: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            // Üstteki pay rozetin kartın üstüne taşan yarısı için.
                            padding: EdgeInsets.fromLTRB(
                                40 * s, 30 * s, 40 * s, 24 * s),
                            child: Column(
                              children: [
                                _PlanCard(
                                  scale: s,
                                  title: 'Yıllık',
                                  detail:
                                      'Ayda ${offer.yearlyPerMonth} · %${offer.yearlySavingPercent} tasarruf',
                                  price: offer.yearlyPrice,
                                  period: '/ yıl',
                                  // "En çok tercih edilen" yayından önce
                                  // doğrulanamaz; öneri bir iddia değil.
                                  badge: 'ÖNERİLEN',
                                  selected: _plan == PremiumPlan.yearly,
                                  onTap: () => setState(
                                      () => _plan = PremiumPlan.yearly),
                                ),
                                SizedBox(height: 28 * s),
                                _PlanCard(
                                  scale: s,
                                  title: 'Aylık',
                                  detail: 'Her ay yenilenir',
                                  price: offer.monthlyPrice,
                                  period: '/ ay',
                                  selected: _plan == PremiumPlan.monthly,
                                  onTap: () => setState(
                                      () => _plan = PremiumPlan.monthly),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: top + 16 * s,
                  left: 40 * s,
                  child: AppIconControlButton(
                    scale: s,
                    label: 'Geri',
                    onPressed: () => _goTo(PremiumStep.benefits),
                    child: KartyControlMark(
                      glyph: KartyControlGlyph.back,
                      size: 50.25 * s,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _plansPanel(s, bottomInset),
        ],
      ),
    );
  }

  /// Plan adımının paneli: mağazanın iptal cümlesi, düğme, yenilenme metni
  /// ve bağlantılar. Yenilenen tam fiyat ile "otomatik olarak yenilenir" burada
  /// (App Store 3.1.2).
  Widget _plansPanel(double s, double bottomInset) {
    final offer = widget.offer;
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    final store = ios ? 'App Store' : 'Google Play';
    // Fiyat ile para birimi satır sonunda ayrılmasın.
    String price(String value) => value.replaceAll(' ', '\u00A0');
    final renewal = _plan == PremiumPlan.yearly
        ? 'yıllık ${price(offer.yearlyPrice)}'
        : 'aylık ${price(offer.monthlyPrice)}';
    final ink = _bg.withValues(alpha: 0.6);
    final small = _body(s, size: 21).copyWith(color: ink);
    final link = TextStyle(
      color: ink,
      fontFamily: AppTypography.family,
      fontSize: 21 * s,
      fontWeight: AppTypography.label,
    );
    Widget linkButton(String text, VoidCallback onTap) => Semantics(
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12 * s),
              child: Text(text, style: link),
            ),
          ),
        );
    final dot = Padding(
      padding: EdgeInsets.symmetric(horizontal: 12 * s),
      child: Text('·', style: link),
    );

    return _panel(
      s,
      bottom: 8 * s + bottomInset,
      color: _ground,
      children: [
        Text(
          // Açıklama ve yasal metin edilgen: "edersen, etmezsen" gibi
          // senli şart kipleri ucuz duruyordu (kullanıcı).
          '$store üzerinden her zaman iptal edilebilir.',
          textAlign: TextAlign.center,
          style: _body(s, size: 24).copyWith(color: ink),
        ),
        SizedBox(height: 18 * s),
        _primaryButton(
          s,
          text: '${offer.trialDays} GÜN ÜCRETSİZ DENE',
          onPressed: () => widget.onPurchase(_plan),
        ),
        SizedBox(height: 16 * s),
        Text.rich(
          TextSpan(
            style: small,
            children: [
              TextSpan(
                // Abonelik adı satın alma adımında görünür kalır
                // (App Store 3.1.2): başlıkta artık ürün adı yok.
                text: 'Stelinda Premium: ${offer.trialDays} gün ücretsiz, '
                    'ardından $renewal. Abonelik, deneme süresi ya da dönem '
                    'bitmeden en az 24 saat önce iptal edilmezse ',
              ),
              TextSpan(
                text: 'otomatik olarak yenilenir',
                style: small.copyWith(
                  color: _bg,
                  fontWeight: AppTypography.label,
                ),
              ),
              const TextSpan(
                text: '. İptal edildiğinde Premium, dönemin sonuna kadar '
                    'kullanılabilir.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4 * s),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            linkButton('Geri yükle', widget.onRestore),
            dot,
            linkButton('Kullanım koşulları', widget.onTerms),
            dot,
            linkButton('Gizlilik politikası', widget.onPrivacy),
          ],
        ),
      ],
    );
  }
}

/// Tablo adımı: gece sahnesi, başlık, Ücretsiz/Premium tablosu ve düğme.
/// Duolingo'nun "planları karşılaştır" sayfasının bizdeki karşılığı: tek ürün
/// olduğu için karşılaştırma bu tablo.
class PremiumBenefitsView extends StatelessWidget {
  const PremiumBenefitsView({
    super.key,
    required this.ctaText,
    required this.onContinue,
    this.entry = PremiumEntry.tickets,
    this.onClose,
  });

  final String ctaText;
  final VoidCallback onContinue;
  final PremiumEntry entry;

  /// Verilirse sol üstte kapatma düğmesi durur.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 750;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const tickets = (label: 'Sınırsız bilet', free: false);
    const freeze = (label: 'Haftada 2 seri koruması', free: false);
    final rows = [
      // Duolingo da tabloyu öğrenme içeriğiyle açıyor: ücretsiz kullanıcı
      // dersi kaybetmediğini ilk satırda görür.
      (label: 'Tüm öğrenme içeriği', free: true),
      if (entry == PremiumEntry.streak) ...[
        freeze,
        tickets
      ] else ...[
        tickets,
        freeze,
      ],
    ];

    final width = MediaQuery.sizeOf(context).width;
    return ColoredBox(
      color: _ground,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    // Açık zemin altta biter; esneyen kaydırma altından
                    // lacivert sayfayı gösterirdi.
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        // Artan yer başlık bloğunun üstüne ve altına eşit
                        // dağılır.
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _scene(context, s, width),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40 * s),
                            child: Column(
                              children: [
                                // Ürün adı değil vaat: sahneyle aynı cümle
                                // (kullanıcı: teşvik edici olmalı). Vurgu,
                                // bulutların ve Premium onayının morunda.
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(
                                          text: 'Almanca seviyeni\n'),
                                      TextSpan(
                                        text: 'bulutların üstüne',
                                        style: _title(s, _violet),
                                      ),
                                      const TextSpan(text: ' çıkar'),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  style: _title(s, _bg),
                                ),
                                SizedBox(height: 8 * s),
                                Text(
                                  'Sınırsız bilet ve seri korumasıyla kesintisiz öğren.',
                                  textAlign: TextAlign.center,
                                  style: _body(s, size: 27).copyWith(
                                      color: _bg.withValues(alpha: 0.6)),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: 28 * s, bottom: 24 * s),
                                  child: _ComparisonTable(scale: s, rows: rows),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                ),
                // Kapatma kaymaz, hep gökyüzünün üstünde durur. Sekmede yok.
                if (onClose != null)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 16 * s,
                    left: 40 * s,
                    child: AppIconControlButton(
                      scale: s,
                      label: 'Kapat',
                      onPressed: onClose!,
                      child: KartyControlMark(
                        glyph: KartyControlGlyph.cross,
                        size: 50.25 * s,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _panel(
            s,
            bottom: 24 * s + bottomInset,
            color: _ground,
            children: [
              _primaryButton(s, text: ctaText, onPressed: onContinue),
            ],
          ),
        ],
      ),
    );
  }

  /// Tablo adımının üst yarısı: gece gökyüzü, yıldızlar ve bulut denizi
  /// kodla çiziliyor, görsel yalnız maskot (kullanıcı kararı: "görsel kısım
  /// sadece maskot olmalı, geri kalan ekranda çizilmeli"). Maskot bulut
  /// denizinden yukarı fırlıyor: arka iki katman ve kalkış izi arkasında,
  /// ön iki katman bacaklarının önünde. Ekranın tepesinden (durum
  /// çubuğunun arkasından) başlar; en öndeki katman sayfanın rengi, başlık
  /// ve tablo onun üstünde.
  Widget _scene(BuildContext context, double s, double width) {
    final top = MediaQuery.paddingOf(context).top;
    final height = top + 680 * s;
    final clouds = 320 * s;
    Widget layers(List<_CloudLayer> list) => Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: clouds,
          child: CustomPaint(
            painter: _CloudLayersPainter(
              list,
              scale: s,
              bleed: identical(list, _CloudLayer.front) ? 20 : 0,
            ),
          ),
        );
    return Container(
      width: width,
      height: height,
      color: _bg,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _StarsPainter(scale: s, top: top)),
          ),
          layers(_CloudLayer.back),
          Positioned(
            left: 0,
            right: 0,
            bottom: 110 * s,
            child: Center(
              child: Image.asset(
                'assets/icons/mascot_premium.png',
                height: 440 * s,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          layers(_CloudLayer.front),
        ],
      ),
    );
  }
}

Widget _panel(
  double s, {
  required double bottom,
  required List<Widget> children,
  Color color = _bg,
}) {
  return Container(
    decoration: BoxDecoration(
      color: color,
      // Açık zeminde ayraç yok: bulut zemini düğmeye kadar kesintisiz.
      border: color == _bg
          ? const Border(top: BorderSide(color: Color(0xFF0B2143), width: 2))
          : null,
    ),
    padding: EdgeInsets.fromLTRB(40 * s, 24 * s, 40 * s, bottom),
    child: Column(mainAxisSize: MainAxisSize.min, children: children),
  );
}

Widget _primaryButton(
  double s, {
  required String text,
  required VoidCallback onPressed,
}) {
  return DepthPressableButton(
    text: text,
    width: 670 * s,
    height: 96 * s,
    radius: 26 * s,
    shadowOffset: 10 * s,
    backgroundColor: _accent,
    shadowColor: _accentDepth,
    fontSize: 28 * s,
    onPressed: onPressed,
  );
}

TextStyle _title(double s, Color color) => TextStyle(
      color: color,
      fontFamily: AppTypography.displayFamily,
      fontSize: 54 * s,
      fontWeight: AppTypography.heading,
      height: 1.1,
    );

TextStyle _body(double s, {required double size}) => TextStyle(
      color: _muted,
      fontFamily: AppTypography.family,
      fontSize: size * s,
      fontWeight: AppTypography.body,
      height: 1.35,
    );

/// Ücretsiz ile Premium'un karşılaştırması, bulutların açık zemininde.
/// Premium sütunu tek parça beyaz; başlığında premium bilet durur. İşaretler
/// kontrol glifi: Premium'da Satürn moru onay, ücretsizde sönük onay ya da
/// kısa çizgi. Gri kullanılmaz, gri bu uygulamada kilitli demek.
class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.scale, required this.rows});

  final double scale;
  final List<({String label, bool free})> rows;

  // Açık zeminde yazı lacivert; sönük öğeler aynı lacivertin saydamı.
  static const _ink = Color(0xFF041227);
  static final _muted = _ink.withValues(alpha: 0.45);
  // Premium onayı Satürn ligi morunda, bulutlarla aynı aile.
  static const _premiumCheck = Color(0xFF4536A4);
  // İki sütun eşit: açık zeminde beyaz dolgu Premium sütununu zaten öne
  // çıkarıyor; geniş olunca "ÜCRETSİZ" yazısı ona değecek kadar sıkıştı.
  static const _freeWidth = 140.0;
  static const _premiumWidth = 140.0;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    Widget check(Color color) => SizedBox.square(
          dimension: 40 * s,
          child: KartyControlMark(
            glyph: KartyControlGlyph.check,
            size: 40 * s,
            color: color,
          ),
        );
    final dash = Container(
      width: 30 * s,
      height: 6 * s,
      decoration: BoxDecoration(
        color: _ink.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(3 * s),
      ),
    );

    return Stack(
      children: [
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: _premiumWidth * s,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30 * s),
            ),
          ),
        ),
        Column(
          children: [
            SizedBox(
              height: 96 * s,
              child: Row(
                children: [
                  const Spacer(),
                  SizedBox(
                    width: _freeWidth * s,
                    child: Text(
                      'ÜCRETSİZ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
                        fontFamily: AppTypography.family,
                        fontSize: 21 * s,
                        fontWeight: AppTypography.number,
                        letterSpacing: 0.8 * s,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _premiumWidth * s,
                    child: Center(child: PremiumTicketMark(width: 100 * s)),
                  ),
                ],
              ),
            ),
            for (final row in rows)
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: 92 * s),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14 * s),
                        child: Text(
                          row.label,
                          style: TextStyle(
                            color: _ink,
                            fontFamily: AppTypography.family,
                            fontSize: 30 * s,
                            fontWeight: AppTypography.label,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: _freeWidth * s,
                      child: Center(child: row.free ? check(_muted) : dash),
                    ),
                    SizedBox(
                      width: _premiumWidth * s,
                      child: Center(child: check(_premiumCheck)),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 14 * s),
          ],
        ),
      ],
    );
  }
}

/// Plan seçimi. Basılabilir yüz (ikincil düğmenin malzemesi); seçili olanın
/// kenarı accent mavi, solundaki kutuda onay işareti. Yenilenen tam fiyat
/// sağda en belirgin yazı (App Store 3.1.2).
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.scale,
    required this.title,
    required this.detail,
    required this.price,
    required this.period,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final double scale;
  final String title;
  final String detail;
  final String price;
  final String period;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  static const _accent = Color(0xFF1CB1F5);
  static const _ink = Color(0xFF041227);
  static final _muted = _ink.withValues(alpha: 0.55);

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final width = 670 * s;
    final height = 128 * s;
    final depth = 10 * s;
    // Kenar çizgisi düğme yüzüyle aynı köşeyi almalı; ortak geometriden okunur.
    final geometry = AppButtonStyle.resolve(
      width: width,
      totalHeight: height + depth,
      legacyRadius: 26 * s,
      legacyDepth: depth,
    );

    return Semantics(
      selected: selected,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DepthPressableButton(
            width: width,
            height: height,
            radius: 26 * s,
            shadowOffset: depth,
            // Açık zeminde beyaz yüz, taban bulutların lavantası.
            backgroundColor: Colors.white,
            shadowColor: const Color(0xFFBFB3FF),
            fontSize: 28 * s,
            onPressed: onTap,
            child: Container(
              width: width,
              height: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 28 * s),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(geometry.radius),
                border: Border.all(
                  color: selected ? _accent : Colors.transparent,
                  width: 4 * s,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42 * s,
                    height: 42 * s,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? _accent : const Color(0xFFE9E4FF),
                      borderRadius: BorderRadius.circular(12 * s),
                    ),
                    child: selected
                        ? KartyControlMark(
                            glyph: KartyControlGlyph.check,
                            size: 24 * s,
                          )
                        : null,
                  ),
                  SizedBox(width: 22 * s),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: _ink,
                            fontFamily: AppTypography.family,
                            fontSize: 30 * s,
                            fontWeight: AppTypography.label,
                          ),
                        ),
                        SizedBox(height: 4 * s),
                        Text(
                          detail,
                          style: TextStyle(
                            color: _muted,
                            fontFamily: AppTypography.family,
                            fontSize: 22 * s,
                            fontWeight: AppTypography.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: price,
                          style: TextStyle(
                            color: _ink,
                            fontSize: 32 * s,
                            fontWeight: AppTypography.number,
                          ),
                        ),
                        TextSpan(
                          text: ' $period',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 22 * s,
                            fontWeight: AppTypography.caption,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontFamily: AppTypography.family),
                  ),
                ],
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -16 * s,
              left: 34 * s,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 16 * s, vertical: 6 * s),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(10 * s),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: AppTypography.family,
                    fontSize: 18 * s,
                    fontWeight: AppTypography.number,
                    letterSpacing: 0.6 * s,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bulut denizinin bir katmanı: düz bir taban ve üstünde tombul puflar
/// (merkez x ve yarıçap, tasarım biriminde; taban tuvalin altından
/// yüksekliği). Her puf ikon reçetesindeki gibi iki tonlu (§2.5): yüz ve sol
/// üstte keskin açık hilal; puflar üst üste binince hilaller kümeyi
/// tombullaştırır. Düz çizimde bulut ancak çevresinden açıksa bulut okunur
/// (koyu puflar kemer ve tepe gibi durdu): uzak katman Satürn ligi lavantası
/// (`8C7BF0 / BFB3FF`), yakın katmanlar ondan açılarak zemine (`F3F1FF`)
/// varır. Kenarlar yüksek, orta alçak: maskot bulutların açıldığı yerden
/// çıkıyor.
class _CloudLayer {
  const _CloudLayer(
    this.face,
    this.light,
    this.base,
    this.bumps, {
    this.mound = const [],
  });

  final Color face;
  final Color light;
  final double base;
  final List<(double, double)> bumps;

  /// Tabandan kalkık puflar (merkez x, yarıçap, yükseklik): maskotun
  /// çıktığı yerde bulut onunla birlikte kabarır.
  final List<(double, double, double)> mound;

  /// Maskotun arkasında kalan uzak katmanlar.
  static const back = [
    _CloudLayer(Color(0xFF8C7BF0), Color(0xFFBFB3FF), 205, [
      (-30, 74),
      (50, 58),
      (118, 46),
      (182, 36),
      (300, 26),
      (452, 28),
      (566, 38),
      (628, 50),
      (694, 62),
      (774, 78),
    ]),
    _CloudLayer(Color(0xFFBFB3FF), Color(0xFFE9E4FF), 150, [
      (-40, 92),
      (70, 76),
      (165, 60),
      (248, 46),
      (330, 38),
      (424, 40),
      (508, 50),
      (590, 64),
      (682, 80),
      (790, 96),
    ]),
  ];

  /// Maskotun bacaklarının önünden geçen en yakın katman: zeminin kendisi.
  static const front = [
    _CloudLayer(
      Color(0xFFF3F1FF),
      Color(0xFFFFFFFF),
      70,
      [
        (-60, 120),
        (80, 96),
        (200, 76),
        (302, 62),
        (402, 66),
        (502, 74),
        (612, 92),
        (742, 118),
      ],
      // Bacakların çevresinde kabaran puflar: maskot bulutu yarıyor.
      mound: [(255, 44, 34), (312, 38, 56), (368, 42, 30)],
    ),
  ];
}

class _CloudLayersPainter extends CustomPainter {
  const _CloudLayersPainter(this.layers, {required this.scale, this.bleed = 0});

  final List<_CloudLayer> layers;
  final double scale;

  /// Son katmanın tuvalin altına taştığı piksel. Katmanlar aynı satırda
  /// biterse kenar yumuşatmaları üst üste biner, zeminde ince bir lavanta
  /// çizgisi kalır; yalnız en öndeki taşar, gerisini o örter.
  final double bleed;

  @override
  void paint(Canvas canvas, Size size) {
    for (final layer in layers) {
      final baseY = size.height - layer.base * scale;
      final face = Paint()..color = layer.face;
      final light = Paint()..color = layer.light;
      canvas.drawRect(
        Rect.fromLTRB(
          -20,
          baseY,
          size.width + 20,
          size.height + (identical(layer, layers.last) ? bleed : 0),
        ),
        face,
      );
      // Büyük puflar arkada, küçükler önde; kabaran puflar en önde.
      final bumps = [
        for (final (x, r) in [
          ...layer.bumps
        ]..sort((a, b) => b.$2.compareTo(a.$2)))
          (x, r, 0.0),
        ...layer.mound,
      ];
      for (final (x, r, lift) in bumps) {
        final center = Offset(x * scale, baseY - lift * scale);
        final radius = r * scale;
        final puff = Path()
          ..addOval(Rect.fromCircle(center: center, radius: radius));
        canvas.drawPath(puff, face);
        // Hilal: puftan sağ alta kaydırılmış kopyası çıkınca kalan şerit.
        final shade = Path()
          ..addOval(Rect.fromCircle(
            center: center + Offset(radius * 0.16, radius * 0.2),
            radius: radius,
          ));
        canvas.save();
        // Tabanın altına inen kısmı gövdenin içinde kalır, çizilmez.
        canvas.clipRect(
          Rect.fromLTRB(-20, -size.height, size.width + 20, center.dy),
        );
        canvas.drawPath(
            Path.combine(PathOperation.difference, puff, shade), light);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_CloudLayersPainter old) =>
      old.scale != scale || old.layers != layers || old.bleed != bleed;
}

/// Gece gökyüzünün birkaç sönük yıldızı, durum çubuğunun altında. Konumlar
/// sabit (tasarım birimi, `top`un altından), her ekranda aynı gökyüzü.
class _StarsPainter extends CustomPainter {
  const _StarsPainter({required this.scale, required this.top});

  final double scale;
  final double top;

  static const _stars = [
    (180.0, 40.0, 2.4, 0.7),
    (330.0, 18.0, 1.8, 0.5),
    (560.0, 30.0, 2.6, 0.8),
    (680.0, 110.0, 2.0, 0.6),
    (90.0, 190.0, 2.2, 0.6),
    (250.0, 150.0, 1.6, 0.45),
    (620.0, 220.0, 2.4, 0.7),
    (40.0, 300.0, 1.8, 0.5),
    (710.0, 300.0, 2.2, 0.6),
    (470.0, 90.0, 1.5, 0.45),
    (150.0, 270.0, 1.6, 0.4),
    (600.0, 330.0, 1.8, 0.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (x, y, r, alpha) in _stars) {
      canvas.drawCircle(
        Offset(x * scale, top + y * scale),
        r * scale,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.scale != scale || old.top != top;
}
