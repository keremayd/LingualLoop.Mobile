import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_button_style.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_icon_control_button.dart';
import 'package:lingualloop/ui/widgets/Buttons/auth_back_button.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/countdown_pill.dart';
import 'package:lingualloop/ui/widgets/karty_control_glyphs.dart';
import 'package:lingualloop/ui/widgets/pressable_layered_card.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

/// Karty Yolu (bkz. `docs/KARTY_PATIKA.md` §8).
///
/// Aşağı akan bir patika; her ünitenin başlığı yolun içinde durur ve
/// kaydırınca görünen ünitenin başlığı üste yapışır. Her düğüm 8 yeni
/// kelimelik bir deste: geçmiş desteler yeşil, bugünkü mavi ve kelime
/// halkalı, yarın ve sonrası lacivert. Düğümler uygulamanın derinlikli
/// ikon kontrolüyle aynı karo (`AppButtonStyle`). Ünitenin sonunda her
/// kelimenin bir boncuk olduğu pekiştirme halkası durur; %80'i yandığında
/// sıradaki ünite açılır. Düğüme dokununca adımın penceresi açılır.
/// Açılışta bugünün düğümü ekranın ortasına gelir.
class KartyPathScreen extends StatefulWidget {
  const KartyPathScreen({
    super.key,
    required this.data,
    required this.onBack,
    required this.onContinue,
    this.onRefresh,
    this.controller,
    this.scrollToToday = true,
  });

  final KartyPathData data;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final Future<void> Function()? onRefresh;
  final ScrollController? controller;

  /// Açılışta bugünün düğümünü ortala. Önizleme sabit kaydırma ister.
  final bool scrollToToday;

  @override
  State<KartyPathScreen> createState() => _KartyPathScreenState();
}

class _KartyPathScreenState extends State<KartyPathScreen> {
  late final ScrollController _controller =
      widget.controller ?? ScrollController();
  late _PathLayout _layout = _PathLayout.compute(widget.data);
  double _scale = 1;
  int? _pinned;
  bool _centeredToday = false;

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
  }

  @override
  void dispose() {
    _controller.removeListener(_updatePinned);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  /// Üstüne kaydırılmış son ünite başlığı yapışır; yerindeki başlık
  /// görünürken yapışan yoktur, ikisi aynı yerde buluşur.
  void _updatePinned() {
    if (!_controller.hasClients) return;
    final offset = _controller.offset;
    int? pinned;
    for (var i = 0; i < _layout.headers.length; i++) {
      if (_layout.headers[i].top * _scale < offset) pinned = i;
    }
    if (pinned != _pinned) setState(() => _pinned = pinned);
  }

  void _centerToday() {
    final today = _layout.today;
    if (today == null || !_controller.hasClients) return;
    final position = _controller.position;
    final target = today.center.dy * _scale - position.viewportDimension * 0.45;
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
          if (widget.scrollToToday && !_centeredToday) {
            _centeredToday = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => _centerToday());
          }

          Widget scroll = SingleChildScrollView(
            controller: _controller,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: _KartyPathBody(
              data: widget.data,
              layout: _layout,
              scale: scale,
              onContinue: widget.onContinue,
              onStepTap: _openStep,
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
                      Positioned.fill(child: scroll),
                      if (pinned != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: ColoredBox(
                            color: _C.bg,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                  40 * scale, 0, 40 * scale, 18 * scale),
                              child: _UnitHeader(
                                unit: pinned.unit,
                                scale: scale,
                                onTap: () {},
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

/// Ünite başlığı — ana ekrandaki Karty kartının dili: aynı mavi yüz,
/// aynı taban ve köşe, solda metin, sağda 3B ünite nesnesi. Kilitli ünitede
/// yüz lacivert, nesne siluet: ne geleceği belli, kendisi henüz kapalı.
class _UnitHeader extends StatelessWidget {
  const _UnitHeader({
    required this.unit,
    required this.scale,
    required this.onTap,
  });

  final KartyUnit unit;
  final double scale;
  final VoidCallback onTap;

  /// Yüz + taban, tasarım biriminde.
  static const height = 244.0;

  @override
  Widget build(BuildContext context) {
    final locked = unit.state == KartyUnitState.locked;
    final radius = BorderRadius.circular(AppButtonStyle.tileRadius(28 * scale));

    return PressableLayeredCard(
      width: 670 * scale,
      height: height * scale,
      shadowOffset: AppButtonStyle.tileDepth(8 * scale),
      radius: radius,
      baseColor: locked ? _C.base : _C.accentDepth,
      onPressed: onTap,
      face: Container(
        decoration: BoxDecoration(
          color: locked ? _C.tile : _C.accent,
          borderRadius: radius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (unit.emblem != null)
              Positioned(
                right: 26 * scale,
                top: 0,
                bottom: 0,
                width: 236 * scale,
                child: Center(
                  child: locked
                      ? _Silhouette(
                          image: unit.emblem!,
                          size: 196 * scale,
                          color: _C.raised,
                        )
                      : _TileShadowedImage(
                          image: unit.emblem!,
                          size: 214 * scale,
                          scale: scale,
                        ),
                ),
              ),
            Positioned(
              left: 40 * scale,
              top: 30 * scale,
              right: 280 * scale,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ÜNİTE ${unit.number}',
                    style: TextStyle(
                      color: locked
                          ? _C.muted
                          : Colors.white.withValues(alpha: 0.82),
                      fontSize: 23 * scale,
                      fontWeight: AppTypography.number,
                      fontFamily: AppTypography.family,
                      letterSpacing: 1.6 * scale,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  // Uzun ünite adı kesilmez, sığacak kadar küçülür
                  // (Karty kelimesindeki kuralın aynısı, §2.11).
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      unit.title,
                      maxLines: 1,
                      style: TextStyle(
                        color: locked ? _C.value : Colors.white,
                        fontSize: 66 * scale,
                        fontWeight: AppTypography.heading,
                        fontFamily: AppTypography.displayFamily,
                        height: 1.05,
                      ),
                    ),
                  ),
                  SizedBox(height: 14 * scale),
                  locked
                      ? _LockedHint(
                          scale: scale,
                          text: unit.unlockHint ??
                              '${unit.wordCount} kelime seni bekliyor',
                        )
                      : _UnitProgress(unit: unit, scale: scale),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitProgress extends StatelessWidget {
  const _UnitProgress({required this.unit, required this.scale});

  final KartyUnit unit;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final barHeight = 20 * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${unit.consolidatedCount}/${unit.wordCount} kelime pekişti',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24 * scale,
            fontWeight: AppTypography.label,
            fontFamily: AppTypography.family,
            height: 1,
          ),
        ),
        SizedBox(height: 12 * scale),
        // Halkadaki ölçünün aynısı: dolgu pekişen kelime, çentik ünite hedefi.
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: barHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _C.accentDepth,
                        borderRadius: BorderRadius.circular(barHeight / 2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: math.max(barHeight, width * unit.consolidatedRatio),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(barHeight / 2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * unit.unlockGoal - 2.5 * scale,
                    top: -5 * scale,
                    bottom: -5 * scale,
                    width: 5 * scale,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3 * scale),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LockedHint extends StatelessWidget {
  const _LockedHint({required this.scale, required this.text});

  final double scale;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LockMark(size: 30 * scale),
        SizedBox(width: 10 * scale),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            style: TextStyle(
              color: _C.muted,
              fontSize: 22 * scale,
              fontWeight: AppTypography.label,
              fontFamily: AppTypography.family,
              height: 1.15,
            ),
          ),
        ),
      ],
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
  });

  final KartyPathData data;
  final _PathLayout layout;
  final double scale;
  final VoidCallback onContinue;
  final void Function(KartyUnit unit, KartyStep step) onStepTap;

  static const _mascotHeight = 236.0;

  @override
  Widget build(BuildContext context) {
    final s = scale;

    final children = <Widget>[
      Positioned.fill(
        child: CustomPaint(painter: _PathPainter(layout: layout, scale: s)),
      ),
      for (final header in layout.headers)
        Positioned(
          left: 40 * s,
          top: header.top * s,
          child: _UnitHeader(unit: header.unit, scale: s, onTap: () {}),
        ),
      for (final gate in layout.gates) ..._gate(gate, s),
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
    final today = step.state == KartyStepState.today;
    final labelGap = today ? 50.0 : 24.0;

    return [
      if (today)
        Positioned(
          left: (node.center.dx + node.width / 2 + 36) * s,
          top: (top + geo.total + 12 - _mascotHeight) * s,
          child: _Mascot(scale: s),
        ),
      Positioned(
        left: left * s,
        top: top * s,
        child: _PathNode(
          step: step,
          width: node.width,
          scale: s,
          dimmed: node.unit.state == KartyUnitState.locked,
          onTap: () => onStepTap(node.unit, step),
        ),
      ),
      if (step.state == KartyStepState.done && step.dueCount > 0)
        Positioned(
          left: (left + node.width - 30) * s,
          top: (top - 16) * s,
          child: _DueBadge(count: step.dueCount, scale: s),
        ),
      if (today)
        Positioned(
          left: (node.center.dx - 150) * s,
          width: 300 * s,
          top: (top - _NodeGeometry.ringGap - 112) * s,
          child: Center(
            child: _ContinueBubble(
              scale: s,
              started: step.newCount > 0,
              onTap: onContinue,
            ),
          ),
        ),
      if (step.label.isNotEmpty && step.state != KartyStepState.locked)
        Positioned(
          left: node.labelLeft ? 24 * s : (left + node.width + labelGap) * s,
          width: node.labelLeft
              ? (left - labelGap - 24) * s
              : (750 - 24 - left - node.width - labelGap) * s,
          top: (node.center.dy - 36) * s,
          child: _NodeLabel(
            title: step.label,
            detail: _labelDetail(step),
            state: step.state,
            alignRight: node.labelLeft,
            scale: s,
          ),
        ),
    ];
  }

  /// Etiketin ikinci satırı. Yeni kelime yoksa (ünite kapısı kapalı ya da
  /// içerik bitti) gün yalnız tekrarla anlatılır.
  static String _labelDetail(KartyStep step) {
    final reviews = '${step.reviewCount} tekrar';
    switch (step.state) {
      case KartyStepState.done:
        return '${step.newGoal} kelime';
      case KartyStepState.today:
        if (step.newGoal == 0) {
          return step.reviewCount > 0 ? reviews : 'Pratik';
        }
        final fresh = '${step.newCount}/${step.newGoal} yeni';
        return step.reviewCount > 0 ? '$fresh\n$reviews' : fresh;
      case KartyStepState.tomorrow:
        if (step.newGoal == 0) {
          return step.reviewCount > 0 ? reviews : 'Yalnız pratik';
        }
        return step.reviewCount > 0
            ? '${step.newGoal} yeni · $reviews'
            : '${step.newGoal} yeni kelime';
      case KartyStepState.upcoming:
        return '${step.newGoal} kelime';
      case KartyStepState.locked:
        return '';
    }
  }

  List<Widget> _gate(_GateSpot gate, double s) {
    final unit = gate.unit;
    final geo = _NodeGeometry(_PathLayout.gateWidth);
    final ready = unit.consolidatedRatio >= unit.unlockGoal;
    final left = gate.center.dx - _PathLayout.gateWidth / 2;
    final top = gate.center.dy - geo.total / 2;
    final labelLeft = gate.center.dx + _PathLayout.ringRadius + 40;

    return [
      Positioned(
        left: left * s,
        top: top * s,
        child: _GateNode(
          ready: ready,
          dimmed: unit.state == KartyUnitState.locked,
          scale: s,
          onTap: () {},
        ),
      ),
      if (unit.state != KartyUnitState.locked)
        Positioned(
          left: labelLeft * s,
          width: (750 - 24 - labelLeft) * s,
          top: (gate.center.dy - 44) * s,
          child: _NodeLabel(
            title: 'Pekiştirme',
            detail: '${unit.consolidatedCount}/${unit.wordCount} kelime',
            state: KartyStepState.tomorrow,
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

  /// Bugünün düğümü ile kelime halkası arasındaki boşluk.
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
    this.trimStart = _PathLayout.nodeClearance,
    this.trimEnd = _PathLayout.nodeClearance,
  });

  final Offset from;
  final Offset to;
  final _TrailStyle style;

  /// Uçlarda taş konmayan pay: düğümün altına yarım taş girmesin.
  final double trimStart;
  final double trimEnd;
}

/// Bütün konumlar tasarım biriminde (750 genişlik). Düğümler her ünitede
/// ortadan başlayan yumuşak bir S çizer; bugünün düğümü balonu için,
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
  static const todayWidth = 150.0;
  static const gateWidth = 150.0;
  static const ringRadius = 160.0;
  static const stepGap = 184.0;
  static const nodeClearance = 84.0;
  static const _todayRoom = 120.0;
  static const _pattern = [-15.0, 140.0, 15.0, -125.0, -45.0, 110.0, 20.0];

  _NodeSpot? get today {
    for (final node in nodes) {
      if (node.step.state == KartyStepState.today) return node;
    }
    return null;
  }

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
      y += _UnitHeader.height + 156;

      final points = <Offset>[];
      var todayIndex = -1;
      var previousToday = false;
      for (var i = 0; i < unit.steps.length; i++) {
        final step = unit.steps[i];
        final today = step.state == KartyStepState.today;
        if (i > 0) {
          y += stepGap + (today ? _todayRoom : 0) + (previousToday ? 26 : 0);
        } else if (today) {
          y += _todayRoom;
        }
        final x = centerX + _pattern[i % _pattern.length];
        final center = Offset(x, y);
        // Etiket geniş tarafta: düğüm sağa kıvrıldıysa solunda.
        nodes.add(_NodeSpot(
          unit: unit,
          step: step,
          center: center,
          width: today ? todayWidth : nodeWidth,
          labelLeft: x > centerX,
        ));
        points.add(center);
        if (today) todayIndex = i;
        previousToday = today;
      }

      final gateCenter = Offset(
        centerX - 60,
        y + 176 + ringRadius + (previousToday ? 40 : 0),
      );
      gates.add(_GateSpot(unit: unit, center: gateCenter));
      final ringTop = gateCenter.translate(0, -ringRadius);
      final ringBottom = gateCenter.translate(0, ringRadius);

      // Önceki ünitenin halkasından bu ünitenin ilk düğümüne; başlığın
      // arkasından geçer.
      // Taşın rengi vardığı adımdan: geçilmiş yol (tamamlanan ya da bugünün
      // düğümüne varan) yeşil. Bir tur ünitenin durumuna bağlanmıştı; eski
      // dönemde öğrenilmiş, açık ama güncel olmayan ünitenin yeşil düğümleri
      // lacivert taşlarla birbirine bağlanıyordu.
      _TrailStyle styleTo(int i) {
        if (locked) return _TrailStyle.locked;
        final state = unit.steps[i].state;
        return state == KartyStepState.done || state == KartyStepState.today
            ? _TrailStyle.done
            : _TrailStyle.ahead;
      }

      if (previousExit != null && points.isNotEmpty) {
        segments.add(_TrailSegment(
          previousExit,
          points.first,
          styleTo(0),
          trimStart: 26,
        ));
      }
      // Bugünün düğümünün çevresinde kelime halkası var; taşlar ona girmez.
      double clearance(int i) => i == todayIndex ? 140 : nodeClearance;
      for (var i = 0; i + 1 < points.length; i++) {
        segments.add(_TrailSegment(
          points[i],
          points[i + 1],
          styleTo(i + 1),
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

/// Taşlar, kapı halkaları, bugünün kelime halkası ve yıldızlar.
///
/// İz düz bir şerit değil **basamak taşları**: her taş §2.5'teki gibi koyu
/// kalınlık bandının üstünde tombul bir parça. Kapı halkasında her taş
/// ünitenin bir kelimesi; pekişen kelime kadar taş yeşil yanar.
class _PathPainter extends CustomPainter {
  _PathPainter({required this.layout, required this.scale});

  final _PathLayout layout;
  final double scale;

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
    final stones = <(RRect, _TrailStyle, double)>[];
    for (final segment in layout.segments) {
      final path = _curve(segment.from * s, segment.to * s);
      for (final metric in path.computeMetrics()) {
        for (final (center, angle) in _stonesAlong(metric, segment)) {
          stones.add((
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: _stoneLength * s,
                height: _stoneWidth * s,
              ),
              Radius.circular(_stoneWidth * s / 2),
            ).shift(center),
            segment.style,
            angle,
          ));
        }
      }
    }
    for (final pass in [0, 1]) {
      for (final (stone, style, angle) in stones) {
        final (face, depth) = _colors(style);
        final c = stone.center;
        canvas.save();
        canvas.translate(c.dx, c.dy + (pass == 0 ? _stoneDepth * s : 0));
        canvas.rotate(angle);
        canvas.drawRRect(
          stone.shift(-c),
          Paint()..color = pass == 0 ? depth : face,
        );
        canvas.restore();
      }
    }
    for (final gate in layout.gates) {
      _paintBeads(canvas, gate);
    }

    for (final gate in layout.gates) {
      if (gate.unit.state != KartyUnitState.locked) {
        _paintGoalMark(canvas, gate);
      }
    }
    final today = layout.today;
    // Yeni kelimesi olmayan gün (yalnız tekrar) halka taşımaz.
    if (today != null && today.step.newGoal > 0) _paintWordRing(canvas, today);
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
  void _paintBeads(Canvas canvas, _GateSpot gate) {
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
    _TrailStyle style(int i) => unit.state == KartyUnitState.locked
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

  /// Bugünün düğümünü saran 8 parçalı halka: her parça bugünün bir yeni
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
    // Yol tepe ortasından başlayıp saat yönünde döner: ilk parça bugünün
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
      // Bugünün düğümünde üstte balon, çevrede halka var.
      final today = node.step.state == KartyStepState.today;
      if (d.dx.abs() < 300 &&
          d.dy > (today ? -250 : -90) &&
          d.dy < (today ? 140 : 90)) {
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
          u.dy < header.top + _UnitHeader.height + 30) {
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
      oldDelegate.layout != layout || oldDelegate.scale != scale;
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
      KartyStepState.today => (_C.accent, _C.accentDepth),
      _ when dimmed => (_C.tile, _C.base),
      _ => (_C.raised, _C.panel),
    };
    final lit =
        step.state == KartyStepState.done || step.state == KartyStepState.today;

    return _NodeTile(
      width: width,
      scale: scale,
      face: face,
      depth: depth,
      label: switch (step.state) {
        KartyStepState.done => '${step.label}, tamamlandı',
        KartyStepState.today => 'Bugünün destesi',
        KartyStepState.tomorrow => 'Yarının destesi',
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

/// Bugünün düğümünün üstündeki eylem balonu: kart çerçevesinin beyazı,
/// altında aynı açık gri kalınlık; yanında giriş bedeli (`ticket-one`).
class _ContinueBubble extends StatelessWidget {
  const _ContinueBubble({
    required this.scale,
    required this.started,
    required this.onTap,
  });

  final double scale;
  final bool started;
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
            started ? 'DEVAM ET' : 'BAŞLA',
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
      label: started ? 'Devam et, 1 bilet' : 'Başla, 1 bilet',
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
              color: state == KartyStepState.today ? _C.accent : _C.muted,
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

/// Bugünün düğümünün yanında duran maskot. Şimşeği kaldıran poz Karty'nin
/// enerjisi; ayağının altında küçük lacivert gölge.
class _Mascot extends StatelessWidget {
  const _Mascot({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    const height = _KartyPathBody._mascotHeight;
    const width = height * 595 / 750;
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

/// Renkli karonun üstündeki 3B görsel: ana ekran Karty kartındaki iki
/// katmanlı yumuşak gölgenin aynısı.
class _TileShadowedImage extends StatelessWidget {
  const _TileShadowedImage({
    required this.image,
    required this.size,
    required this.scale,
  });

  final ImageProvider image;
  final double size;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    Widget shadow(Offset offset, double blur, double alpha) =>
        Transform.translate(
          offset: offset,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: alpha),
                BlendMode.srcIn,
              ),
              child: Image(image: image, width: size, height: size),
            ),
          ),
        );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          shadow(Offset(7 * s, 13 * s), 12 * s, 0.28),
          shadow(Offset(3 * s, 7 * s), 5 * s, 0.2),
          Image(image: image, width: size, height: size),
        ],
      ),
    );
  }
}

class _Silhouette extends StatelessWidget {
  const _Silhouette({required this.image, required this.color, this.size});

  final ImageProvider image;
  final Color color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: Image(
        image: image,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Küçük kilit — lig rozetinin kilitli paletiyle (§2.6): gri burada da
/// "henüz açılmadı" demek.
class _LockMark extends StatelessWidget {
  const _LockMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: const _LockPainter());
  }
}

class _LockPainter extends CustomPainter {
  const _LockPainter();

  static const _light = Color(0xFFA6B0BC);
  static const _face = Color(0xFF8792A0);
  static const _depth = Color(0xFF57606C);

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final shackle = Path()
      ..moveTo(30 * u, 48 * u)
      ..lineTo(30 * u, 34 * u)
      ..arcToPoint(Offset(70 * u, 34 * u), radius: Radius.circular(20 * u))
      ..lineTo(70 * u, 48 * u);
    canvas.drawPath(
      shackle,
      Paint()
        ..color = _face
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12 * u
        ..strokeCap = StrokeCap.round,
    );
    final body = RRect.fromLTRBR(
        14 * u, 42 * u, 86 * u, 92 * u, Radius.circular(14 * u));
    canvas.drawRRect(body.shift(Offset(0, 6 * u)), Paint()..color = _depth);
    canvas.drawRRect(body, Paint()..color = _face);
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(
        Rect.fromLTRB(14 * u, 42 * u, 86 * u, 60 * u), Paint()..color = _light);
    canvas.restore();
    canvas.drawCircle(Offset(50 * u, 66 * u), 7 * u, Paint()..color = _depth);
  }

  @override
  bool shouldRepaint(covariant _LockPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Adım penceresi
// ---------------------------------------------------------------------------

/// Düğüme dokununca açılan pencere. Geçmiş adımda o gün tanışılan kelimeler
/// ve bugünkü ustalıkları; yarında açılmaya kalan süre, yarının kelimeleri
/// (siluet) ve tekrarlar.
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
                KartyStepState.tomorrow => _tomorrow(s),
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
    final today = step.state == KartyStepState.today;
    return [
      if (today && rows.isEmpty) ...[
        _Explainer(
          text: step.newGoal > 0
              ? 'Bugünün ${step.newGoal} yeni kelimesi seni bekliyor.'
              : 'Bugün yeni kelime yok; tekrarlarla ünitenin '
                  'kelimeleri pekişiyor.',
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
      if (today && onContinue != null) ...[
        SizedBox(height: 26 * s),
        _SheetContinueButton(
          scale: s,
          started: step.newCount > 0 || step.newGoal == 0,
          onPressed: onContinue!,
        ),
      ],
    ];
  }

  List<Widget> _tomorrow(double s) {
    final reviews =
        unit.steps.expand((step) => step.words).where((w) => w.due).toList();
    final remaining = step.remainingText(DateTime.now());
    return [
      if (remaining != null)
        Row(
          children: [
            CountdownPill(
              scale: s,
              value: remaining,
              semanticLabel: 'Yarının destesi $remaining sonra açılır',
            ),
            SizedBox(width: 16 * s),
            Text(
              'sonra açılır',
              style: TextStyle(
                color: _C.muted,
                fontSize: 26 * s,
                fontWeight: AppTypography.body,
                fontFamily: AppTypography.family,
              ),
            ),
          ],
        ),
      SizedBox(height: 34 * s),
      if (step.newGoal == 0)
        _Explainer(
          text: 'Yarın yeni kelime yok. Sıradaki ünite, bu ünitenin '
              'kelimelerinin %${(unit.unlockGoal * 100).round()}\'i '
              'pekişince açılır.',
          scale: s,
        )
      else ...[
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
      ],
      if (reviews.isNotEmpty) ...[
        SizedBox(height: 36 * s),
        // Şu an vadesi gelmiş olanlar; yarının sayısı başlıktaki tahmin.
        _SectionTitle(
            text: 'Tekrar bekleyen ${reviews.length} kelime', scale: s),
        SizedBox(height: 18 * s),
        Wrap(
          spacing: 14 * s,
          runSpacing: 18 * s,
          children: [
            for (final word in reviews) _ReviewChip(word: word, scale: s),
          ],
        ),
      ],
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

/// Bugünün penceresindeki eylem: patikadaki balonla aynı iş, aynı bedel.
class _SheetContinueButton extends StatelessWidget {
  const _SheetContinueButton({
    required this.scale,
    required this.started,
    required this.onPressed,
  });

  final double scale;
  final bool started;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      label: started ? 'Devam et, 1 bilet' : 'Başla, 1 bilet',
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
              started ? 'DEVAM ET' : 'BAŞLA',
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
      KartyStepState.today => step.newGoal == 0
          ? '${step.reviewCount} tekrar'
          : '${step.newCount}/${step.newGoal} yeni kelime · ${step.reviewCount} tekrar',
      KartyStepState.tomorrow => step.newGoal == 0
          ? '${step.reviewCount} tekrar'
          : '${step.newGoal} yeni kelime · ${step.reviewCount} tekrar',
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

/// Yarının kelimesi: lacivert karoda siluet — ne olduğu sezilir, kendisi
/// yarın açılır.
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
      child:
          image == null ? null : _Silhouette(image: image!, color: _C.raised),
    );
  }
}

class _ReviewChip extends StatelessWidget {
  const _ReviewChip({required this.word, required this.scale});

  final KartyWord word;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final (pill, _) = _articleColors(word.article);
    return Container(
      padding: EdgeInsets.fromLTRB(8 * s, 8 * s, 20 * s, 8 * s),
      decoration: BoxDecoration(
        color: _C.tile,
        borderRadius: BorderRadius.circular(24 * s),
        boxShadow: [BoxShadow(color: _C.panel, offset: Offset(0, 5 * s))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60 * s,
            height: 60 * s,
            child: Image(image: word.image, fit: BoxFit.contain),
          ),
          SizedBox(width: 10 * s),
          Text(
            word.article,
            style: TextStyle(
              color: pill,
              fontSize: 23 * s,
              fontWeight: AppTypography.label,
              fontFamily: AppTypography.family,
            ),
          ),
          SizedBox(width: 8 * s),
          Text(
            word.word,
            style: TextStyle(
              color: Colors.white,
              fontSize: 27 * s,
              fontWeight: AppTypography.word,
              fontFamily: AppTypography.family,
            ),
          ),
        ],
      ),
    );
  }
}
