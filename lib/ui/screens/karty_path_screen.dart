import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_button_style.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_icon_control_button.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/karty_control_glyphs.dart';
import 'package:lingualloop/ui/widgets/hop_motion.dart';
import 'package:lingualloop/ui/widgets/karty_unit_header.dart';
import 'package:lingualloop/ui/widgets/ticket_spend_scene.dart';
import 'package:lingualloop/ui/widgets/karty_unit_marks.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';
import 'package:lingualloop/ui/widgets/surface_gloss.dart';

/// Ana ekranın içeriği: Karty Yolu (bkz. `docs/KARTY_PATIKA.md` §8, §11).
///
/// Aşağı akan bir patika; her ünitenin başlığı yolun içinde durur ve
/// kaydırınca görünen ünitenin başlığı üste yapışır. Her düğüm ünitenin
/// 8 kelimelik bir destesi; bir oyun bir destedir. Bitmiş desteler yeşil,
/// şu anki mavi ve kelime halkalı, sıradakiler lacivert. Düğümler uygulamanın derinlikli
/// ikon kontrolüyle aynı karo (`AppButtonStyle`). Ünitenin sonunda her
/// kelimenin bir boncuk olduğu pekiştirme halkası durur; %80'i yandığında
/// sıradaki ünite açılır. Düğüme dokununca adımın penceresi açılır.
/// Açılışta şu anki destenin düğümü ekranın ortasına gelir; iki yanında yan
/// duraklar (Artikel Pusulası ve Rövanş) durur. Veri ve akış `HomeScreen`'de.
class KartyPathScreen extends StatefulWidget {
  const KartyPathScreen({
    super.key,
    required this.data,
    required this.header,
    required this.stations,
    required this.onContinue,
    this.currentNodeKey,
    this.hopCurrent = false,
    this.onRefresh,
    this.controller,
    this.scrollToCurrent = true,
    this.arrivalUnit,
    this.playArrival = false,
    this.onArrivalDone,
    this.arrivalPreview,
    this.onDocked,
  });

  final KartyPathData data;

  /// Üst şerit (lig · seri · bilet · koruma); ekran ölçeğini alır.
  final Widget Function(double scale) header;

  /// Şu anki destenin iki yanındaki duraklar.
  final KartyPathStations stations;
  final VoidCallback onContinue;

  /// Şu anki düğüm: harcanan bilet buraya iner (`ticket_spend_scene.dart`).
  final GlobalKey<TicketTargetState>? currentNodeKey;

  /// Şu anki düğüm zıplasın: bugün henüz oynanmadıysa, çağrı o an anlamlı.
  final bool hopCurrent;
  final Future<void> Function()? onRefresh;
  final ScrollController? controller;

  /// Açılışta şu anki destenin düğümünü ortala. Önizleme sabit kaydırma ister.
  final bool scrollToCurrent;

  /// Yeni açılan ünitenin patikaya gelişi ([_Arrival]). [arrivalUnit]
  /// verilince o ünite henüz açılmamış gibi çizilir — kutlama ekranı
  /// üstteyken; [playArrival] true olunca kamera üniteye kayar ve açılış
  /// oynar, bitince [onArrivalDone] çağrılır.
  final int? arrivalUnit;
  final bool playArrival;
  final VoidCallback? onArrivalDone;

  /// Kaydırma bir ünitenin başlığını mıknatısla tepeye oturttu
  /// ([_UnitDockPhysics]); ana ekran hafif titreşim verir.
  final VoidCallback? onDocked;

  /// Önizleme: gelişi bu anda (0–1) dondurur ve kamerayı üniteye götürür.
  final double? arrivalPreview;

  @override
  State<KartyPathScreen> createState() => _KartyPathScreenState();
}

/// Yolun "şu an" satırındaki iki yan durak. Karty desteleri yolun kendisi;
/// Artikel Pusulası ve Rövanş aynı anda yapılabilecek yan işler olduğu için
/// şu anki destenin iki yanında, yolun taşlarıyla ona bağlı durur.
class KartyPathStations {
  const KartyPathStations({required this.article, required this.review});

  final KartyPathStation article;
  final KartyPathStation review;

  /// Yerleşimi etkileyen kısım: hangi durak açık (yan yol taşlarının rengi).
  (bool, bool) get _layoutKey => (article.enabled, review.enabled);
}

class KartyPathStation {
  const KartyPathStation({
    required this.title,
    required this.spokenName,
    required this.icon,
    required this.detail,
    this.onTap,
    this.tileKey,
  });

  /// Karonun altındaki ad ve ekran okuyucunun söylediği tam ad.
  final String title;
  final String spokenName;

  /// Karonun içindeki simge; karonun genişliğini alır.
  final Widget Function(double tileWidth) icon;

  /// Etiketin ikinci satırı: "16 kart" ya da durağın neden kapalı olduğu.
  final String detail;

  /// Kapalı durakta null: sönük çizilir, basılmaz.
  final VoidCallback? onTap;

  /// Harcanan bilet bu karoya iner. Bedelsiz durakta gerekmez.
  final GlobalKey<TicketTargetState>? tileKey;

  bool get enabled => onTap != null;
}

class _KartyPathScreenState extends State<KartyPathScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _controller =
      widget.controller ?? ScrollController();

  /// Patika alanının boyu (tasarım birimi); ilk çizimde ölçülür.
  double _viewportUnits = 0;

  late _PathLayout _layout = _computeLayout();

  _PathLayout _computeLayout() => _PathLayout.compute(
        widget.data,
        stations: widget.stations,
        minUnitSpan: _viewportUnits,
      );
  late final AnimationController _arrival = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  double _scale = 1;
  int? _pinned;
  bool _centeredCurrent = false;
  bool _arriving = false;
  bool _previewPlaced = false;

  /// Şu anki deste ekranda mı: 0 görünüyor, -1 yukarıda kaldı, 1 aşağıda
  /// kaldı ([_BackToCurrentButton]).
  int _away = 0;

  /// Okun son baktığı yön; düğme sönerken ok dönmesin.
  bool _arrowUp = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant KartyPathScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.stations._layoutKey != widget.stations._layoutKey) {
      final before = _layout.current;
      _layout = _computeLayout();
      final after = _layout.current;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onScroll();
        // Deste bitti, şu anki adım ilerledi: eylem ekranda kalsın. Ünite
        // açılışında kamerayı geliş yönetiyor.
        final moved = before?.unit.number != after?.unit.number ||
            before?.step.deck != after?.step.deck;
        if (moved && widget.arrivalUnit == null) _animateToCurrent();
      });
    }
    if (widget.playArrival && !oldWidget.playArrival) unawaited(_runArrival());
    if (widget.arrivalUnit == null && oldWidget.arrivalUnit != null) {
      _arrival.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    if (widget.controller == null) _controller.dispose();
    _arrival.dispose();
    super.dispose();
  }

  /// Kamera açılan üniteye kayar; varınca kapı, fitil, başlık ve düğümler
  /// sırayla açılır ([_Arrival]). Bu sırada patika kaydırılamaz ve yapışan
  /// başlık gizlenir ki kapının açılışını örtmesin. Sonunda ünite yerine
  /// oturur: başlığı üste kayar ve yapışan başlık o olur. Kamera yerinde
  /// kalsaydı önceki ünitenin başlığı yarı saydam belirip kapının üstüne
  /// binerdi; yeni üniteyi kutladıktan sonra tepede "Ünite 1" kalırdı.
  Future<void> _runArrival() async {
    final target = _arrivalOffset();
    if (target == null) {
      widget.onArrivalDone?.call();
      return;
    }
    setState(() => _arriving = true);
    if (MediaQuery.disableAnimationsOf(context)) {
      _arrival.value = 1;
      _controller.jumpTo(_dockOffset() ?? target);
    } else {
      // Uzaktaki ünite daha uzun sürer ama kamera oyalanmaz: 0.7–1.4 sn.
      final distance = (target - _controller.offset).abs() / _scale;
      await _controller.animateTo(
        target,
        duration: Duration(
          milliseconds: (650 + distance * 0.4).clamp(700, 1400).round(),
        ),
        curve: Curves.easeInOutCubic,
      );
      if (!mounted) return;
      await _arrival.forward(from: 0);
      if (!mounted) return;
      final dock = _dockOffset();
      if (dock != null && (dock - _controller.offset).abs() > 1) {
        // Son düğüm açıldıktan sonra kısa bir duruş: sahne okunsun.
        await Future<void>.delayed(const Duration(milliseconds: 320));
        if (!mounted) return;
        await _controller.animateTo(
          dock,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
    }
    if (!mounted) return;
    setState(() => _arriving = false);
    widget.onArrivalDone?.call();
  }

  /// Kameranın varış noktası: başlık ekranın üst üçte birinde; üstünde
  /// önceki ünitenin kapısı, altında ilk düğümler görünür.
  double? _arrivalOffset() {
    final unit = widget.arrivalUnit;
    if (unit == null || !_controller.hasClients) return null;
    final index = _layout.unitIndex(unit);
    if (index < 0) return null;
    final position = _controller.position;
    return (_layout.headers[index].top * _scale -
            position.viewportDimension * 0.30)
        .clamp(0.0, position.maxScrollExtent);
  }

  /// Gelişin bittiği yer: açılan ünitenin başlığı yapışan başlığın yerinde.
  /// Patikanın altı kısaysa (son ünite) başlık oraya kadar çıkamayabilir;
  /// o zaman gidebildiği yere gider.
  double? _dockOffset() {
    final unit = widget.arrivalUnit;
    if (unit == null || !_controller.hasClients) return null;
    final index = _layout.unitIndex(unit);
    if (index < 0) return null;
    return (_layout.headers[index].top * _scale)
        .clamp(0.0, _controller.position.maxScrollExtent);
  }

  _Arrival? _arrivalState() {
    final unit = widget.arrivalUnit;
    if (unit == null) return null;
    return _Arrival.of(_layout, unit, widget.arrivalPreview ?? _arrival.value);
  }

  /// Üste varmış son ünite başlığı yapışır; yerindeki başlık görünürken
  /// yapışan yoktur, ikisi aynı yerde buluşur. Eşitlik de sayılır: gelişin
  /// sonunda başlık tam o konuma oturur ([_dockOffset]).
  void _updatePinned() {
    if (!_controller.hasClients) return;
    final offset = _controller.offset;
    int? pinned;
    for (var i = 0; i < _layout.headers.length; i++) {
      if (_layout.headers[i].top * _scale <= offset) pinned = i;
    }
    if (pinned != _pinned) setState(() => _pinned = pinned);
  }

  /// Yapışan başlığın kapladığı yükseklik.
  double get _pinnedHeight => (KartyUnitHeader.height + 18) * _scale;

  /// Ünite başlıklarının tepeye oturduğu kaydırma konumları ([_UnitDockPhysics]).
  /// İlk ünitenin yeri listenin başı: başlığı orada kendi payıyla durur.
  ///
  /// Başlık tepenin altındayken iki durumda oturur (iPhone 17):
  /// · kartın %65'i (~85 pt) kadar yaklaşmışsa;
  /// · önceki ünitenin kapısı yapışan kartın altına girmişse (`emptyFrom`),
  ///   uzaklık ne olursa olsun. O hâlde ekranda önceki üniteden yalnız kartı
  ///   ve boş yol kalır, iki kart alt alta durur: durulacak yer değil
  ///   (kullanıcı: "iki ünite de alt alta gözüküyor ama bu saçma zaten").
  ///   Kapının bir parçası bile görünüyorsa çekmez, kapıya bakılabilsin.
  /// Tepeyi geçtiyse kartın %35'i (~46 pt) içinde geri çeker; daha ilerisi
  /// "patikada devam".
  ///
  /// Dört turda bulundu (15 Kas 2026, kullanıcı): ~211 pt "çok uzaktan
  /// çalışıyor"; ~33 pt "çok yakındayken çekiyor sadece"; ~85 pt iki kart alt
  /// alta kalınca oturmadı ("şöyle bıraktığımda otomatik oturmuyor, asıl
  /// istediğim burdu"). Uzak çekiş artık yalnız iki kartın alt alta kaldığı
  /// boş aralıkta.
  _UnitDocks _unitDocks() => (
        units: [
          for (var i = 0; i < _layout.headers.length; i++)
            i == 0
                ? (offset: 0.0, emptyFrom: null)
                : (
                    offset: _layout.headers[i].top * _scale,
                    emptyFrom:
                        (_layout.gates[i - 1].bottom - KartyUnitHeader.height) *
                            _scale,
                  ),
        ],
        near: KartyUnitHeader.height * 0.65 * _scale,
        past: KartyUnitHeader.height * 0.35 * _scale,
      );

  /// Başlık mıknatısla yerine oturdu.
  void _docked() {
    if (mounted) widget.onDocked?.call();
  }

  /// Sıradaki ünitenin başlığı üste yaklaşınca yapışan başlığı önünden iter:
  /// ikisi hiçbir kaydırma konumunda üst üste binmez.
  double _pinnedPush() {
    final index = _pinned;
    if (index == null ||
        !_controller.hasClients ||
        index + 1 >= _layout.headers.length) {
      return 0;
    }
    final nextTop =
        _layout.headers[index + 1].top * _scale - _controller.offset;
    return math.min(0, nextTop - _pinnedHeight);
  }

  /// Şu anki düğüm, yapışan ünite başlığının altında kalan alanda ortalanır;
  /// bütün ekranda ortalanınca önceki deste başlığın altında yarım kalıyordu.
  /// Kamera ünitenin kendi başlığından yukarı çıkmaz: ünitenin ilk destesinde
  /// başlığı üste oturur. Yukarıda durulursa önceki ünitenin başlığı yapışık
  /// kalır ve iki ünite birlikte görünür.
  double? _currentOffset() {
    final current = _layout.current;
    if (current == null || !_controller.hasClients) return null;
    final position = _controller.position;
    final centered = current.center.dy * _scale -
        (_pinnedHeight + (position.viewportDimension - _pinnedHeight) * 0.42);
    final unitTop =
        _layout.headers[_layout.unitIndex(current.unit.number)].top * _scale;
    return math
        .max(centered, unitTop)
        .clamp(0.0, position.maxScrollExtent)
        .toDouble();
  }

  void _centerCurrent() {
    final target = _currentOffset();
    if (target != null) _controller.jumpTo(target);
  }

  void _animateToCurrent() {
    final target = _currentOffset();
    if (target == null || !mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpTo(target);
      return;
    }
    unawaited(_controller.animateTo(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    ));
  }

  void _onScroll() {
    _updatePinned();
    _updateAway();
  }

  /// Şu anki destenin karosu (yüz + kalınlık) görünen alanın, yani yapışan
  /// başlığın altı ile patikanın dibi arasının tamamen dışına çıktıysa
  /// "desteye dön" düğmesi belirir; ok destenin kaldığı yöne bakar.
  void _updateAway() {
    final current = _layout.current;
    var away = 0;
    if (current != null && _controller.hasClients) {
      final position = _controller.position;
      final geo = _NodeGeometry(current.width);
      final top =
          (current.center.dy - geo.faceHeight / 2) * _scale - position.pixels;
      final bottom = top + geo.total * _scale;
      if (bottom <= _pinnedHeight) {
        away = -1;
      } else if (top >= position.viewportDimension) {
        away = 1;
      }
    }
    if (away == _away) return;
    setState(() {
      _away = away;
      if (away != 0) _arrowUp = away < 0;
    });
  }

  /// "Desteye dön": kamera şu anki desteye, açılıştaki yerine kayar
  /// ([_currentOffset]). Uzak ünitede daha uzun sürer ama kamera oyalanmaz:
  /// 0,45–0,9 sn.
  void _jumpToCurrent() {
    final target = _currentOffset();
    if (target == null || !mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpTo(target);
      return;
    }
    final distance = (target - _controller.offset).abs() / _scale;
    unawaited(_controller.animateTo(
      target,
      duration: Duration(
        milliseconds: (300 + distance * 0.2).clamp(450, 900).round(),
      ),
      curve: Curves.easeInOutCubic,
    ));
  }

  void _openStep(KartyUnit unit, KartyStep step) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      isScrollControlled: true,
      builder: (sheetContext) => KartyStepSheet(
        unit: unit,
        step: step,
        scale: _scale,
        onContinue: () {
          Navigator.of(sheetContext).pop();
          widget.onContinue();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / 750;
          _scale = scale;
          if (widget.scrollToCurrent && !_centeredCurrent) {
            _centeredCurrent = true;
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _centerCurrent());
          }
          if (widget.arrivalPreview != null && !_previewPlaced) {
            _previewPlaced = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final target = _arrivalOffset();
              if (target != null) _controller.jumpTo(target);
            });
          }

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      40 * scale, 18 * scale, 40 * scale, 12 * scale),
                  child: widget.header(scale),
                ),
                Expanded(
                  // Patika alanının boyu düzene girer: ünite en az bu kadar
                  // uzar ([_PathLayout.compute] `minUnitSpan`).
                  child: LayoutBuilder(builder: (context, area) {
                    final units = area.maxHeight / scale;
                    if ((units - _viewportUnits).abs() > 0.5) {
                      _viewportUnits = units;
                      _layout = _computeLayout();
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _onScroll());
                    }
                    Widget scroll = SingleChildScrollView(
                      controller: _controller,
                      physics: _UnitDockPhysics(
                        docks: _unitDocks,
                        onSettled: _docked,
                        parent: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                      ),
                      child: AnimatedBuilder(
                        animation: _arrival,
                        builder: (context, _) => _KartyPathBody(
                          data: widget.data,
                          layout: _layout,
                          scale: scale,
                          onContinue: widget.onContinue,
                          currentNodeKey: widget.currentNodeKey,
                          hopCurrent: widget.hopCurrent,
                          onStepTap: _openStep,
                          arrival: _arrivalState(),
                          stations: widget.stations,
                        ),
                      ),
                    );
                    if (widget.onRefresh != null) {
                      scroll = RefreshIndicator(
                        color: _C.accent,
                        backgroundColor: _C.panel,
                        onRefresh: widget.onRefresh!,
                        child: scroll,
                      );
                    }

                    final pinned =
                        _pinned == null || _pinned! >= _layout.headers.length
                            ? null
                            : _layout.headers[_pinned!];
                    // İtilen başlık üst şeridin altında kesilir; Transform'u
                    // Stack'in kendi kırpması görmüyor.
                    return ClipRect(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: IgnorePointer(
                                ignoring: _arriving, child: scroll),
                          ),
                          if (pinned != null)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              // Gelişte gizlenir, bitince yumuşakça döner.
                              child: IgnorePointer(
                                ignoring: widget.arrivalUnit != null,
                                child: AnimatedOpacity(
                                  opacity: widget.arrivalUnit == null ? 1 : 0,
                                  duration: const Duration(milliseconds: 280),
                                  child: AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, child) =>
                                        Transform.translate(
                                      offset: Offset(0, _pinnedPush()),
                                      child: child,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(40 * scale,
                                          0, 40 * scale, 18 * scale),
                                      child: Stack(
                                        children: [
                                          // Yol kartın arkasından geçer; yalnız
                                          // altında kalan kendi başlığı üst
                                          // köşelerden görünmesin.
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            top: 0,
                                            height:
                                                KartyUnitHeader.cornerRadius(
                                                    scale),
                                            child:
                                                const ColoredBox(color: _C.bg),
                                          ),
                                          KartyUnitHeader(
                                            unit: pinned.unit,
                                            scale: scale,
                                            onTap: () {},
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            right: 40 * scale,
                            bottom: 40 * scale,
                            child: _BackToCurrentButton(
                              // Gelişte kamerayı geliş yönetiyor.
                              visible: _away != 0 &&
                                  widget.arrivalUnit == null &&
                                  !_arriving,
                              up: _arrowUp,
                              scale: scale,
                              onPressed: _jumpToCurrent,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Şu anki desteye dönüş (16 Kas 2026): patika kaydırılıp deste ekrandan
/// çıkınca sağ altta belirir, ok destenin kaldığı yöne bakar; dokununca
/// kamera desteye kayar. Duolingo'da patikadan uzaklaşınca beliren oklu
/// düğmenin karşılığı. İçerik 24 üniteye çıkınca geçmişe kaydıran kullanıcı
/// şu anki desteye ve yan duraklara buradan döner.
///
/// Malzeme uygulamanın ikon kontrolü ([AppIconControlButton]; Karty'nin
/// duraklatması, giriş ekranlarının geri düğmesi), ok kontrol gliflerinin
/// geri oku. Görünmezken dokunuşa ve ekran okuyucuya kapalı.
class _BackToCurrentButton extends StatelessWidget {
  const _BackToCurrentButton({
    required this.visible,
    required this.up,
    required this.scale,
    required this.onPressed,
  });

  final bool visible;

  /// Deste yukarıda kaldı: ok yukarı bakar.
  final bool up;
  final double scale;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        key: const ValueKey('back-to-current'),
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 0.3),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: AppIconControlButton(
            scale: scale,
            label: 'Bulunduğun desteye dön',
            onPressed: onPressed,
            // Geri oku sola bakar: çeyrek tur yukarı, üç çeyrek aşağı.
            child: RotatedBox(
              quarterTurns: up ? 1 : 3,
              child: KartyControlMark(
                glyph: KartyControlGlyph.back,
                size: 50.25 * scale,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class _C {
  static const bg = Color(0xFF041227);
  static const panel = Color(0xFF0B2143);
  static const tile = Color(0xFF0C2244);
  static const raised = Color(0xFF163258);
  static const base = Color(0xFF07182F);
  static const accent = Color(0xFF1CB1F5);
  static const accentDepth = Color(0xFF1B84B5);
  static const green = Color(0xFF93D334);
  static const greenDepth = Color(0xFF628C22);
  static const muted = Color(0xFF8FA0B5);
  static const value = Color(0xFFE9EEF5);

  // Kart çerçevesinin malzemesi (KartyCardRimPainter).
  static const rimBottom = Color(0xFFD8DCE4);

  /// Kutlama ışığının kremi: fitilin parlayan ucu (görev ödülü reçetesi).
  static const cream = Color(0xFFFFF1DC);
}

// ---------------------------------------------------------------------------
// Patika
// ---------------------------------------------------------------------------

/// Bir ünitenin oturma konumu ve önceki ünitenin kapısının yapışan kartın
/// altına girdiği kaydırma konumu (ilk ünitede yok).
typedef _UnitDock = ({double offset, double? emptyFrom});

typedef _UnitDocks = ({List<_UnitDock> units, double near, double past});

/// Ünite başlıklarında görünmeyen bir çukur (kullanıcı, 15 Kas 2026: "ünite
/// 2'ye geldim, kartı tepeye mıknatıs hissiyatıyla yapışmalı; devam edersem
/// ayrılacak ama geçerken oraya oturmuş hissi olmalı"). Kaydırma bir başlığın
/// oturduğu yerin hemen yakınında duracaksa — yavaş bırakılınca ya da
/// savrulma orada bitecekse — liste yayla oraya çekilir; kısa kalan çekilir,
/// aşan geri döner. Daha uzağa giden kaydırma çukurun üstünden geçer. Yay
/// bitince [onSettled] (hafif titreşim).
///
/// Çukurun genişliği ve neden o kadar: [_KartyPathScreenState._unitDocks].
///
/// Yalnız kullanıcının kaydırmasında çalışır. Kameranın `jumpTo`/`animateTo`'su
/// da sonunda fiziğe sorar; o anda kullanıcı yönü `idle` olduğu için kamera
/// bıraktığı yerde kalır (açılışta şu anki düğüm ortalanır, gelişte ünite
/// kendi yerine oturur).
class _UnitDockPhysics extends ScrollPhysics {
  const _UnitDockPhysics({
    required this.docks,
    required this.onSettled,
    super.parent,
  });

  /// Oturma konumları ve çukurun genişliği (piksel): `near` başlık tepenin
  /// altındayken, `past` tepeyi geçince; `emptyFrom`'dan sonrası (iki kart alt
  /// alta) her zaman oturur. Her soruşta güncel düzenden okunur (aynı türden
  /// fizik değişince Scrollable eskisini tutar).
  final _UnitDocks Function() docks;

  /// Başlık yerine oturdu (yay bitti); kullanıcı yayı keserse çağrılmaz.
  final VoidCallback onSettled;

  /// Oturma: aşmadan, yumuşak.
  static final _settle = SpringDescription.withDampingRatio(
    mass: 0.5,
    stiffness: 140,
    ratio: 1,
  );

  @override
  _UnitDockPhysics applyTo(ScrollPhysics? ancestor) => _UnitDockPhysics(
        docks: docks,
        onSettled: onSettled,
        parent: buildParent(ancestor),
      );

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final natural = super.createBallisticSimulation(position, velocity);
    if (position.outOfRange ||
        position is! ScrollPosition ||
        position.userScrollDirection == ScrollDirection.idle) {
      return natural;
    }
    // Kaydırmanın kendiliğinden duracağı yer.
    final end = natural?.x(10) ?? position.pixels;
    final (:units, :near, :past) = docks();
    double? target;
    for (final unit in units) {
      final dock = unit.offset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      // Eksi: başlık tepenin altında kalacak; artı: tepeyi geçecek.
      final gap = end - dock;
      final emptyFrom = unit.emptyFrom;
      final inside = gap >= 0
          ? gap <= past
          : -gap <= near || (emptyFrom != null && end >= emptyFrom);
      if (inside && (target == null || gap.abs() < (target - end).abs())) {
        target = dock;
      }
    }
    if (target == null) return natural;
    final tolerance = toleranceFor(position);
    if ((target - position.pixels).abs() < tolerance.distance &&
        velocity.abs() < tolerance.velocity) {
      return null;
    }
    return _SettleSimulation(
      ScrollSpringSimulation(
        _settle,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      ),
      onSettled,
    );
  }
}

/// Oturma yayı bittiğinde bir kez haber verir.
class _SettleSimulation extends Simulation {
  _SettleSimulation(this._spring, this._onSettled)
      : super(tolerance: _spring.tolerance);

  final Simulation _spring;
  final VoidCallback _onSettled;
  bool _settled = false;

  @override
  double x(double time) => _spring.x(time);

  @override
  double dx(double time) => _spring.dx(time);

  @override
  bool isDone(double time) {
    final done = _spring.isDone(time);
    if (done && !_settled) {
      _settled = true;
      _onSettled();
    }
    return done;
  }
}

/// Patikanın kaydırılan gövdesi: taş izler, düğümler, kapılar ve sonraki
/// ünitelerin başlıkları. Patikada kart görseli ve maskot yok (kullanıcı
/// kararı); kelimeler yalnız adım penceresinde. Tüm yerleşim [_PathLayout]'ta.
class _KartyPathBody extends StatelessWidget {
  const _KartyPathBody({
    required this.data,
    required this.layout,
    required this.scale,
    required this.onContinue,
    required this.currentNodeKey,
    required this.hopCurrent,
    required this.onStepTap,
    required this.stations,
    this.arrival,
  });

  final KartyPathData data;
  final _PathLayout layout;
  final double scale;
  final VoidCallback onContinue;
  final GlobalKey<TicketTargetState>? currentNodeKey;
  final bool hopCurrent;
  final void Function(KartyUnit unit, KartyStep step) onStepTap;

  /// Yeni açılan ünitenin gelişi sürüyorsa o anki hâli.
  final _Arrival? arrival;

  /// Şu anki destenin yanındaki duraklar.
  final KartyPathStations stations;

  @override
  Widget build(BuildContext context) {
    final s = scale;

    final a = arrival;
    final children = <Widget>[
      Positioned.fill(
        child: CustomPaint(
          painter: _PathPainter(layout: layout, scale: s, arrival: a),
        ),
      ),
      for (final header in layout.headers)
        Positioned(
          left: 40 * s,
          top: header.top * s,
          child: KartyUnitHeader(
            unit: header.unit,
            scale: s,
            onTap: () {},
            arrival:
                a != null && a.unit == header.unit.number ? a.header : null,
          ),
        ),
      for (final (i, gate) in layout.gates.indexed) ..._gate(gate, i, s),
      for (final node in layout.nodes) ..._node(node, s),
    ];

    return SizedBox(
      width: 750 * s,
      height: layout.height * s,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }

  List<Widget> _node(_NodeSpot node, double s) {
    final step = node.step;
    final geo = _NodeGeometry(node.width);
    final left = node.center.dx - node.width / 2;
    final top = node.center.dy - geo.faceHeight / 2;
    final isCurrent = step.state == KartyStepState.current;
    const labelGap = 24.0;

    // Gelişte açılan ünitenin düğümü fitil varana kadar kilitli görünür;
    // fitil geçerken zıplar ve zıplamanın tepesinde gerçek hâline döner.
    // Etiketi ondan sonra belirir.
    final a = arrival;
    final reveal =
        a != null && a.unit == node.unit.number ? a.nodeT(node.center.dy) : 1.0;
    final shown = reveal >= 0.5;
    final settle = ((reveal - 0.5) * 2).clamp(0.0, 1.0);
    final bump = reveal >= 1 ? 1.0 : 1 + 0.16 * math.sin(math.pi * reveal);
    final current = isCurrent && shown;

    // Şu an satırının üç etiketi aynı hizada: düğümün (halkası varsa
    // halkasının) altında.
    final captionTop = top + geo.total + _nowRingPad(step) + 14;

    final tile = _PathNode(
      step: shown ? step : const KartyStep(state: KartyStepState.locked),
      width: node.width,
      scale: s,
      dimmed: !shown || node.unit.state == KartyUnitState.locked,
      // Şu anki düğüm oyunu açar; adım penceresi altındaki etikette.
      onTap: current ? onContinue : () => onStepTap(node.unit, step),
    );

    // Gelişte düğüm zaten kendi hareketini oynuyor.
    final moving = current && a == null && hopCurrent
        ? _NodeHop(scale: s, child: tile)
        : tile;

    return [
      if (current) ...[
        ..._station(node, stations.article, -1, captionTop, settle, s),
        ..._station(node, stations.review, 1, captionTop, settle, s),
      ],
      Positioned(
        left: left * s,
        top: top * s,
        child: _bump(
          bump,
          current && currentNodeKey != null
              ? TicketTarget(key: currentNodeKey, child: moving)
              : moving,
        ),
      ),
      if (shown && step.state == KartyStepState.done && step.dueCount > 0)
        Positioned(
          left: (left + node.width - 30) * s,
          top: (top - 16) * s,
          child: _fade(settle, _DueBadge(count: step.dueCount, scale: s)),
        ),
      if (current)
        Positioned(
          left: (node.center.dx - 160) * s,
          width: 320 * s,
          top: captionTop * s,
          child: _fade(
            settle,
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onStepTap(node.unit, step),
              child: _CenteredLabel(
                title: step.label,
                detail: _labelDetail(step),
                accent: true,
                scale: s,
              ),
            ),
          ),
        ),
      if (shown &&
          !isCurrent &&
          step.label.isNotEmpty &&
          step.state != KartyStepState.locked)
        Positioned(
          left: node.labelLeft ? 24 * s : (left + node.width + labelGap) * s,
          width: node.labelLeft
              ? (left - labelGap - 24) * s
              : (750 - 24 - left - node.width - labelGap) * s,
          top: (node.center.dy - 36) * s,
          child: _fade(
            settle,
            _NodeLabel(
              title: step.label,
              detail: _labelDetail(step),
              state: step.state,
              alignRight: node.labelLeft,
              scale: s,
            ),
          ),
        ),
    ];
  }

  /// Şu anki düğümün kelime halkası alttan ne kadar taşar: etiket halkanın
  /// altına iner. Yeni kelimesi olmayan adım (yalnız tekrar) halka taşımaz.
  static double _nowRingPad(KartyStep step) => step.newGoal > 0
      ? _NodeGeometry.ringGap + _NodeGeometry.ringStroke / 2
      : 0;

  /// Yan durak: şu anki düğümün solunda (Artikel) ya da sağında (Rövanş),
  /// yüzü düğümün yüzüyle aynı hizada; adı ve durumu altında, düğümün
  /// etiketiyle aynı satırda.
  List<Widget> _station(
    _NodeSpot node,
    KartyPathStation station,
    int side,
    double captionTop,
    double settle,
    double s,
  ) {
    final geo = _NodeGeometry(_PathLayout.stationWidth);
    final cx = node.center.dx + side * _PathLayout.stationOffset;
    final left = cx - _PathLayout.stationWidth / 2;
    final top = node.center.dy - geo.faceHeight / 2;
    return [
      Positioned(
        left: left * s,
        top: top * s,
        child: _fade(
          settle,
          _StationTile(
            station: station,
            scale: s,
            label: station.spokenName,
            icon: station.icon(_PathLayout.stationWidth * s),
          ),
        ),
      ),
      Positioned(
        left: (cx - 115) * s,
        width: 230 * s,
        top: captionTop * s,
        child: _fade(
          settle,
          _CenteredLabel(
            title: station.title,
            detail: station.detail,
            accent: station.enabled,
            scale: s,
          ),
        ),
      ),
    ];
  }

  /// Etiketin ikinci satırı. Açık bütün desteler bittiyse (ünite kapısı
  /// kapalı ya da içerik bitti) şu anki adım yalnız tekrarla anlatılır.
  static String _labelDetail(KartyStep step) {
    final reviews = '${step.reviewCount} tekrar';
    switch (step.state) {
      case KartyStepState.done:
        return '${step.newGoal} kelime';
      case KartyStepState.current:
        if (step.newGoal == 0) {
          return step.reviewCount > 0 ? reviews : 'Pratik';
        }
        final fresh = '${step.newCount}/${step.newGoal} yeni';
        return step.reviewCount > 0 ? '$fresh · $reviews' : fresh;
      case KartyStepState.upcoming:
        return '${step.newGoal} yeni kelime';
      case KartyStepState.locked:
        return '';
    }
  }

  List<Widget> _gate(_GateSpot gate, int index, double s) {
    final unit = gate.unit;
    final geo = _NodeGeometry(_PathLayout.gateWidth);
    final left = gate.center.dx - _PathLayout.gateWidth / 2;
    final top = gate.center.dy - geo.total / 2;
    final labelLeft = gate.center.dx + gate.halfWidth + 40;

    // Gelişte: önceki ünitenin kapısı zıplayarak onaya döner; açılan
    // ünitenin kendi kapısı fitil halkasına varana kadar kilitli görünür.
    final a = arrival;
    final arriving = a == null ? -1 : layout.unitIndex(a.unit);
    final opening = a != null && index == arriving - 1;
    final closing = a != null && index == arriving;
    final pop = opening
        ? a.gate
        : closing
            ? a.endGate(gate.top)
            : 1.0;
    final locked = unit.state == KartyUnitState.locked || (closing && pop <= 0);
    final ready =
        unit.consolidatedRatio >= unit.unlockGoal && (!opening || pop >= 0.5);
    // Kapıya ünitenin desteleri bitince varılır; o zamana kadar sıradaki
    // desteler gibi kilitli (kullanıcı, 19 Kas 2026). Halka ve etiket
    // ilerlemeyi göstermeyi sürdürür; hedefe desteler bitmeden ulaşılırsa
    // kapı doğrudan onaya döner.
    final waiting = !locked && !ready && !_decksDone(unit);
    final bump = pop >= 1 ? 1.0 : 1 + 0.16 * math.sin(math.pi * pop);

    return [
      Positioned(
        left: left * s,
        top: top * s,
        child: _bump(
          bump,
          _GateNode(
            ready: ready,
            dimmed: locked,
            waiting: waiting,
            scale: s,
            onTap: () {},
          ),
        ),
      ),
      if (!locked)
        Positioned(
          left: labelLeft * s,
          width: (750 - 24 - labelLeft) * s,
          top: (gate.center.dy - 44) * s,
          child: _NodeLabel(
            title: 'Pekiştirme',
            detail: '${unit.consolidatedCount}/${unit.wordCount} kelime',
            // Varılmamış kapı sıradaki deste gibi sönük başlıklı; varılmış
            // kapı bitmiş deste gibi açık başlık, sönük ayrıntı.
            state: waiting ? KartyStepState.upcoming : KartyStepState.done,
            alignRight: false,
            scale: s,
          ),
        ),
    ];
  }

  /// Ünitenin bütün desteleri bitti (kalan adım yalnız tekrar, [KartyStep.deck]
  /// null): patika kapıya vardı.
  static bool _decksDone(KartyUnit unit) => unit.steps.every(
        (step) => step.deck == null || step.state == KartyStepState.done,
      );
}

/// Düğüm karosunun ölçüleri: `AppIconControlButton` oranları (yüz genişliği
/// toplam yüksekliğin 84.75/89.625'i, derinlik %13.8).
class _NodeGeometry {
  const _NodeGeometry(this.width);

  final double width;

  static const _totalRatio = 89.625 / 84.75;

  /// Şu anki düğüm ile kelime halkası arasındaki boşluk.
  static const ringGap = 16.0;
  static const ringStroke = 12.0;

  double get total => width * _totalRatio;

  AppButtonGeometry get button => AppButtonStyle.resolve(
        width: width,
        totalHeight: total,
        legacyRadius: width * 0.29,
        legacyDepth: total * 0.14,
        icon: true,
      );

  double get faceHeight => button.faceHeight;
  double get depth => button.depth;
  double get radius => button.radius;
}

class _NodeSpot {
  const _NodeSpot({
    required this.unit,
    required this.step,
    required this.center,
    required this.width,
    required this.labelLeft,
  });

  final KartyUnit unit;
  final KartyStep step;

  /// Düğüm yüzünün merkezi (tasarım birimi). İz bu noktadan geçer.
  final Offset center;
  final double width;
  final bool labelLeft;
}

class _GateSpot {
  const _GateSpot({
    required this.unit,
    required this.center,
    required this.offset,
  });

  final KartyUnit unit;
  final Offset center;

  /// Halkanın kapı düğümünden uzaklığı; ünitenin kelime sayısından
  /// ([_PathLayout.ringOffsetFor]).
  final double offset;

  static const _geo = _NodeGeometry(_PathLayout.gateWidth);

  static double halfHeightFor(double offset) => _geo.total / 2 + offset;

  double get halfWidth => _PathLayout.gateWidth / 2 + offset;
  double get halfHeight => halfHeightFor(offset);

  /// Yolun halkaya girdiği ve çıktığı yükseklik.
  double get top => center.dy - halfHeight;
  double get bottom => center.dy + halfHeight;

  /// Halkanın çizgisi, ekran ölçeğinde: düğümle eş merkezli yuvarlatılmış
  /// dikdörtgen, tepe ortasından saat yönünde.
  Path ring(double s) => _clockwiseFromTop(
        Rect.fromCenter(
          center: center * s,
          width: 2 * halfWidth * s,
          height: 2 * halfHeight * s,
        ),
        (_geo.radius + offset) * s,
      );
}

/// Yuvarlatılmış dikdörtgen çizgi, tepe ortasından saat yönünde. Düğümü
/// saran halkalar (kelime halkası, pekiştirme halkası) düğümün biçimini
/// böyle izler.
Path _clockwiseFromTop(Rect rect, double radius) {
  final r = Radius.circular(radius);
  return Path()
    ..moveTo(rect.center.dx, rect.top)
    ..lineTo(rect.right - radius, rect.top)
    ..arcToPoint(Offset(rect.right, rect.top + radius), radius: r)
    ..lineTo(rect.right, rect.bottom - radius)
    ..arcToPoint(Offset(rect.right - radius, rect.bottom), radius: r)
    ..lineTo(rect.left + radius, rect.bottom)
    ..arcToPoint(Offset(rect.left, rect.bottom - radius), radius: r)
    ..lineTo(rect.left, rect.top + radius)
    ..arcToPoint(Offset(rect.left + radius, rect.top), radius: r)
    ..close();
}

class _HeaderSpot {
  const _HeaderSpot({required this.unit, required this.top});

  final KartyUnit unit;
  final double top;
}

enum _TrailStyle { done, ahead, locked }

class _TrailSegment {
  const _TrailSegment(
    this.from,
    this.to,
    this.style, {
    required this.unit,
    this.trimStart = _PathLayout.nodeClearance,
    this.trimEnd = _PathLayout.nodeClearance,
    this.anchorStart = false,
    this.anchorEnd = false,
    this.hideAbove,
  });

  final Offset from;
  final Offset to;
  final _TrailStyle style;

  /// Bu yükseklikten (tasarım birimi) yukarıdaki taşlar çizilmez: ilk
  /// ünitenin görünmeyen kapıdan gelen yolu kartın üstünde görünmesin.
  final double? hideAbove;

  /// Taşların ait olduğu ünitenin sırası; girişteki taşlar (önceki
  /// kapıdan ilk düğüme) da bu ünitenin.
  final int unit;

  /// Uçlarda taş konmayan pay: düğümün altına yarım taş girmesin.
  final double trimStart;
  final double trimEnd;

  /// Taşlar bu uca yaslanır: halkaya giren ve halkadan çıkan iz, halkanın
  /// taşlarına bir taş aralığında bağlansın. Yaslanmasa taşlar aralığa
  /// ortalanır ve uçta yarım aralık kadar fazladan boşluk kalabilir.
  final bool anchorStart;
  final bool anchorEnd;
}

/// Bütün konumlar tasarım biriminde (750 genişlik). Düğümler her ünitede
/// ortadan başlayan yumuşak bir S çizer; şu anki düğüm ve kapı halkası
/// fazladan boşluk alır.
class _PathLayout {
  _PathLayout._({
    required this.nodes,
    required this.gates,
    required this.headers,
    required this.segments,
    required this.height,
  });

  final List<_NodeSpot> nodes;
  final List<_GateSpot> gates;
  final List<_HeaderSpot> headers;
  final List<_TrailSegment> segments;
  final double height;

  static const centerX = 375.0;

  /// Kapının (pekiştirme halkası) yatay konumu; her ünitede aynı.
  static const gateX = centerX - 60;
  static const nodeWidth = 132.0;
  static const currentWidth = 150.0;
  static const gateWidth = 150.0;

  /// Pekiştirme halkası kapıyı sarar: yol tepeden halkaya girer, kapıyı
  /// dolaşır ve alttan çıkar. Her taş ünitenin bir kelimesi. Halka düğümün
  /// biçimini izler: eş merkezli yuvarlatılmış dikdörtgen (12 Kas 2026,
  /// kullanıcı; daire, düğmenin biçimiyle uyuşmuyordu). 16 kelimeye kadar
  /// düğümün dışından 30 birim geçer, taşlar düğüme ~20 birim kalır; kelime
  /// çoğaldıkça taş aralığı yoldakine yakın kalacak kadar açılır, 44'ü
  /// geçmez — ötesinde taşlar orantılı küçülür (bkz. `_PathPainter._paintRing`).
  /// Bir tur halka 160 birimlik noktalardı; kapıdan uzak, yoldan kopuk
  /// okunuyordu (5 Kas 2026).
  static const ringOffsetMin = 30.0;
  static const ringOffsetMax = 44.0;
  static const ringSpacing = 46.0;

  static double ringOffsetFor(int words) {
    const geo = _NodeGeometry(gateWidth);
    // Düğümün çizgisinin boyu; dışa doğru her birimde 2π uzar.
    final outline =
        2 * (gateWidth + geo.total) - (8 - 2 * math.pi) * geo.radius;
    return ((words * ringSpacing - outline) / (2 * math.pi))
        .clamp(ringOffsetMin, ringOffsetMax);
  }

  /// Yan duraklar: şu anki düğümün merkezinden bu kadar sağda ve solda;
  /// arada iki taşlık yan yol kalır. Düğümün etiketi altına iner, altındaki
  /// iz etiketi aşmak için o kadar geç başlar.
  static const stationWidth = 136.0;
  static const stationOffset = 258.0;
  static const _captionRoom = 150.0;
  static const _captionClearance = 225.0;

  /// Başlık kartının altından ilk destenin ortasına: kartın altı ile
  /// destenin üstü arası iPhone 17'de 44 pt (kullanıcı, 15 Kas 2026; 156'da
  /// 51 pt'ydi). 176 denendi, kullanıcı fazla buldu ("başlık ile ilk deste
  /// arasındaki boşluğu neden bu kadar fazla yaptın?").
  static const headerGap = 142.0;

  /// Desteler arası (15 Kas 2026'da 184'ten açıldı, kullanıcı: "patikaların
  /// aralarını biraz uzatalım").
  static const stepGap = 210.0;

  /// Kapının (pekiştirme halkası) altından sonraki ünitenin başlığına yol.
  static const gateTail = 150.0;
  static const nodeClearance = 84.0;

  /// Yol düğüme öbür düğümlerdeki kadar kala biter: sıradan destede
  /// [nodeClearance] yüzün ~24 birim üstü.
  static double get _trailGap =>
      nodeClearance - _NodeGeometry(nodeWidth).faceHeight / 2;

  /// Şu anki düğümün tepesi (kelime halkası varsa halkanın dış kenarı)
  /// yüzünün ortasından bu kadar yukarıda.
  static double _currentReach(bool ringed) =>
      _NodeGeometry(currentWidth).faceHeight / 2 +
      (ringed ? _NodeGeometry.ringGap + _NodeGeometry.ringStroke / 2 : 0);

  /// Şu anki düğüme gelen yol, öbür düğümlerdeki gibi tepesine (halkasına)
  /// ~24 birim kala biter. Halkalı düğümde pay 140'tı, yol halkanın ~50
  /// birim üstünde bitiyordu (kullanıcı, 18 Kas 2026: "patika neden
  /// desteden çok uzakta bitiyor?"); halkasız adımda 15 Kas'ta aynı sebeple
  /// düzeltilmişti ("tekrar bloğunun üstündeki ve altındaki patikalar neden
  /// bu kadar uzakta bitiyor?").
  static double _currentAbove(bool ringed) => _currentReach(ringed) + _trailGap;

  /// Ünitenin ilk destesi şu anki düğümse sıradan bir ilk desteden yalnız
  /// halkası kadar aşağıda durur: halkanın tepesi sıradan destenin yüzünün
  /// tepesine gelir, karttan inen yol da her ünitede aynı yerde biter
  /// (kullanıcı, 18 Kas 2026: "her ünitenin patika izleri aynı olmalı").
  /// Önceden ilk deste de [_currentRoom] alıyordu; Ünite 1'in ilk destesi
  /// karttan 120 birim uzak duruyor, Ünite 2'ninki yakın duruyordu.
  static double _firstCurrentRoom(bool ringed) =>
      _currentReach(ringed) - _NodeGeometry(nodeWidth).faceHeight / 2;

  /// Halkasız şu anki düğümün (yalnız tekrar adımı) altındaki iz etiketin
  /// 24 birim altından başlar. Halkanın payı ([_captionClearance]) burada
  /// boş kalıp yolu uzakta başlatıyordu (kullanıcı, 15 Kas 2026).
  static double get _ringlessBelow {
    final geo = _NodeGeometry(currentWidth);
    // Etiketin üstü `_KartyPathBody`'deki `captionTop` (halkasız); boyu
    // [_CenteredLabel]: başlık 28 × 1.1, ara 6, ayrıntı 22 × 1.25.
    const caption = 28 * 1.1 + 6 + 22 * 1.25;
    return geo.total - geo.faceHeight / 2 + 14 + caption + 24;
  }

  /// Şu anki düğüm ünitenin ilk destesi değilse önceki düğümle arasına
  /// eklenen pay; ilk destede [_firstCurrentRoom].
  static const _currentRoom = 120.0;
  static const _pattern = [0.0, 140.0, 15.0, -125.0, -45.0, 110.0, 20.0];

  /// Kısa ünitede desteler arasına ve son desteden kapıya eklenen pay.
  ///
  /// Koşul: ilk deste yapışan başlık kartının altına yarısı girene kadar
  /// sonraki ünitenin başlığı ekrana girmez; ünite baştan sona görünürken
  /// ikinci ünite görünmez. Ünitenin başlığı tepedeyken ölçülen kaydırma o
  /// ana kadar en çok "ilk destenin ortası − kartın boyu" olur; o konumda
  /// sonraki başlık ekranın dibinde kalmalı.
  ///
  /// Önce iki eşik denendi, ikisi de yetmedi (15 Kas 2026, simulator):
  /// · "kaydırma tepedeyken sonraki başlık ekranın 72 birim altında":
  ///   liste ~45 pt aşağıda durunca sonraki başlık alttan görünüyordu.
  /// · "ilk destenin tepesi yapışan başlığa değene kadar": yapışan başlığın
  ///   altındaki 18 birimlik pay saydam, eşik oraya konunca deste karta
  ///   değmeden sonraki başlık ~8 pt göründü. Göz karta biraz girmiş desteyi
  ///   de "ünite baştan sona görünüyor" diye okuyor, bu yüzden yarısı.
  ///
  /// Başlık → ilk deste aralığına pay konmaz: ikisini birlikte kaydırır,
  /// koşula katkısı olmaz; kullanıcı da desteler arasının açılmasını istedi.
  /// Destesiz ünitede pay başlık → kapı aralığına bölünür, sonraki başlık
  /// kaydırma tepedeyken ekranın 72 birim altında kalır.
  static double _extraGap(KartyUnit unit, double viewport) {
    final natural = _naturalSpan(unit);
    if (unit.steps.isEmpty) {
      return math.max(0.0, (viewport + 72 - natural) / 2);
    }
    final first = unit.steps.first;
    final firstCurrent = first.state == KartyStepState.current;
    // İlk destenin görünen ortası (yüz + kalınlık bandı; düğümün konumu
    // yüzün ortası), başlık kartının alt kenarından.
    final firstBelowCard = headerGap +
        (firstCurrent ? _firstCurrentRoom(first.newGoal > 0) : 0) +
        _NodeGeometry(firstCurrent ? currentWidth : nodeWidth).depth / 2;
    return math.max(
      0.0,
      (viewport + firstBelowCard - natural) / unit.steps.length,
    );
  }

  /// Ünitenin pay eklenmeden boyu: başlığın tepesinden kapıdan sonraki yolun
  /// sonuna (sonraki başlığın tepesi). [compute]'taki adımların aynısı.
  static double _naturalSpan(KartyUnit unit) {
    var y = KartyUnitHeader.height + headerGap;
    var previousCurrent = false;
    for (var i = 0; i < unit.steps.length; i++) {
      final current = unit.steps[i].state == KartyStepState.current;
      if (i > 0) {
        y += stepGap +
            (current ? _currentRoom : 0) +
            (previousCurrent ? 26 + _captionRoom : 0);
      } else if (current) {
        y += _firstCurrentRoom(unit.steps[i].newGoal > 0);
      }
      previousCurrent = current;
    }
    final half = _GateSpot.halfHeightFor(ringOffsetFor(unit.wordCount));
    final gateCenter =
        y + 196 + half + (previousCurrent ? 40 + _captionRoom : 0);
    return gateCenter + half + gateTail;
  }

  _NodeSpot? get current {
    for (final node in nodes) {
      if (node.step.state == KartyStepState.current) return node;
    }
    return null;
  }

  /// Ünitenin listedeki konumu (başlık ve kapı listeleri aynı sırada);
  /// yoksa -1.
  int unitIndex(int number) =>
      headers.indexWhere((header) => header.unit.number == number);

  /// [minUnitSpan]: patika alanının boyu (tasarım birimi). Bir ünite baştan
  /// sona görünürken sonraki ünitenin başlığı ekrana girmez (kullanıcı,
  /// 15 Kas 2026: iki desteli Ünite 1'in altında Ünite 2'nin başlığı
  /// görünüyordu). Kısa ünitede eksik boy **desteler arasına** ve son
  /// desteden kapıya eşit dağılır ([_extraGap]); kapıdan sonraki yol uzamaz.
  /// İlk denemede pay kapıdan sonraki yola konmuştu, kullanıcı:
  /// "pekiştirmenin sonrasını uzatmışsın, kötü duruyor; desteler arası
  /// mesafeyi uzatsan daha iyi olur".
  static _PathLayout compute(
    KartyPathData data, {
    required KartyPathStations stations,
    double minUnitSpan = 0,
  }) {
    final nodes = <_NodeSpot>[];
    final gates = <_GateSpot>[];
    final headers = <_HeaderSpot>[];
    final segments = <_TrailSegment>[];

    var y = 0.0;
    Offset? previousExit;

    for (var u = 0; u < data.units.length; u++) {
      final unit = data.units[u];
      final locked = unit.state == KartyUnitState.locked;

      // Her ünitenin başlığı yolun içinde; kaydırınca üste yapışan da bu.
      if (u == 0) y = 12;
      headers.add(_HeaderSpot(unit: unit, top: y));
      final hasNext = u + 1 < data.units.length;
      final extra =
          hasNext && minUnitSpan > 0 ? _extraGap(unit, minUnitSpan) : 0.0;
      y +=
          KartyUnitHeader.height + headerGap + (unit.steps.isEmpty ? extra : 0);

      final points = <Offset>[];
      var currentIndex = -1;
      var previousCurrent = false;
      for (var i = 0; i < unit.steps.length; i++) {
        final step = unit.steps[i];
        final current = step.state == KartyStepState.current;
        if (i > 0) {
          y += stepGap +
              extra +
              (current ? _currentRoom : 0) +
              (previousCurrent ? 26 + _captionRoom : 0);
        } else if (current) {
          y += _firstCurrentRoom(step.newGoal > 0);
        }
        // Şu anki düğüm ortada: iki yanında durak var. İlk deste de ortada
        // ([_pattern] sıfırla başlar): karttan inen yol her ünitede aynı.
        final x = current ? centerX : centerX + _pattern[i % _pattern.length];
        final center = Offset(x, y);
        // Etiket geniş tarafta: düğüm sağa kıvrıldıysa solunda.
        nodes.add(_NodeSpot(
          unit: unit,
          step: step,
          center: center,
          width: current ? currentWidth : nodeWidth,
          labelLeft: x > centerX,
        ));
        points.add(center);
        if (current) currentIndex = i;
        previousCurrent = current;
      }

      final offset = ringOffsetFor(unit.wordCount);
      final gateCenter = Offset(
        gateX,
        y +
            196 +
            extra +
            _GateSpot.halfHeightFor(offset) +
            (previousCurrent ? 40 + _captionRoom : 0),
      );
      final gate = _GateSpot(unit: unit, center: gateCenter, offset: offset);
      gates.add(gate);
      final ringTop = Offset(gateCenter.dx, gate.top);
      final ringBottom = Offset(gateCenter.dx, gate.bottom);

      // Taşın rengi vardığı adımdan: geçilmiş yol (tamamlanan ya da şu anki
      // düğümüne varan) yeşil. Bir tur ünitenin durumuna bağlanmıştı; eski
      // dönemde öğrenilmiş, açık ama güncel olmayan ünitenin yeşil düğümleri
      // lacivert taşlarla birbirine bağlanıyordu.
      _TrailStyle styleTo(int i) {
        if (locked) return _TrailStyle.locked;
        final state = unit.steps[i].state;
        return state == KartyStepState.done || state == KartyStepState.current
            ? _TrailStyle.done
            : _TrailStyle.ahead;
      }

      // Şu anki düğümün çevresinde kelime halkası var; gelen iz halkaya
      // öbür düğümlerdeki kadar kala biter ([_currentAbove]). Etiketi
      // altında: aşağı inen iz etiketten sonra başlar. Halkasız adım (yalnız
      // tekrar) kendi payını kullanır ([_ringlessBelow]).
      final ringless =
          currentIndex >= 0 && unit.steps[currentIndex].newGoal <= 0;
      double clearance(int i) =>
          i != currentIndex ? nodeClearance : _currentAbove(!ringless);
      double clearanceBelow(int i) => i != currentIndex
          ? nodeClearance
          : ringless
              ? _ringlessBelow
              : _captionClearance;

      // Önceki ünitenin halkasından bu ünitenin ilk düğümüne; başlığın
      // arkasından geçer, kartın altından çıkar. İlk ünitenin önünde kapı
      // yok: yol aynı yerden, başlığın [gateTail] kadar üstündeki görünmeyen
      // bir kapıdan gelir ve kartın üstüne düşen taşları çizilmez. Böylece
      // kart ile ilk deste arasındaki yol her ünitede taşı taşına aynı
      // (kullanıcı, 16 Kas 2026: "100 tane de ünite olabilir, hepsinin aynı
      // şekilde ilerlemeli patikaları").
      if (points.isNotEmpty) {
        final header = headers.last;
        // Yol sıradan bir ilk destenin ortasına varır: ilk deste şu anki
        // düğüm olsa da (halkası kadar aşağıda) eğri ve taşlar aynı kalır.
        final landing = Offset(
          points.first.dx,
          header.top + KartyUnitHeader.height + headerGap,
        );
        segments.add(_TrailSegment(
          previousExit ?? Offset(gateX, header.top - gateTail),
          landing,
          styleTo(0),
          unit: unit.number,
          trimStart: 26,
          trimEnd: nodeClearance,
          anchorStart: true,
          // Taşın yarısı kartın tepesinden taşmasın: bir taş boyu aşağısı.
          hideAbove: previousExit == null
              ? header.top + _PathPainter._stoneLength
              : null,
        ));
      }
      for (var i = 0; i + 1 < points.length; i++) {
        segments.add(_TrailSegment(
          points[i],
          points[i + 1],
          styleTo(i + 1),
          unit: unit.number,
          trimStart: clearanceBelow(i),
          trimEnd: clearance(i + 1),
        ));
      }
      if (currentIndex >= 0) {
        // Yan yollar: şu anki düğümden iki yana, durağa kadar iki taş.
        // Açık durağa giden yol lacivert (yürünebilir), kapalıya giden koyu.
        final c = points[currentIndex];
        final ring = currentWidth / 2 +
            (unit.steps[currentIndex].newGoal > 0
                ? _NodeGeometry.ringGap + _NodeGeometry.ringStroke / 2
                : 8);
        const reach = stationOffset - stationWidth / 2;
        for (final (side, open) in [
          (-1.0, stations.article.enabled),
          (1.0, stations.review.enabled),
        ]) {
          segments.add(_TrailSegment(
            c + Offset(side * ring, 0),
            c + Offset(side * reach, 0),
            open && !locked ? _TrailStyle.ahead : _TrailStyle.locked,
            unit: unit.number,
            trimStart: 10,
            trimEnd: 10,
          ));
        }
      }
      if (points.isNotEmpty) {
        // Kapıya giden taşlar ancak ünitenin bütün adımları geçildiyse yeşil.
        final finished = unit.steps.last.state == KartyStepState.done;
        segments.add(_TrailSegment(
          points.last,
          ringTop,
          locked
              ? _TrailStyle.locked
              : finished
                  ? _TrailStyle.done
                  : _TrailStyle.ahead,
          unit: unit.number,
          trimStart: clearanceBelow(points.length - 1),
          trimEnd: 26,
          anchorEnd: true,
        ));
      }

      previousExit = ringBottom;
      // Kapıdan sonraki ünitenin başlığına sabit yol; kısa ünitede eksik boy
      // yukarıda desteler arasına dağıtıldı ([_extraGap]).
      y = ringBottom.dy + gateTail;
    }

    return _PathLayout._(
      nodes: nodes,
      gates: gates,
      headers: headers,
      segments: segments,
      height: y + 120,
    );
  }
}

double _phase(double t, double begin, double end,
        [Curve curve = Curves.linear]) =>
    curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

// Geliş dışında sarmalayıcı yok: patikanın olağan ağacı aynı kalır.
Widget _fade(double opacity, Widget child) =>
    opacity >= 1 ? child : Opacity(opacity: opacity, child: child);

Widget _bump(double scale, Widget child) =>
    scale == 1 ? child : Transform.scale(scale: scale, child: child);

/// Yeni açılan ünitenin patikaya gelişinin o anki hâli. Kamera üniteye
/// vardıktan sonra tek zaman çizelgesiyle (0–1) oynar:
///
/// | Aralık | Ne olur |
/// |---|---|
/// | 0.00–0.16 | Önceki ünitenin kapısı zıplayarak onaya döner |
/// | 0.06–0.28 | Fitil kapıdan başlığa iner; yanan taş kremle parlar, asıl rengine söner |
/// | 0.28–0.66 | Başlığın kilidi sallanır, açılır ve düşer; renk kilidin yerinden yayılır |
/// | 0.60–1.00 | Fitil düğümlere iner; vardığı düğüm zıplayarak açılır, en sonda ünitenin kapısı |
///
/// Fitil yükseklikle ilerler: patika hep aşağı aktığı için "fitilin
/// üstündeki taşlar yandı" demek yeterli, yol boyu uzunluk ölçmek
/// gerekmiyor. Ölçüler tasarım biriminde.
class _Arrival {
  const _Arrival._({
    required this.unit,
    required this.t,
    required this.fuseY,
    required this.gate,
    required this.header,
  });

  final int unit;
  final double t;

  /// Fitilin vardığı yükseklik.
  final double fuseY;

  /// Önceki ünitenin kapısının onaya dönüşü (0–1).
  final double gate;

  /// Başlığın açılışı (0–1).
  final double header;

  static _Arrival? of(_PathLayout layout, int unit, double t) {
    final index = layout.unitIndex(unit);
    if (index < 0) return null;
    final head = layout.headers[index];
    final start = index > 0 ? layout.gates[index - 1].bottom : head.top;
    final headerBottom = head.top + KartyUnitHeader.height;
    final end = layout.gates[index].top;
    double lerp(double from, double to, double x) => from + (to - from) * x;
    final fuseY = t < 0.06
        ? start
        : t < 0.28
            ? lerp(start, head.top, Curves.easeIn.transform((t - 0.06) / 0.22))
            : t < 0.60
                ? lerp(head.top, headerBottom, (t - 0.28) / 0.32)
                : lerp(
                    headerBottom,
                    end + 60,
                    Curves.easeInOut.transform(
                      ((t - 0.60) / 0.40).clamp(0.0, 1.0),
                    ),
                  );
    return _Arrival._(
      unit: unit,
      t: t,
      fuseY: fuseY,
      gate: _phase(t, 0, 0.16),
      header: _phase(t, 0.28, 0.66),
    );
  }

  bool reached(double y) => y <= fuseY;

  /// Fitilin ucundaki parıltı: yeni yanan taş kremle parlar, 90 birimde
  /// asıl rengine söner; geliş biterken parıltı kalmaz.
  double glow(double y) =>
      (1 - (fuseY - y) / 90).clamp(0.0, 1.0) * (1 - _phase(t, 0.90, 1));

  /// Düğümün açılışı: fitil merkezine 70 birim kala başlar, 70 birim
  /// geçince biter.
  double nodeT(double y) => ((fuseY - (y - 70)) / 140).clamp(0.0, 1.0);

  /// Açılan ünitenin kendi kapısı: fitil halkaya varınca zıplayarak açılır.
  double endGate(double ringTop) => ((fuseY - ringTop) / 60).clamp(0.0, 1.0);
}

/// Taşlar, kapı halkaları, şu anki destenin kelime halkası ve yıldızlar.
///
/// İz düz bir şerit değil **basamak taşları**: her taş §2.5'teki gibi koyu
/// kalınlık bandının üstünde tombul bir parça. Yol kapıyı aynı taşlarla
/// sarar; halkadaki her taş ünitenin bir kelimesi, pekişen kelime kadar taş
/// yeşil yanar.
class _PathPainter extends CustomPainter {
  _PathPainter({required this.layout, required this.scale, this.arrival});

  final _PathLayout layout;
  final double scale;
  final _Arrival? arrival;

  // Yoldaki taş: iz yönünde uzanan tombul kapsül.
  static const _stoneLength = 30.0;
  static const _stoneWidth = 21.0;
  static const _stoneSpacing = 50.0;
  static const _stoneDepth = 6.0;

  static (Color, Color) _colors(_TrailStyle style) => switch (style) {
        _TrailStyle.done => (_C.green, _C.greenDepth),
        _TrailStyle.ahead => (_C.raised, _C.panel),
        _TrailStyle.locked => (_C.tile, _C.base),
      };

  @override
  void paint(Canvas canvas, Size size) {
    final s = scale;
    _paintStars(canvas, size);

    // Önce bütün kalınlık bantları, sonra yüzler: yan yana iki taşta birinin
    // bandı ötekinin yüzüne binmesin.
    // Gelişte açılan ünitenin taşları fitil varana kadar kilitli renkte;
    // fitilin ucundaki taşlar kremle parlar.
    final a = arrival;
    final stones = <(RRect, _TrailStyle, double, double)>[];
    for (final segment in layout.segments) {
      final path = _curve(segment.from * s, segment.to * s);
      for (final metric in path.computeMetrics()) {
        for (final (center, angle) in _stonesAlong(metric, segment)) {
          final y = center.dy / s;
          final hidden = segment.hideAbove;
          if (hidden != null && y < hidden) continue;
          final lit = a == null || segment.unit != a.unit || a.reached(y);
          stones.add((
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: _stoneLength * s,
                height: _stoneWidth * s,
              ),
              Radius.circular(_stoneWidth * s / 2),
            ).shift(center),
            lit ? segment.style : _TrailStyle.locked,
            angle,
            a != null && segment.unit == a.unit && lit ? a.glow(y) : 0.0,
          ));
        }
      }
    }
    for (final pass in [0, 1]) {
      for (final (stone, style, angle, glow) in stones) {
        final (face, depth) = _colors(style);
        final c = stone.center;
        canvas.save();
        canvas.translate(c.dx, c.dy + (pass == 0 ? _stoneDepth * s : 0));
        canvas.rotate(angle);
        canvas.drawRRect(
          stone.shift(-c),
          Paint()
            ..color = pass == 0
                ? depth
                : glow > 0
                    ? Color.lerp(face, _C.cream, glow)!
                    : face,
        );
        canvas.restore();
      }
    }
    // Açılan ünitenin kendi halkası fitil varana kadar kilitli.
    final arriving = a == null ? -1 : layout.unitIndex(a.unit);
    bool held(int index, _GateSpot gate) =>
        a != null && index == arriving && !a.reached(gate.top);
    for (final (i, gate) in layout.gates.indexed) {
      _paintRing(canvas, gate, locked: held(i, gate));
    }

    for (final (i, gate) in layout.gates.indexed) {
      if (gate.unit.state != KartyUnitState.locked && !held(i, gate)) {
        _paintGoalMark(canvas, gate);
      }
    }
    final current = layout.current;
    // Yeni kelimesi olmayan gün (yalnız tekrar) halka taşımaz; gelişte
    // düğümü açılmadan da çizilmez.
    final currentHidden = current != null &&
        a != null &&
        a.unit == current.unit.number &&
        a.nodeT(current.center.dy) < 1;
    if (current != null && current.step.newGoal > 0 && !currentHidden) {
      _paintWordRing(canvas, current);
    }
  }

  /// Düğümden düğüme dikey teğetli yumuşak S.
  Path _curve(Offset a, Offset b) {
    final dy = (b.dy - a.dy) * 0.5;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx, a.dy + dy, b.dx, b.dy - dy, b.dx, b.dy);
  }

  /// Düğümlerin arasında eşit aralıklı taşlar: merkezi ve iz yönündeki açısı.
  Iterable<(Offset, double)> _stonesAlong(
    ui.PathMetric metric,
    _TrailSegment segment,
  ) sync* {
    final s = scale;
    final start = segment.trimStart * s;
    final usable = metric.length - start - segment.trimEnd * s;
    if (usable <= 0) return;
    final spacing = _stoneSpacing * s;
    final count = (usable / spacing).floor() + 1;
    final slack = usable - (count - 1) * spacing;
    final first = start +
        (segment.anchorStart
            ? 0
            : segment.anchorEnd
                ? slack
                : slack / 2);
    for (var i = 0; i < count; i++) {
      final tangent = metric.getTangentForOffset(first + i * spacing);
      if (tangent == null) continue;
      yield (
        tangent.position,
        math.atan2(tangent.vector.dy, tangent.vector.dx),
      );
    }
  }

  /// Kapı halkası: tepeden saat yönünde, kelime başına bir taş. Taşlar
  /// yoldakilerle aynı kapsül ve halkaya teğet; iz kapıya girip onu
  /// dolaşıyor gibi okunur. Pekişen kelime kadar taş yeşil yanar.
  void _paintRing(Canvas canvas, _GateSpot gate, {bool locked = false}) {
    final s = scale;
    final unit = gate.unit;
    final n = math.max(1, unit.wordCount);
    final metric = gate.ring(s).computeMetrics().first;
    final spacing = metric.length / n;
    // Halka büyüyemeyince taş yoldakinin oranlarıyla küçülür: boy aralığın
    // %65'i, en boyun %70'i, kalınlık bandı enle birlikte. 16 kelimede taş
    // yoldakiyle aynı.
    final length = math.min(_stoneLength, spacing / s * 0.65);
    final width = length * _stoneWidth / _stoneLength;
    final band = _stoneDepth * width / _stoneWidth;
    final stone = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: length * s,
        height: width * s,
      ),
      Radius.circular(width * s / 2),
    );
    _TrailStyle style(int i) => locked || unit.state == KartyUnitState.locked
        ? _TrailStyle.locked
        : i < unit.consolidatedCount
            ? _TrailStyle.done
            : _TrailStyle.ahead;
    final places = [
      for (var i = 0; i < n; i++)
        metric.getTangentForOffset((i + 0.5) * spacing),
    ];
    for (final pass in [0, 1]) {
      for (final (i, place) in places.indexed) {
        if (place == null) continue;
        final (face, depth) = _colors(style(i));
        canvas.save();
        canvas.translate(
          place.position.dx,
          place.position.dy + (pass == 0 ? band * s : 0),
        );
        canvas.rotate(math.atan2(place.vector.dy, place.vector.dx));
        canvas.drawRRect(stone, Paint()..color = pass == 0 ? depth : face);
        canvas.restore();
      }
    }
  }

  /// Ünite hedefinin çentiği ve yüzdesi (halkanın dışında).
  ///
  /// Çentik iki taşın arasına düşer: hedefe varmak için yanması gereken son
  /// taşın hemen ardına (16 kelimede %80 → 13. taştan sonra).
  void _paintGoalMark(Canvas canvas, _GateSpot gate) {
    final s = scale;
    final unit = gate.unit;
    final n = math.max(1, unit.wordCount);
    final needed = (unit.unlockGoal * n).ceil().clamp(1, n);
    final metric = gate.ring(s).computeMetrics().first;
    final place = metric.getTangentForOffset(metric.length * needed / n);
    if (place == null) return;
    // Çizgi saat yönünde döndüğü için dışarısı gidiş yönünün solu.
    final dir = Offset(place.vector.dy, -place.vector.dx);
    final p = place.position;
    final inner = p - dir * (20 * s);
    final outer = p + dir * (20 * s);
    for (final (shift, color) in [
      (Offset(0, 4 * s), _C.rimBottom),
      (Offset.zero, Colors.white),
    ]) {
      canvas.drawLine(
        inner + shift,
        outer + shift,
        Paint()
          ..color = color
          ..strokeWidth = 7 * s
          ..strokeCap = StrokeCap.round,
      );
    }
    final label = TextPainter(
      text: TextSpan(
        text: '%${(unit.unlockGoal * 100).round()}',
        style: TextStyle(
          color: _C.value,
          fontSize: 22 * s,
          fontWeight: AppTypography.number,
          fontFamily: AppTypography.family,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final anchor = p + dir * (48 * s);
    label.paint(canvas, anchor - Offset(label.width / 2, label.height / 2));
  }

  /// Şu anki düğümü saran 8 parçalı halka: her parça destenin bir
  /// kelimesi. Tanışılanlar mavi.
  void _paintWordRing(Canvas canvas, _NodeSpot node) {
    final s = scale;
    final step = node.step;
    final geo = _NodeGeometry(node.width);
    const gap = _NodeGeometry.ringGap;
    final top = node.center.dy - geo.faceHeight / 2;
    final rect = Rect.fromLTWH(
      (node.center.dx - node.width / 2 - gap) * s,
      (top - gap) * s,
      (node.width + 2 * gap) * s,
      (geo.total + 2 * gap) * s,
    );
    // Yol tepe ortasından başlayıp saat yönünde döner: ilk parça destenin
    // ilk kelimesi.
    final ring = _clockwiseFromTop(rect, (geo.radius + gap) * s);
    final metric = ring.computeMetrics().first;
    final n = math.max(1, step.newGoal);
    final length = metric.length / n;
    final cut = 16 * s;
    for (var i = 0; i < n; i++) {
      final piece =
          metric.extractPath(i * length + cut / 2, (i + 1) * length - cut / 2);
      canvas.drawPath(
        piece,
        Paint()
          ..color = i < step.newCount ? _C.accent : _C.raised
          ..style = PaintingStyle.stroke
          ..strokeWidth = _NodeGeometry.ringStroke * s
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Yıldız düğüm ve etiket sırasına düşmesin: yazının altında kalan nokta
  /// leke gibi okunuyor.
  bool _busy(Offset p) {
    final u = p / scale;
    for (final node in layout.nodes) {
      final d = u - node.center;
      // Şu anki düğümde çevrede halka, iki yanında duraklar, altında
      // etiketler.
      final current = node.step.state == KartyStepState.current;
      if (d.dx.abs() < (current ? 375 : 300) &&
          d.dy > (current ? -250 : -90) &&
          d.dy < (current ? 250 : 90)) {
        return true;
      }
    }
    for (final gate in layout.gates) {
      final d = u - gate.center;
      if (d.dx.abs() < 440 && d.dy.abs() < gate.halfHeight + 40) {
        return true;
      }
    }
    for (final header in layout.headers) {
      if (u.dy > header.top - 40 &&
          u.dy < header.top + KartyUnitHeader.height + 30) {
        return true;
      }
    }
    return false;
  }

  void _paintStars(Canvas canvas, Size size) {
    final s = scale;
    final random = math.Random(7);
    final dot = Paint();
    for (var i = 0; i < (size.height / (26 * s)).round(); i++) {
      final p = Offset(
          random.nextDouble() * size.width, random.nextDouble() * size.height);
      final r = (1.4 + random.nextDouble() * 1.8) * s;
      final alpha = 0.10 + random.nextDouble() * 0.22;
      if (_busy(p)) continue;
      dot.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(p, r, dot);
    }
    // Seyrek dört köşeli parıltılar (lig sahnesindeki yıldızların dili).
    final sparkle = Paint()..color = _C.value.withValues(alpha: 0.22);
    for (var i = 0; i < (size.height / (190 * s)).round(); i++) {
      final c = Offset(
          random.nextDouble() * size.width, random.nextDouble() * size.height);
      final r = (9 + random.nextDouble() * 6) * s;
      if (_busy(c)) continue;
      final w = r * 0.28;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - r)
          ..quadraticBezierTo(c.dx + w * 0.4, c.dy - w * 0.4, c.dx + r, c.dy)
          ..quadraticBezierTo(c.dx + w * 0.4, c.dy + w * 0.4, c.dx, c.dy + r)
          ..quadraticBezierTo(c.dx - w * 0.4, c.dy + w * 0.4, c.dx - r, c.dy)
          ..quadraticBezierTo(c.dx - w * 0.4, c.dy - w * 0.4, c.dx, c.dy - r)
          ..close(),
        sparkle,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.scale != scale ||
      oldDelegate.arrival != null ||
      arrival != null;
}

// ---------------------------------------------------------------------------
// Düğüm, kapı, etiketler
// ---------------------------------------------------------------------------

class _PathNode extends StatelessWidget {
  const _PathNode({
    required this.step,
    required this.width,
    required this.scale,
    required this.onTap,
    this.dimmed = false,
  });

  final KartyStep step;
  final double width;
  final double scale;
  final VoidCallback onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final (face, depth) = switch (step.state) {
      KartyStepState.done => (_C.green, _C.greenDepth),
      KartyStepState.current => (_C.accent, _C.accentDepth),
      _ when dimmed => (_C.tile, _C.base),
      _ => (_C.raised, _C.panel),
    };
    final lit = step.state == KartyStepState.done ||
        step.state == KartyStepState.current;

    return _NodeTile(
      width: width,
      scale: scale,
      face: face,
      depth: depth,
      label: switch (step.state) {
        KartyStepState.done => '${step.label}, tamamlandı',
        KartyStepState.current => '${step.label}, ${_actionOf(step).spoken}',
        _ => 'Sıradaki deste',
      },
      onTap: onTap,
      // Sırası gelmemiş deste şimşek yerine kilit taşır (19 Kas 2026,
      // kullanıcı): ünite başlığındaki kilidin aynısı. Kilitli ünitede
      // patikayla birlikte söner.
      child: lit
          ? QuestIcon(questKey: 'correct_five', size: width * 0.56 * scale)
          : _ToneIcon(
              tone: dimmed ? _IconTone.muted : _IconTone.lit,
              child: KartyLockMark(size: width * _lockShare * scale),
            ),
    );
  }

  /// Kilidin düğüm genişliğine oranı: kilit şimşekten kütleli, aynı boyda
  /// ağır durur.
  static const _lockShare = 0.5;
}

/// Bugün henüz oynanmadıysa şu anki düğüm, Görevler'deki alınabilir ödülle
/// aynı aralıklı zıplamayla "buraya dokun" der; oynandıktan sonra durur ki
/// ana ekranda gürültüye dönüşmesin. Yüz ve kalınlık bandı birlikte kalkar;
/// halka düğümün yuvası, yerinde kalır.
class _NodeHop extends StatefulWidget {
  const _NodeHop({required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  State<_NodeHop> createState() => _NodeHopState();
}

class _NodeHopState extends State<_NodeHop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: HopMotion.duration,
  );
  bool _pressed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _hop
        ..stop()
        ..value = 0;
    } else if (!_hop.isAnimating) {
      _hop.repeat();
    }
  }

  @override
  void dispose() {
    _hop.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    // Yalnız düğüm yeniden çizilsin, koca patika tuvali değil.
    return RepaintBoundary(
      child: Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: AnimatedBuilder(
          animation: _hop,
          child: widget.child,
          builder: (context, child) {
            // Basılıyken zıplama durur: o an kullanıcının hareketi baskın.
            final hop =
                _pressed ? (lift: 0.0, squash: 0.0) : HopMotion.at(_hop.value);
            return Transform.translate(
              offset: Offset(0, -hop.lift * HopMotion.height * widget.scale),
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: HopMotion.squash(hop.squash),
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Ünite sonu: pekiştirme halkasının ortasındaki karo. İkon Rövanş'ın ve
/// tekrar görevinin yeşil dönüş oku — tekrar burada da aynı simge.
class _GateNode extends StatelessWidget {
  const _GateNode({
    required this.ready,
    required this.dimmed,
    required this.scale,
    required this.onTap,
    this.waiting = false,
  });

  final bool ready;
  final bool dimmed;

  /// Ünitenin desteleri bitmedi: kapıya henüz varılmadı.
  final bool waiting;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const width = _PathLayout.gateWidth;
    return _NodeTile(
      width: width,
      scale: scale,
      face: ready ? _C.green : (dimmed ? _C.tile : _C.raised),
      depth: ready ? _C.greenDepth : (dimmed ? _C.base : _C.panel),
      label: ready ? 'Ünite sonu, hedefe ulaşıldı' : 'Ünite sonu, pekiştirme',
      onTap: onTap,
      // Hedefe ulaşan kapı geçilen düğümler gibi yeşile döner; yeşil dönüş oku
      // yeşil yüzde kaybolacağı için yerine beyaz onay.
      child: ready
          ? KartyControlMark(
              glyph: KartyControlGlyph.check,
              size: width * 0.42 * scale,
            )
          // Varılmamış kapı destelerdeki gibi yalnız kilit taşır (kullanıcı,
          // 19 Kas 2026); kilitli ünitede patikayla birlikte söner.
          : dimmed || waiting
              ? _ToneIcon(
                  tone: dimmed ? _IconTone.muted : _IconTone.lit,
                  child: KartyLockMark(
                    size: width * _PathNode._lockShare * scale,
                  ),
                )
              : QuestIcon(questKey: 'review_two', size: width * 0.6 * scale),
    );
  }
}

class _NodeTile extends StatelessWidget {
  const _NodeTile({
    required this.width,
    required this.scale,
    required this.face,
    required this.depth,
    required this.label,
    required this.onTap,
    required this.child,
    this.glossSpot = true,
  });

  final double width;
  final double scale;
  final Color face;
  final Color depth;
  final String label;
  final VoidCallback onTap;
  final Widget child;

  /// Sol üstteki çizgi parlaması; yan duraklarda kapalı.
  final bool glossSpot;

  @override
  Widget build(BuildContext context) {
    final geo = _NodeGeometry(width);
    final s = scale;
    return Semantics(
      label: label,
      child: DepthPressableButton(
        width: width * s,
        height: (geo.total - geo.depth) * s,
        radius: width * 0.29 * s,
        shadowOffset: geo.depth * s,
        backgroundColor: face,
        shadowColor: depth,
        fontSize: 0,
        onPressed: onTap,
        child: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: FaceGlossPainter(
                    radius: geo.radius * s,
                    spot: glossSpot,
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

enum _IconTone { lit, muted, locked }

/// Simgeyi lacivert yüzde söndürür, tonlar orantılı iner (iki tonlu yapı
/// korunur): kilitli ünitenin destelerindeki ve kapısındaki kilit (`muted`),
/// kapalı durağın simgesi (`locked`).
class _ToneIcon extends StatelessWidget {
  const _ToneIcon({required this.tone, required this.child});

  final _IconTone tone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final (r, g, b) = switch (tone) {
      _IconTone.lit => (1.0, 1.0, 1.0),
      _IconTone.muted => (0.56, 0.63, 0.71),
      _IconTone.locked => (0.33, 0.39, 0.5),
    };
    if (tone == _IconTone.lit) return child;
    return ColorFiltered(
      colorFilter: ColorFilter.matrix([
        r, 0, 0, 0, 0, //
        0, g, 0, 0, 0, //
        0, 0, b, 0, 0, //
        0, 0, 0, 1, 0,
      ]),
      child: child,
    );
  }
}

typedef _StepAction = ({String label, String spoken});

/// Şu anki adımın eylemi: başlanmamış deste BAŞLA, yarım deste DEVAM ET;
/// desteler bittiyse vadesi gelen tekrar varken TEKRAR ET, yoksa PRATİK.
_StepAction _actionOf(KartyStep step) => step.newGoal == 0
    ? step.reviewCount > 0
        ? (label: 'TEKRAR ET', spoken: 'Tekrar et')
        : (label: 'PRATİK', spoken: 'Pratik yap')
    : step.newCount > 0
        ? (label: 'DEVAM ET', spoken: 'Devam et')
        : (label: 'BAŞLA', spoken: 'Başla');

class _DueBadge extends StatelessWidget {
  const _DueBadge({required this.count, required this.scale});

  final int count;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final size = 46 * scale;
    return Semantics(
      label: '$count kelime tekrar bekliyor',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _C.accent,
          shape: BoxShape.circle,
          border: Border.all(color: _C.bg, width: 5 * scale),
        ),
        alignment: Alignment.center,
        child: Text(
          '$count',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22 * scale,
            fontWeight: AppTypography.number,
            fontFamily: AppTypography.family,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Yan durağın karosu: düğümlerle aynı derinlikli karo, içinde durağın
/// simgesi. Açık durak sıradaki desteler gibi lacivert ama simgesi renkli;
/// kapalı durak koyu ve simgesi sönük. Düğümlerden farkı: sol üstteki çizgi
/// parlaması yok (16 Kas 2026, kullanıcı).
class _StationTile extends StatelessWidget {
  const _StationTile({
    required this.station,
    required this.scale,
    required this.label,
    required this.icon,
  });

  final KartyPathStation station;
  final double scale;
  final String label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final open = station.enabled;
    final tile = _NodeTile(
      width: _PathLayout.stationWidth,
      scale: s,
      face: open ? _C.raised : _C.tile,
      depth: open ? _C.panel : _C.base,
      label: open ? label : '$label, ${station.detail}',
      onTap: station.onTap ?? () {},
      glossSpot: false,
      child:
          _ToneIcon(tone: open ? _IconTone.lit : _IconTone.locked, child: icon),
    );
    final tappable = IgnorePointer(ignoring: !open, child: tile);
    final key = station.tileKey;
    return key == null ? tappable : TicketTarget(key: key, child: tappable);
  }
}

/// Şu an satırındaki etiketler: düğümün ve durakların altında, ortalı.
class _CenteredLabel extends StatelessWidget {
  const _CenteredLabel({
    required this.title,
    required this.detail,
    required this.accent,
    required this.scale,
  });

  final String title;
  final String detail;
  final bool accent;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _C.value,
            fontSize: 28 * scale,
            fontWeight: AppTypography.number,
            fontFamily: AppTypography.family,
            height: 1.1,
          ),
        ),
        if (detail.isNotEmpty) ...[
          SizedBox(height: 6 * scale),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent ? _C.accent : _C.muted,
              fontSize: 22 * scale,
              fontWeight: AppTypography.label,
              fontFamily: AppTypography.family,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }
}

class _NodeLabel extends StatelessWidget {
  const _NodeLabel({
    required this.title,
    required this.detail,
    required this.state,
    required this.alignRight,
    required this.scale,
  });

  final String title;
  final String detail;
  final KartyStepState state;
  final bool alignRight;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final quiet = state == KartyStepState.upcoming;
    final align = alignRight ? TextAlign.right : TextAlign.left;
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: align,
          style: TextStyle(
            color: quiet ? _C.muted : _C.value,
            fontSize: 28 * scale,
            fontWeight: AppTypography.number,
            fontFamily: AppTypography.family,
            height: 1.1,
          ),
        ),
        if (detail.isNotEmpty) ...[
          SizedBox(height: 6 * scale),
          Text(
            detail,
            textAlign: align,
            style: TextStyle(
              color: state == KartyStepState.current ? _C.accent : _C.muted,
              fontSize: 22 * scale,
              fontWeight: AppTypography.label,
              fontFamily: AppTypography.family,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Adım penceresi
// ---------------------------------------------------------------------------

/// Düğüme dokununca açılan pencere. Bitmiş destede kelimeler ve bugünkü
/// ustalıkları; şu anki destede tanışılanlar ve DEVAM; sıradaki destede
/// kelimeler silüet.
class KartyStepSheet extends StatelessWidget {
  const KartyStepSheet({
    super.key,
    required this.unit,
    required this.step,
    required this.scale,
    this.onContinue,
  });

  final KartyUnit unit;
  final KartyStep step;
  final double scale;
  final VoidCallback? onContinue;

  static const _visibleRows = 4;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final radius = Radius.circular(56 * s);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: _C.panel,
          borderRadius: BorderRadius.vertical(top: radius),
        ),
        padding: EdgeInsets.only(top: 10 * s),
        child: Container(
          decoration: BoxDecoration(
            color: _C.bg,
            borderRadius: BorderRadius.vertical(top: radius),
          ),
          padding: EdgeInsets.fromLTRB(36 * s, 22 * s, 36 * s, 64 * s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 96 * s,
                  height: 10 * s,
                  decoration: BoxDecoration(
                    color: _C.raised,
                    borderRadius: BorderRadius.circular(5 * s),
                  ),
                ),
              ),
              SizedBox(height: 34 * s),
              _SheetHeader(step: step, scale: s),
              SizedBox(height: 32 * s),
              ...switch (step.state) {
                KartyStepState.upcoming => _upcoming(s),
                _ => _words(s),
              },
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _words(double s) {
    final rows = step.words.take(_visibleRows).toList();
    final rest = step.words.length - rows.length;
    final current = step.state == KartyStepState.current;
    return [
      if (current && rows.isEmpty) ...[
        _Explainer(
          text: step.newGoal > 0
              ? 'Bu destenin ${step.newGoal} yeni kelimesi seni bekliyor.'
              : 'Bu ünitenin desteleri bitti. Sıradaki ünite, kelimelerin '
                  '%${(unit.unlockGoal * 100).round()}\'i pekişince açılır; '
                  'tekrarlar onları pekiştiriyor.',
          scale: s,
        ),
        SizedBox(height: 28 * s),
      ],
      for (final word in rows) ...[
        _WordRow(word: word, scale: s),
        SizedBox(height: 18 * s),
      ],
      if (rest > 0)
        Padding(
          padding: EdgeInsets.only(top: 8 * s),
          child: Text(
            '+$rest kelime daha',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _C.accent,
              fontSize: 27 * s,
              fontWeight: AppTypography.action,
              fontFamily: AppTypography.family,
            ),
          ),
        ),
      if (current && onContinue != null) ...[
        SizedBox(height: 26 * s),
        _SheetContinueButton(
          scale: s,
          action: _actionOf(step),
          onPressed: onContinue!,
        ),
      ],
    ];
  }

  /// Sıradaki deste: kelimeleri belli (deste herkes için aynı), kendisi
  /// önceki deste bitince açılır. Kelimeler silüet.
  List<Widget> _upcoming(double s) {
    return [
      _Explainer(
        text: step.deck != null && step.deck! > 1
            ? 'Deste ${step.deck! - 1} bitince açılır.'
            : 'Önceki ünite bitince açılır.',
        scale: s,
      ),
      SizedBox(height: 34 * s),
      _SectionTitle(text: 'Tanışacağın ${step.newGoal} kelime', scale: s),
      SizedBox(height: 18 * s),
      GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 18 * s,
        crossAxisSpacing: 16 * s,
        children: [
          for (var i = 0; i < step.newGoal; i++)
            _SilhouetteTile(
              image: i < step.upcoming.length ? step.upcoming[i] : null,
              scale: s,
            ),
        ],
      ),
    ];
  }
}

class _Explainer extends StatelessWidget {
  const _Explainer({required this.text, required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: _C.value,
        fontSize: 27 * scale,
        fontWeight: AppTypography.body,
        fontFamily: AppTypography.family,
        height: 1.35,
      ),
    );
  }
}

/// Şu anki destenin penceresindeki eylem: düğüme dokunmakla aynı iş.
class _SheetContinueButton extends StatelessWidget {
  const _SheetContinueButton({
    required this.scale,
    required this.action,
    required this.onPressed,
  });

  final double scale;
  final _StepAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      label: action.spoken,
      excludeSemantics: true,
      child: DepthPressableButton(
        width: 678 * s,
        height: 112 * s,
        radius: 26 * s,
        shadowOffset: 12 * s,
        backgroundColor: _C.accent,
        shadowColor: _C.accentDepth,
        fontSize: 30 * s,
        onPressed: onPressed,
        child: Center(
          child: Text(
            action.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32 * s,
              fontWeight: AppTypography.action,
              fontFamily: AppTypography.family,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.step, required this.scale});

  final KartyStep step;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final consolidated = step.words.where((word) => word.consolidated).length;
    final subtitle = switch (step.state) {
      KartyStepState.done => '${step.words.length} kelimeyle tanıştın · '
          '$consolidated\'${_suffix(consolidated)} pekişti',
      KartyStepState.current => step.newGoal == 0
          ? '${step.reviewCount} tekrar'
          : '${step.newCount}/${step.newGoal} yeni kelime · ${step.reviewCount} tekrar',
      _ => '${step.newGoal} yeni kelime',
    };

    return Row(
      children: [
        IgnorePointer(
          child: _PathNode(step: step, width: 92, scale: s, onTap: () {}),
        ),
        SizedBox(width: 26 * s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 52 * s,
                  fontWeight: AppTypography.heading,
                  fontFamily: AppTypography.displayFamily,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 6 * s),
              Text(
                subtitle,
                style: TextStyle(
                  color: _C.muted,
                  fontSize: 26 * s,
                  fontWeight: AppTypography.body,
                  fontFamily: AppTypography.family,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// "3'ü", "1'i", "2'si" — sayının okunuşuna göre belirtme eki.
  static String _suffix(int n) {
    const table = ['ı', 'i', 'si', 'ü', 'ü', 'i', 'sı', 'si', 'i', 'u'];
    return table[n % 10];
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text, required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: _C.value,
        fontSize: 28 * scale,
        fontWeight: AppTypography.label,
        fontFamily: AppTypography.family,
        height: 1.1,
      ),
    );
  }
}

/// Kelime satırı — Kelimelerim satırıyla aynı yüzey, artikel hapı ve
/// durum renkleri; ek olarak beş kutuluk ustalık noktaları.
class _WordRow extends StatelessWidget {
  const _WordRow({required this.word, required this.scale});

  final KartyWord word;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final (pill, pillDepth) = _articleColors(word.article);
    final (status, statusColor) = word.due
        ? ('Tekrar zamanı', _C.accent)
        : word.consolidated
            ? ('Pekişti', _C.green)
            : ('Öğreniliyor', _C.muted);

    return Container(
      height: 150 * s,
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(30 * s),
        border: Border.all(color: _C.panel, width: 3 * s),
        boxShadow: [BoxShadow(color: _C.panel, offset: Offset(0, 7 * s))],
      ),
      padding: EdgeInsets.all(16 * s),
      child: Row(
        children: [
          Container(
            width: 112 * s,
            height: 112 * s,
            decoration: BoxDecoration(
              color: _C.tile,
              borderRadius: BorderRadius.circular(24 * s),
            ),
            padding: EdgeInsets.all(10 * s),
            child: Image(image: word.image, fit: BoxFit.contain),
          ),
          SizedBox(width: 22 * s),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.fromLTRB(10 * s, 5 * s, 10 * s, 6 * s),
                      decoration: BoxDecoration(
                        color: pill,
                        borderRadius: BorderRadius.circular(11 * s),
                        boxShadow: [
                          BoxShadow(color: pillDepth, offset: Offset(0, 4 * s))
                        ],
                      ),
                      child: Text(
                        word.article,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23 * s,
                          fontWeight: AppTypography.label,
                          fontFamily: AppTypography.family,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: Text(
                        word.word,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38 * s,
                          fontWeight: AppTypography.word,
                          fontFamily: AppTypography.family,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18 * s),
                Row(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Container(
                        width: 20 * s,
                        height: 20 * s,
                        margin: EdgeInsets.only(right: 10 * s),
                        decoration: BoxDecoration(
                          color: i < word.box ? _C.green : _C.raised,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const Spacer(),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 23 * s,
                        fontWeight: AppTypography.label,
                        fontFamily: AppTypography.family,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

(Color, Color) _articleColors(String article) =>
    switch (article.toLowerCase()) {
      'der' => (_C.accent, _C.accentDepth),
      'die' => (const Color(0xFFF52A2A), const Color(0xFFAA1C1C)),
      _ => (const Color(0xFFFF9300), const Color(0xFFC97800)),
    };

/// Sıradaki destenin kelimesi: lacivert karoda silüet — ne olduğu sezilir,
/// kendisi deste açılınca görünür (özette aynı karo renge döner).
class _SilhouetteTile extends StatelessWidget {
  const _SilhouetteTile({required this.image, required this.scale});

  final ImageProvider? image;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      decoration: BoxDecoration(
        color: _C.tile,
        borderRadius: BorderRadius.circular(24 * s),
        boxShadow: [BoxShadow(color: _C.panel, offset: Offset(0, 6 * s))],
      ),
      padding: EdgeInsets.all(20 * s),
      child: image == null
          ? null
          : KartySilhouette(image: image!, color: _C.raised),
    );
  }
}
