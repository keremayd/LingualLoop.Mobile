import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

/// Ödül hedefi — Duolingo araştırmasından sonraki nesil.
///
/// Araştırmanın üç dersi:
///  1. **Sönükten parlağa yükselt.** Duolingo bekleyen sandığı kısar, hazır
///     olanı açıp parlatır. Bizde bekleyen bilet zaten tam parlaklıktaydı;
///     yükseltecek kademe kalmamıştı.
///  2. **Ödülü taşıyan nesnenin durumu olmalı.** Sandık açılır; bilet açılmaz.
///     Durumu taşıyacak bir kabuk gerekiyor.
///  3. **Gri yasak** (§4.3): bu uygulamada gri "kilitli" demek. Sönük hâl
///     alfayla değil **opak koyu altınla** yapılır (§2.2 türetme kuralı:
///     FFC93A → B87E00, lig paletindeki `yildiz` taşının koyusu).
///
///   flutter test --update-goldens test/quest_claim_gen2_test.dart
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Inter');
    final bytes = File(
      '/Users/kerem.aydin/Desktop/Repos/Lingualloop/LingualLoop.Mobile'
      '/assets/fonts/Inter-SemiBold.ttf',
    ).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  });

  testWidgets('claim gen2', (tester) async {
    const size = Size(2140, 820);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(backgroundColor: _bg, body: _Sheet()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/quest_claim_gen2.png'),
    );
  });
}

enum _N { dimToBright, socket, fullBar }

const _bg = Color(0xFF041227);
const _cardBorder = Color(0xFF0B2143);
const _iconTile = Color(0xFF0C2244);
const _track = Color(0xFF0B2143);
const _progress = Color(0xFFFFC93A);
const _onProgress = Color(0xFF4A3400);
const _muted = Color(0xFF8FA0B5);
const _claimFace = Color(0xFF98DE25);
const _claimBase = Color(0xFF6EA51C);
const _cream = Color(0xFFF6EDE4);

/// Sönük biletin tonu. Palet dışı bir renk **değil**: §2.6'daki `yildiz`
/// ligi taşının koyu tonu, yani altının belgeli koyusu.
const _goldDim = Color(0xFFB87E00);

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Col(
            n: _N.dimToBright,
            label: 'N1 — SÖNÜKTEN PARLAĞA',
            note: 'Duolingo mantığının birebiri, yeşilsiz. Bekleyen bilet '
                'opak koyu altın; hazır olan tam renk, kabarık ve hâleli.',
          ),
          SizedBox(width: 26),
          _Col(
            n: _N.socket,
            label: 'N2 — YUVA AÇILIR',
            note: 'Kabuk fikri: bekleyen bilet koyu yuvada durur. Hazır '
                'olunca yuva yeşile döner ve bilet içinden çıkar.',
          ),
          SizedBox(width: 26),
          _Col(
            n: _N.fullBar,
            label: 'N3 — BAR BUTONA DÖNÜŞÜR',
            note: 'Bekleyen sönük bilete varır. Dolunca barın işi biter, '
                'tamamı yeşil butona dönüşür; simge krem.',
          ),
        ],
      ),
    );
  }
}

class _Col extends StatelessWidget {
  const _Col({required this.n, required this.label, required this.note});

  final _N n;
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 670,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 62,
            child: Text(
              note,
              style: const TextStyle(
                color: _muted,
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _Caption('BEKLİYOR'),
          const SizedBox(height: 8),
          _Row(n: n, width: 670, ready: false),
          const SizedBox(height: 18),
          const _Caption('HAZIR — TOPLANABİLİR'),
          const SizedBox(height: 8),
          _Row(n: n, width: 670, ready: true),
          const SizedBox(height: 26),
          const _Caption('GERÇEK BOYUT — 430px'),
          const SizedBox(height: 8),
          SizedBox(width: 430, child: _Row(n: n, width: 430, ready: true)),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF5C6C80),
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.n, required this.width, required this.ready});

  final _N n;
  final double width;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final scale = width / 670;
    // Yuva açılırken bilet kabuğun üstüne taşıyor; o varyantta bar alanı
    // biraz daha yüksek.
    final barArea = (n == _N.socket && ready ? 88.0 : 72.0) * scale;

    return _Surface(
      scale: scale,
      radius: 28 * scale,
      child: Container(
        height: 152 * scale,
        padding: EdgeInsets.symmetric(horizontal: 25 * scale),
        child: Row(
          children: [
            Container(
              width: 87 * scale,
              height: 87 * scale,
              decoration: BoxDecoration(
                color: _iconTile,
                borderRadius: BorderRadius.circular(24 * scale),
              ),
              alignment: Alignment.center,
              child: QuestIcon(questKey: 'checkin', size: 48 * scale),
            ),
            SizedBox(width: 25 * scale),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Güne başla',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25 * scale,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Inter',
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: 13 * scale),
                  if (n == _N.fullBar && ready)
                    SizedBox(
                      height: barArea,
                      child: Center(child: _fullBarButton(scale)),
                    )
                  else
                    SizedBox(
                      height: barArea,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 46 * scale),
                            child: _Bar(
                              scale: scale,
                              fraction: ready ? 1.0 : 0.4,
                              label: ready ? '1/1' : '2/5',
                            ),
                          ),
                          Positioned(right: 0, child: _endCap(scale)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _endCap(double scale) {
    switch (n) {
      case _N.dimToBright:
        return ready ? _brightTicket(scale) : _dimTicket(scale, 62);
      case _N.socket:
        return ready ? _openSocket(scale) : _closedSocket(scale);
      case _N.fullBar:
        return _dimTicket(scale, 62);
    }
  }

  /// Sönük bilet: gri değil **opak koyu altın**. Gri bu uygulamada kilitli
  /// demek (§4.3); ödül kilitli değil, sadece henüz hazır değil.
  Widget _dimTicket(double scale, double w) {
    final width = w * scale;
    return _withCount(
      scale: scale,
      badge: 30 * scale,
      onDim: true,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) =>
            const LinearGradient(colors: [_goldDim, _goldDim]).createShader(r),
        child: Image.asset('assets/icons/ticket.png',
            width: width, fit: BoxFit.contain),
      ),
    );
  }

  /// Hazır bilet: tam renk + §2.5 kalınlık bandı + sıcak hâle.
  Widget _brightTicket(double scale) {
    final w = 76 * scale;
    final h = w * 110 / 172;
    final depth = 6 * scale;

    return SizedBox(
      width: w + 12 * scale,
      height: h + depth + 12 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -12 * scale,
            top: -8 * scale,
            child: Container(
              width: w + 24 * scale,
              height: h + 28 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _progress.withValues(alpha: 0.45),
                    _progress.withValues(alpha: 0),
                  ],
                  stops: const [0.3, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: depth,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (r) => const LinearGradient(
                colors: [_goldDim, _goldDim],
              ).createShader(r),
              child: Image.asset('assets/icons/ticket.png',
                  width: w, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Image.asset('assets/icons/ticket.png',
                width: w, fit: BoxFit.contain),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _badge(scale: scale, badge: 32 * scale, onDim: false),
          ),
        ],
      ),
    );
  }

  /// Kapalı yuva: bilet kabuğunun içinde, sönük.
  Widget _closedSocket(double scale) {
    final d = 72 * scale;
    return SizedBox(
      width: d,
      height: d,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              color: _iconTile,
              borderRadius: BorderRadius.circular(20 * scale),
              border: Border.all(color: _cardBorder, width: 2 * scale),
            ),
            alignment: Alignment.center,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (r) =>
                  const LinearGradient(colors: [_goldDim, _goldDim])
                      .createShader(r),
              child: Image.asset('assets/icons/ticket.png',
                  width: 48 * scale, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            right: -4 * scale,
            bottom: -4 * scale,
            child: _badge(scale: scale, badge: 30 * scale, onDim: true),
          ),
        ],
      ),
    );
  }

  /// Açılan yuva: kabuk yeşile döner, bilet içinden **çıkar** — üst kenarı
  /// aşar, tam renk ve hâleli.
  Widget _openSocket(double scale) {
    final d = 72 * scale;
    final ticketW = 76 * scale;
    final ticketH = ticketW * 110 / 172;

    return SizedBox(
      width: ticketW + 10 * scale,
      height: 88 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Yeşil kabuk, aşağıda.
          Positioned(
            left: (ticketW + 10 * scale - d) / 2,
            bottom: 0,
            child: SizedBox(
              width: d,
              height: d,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 7 * scale,
                    height: d - 7 * scale,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _claimBase,
                        borderRadius: BorderRadius.circular(20 * scale),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: d - 7 * scale,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _claimFace,
                        borderRadius: BorderRadius.circular(20 * scale),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Hâle.
          Positioned(
            left: -6 * scale,
            top: -4 * scale,
            child: Container(
              width: ticketW + 22 * scale,
              height: ticketH + 30 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _progress.withValues(alpha: 0.4),
                    _progress.withValues(alpha: 0),
                  ],
                  stops: const [0.3, 1],
                ),
              ),
            ),
          ),
          // Bilet yuvadan çıkmış: kabuğun üst kenarını aşıyor.
          Positioned(
            left: 0,
            top: 0,
            child: Image.asset('assets/icons/ticket.png',
                width: ticketW, fit: BoxFit.contain),
          ),
          Positioned(
            right: 0,
            top: ticketH - 14 * scale,
            child: _badge(scale: scale, badge: 30 * scale, onDim: false),
          ),
        ],
      ),
    );
  }

  Widget _fullBarButton(double scale) {
    final h = 56 * scale;
    final depth = 8 * scale;
    final radius = BorderRadius.circular(h / 2);

    return SizedBox(
      height: h + depth,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: depth,
            height: h,
            child: DecoratedBox(
              decoration:
                  BoxDecoration(color: _claimBase, borderRadius: radius),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: h,
            child: DecoratedBox(
              decoration:
                  BoxDecoration(color: _claimFace, borderRadius: radius),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (r) =>
                        const LinearGradient(colors: [_cream, _cream])
                            .createShader(r),
                    child: Image.asset('assets/icons/ticket.png',
                        width: 46 * scale, fit: BoxFit.contain),
                  ),
                  SizedBox(width: 10 * scale),
                  Text(
                    '1 BİLET AL',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontSize: 24 * scale,
                      fontWeight: FontWeight.w900,
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

  Widget _withCount({
    required double scale,
    required double badge,
    required bool onDim,
    required Widget child,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -badge * 0.28,
          bottom: -badge * 0.2,
          child: _badge(scale: scale, badge: badge, onDim: onDim),
        ),
      ],
    );
  }

  Widget _badge({
    required double scale,
    required double badge,
    required bool onDim,
  }) {
    return Container(
      width: badge,
      height: badge,
      decoration: BoxDecoration(
        color: _bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: onDim ? _cardBorder : _progress,
          width: 2 * scale,
        ),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.all(3 * scale),
          child: Text(
            '1',
            style: TextStyle(
              color: onDim ? _muted : Colors.white,
              fontFamily: 'Inter',
              fontSize: badge * 0.6,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.scale,
    required this.fraction,
    required this.label,
  });

  final double scale;
  final double fraction;
  final String label;

  @override
  Widget build(BuildContext context) {
    final height = 25 * scale;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: _track)),
            if (fraction > 0)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _progress,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                ),
              ),
            Center(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            if (fraction > 0)
              ClipRect(
                clipper: _FillClipper(fraction),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: _onProgress,
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FillClipper extends CustomClipper<Rect> {
  const _FillClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(covariant _FillClipper oldClipper) =>
      oldClipper.fraction != fraction;
}

class _Surface extends StatelessWidget {
  const _Surface({
    required this.scale,
    required this.radius,
    required this.child,
  });

  final double scale;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBorder,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: EdgeInsets.only(bottom: 7 * scale),
      child: Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(radius),
        ),
        foregroundDecoration: _NoTopBorderDecoration(
          color: _cardBorder,
          strokeWidth: 2 * scale,
          radius: radius,
        ),
        child: child,
      ),
    );
  }
}

class _NoTopBorderDecoration extends Decoration {
  const _NoTopBorderDecoration({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _NoTopBorderBoxPainter(color, strokeWidth, radius);
}

class _NoTopBorderBoxPainter extends BoxPainter {
  _NoTopBorderBoxPainter(this.color, this.strokeWidth, this.radius);

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size ?? Size.zero;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    final inset = strokeWidth / 2;
    final usableRadius = radius.clamp(0, size.shortestSide / 2).toDouble();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(inset, usableRadius)
      ..lineTo(inset, size.height - usableRadius)
      ..quadraticBezierTo(
          inset, size.height - inset, usableRadius, size.height - inset)
      ..lineTo(size.width - usableRadius, size.height - inset)
      ..quadraticBezierTo(size.width - inset, size.height - inset,
          size.width - inset, size.height - usableRadius)
      ..lineTo(size.width - inset, usableRadius);
    canvas.drawPath(path, paint);

    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      Path()
        ..moveTo(usableRadius, inset)
        ..quadraticBezierTo(inset, inset, inset, usableRadius),
      cornerPaint
        ..shader = ui.Gradient.linear(
          Offset(usableRadius, inset),
          Offset(inset, usableRadius),
          [color.withValues(alpha: 0), color],
        ),
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - usableRadius, inset)
        ..quadraticBezierTo(
            size.width - inset, inset, size.width - inset, usableRadius),
      cornerPaint
        ..shader = ui.Gradient.linear(
          Offset(size.width - usableRadius, inset),
          Offset(size.width - inset, usableRadius),
          [color.withValues(alpha: 0), color],
        ),
    );

    canvas.restore();
  }
}
