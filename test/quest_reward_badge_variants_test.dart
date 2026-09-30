import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

/// Görev satırındaki ödül rozeti — varyant karşılaştırması.
///
/// Sorun tipografik değil **anlamsal**: aynı simge (sayısı içine yazılmış
/// bilet) hem başlıkta *bakiyeyi* hem satırlarda *ödülü* anlatıyor. Ekranda
/// yukarıdan aşağı 15 · +1 · 2 · 2 · 2 · 3 diziliyor ve hangisinin "sende
/// olan", hangisinin "kazanacağın" olduğunu yalnızca konum söylüyor.
///
///   flutter test --update-goldens test/quest_reward_badge_variants_test.dart
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

  testWidgets('odul rozeti varyantlari', (tester) async {
    const size = Size(1420, 1960);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        // Material atası olmadan Text'ler sarı alt çizgiyle çiziliyor.
        home: Scaffold(
          backgroundColor: _bg,
          body: _VariantSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Golden'da Image.asset kendiliğinden çözülmez; elle yüklet.
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/quest_reward_badge_variants.png'),
    );
  });
}

const _bg = Color(0xFF041227);
const _cardBorder = Color(0xFF0B2143);
const _iconTile = Color(0xFF0C2244);
const _track = Color(0xFF0B2143);
const _progress = Color(0xFFFFC93A);
const _onProgress = Color(0xFF4A3400);
const _muted = Color(0xFF8FA0B5);
const _claimFace = Color(0xFF98DE25);
const _claimBase = Color(0xFF6EA51C);

class _VariantSheet extends StatelessWidget {
  const _VariantSheet();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _bg,
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _VariantColumn(
                    label: 'A — ŞİMDİKİ HÂL',
                    note: 'Sayı biletin içinde. Başlıktaki bakiye ile '
                        'satırdaki ödül aynı nesne.',
                    style: _RewardStyle.numberInside,
                    balanceStyle: _BalanceStyle.numberInside,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _VariantColumn(
                    label: 'B — KAZANÇ ARTIYLA',
                    note: 'Ödül "+2", sayı dışarıda. Artı zaten senin '
                        'kuralın: "kazanılacak miktar".',
                    style: _RewardStyle.plusOutside,
                    balanceStyle: _BalanceStyle.numberInside,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _VariantColumn(
                    label: 'C — ADET DİLİ (§4.3)',
                    note: 'ticket-one.png + "×2". Uygulamanın geri '
                        'kalanındaki adet/bedel kuralı.',
                    style: _RewardStyle.timesOne,
                    balanceStyle: _BalanceStyle.numberInside,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _VariantColumn(
                    label: 'D — BAKİYEYİ AYIR',
                    note: 'Satırlar aynı kalır; başlıktaki bakiye '
                        'yıldızlı bilete döner, sayı yanında.',
                    style: _RewardStyle.numberInside,
                    balanceStyle: _BalanceStyle.starBeside,
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

enum _RewardStyle { numberInside, plusOutside, timesOne }

enum _BalanceStyle { numberInside, starBeside }

class _VariantColumn extends StatelessWidget {
  const _VariantColumn({
    required this.label,
    required this.note,
    required this.style,
    required this.balanceStyle,
  });

  final String label;
  final String note;
  final _RewardStyle style;
  final _BalanceStyle balanceStyle;

  @override
  Widget build(BuildContext context) {
    // Görevler ekranının referans genişliği 670 (§2.1); hücre o genişlikte
    // çizildiği için ölçek 1 — tasarım birimi = piksel.
    const scale = 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 56,
          child: Text(
            note,
            style: const TextStyle(
              color: _muted,
              fontFamily: 'Inter',
              fontSize: 19,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Başlık: bakiye rozetinin ödül rozetiyle çakışıp çakışmadığı burada
        // görünür.
        _Surface(
          scale: scale,
          radius: 28,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 22),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Günlük Görevler',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ),
                if (balanceStyle == _BalanceStyle.numberInside)
                  const _TicketBadge(scale: scale, value: 15, height: 86)
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Image(
                        image: AssetImage('assets/icons/ticket.png'),
                        width: 134,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: 10),
                      Text(
                        '15',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        _QuestRow(
          scale: scale,
          questKey: 'checkin',
          title: 'Güne başla',
          progress: 1,
          target: 1,
          reward: 1,
          claimable: true,
          style: style,
        ),
        const SizedBox(height: 22),
        _QuestRow(
          scale: scale,
          questKey: 'correct_five',
          title: '5 kelimeyi doğru bil',
          progress: 0,
          target: 5,
          reward: 2,
          claimable: false,
          style: style,
        ),
        const SizedBox(height: 22),
        _QuestRow(
          scale: scale,
          questKey: 'learn_three',
          title: '3 yeni kelime öğren',
          progress: 0,
          target: 3,
          reward: 2,
          claimable: false,
          style: style,
        ),
        const SizedBox(height: 22),
        _QuestRow(
          scale: scale,
          questKey: 'streak_three',
          title: '3 günlük seriye ulaş',
          progress: 0,
          target: 3,
          reward: 3,
          claimable: false,
          style: style,
        ),
      ],
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.scale,
    required this.questKey,
    required this.title,
    required this.progress,
    required this.target,
    required this.reward,
    required this.claimable,
    required this.style,
  });

  final double scale;
  final String questKey;
  final String title;
  final int progress;
  final int target;
  final int reward;
  final bool claimable;
  final _RewardStyle style;

  @override
  Widget build(BuildContext context) {
    final fraction = target == 0 ? 0.0 : (progress / target).clamp(0.0, 1.0);

    return _Surface(
      scale: scale,
      radius: 28 * scale,
      child: Container(
        height: 138 * scale,
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
              child: QuestIcon(questKey: questKey, size: 48 * scale),
            ),
            SizedBox(width: 25 * scale),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
                  _ProgressBar(
                    scale: scale,
                    fraction: fraction,
                    label: '$progress/$target',
                  ),
                ],
              ),
            ),
            SizedBox(width: 25 * scale),
            claimable
                ? _claimButton()
                : _rewardPill(),
          ],
        ),
      ),
    );
  }

  Widget _claimButton() {
    const width = 124.0;
    const height = 66.0;
    const depth = 8.0;

    return SizedBox(
      width: style == _RewardStyle.numberInside ? width : 150,
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: depth,
            height: height - depth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _claimBase,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: height - depth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _claimFace,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(child: _rewardContent(onGreen: true)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: _iconTile,
        borderRadius: BorderRadius.circular(99),
      ),
      child: _rewardContent(onGreen: false),
    );
  }

  Widget _rewardContent({required bool onGreen}) {
    switch (style) {
      case _RewardStyle.numberInside:
        return _TicketBadge(
          scale: scale,
          value: reward,
          height: 46,
          prefix: onGreen ? '+' : '',
        );
      case _RewardStyle.plusOutside:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Image(
              image: AssetImage('assets/icons/ticket.png'),
              width: 62,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              '+$reward',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        );
      case _RewardStyle.timesOne:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Image(
              image: AssetImage('assets/icons/ticket-one.png'),
              width: 62,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              '×$reward',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        );
    }
  }
}

/// Görevler ekranındaki bilet rozeti (sayı biletin içinde) — birebir kopya.
class _TicketBadge extends StatelessWidget {
  const _TicketBadge({
    required this.scale,
    required this.value,
    this.height = 86,
    this.prefix = '',
  });

  final double scale;
  final int value;
  final String prefix;
  final double height;

  static const _aspect = 172 / 110;
  static const _frame = Color(0xFFFFCC29);
  static const _panel = Color(0xFFF99300);
  static const _panelWidthRatio = 0.616;
  static const _panelHeightRatio = 0.727;

  @override
  Widget build(BuildContext context) {
    final h = height * scale;
    final width = h * _aspect;

    return SizedBox(
      width: width,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (rect) => const LinearGradient(
              colors: [_frame, _frame],
            ).createShader(rect),
            child: Image.asset(
              'assets/icons/ticket.png',
              width: width,
              height: h,
              fit: BoxFit.contain,
            ),
          ),
          Container(
            width: width * _panelWidthRatio,
            height: h * _panelHeightRatio,
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(10 * scale),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                child: Text(
                  '$prefix$value',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontSize: height * 0.5 * scale,
                    fontWeight: FontWeight.w900,
                    height: 1,
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

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
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

/// §2.3 kart dili: yüz = sayfa zemini, üstsüz kontur, altta taban dudağı.
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
