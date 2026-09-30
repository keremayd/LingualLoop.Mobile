import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/league_badge_mark.dart';
import 'package:lingualloop/ui/widgets/level_bars_icon.dart';
import 'package:lingualloop/ui/widgets/points_star_icon.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

/// Profil ekranı yerleşim seçenekleri — gerçek cihaz genişliğinde (430px).
///
/// Ölçülen sorunlar (CLAUDE.md §5):
///  * Kimlik kartı 440 birim, tamamı değişmeyen bilgi
///  * İki bölüm başlığı kutusu, her biri 140 birim, içinde tek kelime
///  * Kaplama toplamı içeriğin ~%40'ı
///  * "Genel Bakış" / "İstatistikler" ayrımı yapay — ikisi de sayı
///  * Tek dokunulabilir öğe (Rövanş) en altta
///
/// Bu turda görülen ek sorun: **iki farklı istatistik kutusu biçimi** var
/// (üstteki üçlü dikey, alttaki ikili yatay).
///
/// Referanslar: Duolingo profili kimlik → istatistik → başarım sırasıyla
/// gider ve bölüm başlıkları kutulu değil hafif metindir. Strava en fazla
/// altı istatistiği tek blokta gösterir.
///
///   flutter test --update-goldens test/profile_layout_options_test.dart
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

  testWidgets('profil yerlesim secenekleri', (tester) async {
    const size = Size(1880, 1320);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(backgroundColor: _bg, body: _Sheet()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/profile_layout_options.png'),
    );
  });
}

enum _L { current, grid, actionFirst, hero }

const _bg = Color(0xFF041227);
const _border = Color(0xFF0B2143);
const _tile = Color(0xFF0C2244);
const _muted = Color(0xFF8FA0B5);
const _flame = Color(0xFFFF6536);
const _green = Color(0xFF93D334);
const _greenDark = Color(0xFF628C22);
const _ice = Color(0xFF6BD1FF);

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Col(l: _L.current, label: 'ŞİMDİKİ', note: 'İki bölüm başlığı kutusu, iki farklı kutu biçimi, eylem en altta.'),
          SizedBox(width: 22),
          _Col(l: _L.grid, label: 'A — TEK IZGARA', note: 'Altı istatistik tek blokta (Strava). Başlık kutuları gitti, kimlik yatay.'),
          SizedBox(width: 22),
          _Col(l: _L.actionFirst, label: 'B — EYLEM YUKARIDA', note: 'Seri ve rövanş üstte: yaşayan ve dokunulabilir olan önce.'),
          SizedBox(width: 22),
          _Col(l: _L.hero, label: 'C — SERİ HERO', note: 'Seri tam genişlik kahraman. Duolingo profilinde de streak en görünür öğe.'),
        ],
      ),
    );
  }
}

class _Col extends StatelessWidget {
  const _Col({required this.l, required this.label, required this.note});

  final _L l;
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 430,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          SizedBox(
            height: 60,
            child: Text(note,
                style: const TextStyle(
                    color: _muted,
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3)),
          ),
          const SizedBox(height: 10),
          ..._body(),
        ],
      ),
    );
  }

  List<Widget> _body() {
    switch (l) {
      case _L.current:
        return [
          const _IdentityTall(),
          const SizedBox(height: 14),
          const _SectionBox('Genel Bakış'),
          const SizedBox(height: 12),
          const _TrioOld(),
          const SizedBox(height: 14),
          const _SectionBox('İstatistikler'),
          const SizedBox(height: 12),
          const _StreakCard(),
          const SizedBox(height: 12),
          const _PairOld(),
          const SizedBox(height: 12),
          const _RevengeCard(),
        ];
      case _L.grid:
        return [
          const _IdentityRow(),
          const SizedBox(height: 16),
          const _Grid6(),
          const SizedBox(height: 12),
          const _StreakCard(),
          const SizedBox(height: 12),
          const _RevengeCard(),
        ];
      case _L.actionFirst:
        return [
          const _IdentityRow(),
          const SizedBox(height: 16),
          const _StreakCard(),
          const SizedBox(height: 12),
          const _RevengeCard(),
          const SizedBox(height: 16),
          const _Grid6(),
        ];
      case _L.hero:
        return [
          const _IdentityRow(),
          const SizedBox(height: 16),
          const _StreakHero(),
          const SizedBox(height: 12),
          const _Grid6(),
          const SizedBox(height: 12),
          const _RevengeCard(),
        ];
    }
  }
}

// ---------------------------------------------------------------- kimlik

/// Şimdiki: 440 birim, fotoğraf ortada, ad altında.
class _IdentityTall extends StatelessWidget {
  const _IdentityTall();

  @override
  Widget build(BuildContext context) {
    return _Surface(
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: _tile, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.settings, color: Colors.white, size: 22),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                  color: _tile, borderRadius: BorderRadius.circular(20)),
            ),
            const SizedBox(height: 10),
            const Text('@sefasefa52007',
                style: TextStyle(
                    color: _muted,
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('sefa sefa',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

/// Öneri: yatay şerit. Aynı bilgi, dörtte bir yer.
class _IdentityRow extends StatelessWidget {
  const _IdentityRow();

  @override
  Widget build(BuildContext context) {
    return _Surface(
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: _tile, borderRadius: BorderRadius.circular(16)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('sefa sefa',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 19,
                          fontWeight: FontWeight.w900)),
                  SizedBox(height: 2),
                  Text('@sefasefa52007',
                      style: TextStyle(
                          color: _muted,
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: _tile, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.settings, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ bölüm başlığı

/// Şimdiki: tek kelime için 140 birimlik kutu.
class _SectionBox extends StatelessWidget {
  const _SectionBox(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w900)),
      ),
    );
  }
}

// ------------------------------------------------------------- istatistik

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});

  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 34, child: icon),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: _muted,
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4)),
            const SizedBox(height: 2),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontSize: 19,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

/// Şimdiki üstteki üçlü.
class _TrioOld extends StatelessWidget {
  const _TrioOld();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatTile(
                icon: const PointsStarIcon(size: 34),
                label: 'PUAN',
                value: '105')),
        const SizedBox(width: 10),
        Expanded(
            child: _StatTile(
                icon: const LevelBarsIcon(size: 34),
                label: 'SEVİYE',
                value: '2')),
        const SizedBox(width: 10),
        Expanded(
            child: _StatTile(
                icon: const LeagueBadgeMark(leagueKey: 'supernova', size: 34),
                label: 'LİG',
                value: 'Supernova')),
      ],
    );
  }
}

/// Şimdiki alttaki ikili — **farklı biçim**: ikon solda, sayı sağda.
class _PairOld extends StatelessWidget {
  const _PairOld();

  @override
  Widget build(BuildContext context) {
    Widget cell(Widget icon, String value, String label) => _Surface(
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                SizedBox(width: 32, height: 32, child: icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(value,
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w900)),
                      Text(label,
                          style: const TextStyle(
                              color: _muted,
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return Row(
      children: [
        Expanded(
            child: cell(const QuestIcon(questKey: 'correct_five', size: 32), '13',
                'Kelime öğrendin')),
        const SizedBox(width: 10),
        Expanded(
            child: cell(const QuestIcon(questKey: 'learn_three', size: 32), '5',
                'Artikel ezberledin')),
      ],
    );
  }
}

/// Öneri: altı istatistik **tek biçimde**, tek ızgarada.
class _Grid6 extends StatelessWidget {
  const _Grid6();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _StatTile(
                    icon: const PointsStarIcon(size: 34),
                    label: 'PUAN',
                    value: '105')),
            const SizedBox(width: 10),
            Expanded(
                child: _StatTile(
                    icon: const LevelBarsIcon(size: 34),
                    label: 'SEVİYE',
                    value: '2')),
            const SizedBox(width: 10),
            Expanded(
                child: _StatTile(
                    icon:
                        const LeagueBadgeMark(leagueKey: 'supernova', size: 34),
                    label: 'LİG',
                    value: 'Supernova')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _StatTile(
                    icon: const QuestIcon(questKey: 'correct_five', size: 34),
                    label: 'KELİME',
                    value: '13')),
            const SizedBox(width: 10),
            Expanded(
                child: _StatTile(
                    icon: const QuestIcon(questKey: 'learn_three', size: 34),
                    label: 'ARTİKEL',
                    value: '5')),
            const SizedBox(width: 10),
            Expanded(
                child: _StatTile(
                    icon: const TrophyIcon(size: 34),
                    label: 'LİDERLİK',
                    value: '1.')),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ seri

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    return _Surface(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const QuestIcon(questKey: 'streak_three', size: 26),
                const SizedBox(width: 8),
                const Text('0',
                    style: TextStyle(
                        color: _flame,
                        fontFamily: 'Inter',
                        fontSize: 19,
                        fontWeight: FontWeight.w900)),
                const SizedBox(width: 4),
                const Text('günlük seri',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: _tile, borderRadius: BorderRadius.circular(99)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.ac_unit, color: _ice, size: 14),
                      SizedBox(width: 4),
                      Text('2 koruma',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const _Week(),
          ],
        ),
      ),
    );
  }
}

/// C seçeneği: seri tam genişlik kahraman.
class _StreakHero extends StatelessWidget {
  const _StreakHero();

  @override
  Widget build(BuildContext context) {
    return _Surface(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                const QuestIcon(questKey: 'streak_three', size: 44),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('0 günlük seri',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                      SizedBox(height: 2),
                      Text('Serine bugün başla',
                          style: TextStyle(
                              color: _flame,
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: _tile, borderRadius: BorderRadius.circular(99)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.ac_unit, color: _ice, size: 14),
                      SizedBox(width: 4),
                      Text('2',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _Week(),
          ],
        ),
      ),
    );
  }
}

class _Week extends StatelessWidget {
  const _Week();

  static const _labels = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pa'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_labels[i],
                  style: TextStyle(
                      color: i == 6 ? Colors.white : _muted,
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: i == 6 ? FontWeight.w900 : FontWeight.w700)),
              const SizedBox(height: 5),
              SizedBox(
                  width: 26,
                  height: 26,
                  child: CustomPaint(painter: _DayPainter(filled: i == 0))),
            ],
          ),
      ],
    );
  }
}

class _DayPainter extends CustomPainter {
  const _DayPainter({required this.filled});

  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    if (!filled) {
      final dash = Paint()
        ..color = const Color(0xFF2A3A52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (var i = 0; i < 12; i++) {
        canvas.drawArc(Rect.fromCircle(center: c, radius: r - 1),
            i * 3.14159 / 6, 3.14159 / 11, false, dash);
      }
      return;
    }
    canvas.drawCircle(c, r, Paint()..color = _flame);
    canvas.drawPath(
      Path()
        ..moveTo(r * 0.55, r * 1.02)
        ..lineTo(r * 0.88, r * 1.35)
        ..lineTo(r * 1.45, r * 0.68),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DayPainter old) => old.filled != filled;
}

// ---------------------------------------------------------------- eylem

class _RevengeCard extends StatelessWidget {
  const _RevengeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          const QuestIcon(questKey: 'review_two', size: 30),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('1 rövanş kartı seni bekliyor',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w900)),
                SizedBox(height: 2),
                Text('Yanlış bildiklerini geri kazan',
                    style: TextStyle(
                        color: _muted,
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 30,
            decoration: BoxDecoration(
                color: _green, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.chevron_right,
                color: _greenDark, size: 22),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- yüzey

class _Surface extends StatelessWidget {
  const _Surface({required this.radius, required this.child});

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _border,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: const EdgeInsets.only(bottom: 5),
      child: Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(radius),
        ),
        foregroundDecoration: _NoTop(color: _border, radius: radius),
        child: child,
      ),
    );
  }
}

class _NoTop extends Decoration {
  const _NoTop({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _NoTopPainter(color, radius);
}

class _NoTopPainter extends BoxPainter {
  _NoTopPainter(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final size = cfg.size ?? Size.zero;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    const sw = 1.5;
    const inset = sw / 2;
    final r = radius.clamp(0, size.shortestSide / 2).toDouble();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw;

    canvas.drawPath(
      Path()
        ..moveTo(inset, r)
        ..lineTo(inset, size.height - r)
        ..quadraticBezierTo(inset, size.height - inset, r, size.height - inset)
        ..lineTo(size.width - r, size.height - inset)
        ..quadraticBezierTo(size.width - inset, size.height - inset,
            size.width - inset, size.height - r)
        ..lineTo(size.width - inset, r),
      paint,
    );

    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(r, inset)
        ..quadraticBezierTo(inset, inset, inset, r),
      corner
        ..shader = ui.Gradient.linear(Offset(r, inset), Offset(inset, r),
            [color.withValues(alpha: 0), color]),
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - r, inset)
        ..quadraticBezierTo(
            size.width - inset, inset, size.width - inset, r),
      corner
        ..shader = ui.Gradient.linear(Offset(size.width - r, inset),
            Offset(size.width - inset, r), [color.withValues(alpha: 0), color]),
    );
    canvas.restore();
  }
}
