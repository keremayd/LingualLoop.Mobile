import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingualloop/ui/widgets/karty_unit_marks.dart';

/// Oyuna girişin bedeli: bilet sayaçtan büyüyerek düğümün üstüne iner, kapıda
/// kesilir gibi yırtılır, kopan parça düşer, yıldızlı gövde düğüme girer ve
/// oyun düğümün içinden açılır. Bedel yolda yazmadığı için harcamayı bu sahne
/// söylüyor; göz o anda düğümde olduğu için olay orada geçiyor.
///
/// Her oyun başında tekrarlanır: ışık hüzmesi, konfeti yok (onlar kutlama).
/// Olayların arasındaki duruşlar bilinçli, göz her birini takip edebilsin.
abstract final class _Beat {
  /// Bilet sayaçtan kalkıp büyüyerek yerine iner.
  static const launch = 320.0;

  /// Yerinde durur; kesik çizgisi belirir, gerilir ve yırtılır.
  static const tear = 510.0;

  /// Kopan parçanın düşüşü.
  static const stubEnd = tear + 400;

  /// Gövde yırtılmanın tepkisiyle yana sekip düğüme süzülmeye başlar.
  static const kickEnd = tear + 110;
  static const dive = tear + 130;

  /// Gövde düğüme girer.
  static const impact = 930.0;
  static const reaction = 300.0;

  /// Oyun açılmaya başlar; sahne daire ekranı kaplayana kadar yaşar.
  static const portal = impact + 70;
  static const portalLength = 520.0;
  static const end = portal + portalLength + 40;
}

const _aspect = 516 / 331;

/// Oyun dairesinin başladığı boy (karonun yarı genişliğine oranı).
const _portalStart = 0.6;

/// Yırtılma çizgisi (genişlik oranı): yıldızın solundan geçer, kesilen koçan
/// olur, yıldızlı gövde sağlam kalır.
const _tearAt = 0.29;

const _depth = Color(0xFFB87E00);
const _cream = Color(0xFFFFF1DC);
const _gold = Color(0xFFFFC93A);
const _orange = Color(0xFFF99300);
const _accent = Color(0xFF1CB1F5);

/// Üzerine bilet inen karo: düğüm ya da durak. Bilet girince ezilip taşar.
class TicketTarget extends StatefulWidget {
  const TicketTarget({super.key, required this.child});

  final Widget child;

  @override
  State<TicketTarget> createState() => TicketTargetState();
}

class TicketTargetState extends State<TicketTarget> {
  double _impact = 0;

  void _setImpact(double value) {
    if (_impact != value) setState(() => _impact = value);
  }

  /// Önce ezilir, sonra taşarak geri gelir (0–1).
  Matrix4 get _transform {
    final x = _impact;
    if (x <= 0 || x >= 1) return Matrix4.identity();
    if (x < 0.25) {
      final k = Curves.easeOut.transform(x / 0.25);
      return Matrix4.diagonal3Values(1 + 0.10 * k, 1 - 0.13 * k, 1);
    }
    final rise = (x - 0.25) / 0.75;
    final k = 1 - Curves.easeOutCubic.transform(math.min(rise * 2.4, 1));
    final pop = 0.16 * math.sin(math.pi * rise);
    return Matrix4.diagonal3Values(1 + 0.10 * k + pop, 1 - 0.13 * k + pop, 1);
  }

  @override
  Widget build(BuildContext context) => Transform(
        alignment: Alignment.bottomCenter,
        transform: _transform,
        child: widget.child,
      );
}

/// Oyunun açılacağı yer: düğümün merkezi ve dairenin başlangıç yarıçapı.
class GamePortal {
  const GamePortal({required this.center, required this.startRadius});

  final Offset center;
  final double startRadius;
}

/// Oyun, biletin girdiği düğümün içinden genişleyen bir daireyle açılır;
/// kapanırken aynı noktaya geri döner.
class GamePortalRoute<T> extends PageRouteBuilder<T> {
  GamePortalRoute({
    required RouteSettings super.settings,
    required WidgetBuilder builder,
    required GamePortal portal,
  }) : super(
          transitionDuration: Duration(
            milliseconds: _Beat.portalLength.round(),
          ),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              _PortalTransition(
            animation: animation,
            portal: portal,
            child: child,
          ),
        );
}

/// Dairenin ekranı kaplamak için varması gereken yarıçap.
double _portalReach(Size size, Offset center) => [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((corner) => (corner - center).distance).reduce(math.max);

class _PortalTransition extends StatelessWidget {
  const _PortalTransition({
    required this.animation,
    required this.portal,
    required this.child,
  });

  final Animation<double> animation;
  final GamePortal portal;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final center = portal.center;
    final far = _portalReach(size, center);
    final scale = size.width / 750;

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, page) {
        final t = Curves.easeInOutCubic.transform(animation.value);
        final radius = portal.startRadius + (far - portal.startRadius) * t;
        final open = animation.isCompleted;
        // Ağaç biçimi değişmez: oyun sayfası yeniden kurulmasın.
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipOval(
              clipper: KartyCircleReveal(center: center, radius: radius),
              clipBehavior: open ? Clip.none : Clip.antiAlias,
              child: page,
            ),
            if (!open && !animation.isDismissed)
              IgnorePointer(
                child: CustomPaint(
                  painter: _PortalEdgePainter(
                    center: center,
                    radius: radius,
                    width: (16 - 10 * animation.value) * scale,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Oynayan sahnenin denetimi.
class TicketSpendPlayback {
  TicketSpendPlayback._({
    required this.arrived,
    required this.portal,
    required void Function() remove,
  }) : _remove = remove;

  /// Bilet düğüme girdi, oyun açılabilir.
  final Future<void> arrived;

  /// Oyunun açılacağı yer; azaltılmış harekette yok, oyun düz açılır.
  final GamePortal? portal;

  final void Function() _remove;
  bool _removed = false;

  /// Giriş reddedildi: sahne hemen kalkar.
  void cancel() {
    if (_removed) return;
    _removed = true;
    _remove();
  }

  /// Oyun sayfası üste açılırken sahne altında kalır, daire ekranı
  /// kaplayınca kaldırılır.
  void removeWhenCovered() {
    unawaited(
      Future<void>.delayed(
        Duration(milliseconds: (_Beat.portalLength + 40).round()),
        cancel,
      ),
    );
  }
}

/// Sahneyi kök Overlay'de başlatır. Azaltılmış hareket tercihinde ya da uçlar
/// ölçülemezse sahne oynamaz, oyun hemen açılabilir.
TicketSpendPlayback playTicketSpend(
  BuildContext context, {
  required GlobalKey from,
  required GlobalKey<TicketTargetState> to,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final space = overlay.context.findRenderObject() as RenderBox?;
  final source = from.currentContext?.findRenderObject() as RenderBox?;
  final target = to.currentContext?.findRenderObject() as RenderBox?;
  if (MediaQuery.disableAnimationsOf(context) ||
      space == null ||
      source == null ||
      target == null) {
    return TicketSpendPlayback._(
      arrived: Future.value(),
      portal: null,
      remove: () {},
    );
  }

  // Katman kökteki Overlay; ölçüler onun yerel uzayına çevrilir.
  Offset center(RenderBox box) =>
      space.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  final node = center(target);
  final nodeRadius = target.size.width / 2;
  final scene = _SceneGeometry(
    counter: center(source),
    counterWidth: source.size.width,
    node: node,
    nodeRadius: nodeRadius,
    top: center(source).dy + source.size.height / 2 + 14,
    screen: space.size,
    scale: space.size.width / 750,
  );

  final arrived = Completer<void>();
  final entry = OverlayEntry(
    builder: (_) => _TicketSpendOverlay(
      geometry: scene,
      onImpact: (value) => to.currentState?._setImpact(value),
      onArrived: () {
        if (!arrived.isCompleted) arrived.complete();
      },
    ),
  );
  overlay.insert(entry);
  return TicketSpendPlayback._(
    arrived: arrived.future,
    portal: GamePortal(center: node, startRadius: nodeRadius * _portalStart),
    remove: () {
      if (!arrived.isCompleted) arrived.complete();
      to.currentState?._setImpact(0);
      entry
        ..remove()
        ..dispose();
    },
  );
}

class _SceneGeometry {
  const _SceneGeometry({
    required this.counter,
    required this.counterWidth,
    required this.node,
    required this.nodeRadius,
    required this.top,
    required this.screen,
    required this.scale,
  });

  final Offset counter;
  final double counterWidth;
  final Offset node;
  final double nodeRadius;

  /// Karartmanın başladığı yer: üst şerit açık kalır, sayaç görünsün.
  final double top;
  final Size screen;
  final double scale;
}

class _TicketSpendOverlay extends StatefulWidget {
  const _TicketSpendOverlay({
    required this.geometry,
    required this.onImpact,
    required this.onArrived,
  });

  final _SceneGeometry geometry;
  final ValueChanged<double> onImpact;
  final VoidCallback onArrived;

  @override
  State<_TicketSpendOverlay> createState() => _TicketSpendOverlayState();
}

class _TicketSpendOverlayState extends State<_TicketSpendOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _Beat.end.round()),
  )
    ..addListener(_onTick)
    ..forward();

  bool _tore = false;
  bool _hit = false;

  void _onTick() {
    final ms = _clock.value * _Beat.end;
    if (!_tore && ms >= _Beat.tear) {
      _tore = true;
      HapticFeedback.lightImpact();
    }
    if (ms >= _Beat.impact) {
      if (!_hit) {
        _hit = true;
        HapticFeedback.mediumImpact();
      }
      final x = (ms - _Beat.impact) / _Beat.reaction;
      widget.onImpact(x >= 1 ? 0 : x);
    }
    if (ms >= _Beat.portal) widget.onArrived();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sahne sürerken başka bir oyun açılmasın.
    return AbsorbPointer(
      child: AnimatedBuilder(
        animation: _clock,
        builder: (context, _) => _Scene(
          ms: _clock.value * _Beat.end,
          geometry: widget.geometry,
        ),
      ),
    );
  }
}

class _Scene extends StatelessWidget {
  const _Scene({required this.ms, required this.geometry});

  final double ms;
  final _SceneGeometry geometry;

  double _seg(double a, double b) => ((ms - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final g = geometry;
    final s = g.scale;
    final width = 286 * s;
    final height = width / _aspect;
    // Kenardaki durakta bilet ekrandan taşmasın.
    final margin = 16 * s + width / 2;
    final hero = Offset(
      g.node.dx.clamp(margin, g.screen.width - margin),
      math.max(g.node.dy - 150 * s, g.top + height / 2 + 12 * s),
    );

    // Sahne oyun sayfasının üstünde kalır: oyun açılırken karartma dairenin
    // dışına çekilir, açılan sayfayı karartmaz.
    final opening = Curves.easeInOutCubic.transform(
      _seg(_Beat.portal, _Beat.portal + _Beat.portalLength),
    );
    final start = g.nodeRadius * _portalStart;
    final hole = math.max(
      g.nodeRadius + 34 * s,
      start + (_portalReach(g.screen, g.node) - start) * opening,
    );

    final children = <Widget>[
      // Sahne kararır: göz bilete ve düğüme toplanır.
      Positioned.fill(
        child: CustomPaint(
          painter: _DimPainter(
            alpha: 0.46 * Curves.easeOut.transform(_seg(0, 190)),
            hole: g.node,
            radius: hole,
            top: g.top,
          ),
        ),
      ),
    ];

    if (ms < _Beat.impact) {
      final launch = _seg(0, _Beat.launch);
      final flown = Curves.easeOutCubic.transform(launch);
      final travel = hero - g.counter;
      final control = Offset.lerp(g.counter, hero, 0.5)! +
          Offset(travel.dy, -travel.dx) * 0.2;
      final at = _quadratic(g.counter, control, hero, flown);
      final size = g.counterWidth +
          (width - g.counterWidth) * Curves.easeOutBack.transform(launch);
      // Vardığında hafifçe sallanır: ağırlığı olan bir nesne.
      final settle = _seg(_Beat.launch, _Beat.launch + 190);
      final wobble = 0.075 * math.cos(settle * math.pi * 2.5) * (1 - settle);
      final rotation = launch < 1 ? -0.34 + (0.34 + 0.075) * flown : wobble;
      children.addAll(_ticket(at, size, rotation, s));
    }

    final ring = _seg(_Beat.impact, _Beat.impact + 340);
    if (ring > 0 && ring < 1) {
      children.add(
        _centered(
          g.node,
          KartyUnlockRing(progress: ring, radius: g.nodeRadius, scale: s),
        ),
      );
    }
    final sparkle = _seg(_Beat.impact, _Beat.impact + 380);
    if (sparkle > 0 && sparkle < 1) {
      children.add(
        _centered(
          g.node,
          KartyUnlockSparkles(
            progress: sparkle,
            radius: g.nodeRadius,
            scale: s,
          ),
        ),
      );
    }

    return Stack(children: children);
  }

  List<Widget> _ticket(Offset at, double size, double rotation, double s) {
    final height = size / _aspect;
    if (ms < _Beat.tear) {
      // Yırtılmadan hemen önce gerilir.
      final strain = _seg(_Beat.tear - 50, _Beat.tear);
      final tremble = math.sin(ms * 0.55) * 1.6 * s * strain;
      return [
        _placed(
          at + Offset(tremble, 0),
          _Ticket(
            width: size,
            part: _Part.whole,
            perforation: _seg(_Beat.launch + 40, _Beat.launch + 120),
            sheen: _seg(_Beat.launch - 60, _Beat.tear - 10),
            stretch: 1 + 0.035 * strain,
            scale: s,
          ),
          rotation,
        ),
      ];
    }

    final fall = _seg(_Beat.tear, _Beat.stubEnd);
    final out = Curves.easeOutCubic.transform(fall);
    final kick = Curves.easeOutCubic.transform(_seg(_Beat.tear, _Beat.kickEnd));
    // İnişte hızlanıp varışta yumuşar: göz gövdeyi düğüme kadar izleyebilsin.
    final dive =
        Curves.easeInOutCubic.transform(_seg(_Beat.dive, _Beat.impact));
    final mainStart = at + Offset(26 * s * kick, 4 * s * kick);
    final mainEnd = geometry.node - Offset(size * _tearAt / 2 * 0.14, 0);

    return [
      _placed(
        at + Offset(-104 * out * s, (-58 * fall + 340 * fall * fall) * s),
        Transform.scale(
          // Lacivert üstünde yarı saydam altın zeytine döner: solmaz, küçülür.
          scale: 1 -
              Curves.easeInCubic
                  .transform(_seg(_Beat.tear + 180, _Beat.stubEnd)),
          alignment: const Alignment(_tearAt - 1, 0),
          child: _Ticket(width: size, part: _Part.stub, scale: s),
        ),
        rotation - 1.15 * out,
        alignment: const Alignment(_tearAt - 1, 0),
      ),
      Positioned.fill(
        child: CustomPaint(
          painter: _ChipsPainter(
            t: _seg(_Beat.tear, _Beat.tear + 430),
            origin: at + Offset((_tearAt - 0.5) * size, 0),
            span: height,
            scale: s,
          ),
        ),
      ),
      _placed(
        Offset.lerp(mainStart, mainEnd, dive)!,
        Transform.scale(
          scale: 1 - 0.86 * dive,
          alignment: const Alignment(_tearAt, 0),
          child: _Ticket(width: size, part: _Part.main, scale: s),
        ),
        rotation + 0.11 * kick + 0.5 * dive,
        alignment: const Alignment(_tearAt, 0),
      ),
    ];
  }

  Offset _quadratic(Offset a, Offset c, Offset b, double t) {
    final u = 1 - t;
    return a * (u * u) + c * (2 * u * t) + b * (t * t);
  }

  Widget _placed(
    Offset at,
    Widget child,
    double rotation, {
    Alignment alignment = Alignment.center,
  }) =>
      Positioned(
        left: at.dx,
        top: at.dy,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: Transform.rotate(
            angle: rotation,
            alignment: alignment,
            child: child,
          ),
        ),
      );

  Widget _centered(Offset at, Widget child) => Positioned(
        left: at.dx,
        top: at.dy,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: child,
        ),
      );
}

enum _Part { whole, stub, main }

/// Biletin kendisi (`ticket.png`), kalınlık bandıyla: sahnede büyüdüğünde
/// fiziksel bir nesne gibi durur (§2.5). Parçalar aynı görselden kesilir.
class _Ticket extends StatelessWidget {
  const _Ticket({
    required this.width,
    required this.part,
    required this.scale,
    this.perforation = 0,
    this.sheen = 0,
    this.stretch = 1,
  });

  final double width;
  final _Part part;
  final double scale;
  final double perforation;
  final double sheen;
  final double stretch;

  @override
  Widget build(BuildContext context) {
    final height = width / _aspect;
    final depth = width * 0.036;

    Widget image() => Image.asset(
          'assets/icons/ticket.png',
          width: width,
          height: height,
          fit: BoxFit.fill,
        );
    Widget cut(Widget child) => part == _Part.whole
        ? child
        : ClipPath(clipper: _TearClipper(part), child: child);

    var face = image();
    if (sheen > 0 && sheen < 1) {
      // Keskin kenarlı parıltı; bulanık gradyan yok (§2.2).
      final x = -0.3 + 1.6 * sheen;
      face = ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: const Alignment(-1, -0.6),
          end: const Alignment(1, 0.6),
          stops: [x - 0.1, x - 0.1, x + 0.1, x + 0.1],
          colors: const [
            Color(0x00FFFFFF),
            Color(0x8CFFFFFF),
            Color(0x8CFFFFFF),
            Color(0x00FFFFFF),
          ],
        ).createShader(bounds),
        child: face,
      );
    }

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(stretch, 1 / stretch, 1),
      child: SizedBox(
        width: width,
        height: height + depth,
        child: Stack(
          children: [
            Positioned(
              top: depth,
              child: cut(
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_depth, _depth],
                  ).createShader(bounds),
                  child: image(),
                ),
              ),
            ),
            Positioned(top: 0, child: cut(face)),
            if (part != _Part.whole || perforation > 0)
              Positioned(
                top: 0,
                child: CustomPaint(
                  size: Size(width, height),
                  painter: _TearEdgePainter(
                    part: part,
                    perforation: perforation,
                    scale: scale,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void _addTearLine(Path path, Size size) {
  const teeth = 13;
  final x = size.width * _tearAt;
  final amp = size.width * 0.017;
  final step = size.height / teeth;
  for (var i = 0; i < teeth; i++) {
    final y = i * step;
    final dir = i.isEven ? 1.0 : -1.0;
    path.quadraticBezierTo(x + dir * amp, y + step / 2, x, y + step);
  }
}

class _TearClipper extends CustomClipper<Path> {
  const _TearClipper(this.part);

  final _Part part;

  @override
  Path getClip(Size size) {
    final x = size.width * _tearAt;
    final edge = part == _Part.stub ? 0.0 : size.width;
    final path = Path()
      ..moveTo(edge, 0)
      ..lineTo(x, 0);
    _addTearLine(path, size);
    return path
      ..lineTo(edge, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant _TearClipper oldClipper) =>
      oldClipper.part != part;
}

class _TearEdgePainter extends CustomPainter {
  const _TearEdgePainter({
    required this.part,
    required this.perforation,
    required this.scale,
  });

  final _Part part;
  final double perforation;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * _tearAt;
    if (part == _Part.whole) {
      // Yırtılacak çizgi önce belirir.
      final paint = Paint()
        ..color = _cream.withValues(alpha: perforation)
        ..strokeWidth = 5 * scale
        ..strokeCap = StrokeCap.round;
      const dots = 9;
      for (var i = 0; i < dots; i++) {
        final y = size.height * (i + 0.5) / dots;
        canvas.drawLine(
          Offset(x, y - 5 * scale),
          Offset(x, y + 5 * scale),
          paint,
        );
      }
      return;
    }
    final path = Path()..moveTo(x, 0);
    _addTearLine(path, size);
    canvas.drawPath(
      path,
      Paint()
        ..color = _cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TearEdgePainter oldDelegate) =>
      oldDelegate.perforation != perforation || oldDelegate.part != part;
}

class _DimPainter extends CustomPainter {
  const _DimPainter({
    required this.alpha,
    required this.hole,
    required this.radius,
    required this.top,
  });

  final double alpha;
  final Offset hole;
  final double radius;
  final double top;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Rect.fromLTRB(0, top, size.width, size.height))
        ..addOval(Rect.fromCircle(center: hole, radius: radius)),
      Paint()..color = Colors.black.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(covariant _DimPainter oldDelegate) =>
      oldDelegate.alpha != alpha || oldDelegate.radius != radius;
}

/// Yırtılma çizgisinden saçılan kırıntılar. Solmaz, küçülür: lacivert üstünde
/// yarı saydam altın zeytine döner.
class _ChipsPainter extends CustomPainter {
  const _ChipsPainter({
    required this.t,
    required this.origin,
    required this.span,
    required this.scale,
  });

  final double t;
  final Offset origin;
  final double span;
  final double scale;

  // Yatay, dikey, boy, dönüş, kesik boyunca başlangıç, renk.
  static const _chips = [
    (-150.0, -120.0, 20.0, 5.0, -0.34, _gold),
    (130.0, -150.0, 16.0, -6.0, -0.2, _orange),
    (-120.0, -40.0, 14.0, 7.0, -0.05, _cream),
    (160.0, -50.0, 22.0, -4.0, 0.06, _gold),
    (-170.0, 30.0, 17.0, 6.0, 0.2, _orange),
    (120.0, 40.0, 13.0, -7.0, 0.3, _cream),
    (-70.0, -170.0, 12.0, 8.0, -0.42, _gold),
    (80.0, -180.0, 15.0, -8.0, 0.4, _gold),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final fall = 400 * t * t;
    final out = Curves.easeOutCubic.transform(t);
    final shrink = t < 0.55 ? 1.0 : 1 - (t - 0.55) / 0.45;
    for (final (dx, dy, side, spin, along, color) in _chips) {
      final at = origin +
          Offset(dx * out * scale, (dy * out + fall) * scale) +
          Offset(0, along * span);
      final w = side * scale * shrink;
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: w * 0.72),
          Radius.circular(w * 0.26),
        ),
        Paint()..color = color,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ChipsPainter oldDelegate) => oldDelegate.t != t;
}

class _PortalEdgePainter extends CustomPainter {
  const _PortalEdgePainter({
    required this.center,
    required this.radius,
    required this.width,
  });

  final Offset center;
  final double radius;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(covariant _PortalEdgePainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.width != width;
}
