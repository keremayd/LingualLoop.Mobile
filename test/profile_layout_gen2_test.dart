import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/league_badge_mark.dart';
import 'package:lingualloop/ui/widgets/level_bars_icon.dart';
import 'package:lingualloop/ui/widgets/points_star_icon.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

/// Profil yerleşimi — **araştırma tabanlı ikinci nesil.**
///
/// Önceki tur (CLAUDE.md'deki A/B ve onların rötuşu) yalnızca kutuları
/// yeniden diziyordu; kullanıcı beğenmedi. Bu tur araştırmadan çıkan üç
/// kalıbı uyguluyor:
///
///  1. **Isı takvimi** — dil takip uygulamaları haftalık çubuk + ısı
///     haritası kullanıyor; tutarlılık tek bakışta görülüyor. Bizim şerit
///     7 günle sınırlı, geçmiş hiç yok.
///  2. **Tek kahraman metrik** — Busuu'nun Fluency Score'u gibi tek baskın
///     sayı. Bizde altı sayı eşit ağırlıkta; hiyerarşi yokluğu dağınıklığın
///     asıl sebebi.
///  3. **Seri kartı dört şeyi açıklamalı**: neyin sayıldığı, zaman sınırı,
///     telafi yolu, görevin kendisi (10 uygulamalık seri tasarımı incelemesi).
///
///   flutter test --update-goldens test/profile_layout_gen2_test.dart
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

  testWidgets('profil gen2', (tester) async {
    const size = Size(1450, 1280);
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
      matchesGoldenFile('goldens/profile_layout_gen2.png'),
    );
  });
}

enum _G { heatmap, hero, list }

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
            g: _G.heatmap,
            label: 'D — ISI TAKVİMİ',
            note: 'Şerit yerine 5 haftalık ısı haritası. Tutarlılık tek '
                'bakışta görülüyor; 7 günlük pencere geçmişi saklıyordu.',
          ),
          SizedBox(width: 24),
          _Col(
            g: _G.hero,
            label: 'E — KAHRAMAN METRİK',
            note: 'Seviye tek baskın sayı, ilerlemesiyle. Diğerleri onu '
                'destekliyor. Altı eşit sayı yerine hiyerarşi.',
          ),
          SizedBox(width: 24),
          _Col(
            g: _G.list,
            label: 'F — KUTUSUZ LİSTE',
            note: 'Her sayının kendi çerçevesi yok. Kutu sayısı 9\'dan 3\'e '
                'iniyor — dağınıklığın kaynağı kutu enflasyonuydu.',
          ),
        ],
      ),
    );
  }
}

class _Col extends StatelessWidget {
  const _Col({required this.g, required this.label, required this.note});

  final _G g;
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
            height: 66,
            child: Text(note,
                style: const TextStyle(
                    color: _muted,
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3)),
          ),
          const SizedBox(height: 10),
          const _IdentityRow(),
          const SizedBox(height: 14),
          ..._body(),
        ],
      ),
    );
  }

  List<Widget> _body() {
    switch (g) {
      case _G.heatmap:
        return const [
          _StreakWithHeatmap(),
          SizedBox(height: 12),
          _Grid6(),
          SizedBox(height: 12),
          _RevengeCard(),
        ];
      case _G.hero:
        return const [
          _HeroMetric(),
          SizedBox(height: 12),
          _StreakCompact(),
          SizedBox(height: 12),
          _SecondaryRow(),
          SizedBox(height: 12),
          _RevengeCard(),
        ];
      case _G.list:
        return const [
          _StreakCompact(),
          SizedBox(height: 12),
          _StatList(),
          SizedBox(height: 12),
          _RevengeCard(),
        ];
    }
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration:
              BoxDecoration(color: _tile, borderRadius: BorderRadius.circular(16)),
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
          width: 38,
          height: 38,
          decoration:
              BoxDecoration(color: _tile, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.settings, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}

// -------------------------------------------------- D: ısı takvimi

class _StreakWithHeatmap extends StatelessWidget {
  const _StreakWithHeatmap();

  /// 5 hafta × 7 gün. 0 = boş, 1 = oynandı, 2 = korundu.
  static const _weeks = <List<int>>[
    [1, 1, 0, 1, 1, 1, 0],
    [1, 0, 1, 1, 2, 1, 1],
    [1, 1, 1, 0, 0, 1, 1],
    [0, 1, 1, 1, 1, 0, 0],
    [1, 0, 0, 0, 0, 0, 0],
  ];

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
                const QuestIcon(questKey: 'streak_three', size: 30),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('0 günlük seri',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontSize: 19,
                              fontWeight: FontWeight.w900)),
                      SizedBox(height: 1),
                      // Seri kartı "neyin sayıldığını" söylemeli.
                      Text('Bir oyun bitir, gün sayılsın',
                          style: TextStyle(
                              color: _muted,
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                _FreezePill(),
              ],
            ),
            const SizedBox(height: 14),
            // Isı takvimi: satır = hafta, sütun = gün.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var col = 0; col < 7; col++)
                  Column(
                    children: [
                      Text(
                        const ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pa'][col],
                        style: const TextStyle(
                            color: _muted,
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 5),
                      for (var row = 0; row < _weeks.length; row++) ...[
                        if (row > 0) const SizedBox(height: 4),
                        _cell(_weeks[row][col]),
                      ],
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('5 hafta',
                    style: TextStyle(
                        color: _muted,
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                _legend(_tile, 'boş'),
                const SizedBox(width: 10),
                _legend(_flame, 'oynadın'),
                const SizedBox(width: 10),
                _legend(_ice, 'korundu'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(int v) {
    final color = switch (v) {
      1 => _flame,
      2 => _ice,
      _ => _tile,
    };
    return Container(
      width: 34,
      height: 15,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
    );
  }

  Widget _legend(Color c, String t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Text(t,
              style: const TextStyle(
                  color: _muted,
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      );
}

// -------------------------------------------------- E: kahraman metrik

class _HeroMetric extends StatelessWidget {
  const _HeroMetric();

  @override
  Widget build(BuildContext context) {
    return _Surface(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const LevelBarsIcon(size: 40),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('SEVİYE',
                        style: TextStyle(
                            color: _muted,
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: const [
                        Text('2',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                height: 1)),
                        SizedBox(width: 6),
                        Text('/ 20',
                            style: TextStyle(
                                color: _muted,
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('SONRAKİ SEVİYE',
                        style: TextStyle(
                            color: _muted,
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('45 puan',
                        style: TextStyle(
                            color: _green,
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 12,
                child: Stack(
                  children: [
                    const Positioned.fill(child: ColoredBox(color: _tile)),
                    FractionallySizedBox(
                      widthFactor: 0.55,
                      child: Container(color: _green),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryRow extends StatelessWidget {
  const _SecondaryRow();

  @override
  Widget build(BuildContext context) {
    Widget cell(Widget icon, String value, String label) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 28, child: icon),
              const SizedBox(height: 6),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w900)),
              Text(label,
                  style: const TextStyle(
                      color: _muted,
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3)),
            ],
          ),
        );

    return _Surface(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            cell(const PointsStarIcon(size: 28), '105', 'PUAN'),
            cell(const LeagueBadgeMark(leagueKey: 'supernova', size: 28),
                'Supernova', 'LİG'),
            cell(const QuestIcon(questKey: 'correct_five', size: 28), '13',
                'KELİME'),
            cell(const QuestIcon(questKey: 'learn_three', size: 28), '5',
                'ARTİKEL'),
            cell(const TrophyIcon(size: 28), '1.', 'LİDERLİK'),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------- F: kutusuz liste

class _StatList extends StatelessWidget {
  const _StatList();

  @override
  Widget build(BuildContext context) {
    Widget row(Widget icon, String label, String value, {bool last = false}) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
            child: Row(
              children: [
                SizedBox(width: 26, height: 26, child: icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          if (!last)
            Padding(
              padding: const EdgeInsets.only(left: 54),
              child: Container(height: 1, color: _border),
            ),
        ],
      );
    }

    return _Surface(
      radius: 20,
      child: Column(
        children: [
          row(const PointsStarIcon(size: 26), 'Puan', '105'),
          row(const LevelBarsIcon(size: 26), 'Seviye', '2'),
          row(const LeagueBadgeMark(leagueKey: 'supernova', size: 26), 'Lig',
              'Supernova'),
          row(const QuestIcon(questKey: 'correct_five', size: 26),
              'Öğrenilen kelime', '13'),
          row(const QuestIcon(questKey: 'learn_three', size: 26),
              'Ezberlenen artikel', '5'),
          row(const TrophyIcon(size: 26), 'Liderlik', '1.', last: true),
        ],
      ),
    );
  }
}

// -------------------------------------------------- ortak

class _FreezePill extends StatelessWidget {
  const _FreezePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: _tile, borderRadius: BorderRadius.circular(99)),
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
    );
  }
}

class _StreakCompact extends StatelessWidget {
  const _StreakCompact();

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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('0 günlük seri',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                      Text('Bir oyun bitir, gün sayılsın',
                          style: TextStyle(
                              color: _muted,
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const _FreezePill(),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 7; i++)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          const ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pa'][i],
                          style: TextStyle(
                              color: i == 6 ? Colors.white : _muted,
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight:
                                  i == 6 ? FontWeight.w900 : FontWeight.w700)),
                      const SizedBox(height: 5),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0 ? _flame : Colors.transparent,
                          border: i == 0
                              ? null
                              : Border.all(color: const Color(0xFF2A3A52), width: 2),
                        ),
                        child: i == 0
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : null,
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

class _Grid6 extends StatelessWidget {
  const _Grid6();

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
                  SizedBox(height: 32, child: icon),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        );

    return Column(
      children: [
        Row(children: [
          tile(const PointsStarIcon(size: 32), 'PUAN', '105'),
          const SizedBox(width: 10),
          tile(const LevelBarsIcon(size: 32), 'SEVİYE', '2'),
          const SizedBox(width: 10),
          tile(const LeagueBadgeMark(leagueKey: 'supernova', size: 32), 'LİG',
              'Supernova'),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          tile(const QuestIcon(questKey: 'correct_five', size: 32), 'KELİME',
              '13'),
          const SizedBox(width: 10),
          tile(const QuestIcon(questKey: 'learn_three', size: 32), 'ARTİKEL',
              '5'),
          const SizedBox(width: 10),
          tile(const TrophyIcon(size: 32), 'LİDERLİK', '1.'),
        ]),
      ],
    );
  }
}

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
