import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

/// Alınabilir görevin ödül hedefi — revizyon adayları.
///
/// Şimdiki hâlin iki kusuru: (1) daire uygulamada olmayan bir biçim
/// (§2.4 basılabilirler yuvarlatılmış dikdörtgen), (2) altın bilet yeşil
/// zemine oturunca iki doymuş renk birbirini bulandırıyor — bilet
/// uygulamanın her yerinde koyu lacivert üstünde duruyor.
///
///   flutter test --update-goldens test/quest_claim_revision_test.dart
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

  testWidgets('claim hedefi revizyonlari', (tester) async {
    const size = Size(2812, 1090);
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
      matchesGoldenFile('goldens/quest_claim_revision.png'),
    );
  });
}

/// R0 şimdiki (daire + altın bilet), R1 uygulamanın buton biçimi,
/// R2 biletin kendisi buton, R3 yeşil buton + krem bilet,
/// R4 koyu zeminde altın bilet + yeşil halka.
enum _Rev { current, appButton, ticketButton, creamTicket, greenRing, fullBar }

const _bg = Color(0xFF041227);
const _cardBorder = Color(0xFF0B2143);
const _iconTile = Color(0xFF0C2244);
const _track = Color(0xFF0B2143);
const _progress = Color(0xFFFFC93A);
const _onProgress = Color(0xFF4A3400);
const _muted = Color(0xFF8FA0B5);
const _claimFace = Color(0xFF98DE25);
const _claimBase = Color(0xFF6EA51C);
const _green = Color(0xFF93D334);

/// Altının koyusu — §2.2'ye göre yüzden türetilir (lig paletindeki `yildiz`
/// taşının koyu tonu ile aynı).
const _goldDepth = Color(0xFFB87E00);

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
            rev: _Rev.appButton,
            label: 'R1 — YEŞİL BUTON + ALTIN BİLET',
            note: 'Biçim uygulamaya döndü (§2.4 yuvarlatılmış dikdörtgen), '
                'ama iki doymuş renk hâlâ üst üste.',
          ),
          SizedBox(width: 24),
          _Col(
            rev: _Rev.creamTicket,
            label: 'R3 — YEŞİL BUTON + KREM BİLET',
            note: 'Yeşil butonun üstünde krem simge — DepthPressableButton '
                'zaten beyaz metin koyuyor, correct_five ikonu zaten krem.',
          ),
          SizedBox(width: 24),
          _Col(
            rev: _Rev.ticketButton,
            label: 'R2+ — KABARIK BİLET + HÂLE',
            note: 'Yeşil kap yok; kalınlık bandı + sıcak hâle. Hâle olmadan '
                'bekleyen satırdan ayırt edilemiyordu.',
          ),
          SizedBox(width: 24),
          _Col(
            rev: _Rev.fullBar,
            label: 'R5 — BARIN KENDİSİ BUTON',
            note: 'Bar dolduysa işi bitti; tamamı yeşil basılabilir butona '
                'dönüşür. En büyük dokunma hedefi.',
          ),
        ],
      ),
    );
  }
}

class _Col extends StatelessWidget {
  const _Col({required this.rev, required this.label, required this.note});

  final _Rev rev;
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
            height: 84,
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
          const SizedBox(height: 10),
          const _Caption('TASARIM BOYUTU'),
          const SizedBox(height: 10),
          _Row(rev: rev, width: 670, claimable: true),
          const SizedBox(height: 20),
          _Row(rev: rev, width: 670, claimable: false),
          const SizedBox(height: 30),
          // Asıl yargı burada: öğe cihazda ≈46pt. Tasarım boyutunda iyi
          // görünen bir şey bu ölçekte dağılabilir.
          const _Caption('GERÇEK BOYUT — 430px cihaz'),
          const SizedBox(height: 10),
          SizedBox(width: 430, child: _Row(rev: rev, width: 430, claimable: true)),
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
        fontSize: 17,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.rev,
    required this.width,
    required this.claimable,
  });

  final _Rev rev;
  final double width;
  final bool claimable;

  @override
  Widget build(BuildContext context) {
    final scale = width / 670;
    final fraction = claimable ? 1.0 : 0.4;

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
              child: QuestIcon(
                questKey: claimable ? 'checkin' : 'correct_five',
                size: 48 * scale,
              ),
            ),
            SizedBox(width: 25 * scale),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    claimable ? 'Güne başla' : '5 kelimeyi doğru bil',
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
                  // R5: bar dolduğunda bar **butona dönüşür**; ayrı bir uç
                  // öğesi kalmaz.
                  if (rev == _Rev.fullBar && claimable)
                    SizedBox(
                      height: 72 * scale,
                      child: Center(child: _fullBarButton(scale)),
                    )
                  else
                    SizedBox(
                      height: 72 * scale,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 46 * scale),
                            child: _Bar(
                              scale: scale,
                              fraction: fraction,
                              label: claimable ? '1/1' : '2/5',
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
    if (!claimable) {
      return _TicketWithCount(
        scale: scale,
        count: 2,
        ticketWidth: 66,
        badgeSize: 34,
      );
    }

    switch (rev) {
      case _Rev.current:
        return _greenContainer(scale, circle: true, ticketGold: true);
      case _Rev.appButton:
        return _greenContainer(scale, circle: false, ticketGold: true);
      case _Rev.creamTicket:
        return _greenContainer(scale, circle: false, ticketGold: false);
      case _Rev.ticketButton:
        return _raisedTicket(scale);
      case _Rev.greenRing:
        return _ringedTicket(scale);
      case _Rev.fullBar:
        return const SizedBox.shrink();
    }
  }

  /// R5: dolu bar tamamen yeşil basılabilir butona dönüşür.
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
                    shaderCallback: (r) => const LinearGradient(
                      colors: [Color(0xFFF6EDE4), Color(0xFFF6EDE4)],
                    ).createShader(r),
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

  /// R0/R1/R3: yeşil kap. `circle` biçimi, `ticketGold` bilet rengini seçer.
  Widget _greenContainer(double scale,
      {required bool circle, required bool ticketGold}) {
    final w = 72 * scale;
    final h = 72 * scale;
    final depth = 7 * scale;
    final radius =
        BorderRadius.circular(circle ? 99 : 20 * scale);

    final ticket = ticketGold
        ? Image.asset('assets/icons/ticket.png',
            width: 52 * scale, fit: BoxFit.contain)
        : ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (r) => const LinearGradient(
              colors: [Color(0xFFF6EDE4), Color(0xFFF6EDE4)],
            ).createShader(r),
            child: Image.asset('assets/icons/ticket.png',
                width: 52 * scale, fit: BoxFit.contain),
          );

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: depth,
            height: h - depth,
            child: DecoratedBox(
              decoration:
                  BoxDecoration(color: _claimBase, borderRadius: radius),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: h - depth,
            child: DecoratedBox(
              decoration:
                  BoxDecoration(color: _claimFace, borderRadius: radius),
              child: Center(
                child: _withCorner(
                  scale: scale,
                  child: ticket,
                  badge: 28 * scale,
                  onGreen: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// R2: biletin kendisi buton. §2.5 kalınlık bandı — biletin koyu silueti
  /// altına iner, kabartma onu basılabilir yapar. Yeşil kap yok.
  Widget _raisedTicket(double scale) {
    final w = 78 * scale;
    final h = w * 110 / 172;
    final depth = 7 * scale;

    return SizedBox(
      width: w + 14 * scale,
      height: h + depth + 10 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Sıcak hâle: "toplanabilir" sinyali. Bu olmadan alınabilir satır
          // bekleyen satırdan ayırt edilemiyordu — ikisi de lacivert üstünde
          // altın bilet. Alfa yüksek tutulur (§5: lacivert üstünde düşük
          // alfalı doymuş sıcak ton zeytine döner).
          Positioned(
            left: -10 * scale,
            top: -6 * scale,
            child: Container(
              width: w + 20 * scale,
              height: h + 20 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFC93A).withValues(alpha: 0.42),
                    const Color(0xFFFFC93A).withValues(alpha: 0),
                  ],
                  stops: const [0.35, 1],
                ),
              ),
            ),
          ),
          // Kalınlık bandı.
          Positioned(
            left: 0,
            top: depth,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (r) => const LinearGradient(
                colors: [_goldDepth, _goldDepth],
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
            child: _countBadge(scale: scale, badge: 32 * scale, onGreen: false),
          ),
        ],
      ),
    );
  }

  /// R4: bilet koyu zeminde, çevresinde ince yeşil halka.
  Widget _ringedTicket(double scale) {
    final d = 76 * scale;

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
              shape: BoxShape.circle,
              border: Border.all(color: _green, width: 4 * scale),
            ),
            alignment: Alignment.center,
            child: Image.asset('assets/icons/ticket.png',
                width: 50 * scale, fit: BoxFit.contain),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _countBadge(scale: scale, badge: 30 * scale, onGreen: false),
          ),
        ],
      ),
    );
  }

  Widget _withCorner({
    required double scale,
    required Widget child,
    required double badge,
    required bool onGreen,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -badge * 0.3,
          bottom: -badge * 0.22,
          child: _countBadge(scale: scale, badge: badge, onGreen: onGreen),
        ),
      ],
    );
  }

  Widget _countBadge({
    required double scale,
    required double badge,
    required bool onGreen,
  }) {
    return Container(
      width: badge,
      height: badge,
      decoration: BoxDecoration(
        color: onGreen ? _claimBase : _bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: onGreen ? _claimFace : _cardBorder,
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
              color: Colors.white,
              fontFamily: 'Inter',
              fontSize: badge * 0.62,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketWithCount extends StatelessWidget {
  const _TicketWithCount({
    required this.scale,
    required this.count,
    required this.ticketWidth,
    required this.badgeSize,
  });

  final double scale;
  final int count;
  final double ticketWidth;
  final double badgeSize;

  static const _aspect = 172 / 110;

  @override
  Widget build(BuildContext context) {
    final w = ticketWidth * scale;
    final h = w / _aspect;
    final badge = badgeSize * scale;

    return SizedBox(
      width: w + badge * 0.42,
      height: h + badge * 0.34,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Image.asset('assets/icons/ticket.png',
                width: w, fit: BoxFit.contain),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: badge,
              height: badge,
              decoration: BoxDecoration(
                color: _bg,
                shape: BoxShape.circle,
                border: Border.all(color: _cardBorder, width: 2 * scale),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.all(3 * scale),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontSize: badge * 0.62,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
