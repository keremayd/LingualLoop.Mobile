import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

/// B ve D varyantlarının **tam ekran** hâli — karar için.
///
/// B: ödül satırları "+N" (sayı biletin dışında), başlık aynı kalır.
/// D: satırlar aynı kalır, başlıktaki bakiye yıldızlı bilete döner.
///
///   flutter test --update-goldens test/quest_variant_bd_test.dart
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

    // Golden'da MaterialIcons yüklenmezse kum saati boş kare çıkar.
    final icons = FontLoader('MaterialIcons');
    final iconBytes = File(
      '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts'
      '/MaterialIcons-Regular.otf',
    ).readAsBytesSync();
    icons.addFont(Future.value(ByteData.view(iconBytes.buffer)));
    await icons.load();
  });

  for (final variant in _Variant.values) {
    testWidgets('varyant ${variant.name}', (tester) async {
      // Görevler ekranının referans genişliği 670 (§2.1) → ölçek 1.
      // devicePixelRatio 2: PNG net çıksın.
      const size = Size(670, 1180);
      await tester.binding.setSurfaceSize(size);
      tester.view.physicalSize = Size(size.width * 2, size.height * 2);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: _bg,
            body: _QuestsMock(variant: variant),
          ),
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
        matchesGoldenFile('goldens/quest_variant_${variant.name}.png'),
      );
    });
  }
}

enum _Variant { B, D }

const _bg = Color(0xFF041227);
const _cardBorder = Color(0xFF0B2143);
const _iconTile = Color(0xFF0C2244);
const _track = Color(0xFF0B2143);
const _progress = Color(0xFFFFC93A);
const _onProgress = Color(0xFF4A3400);
const _muted = Color(0xFF8FA0B5);
const _countdownValue = Color(0xFFE9EEF5);
const _claimFace = Color(0xFF98DE25);
const _claimBase = Color(0xFF6EA51C);

class _Quest {
  const _Quest(this.key, this.title, this.progress, this.target, this.reward,
      this.claimable);

  final String key;
  final String title;
  final int progress;
  final int target;
  final int reward;
  final bool claimable;
}

// Kullanıcının ekran görüntüsündeki liste birebir.
const _quests = <_Quest>[
  _Quest('checkin', 'Güne başla', 1, 1, 1, true),
  _Quest('correct_five', '5 kelimeyi doğru bil', 0, 5, 2, false),
  _Quest('learn_three', '3 yeni kelime öğren', 0, 3, 2, false),
  _Quest('review_two', '2 rövanş kartını geri kazan', 0, 2, 2, false),
  _Quest('streak_three', '3 günlük seriye ulaş', 0, 3, 3, false),
];

class _QuestsMock extends StatelessWidget {
  const _QuestsMock({required this.variant});

  final _Variant variant;

  @override
  Widget build(BuildContext context) {
    const scale = 1.0;

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(34, 26, 34, 54),
      children: [
        _HeaderCard(scale: scale, variant: variant),
        const SizedBox(height: 40),
        for (var i = 0; i < _quests.length; i++) ...[
          if (i > 0) const SizedBox(height: 22),
          _QuestRow(scale: scale, quest: _quests[i], variant: variant),
        ],
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.scale, required this.variant});

  final double scale;
  final _Variant variant;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      scale: scale,
      radius: 34 * scale,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            36 * scale, 34 * scale, 30 * scale, 32 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Günlük Görevler',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36 * scale,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Inter',
                          height: 1,
                        ),
                      ),
                      SizedBox(height: 18 * scale),
                      Row(
                        children: [
                          Icon(
                            Icons.hourglass_bottom_rounded,
                            color: _muted,
                            size: 27 * scale,
                          ),
                          SizedBox(width: 6 * scale),
                          Text(
                            '13 sa 33 dk',
                            style: TextStyle(
                              color: _countdownValue,
                              fontSize: 22 * scale,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Inter',
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          Flexible(
                            child: Text(
                              'sonra yenilenir',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _muted,
                                fontSize: 22 * scale,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 14 * scale),
                _balance(),
              ],
            ),
            SizedBox(height: 25 * scale),
            // Günlük hedef çubuğu: her görev bir bölme, hepsi boş (0/5).
            Row(
              children: [
                for (var i = 0; i < _quests.length; i++) ...[
                  if (i > 0) SizedBox(width: 9 * scale),
                  Expanded(
                    child: Container(
                      height: 15 * scale,
                      decoration: BoxDecoration(
                        color: _track,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 15 * scale),
            Text(
              '0/5 görev · 10 bilet seni bekliyor',
              style: TextStyle(
                color: _muted,
                fontSize: 22 * scale,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balance() {
    // D: bakiye yıldızlı bilete döner (§4.3: ticket.png = bakiye), sayı yanında.
    if (variant == _Variant.D) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icons/ticket.png',
            width: 134 * scale,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 10 * scale),
          Text(
            '15',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontSize: 46 * scale,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      );
    }
    // B: başlık bugünkü hâlinde kalır.
    return _TicketBadge(scale: scale, value: 15, height: 86);
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.scale,
    required this.quest,
    required this.variant,
  });

  final double scale;
  final _Quest quest;
  final _Variant variant;

  @override
  Widget build(BuildContext context) {
    final fraction = quest.target == 0
        ? 0.0
        : (quest.progress / quest.target).clamp(0.0, 1.0);

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
              child: QuestIcon(questKey: quest.key, size: 48 * scale),
            ),
            SizedBox(width: 25 * scale),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
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
                    label: '${quest.progress}/${quest.target}',
                  ),
                ],
              ),
            ),
            SizedBox(width: 25 * scale),
            quest.claimable ? _claimButton() : _rewardPill(),
          ],
        ),
      ),
    );
  }

  Widget _claimButton() {
    final width = (variant == _Variant.B ? 150.0 : 124.0) * scale;
    final height = 66 * scale;
    final depth = 8 * scale;

    return SizedBox(
      width: width,
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
                borderRadius: BorderRadius.circular(18 * scale),
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
                borderRadius: BorderRadius.circular(18 * scale),
              ),
              child: Center(child: _reward(onGreen: true)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardPill() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 18 * scale,
        vertical: 9 * scale,
      ),
      decoration: BoxDecoration(
        color: _iconTile,
        borderRadius: BorderRadius.circular(99),
      ),
      child: _reward(onGreen: false),
    );
  }

  Widget _reward({required bool onGreen}) {
    // D: satırlar bugünkü hâlinde — sayı biletin içinde.
    if (variant == _Variant.D) {
      return _TicketBadge(
        scale: scale,
        value: quest.reward,
        height: 46,
        prefix: onGreen ? '+' : '',
      );
    }
    // B: yıldızlı bilet + "+N" — kazanç olduğu artıdan belli.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/icons/ticket.png',
          width: 62 * scale,
          fit: BoxFit.contain,
        ),
        SizedBox(width: 8 * scale),
        Text(
          '+${quest.reward}',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: 32 * scale,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// Sayı biletin içinde — bugünkü `_TicketBadge`'in birebir kopyası.
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
