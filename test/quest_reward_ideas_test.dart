import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

/// Görev ödülü — yapısal fikirler, tek sayfada yan yana.
///
/// Araştırma notu: Duolingo bir görevin yanına **çıplak sayı koymuyor**.
/// Ödül, ilerleme barının **ucundaki sandık**; değeri sandığın kademesi
/// söylüyor. Gerekçe goal-gradient: bar bir hedefe doğru dolmalı ve hedef
/// görünür olmalı. Aşağıdaki E bu fikrin bizim dilimizdeki karşılığı.
///
///   flutter test --update-goldens test/quest_reward_ideas_test.dart
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

    final icons = FontLoader('MaterialIcons');
    final iconBytes = File(
      '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts'
      '/MaterialIcons-Regular.otf',
    ).readAsBytesSync();
    icons.addFont(Future.value(ByteData.view(iconBytes.buffer)));
    await icons.load();
  });

  testWidgets('odul fikirleri', (tester) async {
    const size = Size(2812, 950);
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
      matchesGoldenFile('goldens/quest_reward_ideas.png'),
    );
  });
}

enum _Idea { current, barEnd, cornerCount, stack }

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

const _quests = <_Quest>[
  _Quest('checkin', 'Güne başla', 1, 1, 1, true),
  _Quest('correct_five', '5 kelimeyi doğru bil', 2, 5, 2, false),
  _Quest('streak_three', '3 günlük seriye ulaş', 0, 3, 3, false),
];

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Column(
            idea: _Idea.current,
            label: 'A — ŞİMDİKİ',
            note: 'Sayı biletin yüzünde. Başlıktaki bakiye ile '
                'satırdaki ödül aynı nesne.',
          ),
          const SizedBox(width: 24),
          _Column(
            idea: _Idea.barEnd,
            label: 'E — ÖDÜL BARIN UCUNDA',
            note: "Duolingo'nun asıl fikri: bar bir hedefe doğru dolar. "
                'Ödül ayrı sütun değil, barın varış noktası.',
          ),
          const SizedBox(width: 24),
          _Column(
            idea: _Idea.cornerCount,
            label: 'F — KÖŞE SAYACI',
            note: 'Bilet olduğu gibi kalır (yıldız yerinde), adet '
                'köşeye küçük rozet olarak iner. Oyun standardı.',
          ),
          const SizedBox(width: 24),
          _Column(
            idea: _Idea.stack,
            label: 'G — BİLET İSTİFİ',
            note: 'Rakam yok. Ödül 1–3 olduğu için o kadar bilet '
                'üst üste çizilir; göz sayar.',
          ),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.idea, required this.label, required this.note});

  final _Idea idea;
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    const scale = 1.0;

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
          const SizedBox(height: 16),
          _HeaderCard(scale: scale, idea: idea),
          const SizedBox(height: 34),
          for (var i = 0; i < _quests.length; i++) ...[
            if (i > 0) const SizedBox(height: 22),
            _QuestRow(scale: scale, quest: _quests[i], idea: idea),
          ],
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.scale, required this.idea});

  final double scale;
  final _Idea idea;

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
                          Icon(Icons.hourglass_bottom_rounded,
                              color: _muted, size: 27 * scale),
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
                // Bakiye: A'da sayı biletin yüzünde. Diğer üçünde satırlar
                // zaten farklı bir dil konuştuğu için bakiye yıldızlı bilete
                // dönebiliyor — çakışma kendiliğinden kalkıyor.
                if (idea == _Idea.current)
                  _TicketBadge(scale: scale, value: 15, height: 86)
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/icons/ticket.png',
                          width: 118 * scale, fit: BoxFit.contain),
                      SizedBox(width: 10 * scale),
                      Text(
                        '15',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 44 * scale,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            SizedBox(height: 25 * scale),
            Row(
              children: [
                for (var i = 0; i < 5; i++) ...[
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
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.scale,
    required this.quest,
    required this.idea,
  });

  final double scale;
  final _Quest quest;
  final _Idea idea;

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
                  // E: ödül barın **varış noktası** — barın sağ ucuna biner.
                  if (idea == _Idea.barEnd)
                    SizedBox(
                      height: 72 * scale,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Bar, ödülün altından geçsin diye sağdan içeri çekilir.
                          Padding(
                            padding: EdgeInsets.only(right: 46 * scale),
                            child: _ProgressBar(
                              scale: scale,
                              fraction: fraction,
                              label: '${quest.progress}/${quest.target}',
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: _barEndCap(),
                          ),
                        ],
                      ),
                    )
                  else
                    _ProgressBar(
                      scale: scale,
                      fraction: fraction,
                      label: '${quest.progress}/${quest.target}',
                    ),
                ],
              ),
            ),
            if (idea != _Idea.barEnd) ...[
              SizedBox(width: 25 * scale),
              quest.claimable ? _claimButton() : _rewardPill(),
            ],
          ],
        ),
      ),
    );
  }

  /// E: barın ucundaki ödül — küçültülmüş bir nokta değil, **görünür bir
  /// hedef**. Tamamlandıysa yeşil daireye oturur; değilse çıplak durur ve
  /// barın vardığı yeri işaretler.
  Widget _barEndCap() {
    if (quest.claimable) {
      final d = 72 * scale;
      return SizedBox(
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
                  borderRadius: BorderRadius.circular(99),
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
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Center(
                  child: Image.asset('assets/icons/ticket.png',
                      width: 52 * scale, fit: BoxFit.contain),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Koyu yuva kaldırıldı: "devre dışı nokta" gibi okunuyordu. Ödül çıplak
    // durunca bar ona doğru dolan bir yol hâline geliyor.
    return _ticketWithCorner(ticketWidth: 66 * scale, badge: 34 * scale);
  }

  Widget _claimButton() {
    final width = (idea == _Idea.stack ? 150.0 : 124.0) * scale;
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
    switch (idea) {
      case _Idea.current:
        return _TicketBadge(
          scale: scale,
          value: quest.reward,
          height: 46,
          prefix: onGreen ? '+' : '',
        );
      case _Idea.cornerCount:
        return _ticketWithCorner(
          ticketWidth: 62 * scale,
          badge: 32 * scale,
          onGreen: onGreen,
        );
      case _Idea.stack:
        return _ticketStack(onGreen: onGreen);
      case _Idea.barEnd:
        return const SizedBox.shrink();
    }
  }

  /// F: bilet olduğu gibi durur, adet köşede küçük rozet.
  Widget _ticketWithCorner({
    required double ticketWidth,
    required double badge,
    bool onGreen = false,
  }) {
    final h = ticketWidth * 110 / 172;

    return SizedBox(
      width: ticketWidth + badge * 0.42,
      height: h + badge * 0.34,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Image.asset('assets/icons/ticket.png',
                width: ticketWidth, fit: BoxFit.contain),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: badge,
              height: badge,
              decoration: BoxDecoration(
                // Yeşil butonun üstünde koyu yeşil, koyu yuvada sayfa zemini:
                // rozet her iki zeminde de "oyulmuş" görünür.
                color: onGreen ? _claimBase : _bg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: onGreen ? _claimFace : _iconTile,
                  width: 2 * scale,
                ),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.all(3 * scale),
                  child: Text(
                    '${quest.reward}',
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

  /// G: rakam yok — ödül kaçsa o kadar bilet üst üste.
  ///
  /// İlk denemede adım çok dardı (26/58) ve üç bilet leke oluyordu. İki
  /// düzeltme: adım açıldı, ve her biletin arkasına zemin renginde bir
  /// siluet kondu — üst üste binen kenarlar birbirinden **kesilerek**
  /// ayrılıyor, göz tek tek sayabiliyor.
  Widget _ticketStack({required bool onGreen}) {
    const step = 40.0;
    final w = 54 * scale;
    final h = w * 110 / 172;
    final outline = 5 * scale;
    final total = w + step * (quest.reward - 1) * scale;

    return SizedBox(
      width: total + outline,
      height: h + outline * 2,
      child: Stack(
        children: [
          for (var i = 0; i < quest.reward; i++)
            Positioned(
              left: i * step * scale,
              top: outline,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Ayırıcı siluet: bir alttaki biletin kenarını keser.
                  Positioned(
                    left: -outline,
                    top: -outline,
                    child: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (rect) => LinearGradient(
                        colors: [
                          onGreen ? _claimFace : _bg,
                          onGreen ? _claimFace : _bg,
                        ],
                      ).createShader(rect),
                      child: Image.asset(
                        'assets/icons/ticket.png',
                        width: w + outline * 2,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Image.asset('assets/icons/ticket.png',
                      width: w, fit: BoxFit.contain),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

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
            child: Image.asset('assets/icons/ticket.png',
                width: width, height: h, fit: BoxFit.contain),
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
