import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingualloop/models/responses/DailyActivityResponse.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/streak_freeze_flake.dart';
import 'package:lingualloop/ui/widgets/streak_freeze_mark.dart';
import 'package:lingualloop/ui/widgets/streak_week_strip.dart';

/// Seri kırılmak üzereyken açılan **karar** penceresi.
///
/// Koruma otomatik harcanmıyor: kısa bir seri için kıymetli bir korumayı yakmak
/// istemeyen kullanıcı olur. Bu yüzden pencere bir bildirim değil, iki seçenekli
/// bir sorudur ve kapatılamaz — karar verilmeden geçilemez.
///
/// Şerit burada süs değil kanıt: kullanıcı hangi günü kaçırdığını kesikli
/// halkadan görür, kararı somut bir veriye bakarak verir.
///
/// ## Tek pencere
///
/// "Kullan" denince buz bloğu o güne **çakılır** ve pencere **kapanmaz**:
/// başlık, açıklama ve düğmeler yerinde değişerek kutlamaya döner. Önce ayrı
/// bir kutlama penceresi açılıyordu; kapanıp yeniden açılma anı akışı kesiyor
/// ve çakılma ile ödül birbirinden kopuyordu. Aynı kartta kalınca sebep–sonuç
/// tek sahnede görülüyor.
Future<void> showStreakAtRiskPopup(
  BuildContext context, {
  required int currentStreak,
  required int missedDays,
  required int freezeCount,
  required List<DailyActivityDay> week,
  required Future<DailyActivityResponse?> Function(bool useFreeze) onResolve,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xFF041227).withValues(alpha: 0.86),
    builder: (context) => PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width * 0.06,
        ),
        child: StreakAtRiskCard(
          currentStreak: currentStreak,
          missedDays: missedDays,
          freezeCount: freezeCount,
          week: week,
          onResolve: onResolve,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    ),
  );
}

/// Pencerenin içeriği. `Dialog`'dan ayrı ki golden önizlemesi kartı tek başına
/// render edebilsin.
class StreakAtRiskCard extends StatefulWidget {
  const StreakAtRiskCard({
    super.key,
    required this.currentStreak,
    required this.missedDays,
    required this.freezeCount,
    required this.week,
    required this.onResolve,
    required this.onClose,
    this.strikeProgress,
    this.strikeTargetIndex,
    this.previewResult,
  });

  final int currentStreak;
  final int missedDays;
  final int freezeCount;
  final List<DailyActivityDay> week;

  /// Kararı backend'e yazar ve sonucu döndürür. Kart sonucu **kendisi**
  /// gösterdiği için sayıları tahmin etmiyor, gerçek veriyi bekliyor.
  final Future<DailyActivityResponse?> Function(bool useFreeze) onResolve;

  final VoidCallback onClose;

  /// Yalnızca golden önizlemesi için: çakılma animasyonunu belirli bir anda
  /// dondurur. Uygulamada `null` — animasyon kendi denetleyicisiyle akar.
  final double? strikeProgress;

  /// Önizlemede hangi güne çakılacağı.
  final int? strikeTargetIndex;

  /// Yalnızca golden önizlemesi için: kartı doğrudan sonuç hâlinde açar.
  final DailyActivityResponse? previewResult;

  @override
  State<StreakAtRiskCard> createState() => _StreakAtRiskCardState();
}

class _StreakAtRiskCardState extends State<StreakAtRiskCard>
    with TickerProviderStateMixin {
  static const _cardFace = Color(0xFF041227);
  static const _cardBorder = Color(0xFF0B2143);
  static const _panel = Color(0xFF0C2244);
  static const _muted = Color(0xFF8FA0B5);
  static const _ice = Color(0xFF1CB1F5);
  static const _flame = Color(0xFFFF6536);
  static const _green = Color(0xFF93D334);
  static const _greenDeep = Color(0xFF628C22);

  static const _cardWidth = 662.0;
  static const _cardPadding = 34.0;
  static const _contentWidth = _cardWidth - _cardPadding * 2;

  /// Başlıktaki bloğun boyutu; çakılan blok buradan yola çıkıyor.
  static const _markSize = 210.0;

  /// Bloğun hedefe çakıldığı andaki boyutu. Gün kutusundan (54) biraz büyük:
  /// tam kutu boyunda olsaydı "çakıldı" değil "yerine oturdu" gibi okunurdu.
  static const _landedSize = 84.0;

  /// Çakılmanın evreleri (denetleyici 0→1).
  static const _windupEnd = 0.22;
  static const _travelEnd = 0.60;
  static const _impactEnd = 0.70;

  /// Bölümler arası geçiş süresi. Kart yüksekliği de bu sürede değişiyor.
  static const _swapDuration = Duration(milliseconds: 340);

  late final AnimationController _entry;
  late final AnimationController _strike;

  /// Kart yerel koordinatlarına çevirmek için — hedefin ekrandaki yeri ancak
  /// yerleşim bittikten sonra bilinebiliyor.
  final _stackKey = GlobalKey();
  final _markKey = GlobalKey();
  late final List<GlobalKey> _markerKeys;

  Offset? _target;
  Offset? _origin;
  int? _targetSlot;

  /// Çakılması bitmiş günler — şeritte artık buzlu tik gösterilir.
  final Set<int> _landed = {};

  bool _striking = false;

  /// Backend'den dönen sonuç. Doluysa kart kutlama hâlindedir.
  DailyActivityResponse? _result;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();

    _strike = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );

    _markerKeys = List.generate(widget.week.length, (_) => GlobalKey());
    _result = widget.previewResult;

    if (widget.strikeProgress != null) {
      _entry.value = 1;
      _strike.value = widget.strikeProgress!;
      _striking = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _targetSlot = widget.strikeTargetIndex ?? 0;
          _origin = _centerOf(_markKey);
          _target = _centerOf(_markerKeys[_targetSlot!]);
        });
      });
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    _strike.dispose();
    super.dispose();
  }

  bool get _resolved => _result != null;

  /// Şu anda korunmuş sayılan günler.
  ///
  /// Hedef gün, animasyonun **sonunda** değil **çarpma anında** dönüşür: sonda
  /// dönseydi blok sönerken altında boş halka kalır, "çakıldı ama bir şey
  /// olmadı" gibi okunurdu.
  Set<int> get _landedNow {
    final target = _targetSlot;
    if (target == null || _strike.value < _impactEnd) return _landed;
    return {..._landed, target};
  }

  Offset? _centerOf(GlobalKey key) {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || box == null) return null;

    return stackBox
        .globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }

  /// Korumanın kapatacağı günler: bugünün hemen öncesindeki boş günler.
  ///
  /// Şeritte daha eski boşluklar da olabilir (bu özellikten önce kırılmış
  /// seriler); kapatılacak olanlar yalnızca **sondaki** `missedDays` tanesi.
  List<int> get _targetIndices {
    final empty = <int>[];
    for (var index = 0; index < widget.week.length; index++) {
      final day = widget.week[index];
      if (!day.active && !day.frozen) empty.add(index);
    }
    if (empty.length <= widget.missedDays) return empty;
    return empty.sublist(empty.length - widget.missedDays);
  }

  Future<void> _handleUseFreeze() async {
    if (_striking) return;

    setState(() => _striking = true);

    // İstek animasyonla **aynı anda** başlar: ağ gecikmesi çakılmanın arkasına
    // gizlenir, kullanıcı boş bir bekleme görmez.
    final pending = widget.onResolve(true);

    final targets = _targetIndices;
    final origin = _centerOf(_markKey);

    if (targets.isNotEmpty && origin != null) {
      setState(() => _origin = origin);

      for (final index in targets) {
        final target = _centerOf(_markerKeys[index]);
        if (target == null) continue;

        setState(() {
          _target = target;
          _targetSlot = index;
        });
        await _strike.forward(from: 0);
        if (!mounted) return;
        setState(() => _landed.add(index));
      }
    }

    final result = await pending;
    if (!mounted) return;

    // İstek başarısızsa kutlama gösterilemez — backend hâlâ "risk" diyor ve
    // soru bir sonraki açılışta yeniden sorulacak.
    if (result == null) {
      widget.onClose();
      return;
    }

    setState(() => _result = result);
  }

  Future<void> _handleDecline() async {
    if (_striking) return;
    setState(() => _striking = true);
    await widget.onResolve(false);
    if (!mounted) return;
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 750;

    return ScaleTransition(
      scale: Tween(begin: 0.86, end: 1.0).animate(
        CurvedAnimation(parent: _entry, curve: Curves.easeOutBack),
      ),
      child: FadeTransition(
        opacity: _entry,
        child: Stack(
          key: _stackKey,
          children: [
            _card(scale),
            if (_striking &&
                !_resolved &&
                _target != null &&
                _origin != null) ...[_burstLayer(scale), _strikeLayer(scale)],
          ],
        ),
      ),
    );
  }

  Widget _card(double scale) {
    final radius = BorderRadius.circular(AppShapeStyle.cardRadius(34 * scale));

    return Container(
      width: _cardWidth * scale,
      decoration: BoxDecoration(color: _cardBorder, borderRadius: radius),
      padding: EdgeInsets.only(bottom: AppShapeStyle.cardDepth(8 * scale)),
      child: Container(
        decoration: BoxDecoration(
          color: _cardFace,
          borderRadius: radius,
          border: Border.all(
              color: _cardBorder, width: AppShapeStyle.outline(2 * scale)),
        ),
        padding: EdgeInsets.fromLTRB(
          _cardPadding * scale,
          34 * scale,
          _cardPadding * scale,
          22 * scale,
        ),
        // Bölümlerin yükseklikleri değişiyor; kart zıplamadan uzasın/kısalsın.
        child: AnimatedSize(
          duration: _swapDuration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(scale),
              SizedBox(height: 20 * scale),
              _swap(_title(scale)),
              SizedBox(height: 12 * scale),
              _swap(_subtitle(scale)),
              SizedBox(height: 24 * scale),
              _weekPanel(scale),
              SizedBox(height: 18 * scale),
              _swap(_detail(scale)),
              SizedBox(height: 24 * scale),
              _swap(_actions(scale)),
            ],
          ),
        ),
      ),
    );
  }

  /// Bölüm değişimi: soluklaşarak ve hafifçe yukarı kayarak gelir.
  Widget _swap(Widget child) {
    return AnimatedSwitcher(
      duration: _swapDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.16), end: Offset.zero)
              .animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }

  /// Kart başlığındaki görsel.
  ///
  /// Karar aşamasında buz bloğu animasyonun başlangıç noktasıdır. Sonuçta ise
  /// maskot, buzun içinde yanmaya devam eden alevin yanında görünür: harcanan
  /// nesneyi değil, dondurma sayesinde **korunan seriyi** anlatır.
  Widget _header(double scale) {
    if (_resolved) {
      return TweenAnimationBuilder<double>(
        key: const ValueKey('header-freeze-mascot'),
        tween: Tween(begin: 0.6, end: 1),
        duration: const Duration(milliseconds: 460),
        curve: Curves.easeOutBack,
        builder: (context, value, child) =>
            Transform.scale(scale: value, child: child),
        child: SizedBox(
          width: _markSize * scale,
          height: _markSize * scale,
          child: Image.asset(
            'assets/icons/fire-freeze-relax.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      );
    }

    // Uçarken başlıktaki blok görünmez olur; iki blok aynı anda durursa
    // "kopyası çıktı" gibi okunuyor, "yerinden fırladı" değil.
    return Opacity(
      opacity: _striking ? 0 : 1,
      child: SizedBox(
        key: _markKey,
        width: _markSize * scale,
        height: _markSize * scale,
        child: StreakFreezeMark(size: _markSize * scale),
      ),
    );
  }

  Widget _title(double scale) {
    return Text(
      _resolved
          ? 'Serin korundu!'
          : '${widget.currentStreak} günlük serin tehlikede',
      key: ValueKey('title-$_resolved'),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: (_resolved ? 46 : 42) * scale,
        fontWeight: AppTypography.heading,
        fontFamily: AppTypography.displayFamily,
        height: 1.1,
      ),
    );
  }

  Widget _subtitle(double scale) {
    final many = widget.missedDays > 1;
    final text = _resolved
        ? (many
            ? '${widget.missedDays} gün ara verdin ama seri koruman devreye '
                'girdi.'
            : 'Bir gün ara verdin ama seri koruman devreye girdi.')
        : (many
            ? '${widget.missedDays} gün ara verdin. Seri koruman kullanılsın mı?'
            : 'Bir gün ara verdin. Seri koruman kullanılsın mı?');

    return Text(
      text,
      key: ValueKey('subtitle-$_resolved'),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _muted,
        fontSize: 26 * scale,
        fontWeight: AppTypography.body,
        fontFamily: AppTypography.family,
        height: 1.3,
      ),
    );
  }

  /// Karar aşamasında bedel, sonuçta kazanç.
  Widget _detail(double scale) {
    if (_resolved) return _resultPanel(scale);

    final left = widget.freezeCount - widget.missedDays;
    return Row(
      key: const ValueKey('cost'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Üst şerit ve profildeki sayaçla **aynı** ikon: burada da soru
        // "kaç korumam var / kaçı gidecek", yani kaynak sayılıyor.
        // Animasyonlu blok (`StreakFreezeMark`) bu satır için değil,
        // pencerenin kahraman sahnesi için.
        StreakFreezeFlake(size: 36 * scale),
        SizedBox(width: 10 * scale),
        Flexible(
          child: Text(
            widget.missedDays > 1
                ? '${widget.missedDays} koruma harcanır, $left kalır'
                : '1 koruma harcanır, $left kalır',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _ice,
              fontSize: 25 * scale,
              fontWeight: AppTypography.caption,
              fontFamily: AppTypography.family,
            ),
          ),
        ),
      ],
    );
  }

  /// Korunan seri ve kalan koruma yan yana: biri kazanılan, diğeri kalan.
  Widget _resultPanel(double scale) {
    final result = _result!;

    return Container(
      key: const ValueKey('result'),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius:
            BorderRadius.circular(AppShapeStyle.cardRadius(26 * scale)),
      ),
      padding: EdgeInsets.symmetric(vertical: 22 * scale),
      child: Row(
        children: [
          Expanded(
            child: _metric(
              scale,
              value: '${result.currentStreak}',
              label: 'günlük seri',
              color: _flame,
            ),
          ),
          Container(width: 2 * scale, height: 62 * scale, color: _cardBorder),
          Expanded(
            child: _metric(
              scale,
              value: '${result.freezeCount}',
              label: 'koruma kaldı',
              color: _ice,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(
    double scale, {
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 44 * scale,
            fontWeight: AppTypography.number,
            fontFamily: AppTypography.family,
            height: 1,
          ),
        ),
        SizedBox(height: 6 * scale),
        Text(
          label,
          style: TextStyle(
            color: _muted,
            fontSize: 23 * scale,
            fontWeight: AppTypography.caption,
            fontFamily: AppTypography.family,
          ),
        ),
      ],
    );
  }

  Widget _actions(double scale) {
    if (_resolved) {
      return DepthPressableButton(
        key: const ValueKey('actions-done'),
        text: 'DEVAM ET',
        width: _contentWidth * scale,
        height: 96 * scale,
        radius: 24 * scale,
        shadowOffset: 9 * scale,
        backgroundColor: _green,
        shadowColor: _greenDeep,
        fontSize: 30 * scale,
        fontWeight: AppTypography.action,
        onPressed: widget.onClose,
      );
    }

    // Karar verildikten sonra düğmeler geri çekilir: sahne artık şeridin.
    return AnimatedOpacity(
      key: const ValueKey('actions-decide'),
      opacity: _striking ? 0.2 : 1,
      duration: const Duration(milliseconds: 220),
      child: IgnorePointer(
        ignoring: _striking,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DepthPressableButton(
              text: 'KORUMAYI KULLAN',
              width: _contentWidth * scale,
              height: 96 * scale,
              radius: 24 * scale,
              shadowOffset: 9 * scale,
              backgroundColor: _green,
              shadowColor: _greenDeep,
              fontSize: 30 * scale,
              fontWeight: AppTypography.action,
              onPressed: _handleUseFreeze,
            ),
            // İkinci seçenek gerçekten seçilebilir olmalı: kullanıcı kısa bir
            // seri için korumasını saklamak isteyebilir. Gizlenmiş ya da
            // okunmaz bir bağlantı bunu karar olmaktan çıkarır.
            TextButton(
              onPressed: _handleDecline,
              style: TextButton.styleFrom(
                minimumSize: Size(_contentWidth * scale, 72 * scale),
                foregroundColor: _muted,
              ),
              child: Text(
                'GEREK YOK, SERİ SIFIRLANSIN',
                style: TextStyle(
                  color: _muted,
                  fontSize: 25 * scale,
                  fontWeight: AppTypography.action,
                  fontFamily: AppTypography.family,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekPanel(double scale) {
    return AnimatedBuilder(
      animation: _strike,
      builder: (context, child) {
        // Çarpma anında şerit sarsılır. Sönümlü sinüs: darbe sert başlayıp
        // hızla durulur; sabit genlikli titreme "bozuk" gibi görünüyor.
        final shake = _segment(_strike.value, _travelEnd, 0.86);
        final offset = _striking && !_resolved && shake > 0 && shake < 1
            ? math.sin(shake * math.pi * 5) * (1 - shake) * 7 * scale
            : 0.0;

        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            decoration: BoxDecoration(
              color: _panel,
              borderRadius:
                  BorderRadius.circular(AppShapeStyle.cardRadius(26 * scale)),
            ),
            padding: EdgeInsets.symmetric(
              vertical: 20 * scale,
              horizontal: 22 * scale,
            ),
            child: StreakWeekStrip(
              days: _stripDays(),
              scale: scale,
              markerKeys: _markerKeys,
            ),
          ),
        );
      },
    );
  }

  /// Çakılması tamamlanan günler artık korunmuş gösterilir. Sonuç geldiyse
  /// backend'in şeridi kullanılır — tek doğruluk kaynağı orası.
  List<StreakDay> _stripDays() {
    final result = _result;
    if (result != null) return result.week.toStrip();

    final days = widget.week.toStrip();
    final landed = _landedNow;
    return [
      for (var index = 0; index < days.length; index++)
        if (landed.contains(index))
          StreakDay(
            date: days[index].date,
            active: days[index].active,
            frozen: true,
            isToday: days[index].isToday,
          )
        else
          days[index],
    ];
  }

  /// Çakılma anında hedef günden çıkan don dalgası.
  Widget _burstLayer(double scale) {
    // Panel iç yüksekliğini aşmayacak kadar: daha büyüğü panelin yuvarlak
    // kenarını kesip başıboş bir çizgi gibi görünüyor.
    const burstSize = 148.0;

    return AnimatedBuilder(
      animation: _strike,
      builder: (context, child) {
        final progress = _segment(_strike.value, _travelEnd, 1);
        if (progress <= 0) return const SizedBox.shrink();

        final target = _target!;
        return Positioned(
          left: target.dx - burstSize * scale / 2,
          top: target.dy - burstSize * scale / 2,
          child: StreakFrostBurst(
            size: burstSize * scale,
            progress: progress,
          ),
        );
      },
    );
  }

  /// Uçan blok: geri çekilir, hızlanarak iner, güne çakılır ve kutuya oturur.
  Widget _strikeLayer(double scale) {
    return AnimatedBuilder(
      animation: _strike,
      builder: (context, child) {
        final t = _strike.value;
        final origin = _origin!;
        final target = _target!;

        final windup =
            Curves.easeOutCubic.transform(_segment(t, 0, _windupEnd));
        // Hızlanarak iner: çakılma bir darbedir, yumuşak iniş değil.
        final travel =
            Curves.easeInCubic.transform(_segment(t, _windupEnd, _travelEnd));
        final impact = _segment(t, _travelEnd, _impactEnd);
        final settle =
            Curves.easeOutCubic.transform(_segment(t, _impactEnd, 1));

        // Boyut: başlıktaki bloktan çarpma boyutuna, sonra gün kutusuna.
        final size =
            _lerp(_lerp(_markSize, _landedSize, travel), 54, settle) * scale;

        // Geri çekilme: vurmadan önce yukarı doğru bir soluk alır.
        final liftedOrigin = origin - Offset(0, 26 * scale * windup);

        // Uçuş boyunca blok **tabanından** hizalanır; oturunca merkeze geçer.
        final baseAnchor = (StreakFreezeMark.contactFraction - 0.5) * size;
        final anchor = _lerp(baseAnchor, 0, settle);

        final center =
            Offset.lerp(liftedOrigin, target, travel)! - Offset(0, anchor);

        // Çarpmada ezilme: yatay yayılır, dikey basılır. Blok ağır bir nesne,
        // darbe de sert olmalı.
        final squash =
            impact > 0 && impact < 1 ? math.sin(impact * math.pi) * 0.20 : 0.0;

        return Positioned(
          left: center.dx - size / 2,
          top: center.dy - size / 2,
          width: size,
          height: size,
          child: IgnorePointer(
            child: Transform.rotate(
              // Havalanırken hafif yatar, vururken düzelir.
              angle: -0.09 * windup * (1 - travel),
              child: Transform.scale(
                scaleX: 1 + squash,
                scaleY: 1 - squash,
                child: Opacity(
                  opacity: 1 - settle,
                  child: StreakFreezeMark(size: size),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// [value]'nun [start]–[end] aralığındaki ilerlemesi, 0–1'e sıkıştırılmış.
  static double _segment(double value, double start, double end) {
    return ((value - start) / (end - start)).clamp(0.0, 1.0);
  }
}

/// API modelini şerit modeline çevirir.
///
/// "Bugün" listenin son günüdür — backend şeridi her zaman bugünle bitirir,
/// böylece istemcinin saat dilimi hesabına girmesi gerekmez (istemci cihaz
/// saatini, backend İstanbul saatini kullanıyor; ikisi ayrı güne düşebilir).
extension StreakWeekMapper on List<DailyActivityDay> {
  List<StreakDay> toStrip() {
    return [
      for (var index = 0; index < length; index++)
        StreakDay(
          date: this[index].date,
          active: this[index].active,
          frozen: this[index].frozen,
          isToday: index == length - 1,
        ),
    ];
  }

  /// Son **iki** günden biri korumayla kapatılmış mı.
  ///
  /// İki gün, bir gün değil: `ResolveStreakFreeze` **kaçırılan** günleri
  /// işaretliyor ve `LastActiveDate`'i düne çekiyor — bugün değil, dün (ve
  /// öncesi) frozen oluyor. Yalnız bugüne bakan bir kontrol hiç tetiklenmez.
  bool get freezeUsedRecently {
    for (var index = length - 1; index >= 0 && index >= length - 2; index--) {
      if (this[index].frozen) return true;
    }
    return false;
  }
}
