import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/league_badge_mark.dart';
import 'package:lingualloop/ui/widgets/level_bars_icon.dart';
import 'package:lingualloop/ui/widgets/points_star_icon.dart';
import 'package:lingualloop/ui/widgets/profile_learning_stats_card.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

/// Profil yerleşimi — **yönlendirici** tasarım.
///
/// Önceki iki tur reddedildi. Geri bildirim: "alt başlıklar yok, yönlendirici
/// değil". Doğruydu — bölüm başlıklarını kaldırmıştım ve ekran yalnızca
/// güncel sayı döküyordu.
///
/// Araştırma bulguları:
///  * **Duolingo profili başlıklı bölümlerden oluşur**: Statistics →
///    Achievements → Friends → Courses.
///  * **Achievements ikiye ayrılır: Personal Records + Awards.** Personal
///    Records = en uzun seri, bir günde en çok XP — yani **aşılacak hedef**.
///    Bizde yalnızca güncel değer vardı.
///  * **Busuu** ders yolunu "nerede olduğun ve sırada ne olduğu" olarak
///    gösterir; Review sekmesi kelimeleri güce göre ayırıp **eylem** sunar.
///
/// Ortak payda: bu ekranlar hedef, rekor ve eylem gösteriyor.
///
///   flutter test --update-goldens test/profile_guiding_test.dart
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

  testWidgets('profil yonlendirici', (tester) async {
    const size = Size(490, 1180);
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
      matchesGoldenFile('goldens/profile_guiding.png'),
    );
  });
}

enum _P { goals, duo }

const _bg = Color(0xFF041227);
const _border = Color(0xFF0B2143);
const _tile = Color(0xFF0C2244);
const _muted = Color(0xFF8FA0B5);
const _flame = Color(0xFFFF6536);
const _green = Color(0xFF93D334);
const _gold = Color(0xFFFFC93A);
const _blue = Color(0xFF1CB1F5);
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
          _Col(
            p: _P.goals,
            label: 'G — SON HÂL',
            note: 'Seri kartı aynen korundu, ikonlar değişmedi. Değişen '
                'yalnızca yerleşim ve bölüm başlıkları.',
          ),
        ],
      ),
    );
  }
}

class _Col extends StatelessWidget {
  const _Col({required this.p, required this.label, required this.note});

  final _P p;
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
            height: 52,
            child: Text(note,
                style: const TextStyle(
                    color: _muted,
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.3)),
          ),
          const SizedBox(height: 10),
          const _Identity(),
          const SizedBox(height: 18),
          ...(p == _P.goals ? _goals() : _duo()),
        ],
      ),
    );
  }

  // G — hedef odaklı
  List<Widget> _goals() => const [
        _Heading('SIRADAKİ HEDEFLERİN'),
        SizedBox(height: 10),
        _GoalCard(),
        SizedBox(height: 18),
        _Heading('BUGÜN'),
        SizedBox(height: 10),
        _StreakCard(),
        SizedBox(height: 10),
        _ActionCard(),
        SizedBox(height: 18),
        _Heading('TOPLAM'),
        SizedBox(height: 10),
        _StatRow(),
      ];

  // H — Duolingo yapısı
  List<Widget> _duo() => const [
        _Heading('İSTATİSTİKLER'),
        SizedBox(height: 10),
        _Grid4(),
        SizedBox(height: 18),
        _Heading('REKORLARIN'),
        SizedBox(height: 10),
        _RecordsCard(),
        SizedBox(height: 18),
        _Heading('YAPILACAKLAR'),
        SizedBox(height: 10),
        _ActionCard(),
        SizedBox(height: 10),
        _WeakWordsCard(),
      ];
}

/// Bölüm başlığı: **kutu değil**, hafif metin. Eskiden tek kelime için
/// 140 birimlik kart harcanıyordu; başlığın kendisi değil kutusu sorundu.
class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _muted,
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }
}

/// Kimlik kartı **büyük kalıyor**. Küçültmek daha önce denenmiş ve geri
/// alınmıştı: kart tek başına küçülünce sayfanın kalanı yanında cılız
/// görünüyor (CLAUDE.md §5). Ayrıca ekranın üstü boşalıyor.
class _Identity extends StatelessWidget {
  const _Identity();

  @override
  Widget build(BuildContext context) {
    return _Surface(
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: _tile, borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.settings, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                  color: _tile, borderRadius: BorderRadius.circular(24)),
            ),
            const SizedBox(height: 12),
            const Text('@sefasefa52007',
                style: TextStyle(
                    color: _muted,
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            const Text('sefa sefa',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontSize: 21,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

/// G'nin omurgası: üç hedef, her biri "ne kadar kaldı" diyor.
class _GoalCard extends StatelessWidget {
  const _GoalCard();

  @override
  Widget build(BuildContext context) {
    return _Surface(
      radius: 20,
      child: Column(
        children: [
          _goalRow(
            icon: const LevelBarsIcon(size: 28),
            title: 'Seviye 3',
            hint: '45 puan kaldı',
            fraction: 0.55,
            color: _blue,
          ),
          _divider(),
          _goalRow(
            icon: const LeagueBadgeMark(leagueKey: 'pulsar', size: 28),
            title: 'Pulsar ligi',
            hint: '18 puan kaldı',
            fraction: 0.7,
            color: _gold,
          ),
          _divider(),
          _goalRow(
            icon: const QuestIcon(questKey: 'streak_three', size: 28),
            title: '3 günlük rozet',
            hint: '3 gün kaldı',
            fraction: 0.0,
            color: _flame,
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.only(left: 52),
        child: Container(height: 1, color: _border),
      );

  Widget _goalRow({
    required Widget icon,
    required String title,
    required String hint,
    required double fraction,
    required Color color,
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 13, 14, last ? 15 : 13),
      child: Row(
        children: [
          SizedBox(width: 28, height: 28, child: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    ),
                    Text(hint,
                        style: TextStyle(
                            color: color,
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 8,
                    child: Stack(
                      children: [
                        const Positioned.fill(child: ColoredBox(color: _tile)),
                        if (fraction > 0)
                          FractionallySizedBox(
                            widthFactor: fraction,
                            child: Container(color: color),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mevcut `ProfileStreakCard` görünümü korunuyor: alev + sayı + koruma hapı,
/// altında yedi günlük şerit. Kullanıcı bu kartın **aynen kalmasını** istedi;
/// yerleşim değişiyor, kartın kendisi değil.
class _StreakCard extends StatelessWidget {
  const _StreakCard();

  static const _labels = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pa'];

  @override
  Widget build(BuildContext context) {
    return _Surface(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const QuestIcon(questKey: 'streak_three', size: 34),
                const SizedBox(width: 10),
                const Text('0',
                    style: TextStyle(
                        color: _flame,
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                const SizedBox(width: 5),
                const Text('günlük seri',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                      color: _tile, borderRadius: BorderRadius.circular(99)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.ac_unit, color: _ice, size: 16),
                      SizedBox(width: 5),
                      Text('2 koruma',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
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
                              fontSize: 14,
                              fontWeight: i == 6
                                  ? FontWeight.w900
                                  : FontWeight.w700)),
                      const SizedBox(height: 7),
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: CustomPaint(
                            painter: _DayMark(filled: i == 0)),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayMark extends CustomPainter {
  const _DayMark({required this.filled});

  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);

    if (!filled) {
      final dash = Paint()
        ..color = const Color(0xFF2A3A52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4;
      for (var i = 0; i < 12; i++) {
        canvas.drawArc(Rect.fromCircle(center: c, radius: r - 1.4),
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
  bool shouldRepaint(covariant _DayMark old) => old.filled != filled;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard();

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
          const QuestIcon(questKey: 'review_two', size: 28),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w900)),
                Text('Yanlış bildiklerini geri kazan',
                    style: TextStyle(
                        color: _muted,
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _green, size: 24),
        ],
      ),
    );
  }
}

/// Busuu'nun "Review" mantığı: kelimeler güce göre ayrılır ve pratik
/// eylemi sunulur. Bizde `user_karty_learning` verisi zaten var.
class _WeakWordsCard extends StatelessWidget {
  const _WeakWordsCard();

  @override
  Widget build(BuildContext context) {
    return _Surface(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            const QuestIcon(questKey: 'learn_three', size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('4 kelime zayıflıyor',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w900)),
                  Text('Tekrar et, unutma',
                      style: TextStyle(
                          color: _muted,
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _muted, size: 24),
          ],
        ),
      ),
    );
  }
}

/// Duolingo'nun "Personal Records"ı — aşılacak hedefler.
class _RecordsCard extends StatelessWidget {
  const _RecordsCard();

  @override
  Widget build(BuildContext context) {
    Widget row(Widget icon, String label, String value, String sub,
        {bool last = false}) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SizedBox(width: 26, height: 26, child: icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                      Text(sub,
                          style: const TextStyle(
                              color: _muted,
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          if (!last)
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Container(height: 1, color: _border),
            ),
        ],
      );
    }

    return _Surface(
      radius: 20,
      child: Column(
        children: [
          row(const QuestIcon(questKey: 'streak_three', size: 26),
              'En uzun seri', '13 gün', 'Şu an 0 — rekorunu geç'),
          row(const PointsStarIcon(size: 26), 'Bir günde en çok puan', '48',
              'Bugün 0'),
          row(const LeagueBadgeMark(leagueKey: 'supernova', size: 26),
              'En yüksek lig', 'Supernova', 'Pulsar bir üstü', last: true),
        ],
      ),
    );
  }
}

class _Grid4 extends StatelessWidget {
  const _Grid4();

  @override
  Widget build(BuildContext context) {
    Widget tile(Widget icon, String label, String value) => Expanded(
          child: _Surface(
            radius: 18,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 30, child: icon),
                  const SizedBox(height: 6),
                  Text(label,
                      style: const TextStyle(
                          color: _muted,
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4)),
                  const SizedBox(height: 2),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        );

    return Column(
      children: [
        Row(children: [
          tile(const PointsStarIcon(size: 30), 'PUAN', '105'),
          const SizedBox(width: 10),
          tile(const LevelBarsIcon(size: 30), 'SEVİYE', '2'),
          const SizedBox(width: 10),
          tile(const LeagueBadgeMark(leagueKey: 'supernova', size: 30), 'LİG',
              'Supernova'),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          tile(const QuestIcon(questKey: 'correct_five', size: 30), 'KELİME',
              '13'),
          const SizedBox(width: 10),
          tile(const QuestIcon(questKey: 'learn_three', size: 30), 'ARTİKEL',
              '5'),
          const SizedBox(width: 10),
          tile(const TrophyIcon(size: 30), 'LİDERLİK', '1.'),
        ]),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow();

  @override
  Widget build(BuildContext context) {
    Widget cell(Widget icon, String value, String label) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 26, child: icon),
              const SizedBox(height: 5),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w900)),
              Text(label,
                  style: const TextStyle(
                      color: _muted,
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3)),
            ],
          ),
        );

    return _Surface(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
        child: Row(
          children: [
            cell(const PointsStarIcon(size: 26), '105', 'PUAN'),
            cell(const QuestIcon(questKey: 'correct_five', size: 26), '13',
                'KELİME'),
            cell(const ArticleLearnedIcon(size: 26), '5', 'ARTİKEL'),
            cell(const TrophyIcon(size: 26), '1.', 'LİDERLİK'),
          ],
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.radius, required this.child});

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: _border, borderRadius: BorderRadius.circular(radius)),
      padding: const EdgeInsets.only(bottom: 5),
      child: Container(
        decoration: BoxDecoration(
            color: _bg, borderRadius: BorderRadius.circular(radius)),
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
    canvas.drawPath(
      Path()
        ..moveTo(inset, r)
        ..lineTo(inset, size.height - r)
        ..quadraticBezierTo(inset, size.height - inset, r, size.height - inset)
        ..lineTo(size.width - r, size.height - inset)
        ..quadraticBezierTo(size.width - inset, size.height - inset,
            size.width - inset, size.height - r)
        ..lineTo(size.width - inset, r),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw,
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
        ..quadraticBezierTo(size.width - inset, inset, size.width - inset, r),
      corner
        ..shader = ui.Gradient.linear(Offset(size.width - r, inset),
            Offset(size.width - inset, r), [color.withValues(alpha: 0), color]),
    );
    canvas.restore();
  }
}
