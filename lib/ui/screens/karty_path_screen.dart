import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_button_style.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_icon_control_button.dart';
import 'package:lingualloop/ui/widgets/Buttons/auth_back_button.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/karty_control_glyphs.dart';
import 'package:lingualloop/ui/widgets/karty_unit_header.dart';
import 'package:lingualloop/ui/widgets/karty_unit_marks.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

/// Karty Yolu (bkz. `docs/KARTY_PATIKA.md` §8).
///
/// Aşağı akan bir patika; her ünitenin başlığı yolun içinde durur ve
/// kaydırınca görünen ünitenin başlığı üste yapışır. Her düğüm ünitenin
/// 8 kelimelik bir destesi; bir oyun bir destedir. Bitmiş desteler yeşil,
/// şu anki mavi ve kelime halkalı, sıradakiler lacivert. Düğümler uygulamanın derinlikli
/// ikon kontrolüyle aynı karo (`AppButtonStyle`). Ünitenin sonunda her
/// kelimenin bir boncuk olduğu pekiştirme halkası durur; %80'i yandığında
/// sıradaki ünite açılır. Düğüme dokununca adımın penceresi açılır.
/// Açılışta şu anki destenin düğümü ekranın ortasına gelir.
class KartyPathScreen extends StatefulWidget {
  const KartyPathScreen({
    super.key,
    required this.data,
    required this.onBack,
    required this.onContinue,
    this.onRefresh,
    this.controller,
    this.scrollToCurrent = true,
    this.arrivalUnit,
    this.playArrival = false,
    this.onArrivalDone,
    this.arrivalPreview,
  });

  final KartyPathData data;
  final VoidCallback onBack;
  final VoidCallback onContinue;
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

  /// Önizleme: gelişi bu anda (0–1) dondurur ve kamerayı üniteye götürür.
  final double? arrivalPreview;

  @override
  State<KartyPathScreen> createState() => _KartyPathScreenState();
}

class _KartyPathScreenState extends State<KartyPathScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _controller =
      widget.controller ?? ScrollController();
  late _PathLayout _layout = _PathLayout.compute(widget.data);
  late final AnimationController _arrival = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  double _scale = 1;
  int? _pinned;
  bool _centeredCurrent = false;
  bool _arriving = false;
  bool _previewPlaced = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updatePinned);
  }

  @override
  void didUpdateWidget(covariant KartyPathScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _layout = _PathLayout.compute(widget.data);
      WidgetsBinding.instance.addPostFrameCallback((_) => _updatePinned());
    }
    if (widget.playArrival && !oldWidget.playArrival) unawaited(_runArrival());
    if (widget.arrivalUnit == null && oldWidget.arrivalUnit != null) {
      _arrival.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updatePinned);
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

  void _centerCurrent() {
    final current = _layout.current;
    if (current == null || !_controller.hasClients) return;
    final position = _controller.position;
    final target =
        current.center.dy * _scale - position.viewportDimension * 0.45;
    _controller.jumpTo(target.clamp(0.0, position.maxScrollExtent));
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

          Widget scroll = SingleChildScrollView(
            controller: _controller,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: AnimatedBuilder(
              animation: _arrival,
              builder: (context, _) => _KartyPathBody(
                data: widget.data,
                layout: _layout,
                scale: scale,
                onContinue: widget.onContinue,
                onStepTap: _openStep,
                arrival: _arrivalState(),
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

          final pinned = _pinned == null ? null : _layout.headers[_pinned!];
          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      40 * scale, 18 * scale, 40 * scale, 12 * scale),
                  child: _TopBar(
                    scale: scale,
                    tickets: widget.data.tickets,
                    onBack: widget.onBack,
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child:
                            IgnorePointer(ignoring: _arriving, child: scroll),
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
                              child: ColoredBox(
                                color: _C.bg,
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                      40 * scale, 0, 40 * scale, 18 * scale),
                                  child: KartyUnitHeader(
                                    unit: pinned.unit,
                                    scale: scale,
                                    onTap: () {},
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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

  // Kart çerçevesinin malzemesi (KartyCardRimPainter): balon da aynı beyaz
  // yüzde ve aynı açık gri kalınlıkta durur.
  static const rimBottom = Color(0xFFD8DCE4);

  /// Kutlama ışığının kremi: fitilin parlayan ucu (görev ödülü reçetesi).
  static const cream = Color(0xFFFFF1DC);
}

// ---------------------------------------------------------------------------
// Üst satır ve ünite başlığı
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.scale,
    required this.tickets,
    required this.onBack,
  });

  final double scale;
  final int tickets;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppIconControlButton.outerHeightForScale(scale),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AuthBackButton(scale: scale, onPressed: onBack),
          ),
          Text(
            'Karty Yolu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 40 * scale,
              fontWeight: AppTypography.heading,
              fontFamily: AppTypography.displayFamily,
              height: 1,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              label: '$tickets bilet',
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icons/ticket.png',
                    width: 64 * scale,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 10 * scale),
                  Text(
                    '$tickets',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36 * scale,
                      fontWeight: AppTypography.number,
                      fontFamily: AppTypography.family,
                      height: 1,
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
}

// ---------------------------------------------------------------------------
// Patika
// ---------------------------------------------------------------------------

/// Patikanın kaydırılan gövdesi: taş izler, düğümler, kapılar, sonraki
/// ünitelerin başlıkları ve maskot. Patikada kart görseli yok (kullanıcı
/// kararı); kelimeler yalnız adım penceresinde. Tüm yerleşim [_PathLayout]'ta.
class _KartyPathBody extends StatelessWidget {
  const _KartyPathBody({
    required this.data,
    required this.layout,
    required this.scale,
    required this.onContinue,
    required this.onStepTap,
    this.arrival,
  });

  final KartyPathData data;
  final _PathLayout layout;
  final double scale;
  final VoidCallback onContinue;
  final void Function(KartyUnit unit, KartyStep step) onStepTap;

  /// Yeni açılan ünitenin gelişi sürüyorsa o anki hâli.
  final _Arrival? arrival;

  static const _mascotHeight = 236.0;

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
    final labelGap = isCurrent ? 50.0 : 24.0;

    // Gelişte açılan ünitenin düğümü fitil varana kadar kilitli görünür;
    // fitil geçerken zıplar ve zıplamanın tepesinde gerçek hâline döner.
    // Etiketi, balonu ve maskotu ondan sonra belirir.
    final a = arrival;
    final reveal =
        a != null && a.unit == node.unit.number ? a.nodeT(node.center.dy) : 1.0;
    final shown = reveal >= 0.5;
    final settle = ((reveal - 0.5) * 2).clamp(0.0, 1.0);
    final bump = reveal >= 1 ? 1.0 : 1 + 0.16 * math.sin(math.pi * reveal);
    final current = isCurrent && shown;

    return [
      if (current)
        Positioned(
          left: _mascotLeft(node) * s,
          top: (top + geo.total + 12 - _mascotHeight) * s,
          child: _fade(settle, _Mascot(scale: s)),
        ),
      Positioned(
        left: left * s,
        top: top * s,
        child: _bump(
          bump,
          _PathNode(
            step: shown ? step : const KartyStep(state: KartyStepState.locked),
            width: node.width,
            scale: s,
            dimmed: !shown || node.unit.state == KartyUnitState.locked,
            onTap: () => onStepTap(node.unit, step),
          ),
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
          left: (node.center.dx - 150) * s,
          width: 300 * s,
          top: (top - _NodeGeometry.ringGap - 112) * s,
          child: Center(
            child: _fade(
              settle,
              _ContinueBubble(
                scale: s,
                action: _actionOf(step),
                onTap: onContinue,
              ),
            ),
          ),
        ),
      if (shown && step.label.isNotEmpty && step.state != KartyStepState.locked)
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

  /// Maskot şu anki düğümün etiketsiz yanında durur ve ekrandan taşmaz.
  /// Yeni açılan ünitede şu anki deste ilk düğümdür ve etiketi sağa düşer; maskot
  /// hep sağda kalsaydı etiketin üstüne binerdi.
  static double _mascotLeft(_NodeSpot node) {
    final left = node.labelLeft
        ? node.center.dx + node.width / 2 + 36
        : node.center.dx - node.width / 2 - 36 - _Mascot.width;
    return left.clamp(8.0, 750 - 8 - _Mascot.width);
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
        return step.reviewCount > 0 ? '$fresh\n$reviews' : fresh;
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
    final labelLeft = gate.center.dx + _PathLayout.ringRadius + 40;

    // Gelişte: önceki ünitenin kapısı zıplayarak onaya döner; açılan
    // ünitenin kendi kapısı fitil halkasına varana kadar kilitli görünür.
    final a = arrival;
    final arriving = a == null ? -1 : layout.unitIndex(a.unit);
    final opening = a != null && index == arriving - 1;
    final closing = a != null && index == arriving;
    final pop = opening
        ? a.gate
        : closing
            ? a.endGate(gate.center.dy - _PathLayout.ringRadius)
            : 1.0;
    final locked = unit.state == KartyUnitState.locked || (closing && pop <= 0);
    final ready =
        unit.consolidatedRatio >= unit.unlockGoal && (!opening || pop >= 0.5);
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
            // Bitmiş destenin etiketiyle aynı ton: açık başlık, sönük ayrıntı.
            state: KartyStepState.done,
            alignRight: false,
            scale: s,
          ),
        ),
    ];
  }
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
  const _GateSpot({required this.unit, required this.center});

  final KartyUnit unit;
  final Offset center;
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
  });

  final Offset from;
  final Offset to;
  final _TrailStyle style;

  /// Taşların ait olduğu ünitenin sırası; girişteki taşlar (önceki
  /// kapıdan ilk düğüme) da bu ünitenin.
  final int unit;

  /// Uçlarda taş konmayan pay: düğümün altına yarım taş girmesin.
  final double trimStart;
  final double trimEnd;
}

/// Bütün konumlar tasarım biriminde (750 genişlik). Düğümler her ünitede
/// ortadan başlayan yumuşak bir S çizer; şu anki düğüm balonu için,
/// kapı halkası için fazladan boşluk alır.
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
  static const nodeWidth = 132.0;
  static const currentWidth = 150.0;
  static const gateWidth = 150.0;
  static const ringRadius = 160.0;
  static const stepGap = 184.0;
  static const nodeClearance = 84.0;
  static const _currentRoom = 120.0;
  static const _pattern = [-15.0, 140.0, 15.0, -125.0, -45.0, 110.0, 20.0];

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

  static _PathLayout compute(KartyPathData data) {
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
      y += KartyUnitHeader.height + 156;

      final points = <Offset>[];
      var currentIndex = -1;
      var previousCurrent = false;
      for (var i = 0; i < unit.steps.length; i++) {
        final step = unit.steps[i];
        final current = step.state == KartyStepState.current;
        if (i > 0) {
          y += stepGap +
              (current ? _currentRoom : 0) +
              (previousCurrent ? 26 : 0);
        } else if (current) {
          y += _currentRoom;
        }
        final x = centerX + _pattern[i % _pattern.length];
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

      final gateCenter = Offset(
        centerX - 60,
        y + 176 + ringRadius + (previousCurrent ? 40 : 0),
      );
      gates.add(_GateSpot(unit: unit, center: gateCenter));
      final ringTop = gateCenter.translate(0, -ringRadius);
      final ringBottom = gateCenter.translate(0, ringRadius);

      // Önceki ünitenin halkasından bu ünitenin ilk düğümüne; başlığın
      // arkasından geçer.
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

      if (previousExit != null && points.isNotEmpty) {
        segments.add(_TrailSegment(
          previousExit,
          points.first,
          styleTo(0),
          unit: unit.number,
          trimStart: 26,
        ));
      }
      // Şu anki düğümün çevresinde kelime halkası var; taşlar ona girmez.
      double clearance(int i) => i == currentIndex ? 140 : nodeClearance;
      for (var i = 0; i + 1 < points.length; i++) {
        segments.add(_TrailSegment(
          points[i],
          points[i + 1],
          styleTo(i + 1),
          unit: unit.number,
          trimStart: clearance(i),
          trimEnd: clearance(i + 1),
        ));
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
          trimStart: clearance(points.length - 1),
          trimEnd: 26,
        ));
      }

      previousExit = ringBottom;
      y = ringBottom.dy + 128;
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
    final start = index > 0
        ? layout.gates[index - 1].center.dy + _PathLayout.ringRadius
        : head.top;
    final headerBottom = head.top + KartyUnitHeader.height;
    final end = layout.gates[index].center.dy - _PathLayout.ringRadius;
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
/// kalınlık bandının üstünde tombul bir parça. Kapı halkasında her taş
/// ünitenin bir kelimesi; pekişen kelime kadar taş yeşil yanar.
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

  // Halkadaki boncuk: ünitenin bir kelimesi.
  static const _beadRadius = 9.5;
  static const _beadDepth = 5.0;

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
        a != null &&
        index == arriving &&
        !a.reached(gate.center.dy - _PathLayout.ringRadius);
    for (final (i, gate) in layout.gates.indexed) {
      _paintBeads(canvas, gate, locked: held(i, gate));
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
    final first = start + (usable - (count - 1) * spacing) / 2;
    for (var i = 0; i < count; i++) {
      final tangent = metric.getTangentForOffset(first + i * spacing);
      if (tangent == null) continue;
      yield (
        tangent.position,
        math.atan2(tangent.vector.dy, tangent.vector.dx),
      );
    }
  }

  /// Kapı halkası: tepeden saat yönünde, kelime başına bir boncuk. Pekişen
  /// kelime kadar boncuk yeşil yanar.
  void _paintBeads(Canvas canvas, _GateSpot gate, {bool locked = false}) {
    final s = scale;
    final unit = gate.unit;
    final n = math.max(1, unit.wordCount);
    final r = _PathLayout.ringRadius * s;
    final c = gate.center * s;
    final centers = [
      for (var i = 0; i < n; i++)
        c +
            Offset(
                  math.cos(-math.pi / 2 + (i + 0.5) * 2 * math.pi / n),
                  math.sin(-math.pi / 2 + (i + 0.5) * 2 * math.pi / n),
                ) *
                r,
    ];
    _TrailStyle style(int i) => locked || unit.state == KartyUnitState.locked
        ? _TrailStyle.locked
        : i < unit.consolidatedCount
            ? _TrailStyle.done
            : _TrailStyle.ahead;
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(centers[i].translate(0, _beadDepth * s),
          _beadRadius * s, Paint()..color = _colors(style(i)).$2);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(
          centers[i], _beadRadius * s, Paint()..color = _colors(style(i)).$1);
    }
  }

  /// Ünite hedefinin çentiği ve yüzdesi (halkanın dışında).
  void _paintGoalMark(Canvas canvas, _GateSpot gate) {
    final s = scale;
    final unit = gate.unit;
    final angle = -math.pi / 2 + unit.unlockGoal * 2 * math.pi;
    final c = gate.center * s;
    final dir = Offset(math.cos(angle), math.sin(angle));
    final r = _PathLayout.ringRadius * s;
    final inner = c + dir * (r - 20 * s);
    final outer = c + dir * (r + 20 * s);
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
    final anchor = c + dir * (r + 50 * s);
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
    final r = Radius.circular((geo.radius + gap) * s);
    final ring = Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.right - r.x, rect.top)
      ..arcToPoint(Offset(rect.right, rect.top + r.x), radius: r)
      ..lineTo(rect.right, rect.bottom - r.x)
      ..arcToPoint(Offset(rect.right - r.x, rect.bottom), radius: r)
      ..lineTo(rect.left + r.x, rect.bottom)
      ..arcToPoint(Offset(rect.left, rect.bottom - r.x), radius: r)
      ..lineTo(rect.left, rect.top + r.x)
      ..arcToPoint(Offset(rect.left + r.x, rect.top), radius: r)
      ..close();
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
      // Şu anki düğümde üstte balon, çevrede halka var.
      final current = node.step.state == KartyStepState.current;
      if (d.dx.abs() < 300 &&
          d.dy > (current ? -250 : -90) &&
          d.dy < (current ? 140 : 90)) {
        return true;
      }
    }
    for (final gate in layout.gates) {
      final d = u - gate.center;
      if (d.dx.abs() < 440 && d.dy.abs() < _PathLayout.ringRadius + 40) {
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
// Düğüm, kapı, balon, etiketler
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
        KartyStepState.current => 'Şu anki deste',
        _ => 'Sıradaki deste',
      },
      onTap: onTap,
      child: _ToneIcon(
        tone: lit
            ? _IconTone.lit
            : dimmed
                ? _IconTone.locked
                : _IconTone.muted,
        child: QuestIcon(questKey: 'correct_five', size: width * 0.56 * scale),
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
  });

  final bool ready;
  final bool dimmed;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const width = _PathLayout.gateWidth;
    // Hedefe ulaşan kapı geçilen düğümler gibi yeşile döner; yeşil dönüş oku
    // yeşil yüzde kaybolacağı için yerine beyaz onay.
    return _NodeTile(
      width: width,
      scale: scale,
      face: ready ? _C.green : (dimmed ? _C.tile : _C.raised),
      depth: ready ? _C.greenDepth : (dimmed ? _C.base : _C.panel),
      label: ready ? 'Ünite sonu, hedefe ulaşıldı' : 'Ünite sonu, pekiştirme',
      onTap: onTap,
      child: ready
          ? KartyControlMark(
              glyph: KartyControlGlyph.check,
              size: width * 0.42 * scale,
            )
          : _ToneIcon(
              tone: dimmed ? _IconTone.locked : _IconTone.lit,
              child:
                  QuestIcon(questKey: 'review_two', size: width * 0.6 * scale),
            ),
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
  });

  final double width;
  final double scale;
  final Color face;
  final Color depth;
  final String label;
  final VoidCallback onTap;
  final Widget child;

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
                  painter: _FaceGlossPainter(radius: geo.radius * s),
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

/// Karo yüzünün üst kenarında ince cam parlaması ve sol üstte küçük
/// parlama — seri kartının üst kenar parlamasıyla aynı aile, bulanıklık yok.
class _FaceGlossPainter extends CustomPainter {
  const _FaceGlossPainter({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * 0.03;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.5));
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(stroke * 1.2),
          Radius.circular(math.max(0, radius - stroke * 1.2))),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          Offset(rect.center.dx, size.height * 0.5),
          [
            Colors.white.withValues(alpha: 0.34),
            Colors.white.withValues(alpha: 0),
          ],
        ),
    );
    canvas.restore();
    final u = size.width / 100;
    canvas.save();
    canvas.translate(22 * u, 19 * u);
    canvas.rotate(-0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 16 * u, height: 6.5 * u),
        Radius.circular(3.25 * u),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.38),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FaceGlossPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

enum _IconTone { lit, muted, locked }

/// Henüz açılmamış düğümde aynı şimşek, lacivert yüzde sönük tonda.
/// İki tonlu yapı korunur: beyaz `8FA0B5`'e, krem gölge orantılı iner.
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

/// Şu anki düğümün üstündeki eylem balonu: kart çerçevesinin beyazı,
/// altında aynı açık gri kalınlık; yanında giriş bedeli (`ticket-one`).
class _ContinueBubble extends StatelessWidget {
  const _ContinueBubble({
    required this.scale,
    required this.action,
    required this.onTap,
  });

  final double scale;
  final _StepAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final radius = BorderRadius.circular(24 * s);
    final body = Container(
      padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 24 * s, 12 * s),
      decoration: BoxDecoration(color: Colors.white, borderRadius: radius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/icons/ticket-one.png', width: 50 * s),
          SizedBox(width: 12 * s),
          Text(
            action.label,
            style: TextStyle(
              color: _C.accent,
              fontSize: 28 * s,
              fontWeight: AppTypography.number,
              fontFamily: AppTypography.family,
              height: 1,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: '${action.spoken}, 1 bilet',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  top: 6 * s,
                  bottom: -6 * s,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _C.rimBottom,
                      borderRadius: radius,
                    ),
                  ),
                ),
                body,
              ],
            ),
            CustomPaint(
              size: Size(30 * s, 16 * s),
              painter: const _PointerPainter(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  const _PointerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, -1)
      ..lineTo(size.width, -1)
      ..quadraticBezierTo(
          size.width * 0.58, size.height * 0.92, size.width / 2, size.height)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.92, 0, -1)
      ..close();
    canvas.drawPath(path.shift(Offset(0, size.height * 0.3)),
        Paint()..color = _C.rimBottom);
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter oldDelegate) => false;
}

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
// Maskot ve görseller
// ---------------------------------------------------------------------------

/// Şu anki düğümün yanında duran maskot. Şimşeği kaldıran poz Karty'nin
/// enerjisi; ayağının altında küçük lacivert gölge.
class _Mascot extends StatelessWidget {
  const _Mascot({required this.scale});

  final double scale;

  /// Görselin en-boy oranından (595 × 750).
  static const width = _KartyPathBody._mascotHeight * 595 / 750;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    const height = _KartyPathBody._mascotHeight;
    return SizedBox(
      width: width * s,
      height: (height + 10) * s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: width * 0.2 * s,
            right: width * 0.2 * s,
            bottom: 0,
            height: 22 * s,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _C.panel,
                borderRadius: BorderRadius.circular(11 * s),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 8 * s,
            child: Image.asset(
              'assets/icons/mascot_flex.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
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

/// Şu anki destenin penceresindeki eylem: patikadaki balonla aynı iş, aynı bedel.
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
      label: '${action.spoken}, 1 bilet',
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/ticket-one.png', width: 54 * s),
            SizedBox(width: 14 * s),
            Text(
              action.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32 * s,
                fontWeight: AppTypography.action,
                fontFamily: AppTypography.family,
                height: 1,
              ),
            ),
          ],
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
