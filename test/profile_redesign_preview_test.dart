import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/league_badge_mark.dart';
import 'package:lingualloop/ui/widgets/level_bars_icon.dart';
import 'package:lingualloop/ui/widgets/points_star_icon.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';
import 'package:lingualloop/ui/widgets/streak_week_strip.dart';

/// Profil ekranı yeniden tasarım önerileri.
///
/// Mevcut ekranın dikey bütçesinin ~%40'ı kaplamaya gidiyor: profil kartı tek
/// başına 440 birim, iki bölüm başlığı kutusu 140 birim. Bu öneriler o alanı
/// bilgiye çeviriyor.
///
///   flutter test --update-goldens test/profile_redesign_preview_test.dart
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

  testWidgets('profil yeniden tasarim onerileri', (tester) async {
    const cell = Size(430, 932);
    final size = Size(cell.width * 2 + 60, cell.height + 90);

    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: const Color(0xFF020A16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Labelled(
                title: 'A — Kompakt kimlik + tek ızgara',
                child: SizedBox.fromSize(size: cell, child: const _OptionA()),
              ),
              const SizedBox(width: 40),
              _Labelled(
                title: 'B — Seri hero, eylem yukarıda',
                child: SizedBox.fromSize(size: cell, child: const _OptionB()),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/profile_redesign.png'),
    );
  });
}

class _Labelled extends StatelessWidget {
  const _Labelled({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8FA0B5),
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────── ortak parçalar

const _bg = Color(0xFF041227);
const _border = Color(0xFF0B2143);
const _tile = Color(0xFF0C2244);
const _muted = Color(0xFF8FA0B5);
const _green = Color(0xFF93D334);
const _flame = Color(0xFFFF6536);

/// §2.3 kart yüzeyi: yüz sayfa zemini, kontur, altta taban dudağı.
class _Surface extends StatelessWidget {
  const _Surface({required this.scale, required this.child, this.radius = 24});

  final double scale;
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius * scale);
    return Container(
      decoration: BoxDecoration(color: _border, borderRadius: r),
      padding: EdgeInsets.only(bottom: 7 * scale),
      child: Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: r,
          border: Border.all(color: _border, width: 2 * scale),
        ),
        child: child,
      ),
    );
  }
}

Widget _text(String s, double size, FontWeight w, Color c,
        {double height = 1}) =>
    Text(s,
        style: TextStyle(
          color: c,
          fontFamily: 'Inter',
          fontSize: size,
          fontWeight: w,
          height: height,
        ));

/// Kompakt kimlik satırı: fotoğraf solda, ad yanında, ayar sağda.
/// Mevcut hâli 440 birim dikey yer kaplıyordu; bu ~150.
class _IdentityRow extends StatelessWidget {
  const _IdentityRow({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 118 * scale,
          height: 118 * scale,
          decoration: BoxDecoration(
            color: _tile,
            borderRadius: BorderRadius.circular(28 * scale),
            border: Border.all(color: _border, width: 3 * scale),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.person, color: _muted, size: 62 * scale),
        ),
        SizedBox(width: 20 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _text('sefa sefa', 38 * scale, FontWeight.w900, Colors.white),
              SizedBox(height: 8 * scale),
              _text('@sefasefa52007', 24 * scale, FontWeight.w700, _muted),
            ],
          ),
        ),
        Container(
          width: 76 * scale,
          height: 76 * scale,
          decoration: BoxDecoration(
            color: _tile,
            borderRadius: BorderRadius.circular(22 * scale),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.settings, color: Colors.white, size: 40 * scale),
        ),
      ],
    );
  }
}

/// Seri kartı: alev + sayı + koruma hapı + hafta şeridi.
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final today = DateTime(2026, 8, 10);
    const active = [true, false, false, true, true, true, false];
    const frozen = [false, false, false, false, true, false, false];

    return _Surface(
      scale: scale,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            26 * scale, 22 * scale, 26 * scale, 24 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                QuestIcon(questKey: 'streak_three', size: 46 * scale),
                SizedBox(width: 12 * scale),
                _text('3', 40 * scale, FontWeight.w900, _flame),
                SizedBox(width: 8 * scale),
                _text('günlük seri', 26 * scale, FontWeight.w700, Colors.white),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16 * scale, vertical: 9 * scale),
                  decoration: BoxDecoration(
                    color: _tile,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.ac_unit,
                        color: const Color(0xFF1CB1F5), size: 26 * scale),
                    SizedBox(width: 7 * scale),
                    _text('2', 24 * scale, FontWeight.w900,
                        const Color(0xFF1CB1F5)),
                  ]),
                ),
              ],
            ),
            SizedBox(height: 20 * scale),
            StreakWeekStrip(
              scale: scale * 0.78,
              days: [
                for (var i = 0; i < 7; i++)
                  StreakDay(
                    date: today.subtract(Duration(days: 6 - i)),
                    active: active[i],
                    frozen: frozen[i],
                    isToday: i == 6,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tek satırlık istatistik karosu: ikon üstte, sayı ortada, etiket altta.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.scale,
    required this.icon,
    required this.value,
    required this.label,
  });

  final double scale;
  final Widget icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      scale: scale,
      radius: 22,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            SizedBox(height: 10 * scale),
            _text(value, 34 * scale, FontWeight.w900, Colors.white),
            SizedBox(height: 6 * scale),
            _text(label, 20 * scale, FontWeight.w700, _muted),
          ],
        ),
      ),
    );
  }
}

/// Rövanş: ekrandaki tek dokunulabilir öğe, yeşil konturla ayrılır.
class _RevengeAction extends StatelessWidget {
  const _RevengeAction({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(24 * scale);
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF4B8B00), borderRadius: r),
      padding: EdgeInsets.only(bottom: 7 * scale),
      child: Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: r,
          border: Border.all(color: const Color(0xFF7FD500), width: 3 * scale),
        ),
        padding: EdgeInsets.symmetric(
            horizontal: 24 * scale, vertical: 22 * scale),
        child: Row(
          children: [
            Container(
              width: 66 * scale,
              height: 66 * scale,
              decoration: BoxDecoration(
                color: _tile,
                borderRadius: BorderRadius.circular(18 * scale),
              ),
              alignment: Alignment.center,
              child: QuestIcon(questKey: 'review_two', size: 36 * scale),
            ),
            SizedBox(width: 16 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _text('1 rövanş kartı seni bekliyor', 26 * scale,
                      FontWeight.w900, Colors.white),
                  SizedBox(height: 6 * scale),
                  _text('Yanlış bildiklerini geri kazan', 21 * scale,
                      FontWeight.w700, _muted),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _green, size: 44 * scale),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────── ÖNERİ A

/// Kimlik satırı → tek istatistik ızgarası (5 karo) → seri → eylem.
/// Bölüm başlığı kutuları tamamen kalkıyor.
class _OptionA extends StatelessWidget {
  const _OptionA();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final scale = c.maxWidth / 750;
      return ColoredBox(
        color: _bg,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              38 * scale, 40 * scale, 38 * scale, 24 * scale),
          child: Column(
            children: [
              _IdentityRow(scale: scale),
              SizedBox(height: 30 * scale),
              Row(children: [
                Expanded(
                    child: _StatTile(
                        scale: scale,
                        icon: PointsStarIcon(size: 52 * scale),
                        value: '101',
                        label: 'PUAN')),
                SizedBox(width: 14 * scale),
                Expanded(
                    child: _StatTile(
                        scale: scale,
                        icon: LevelBarsIcon(size: 52 * scale),
                        value: '2',
                        label: 'SEVİYE')),
                SizedBox(width: 14 * scale),
                Expanded(
                    child: _StatTile(
                        scale: scale,
                        icon: LeagueBadgeMark(
                            leagueKey: 'kosmoz', size: 52 * scale),
                        value: 'Kosmoz',
                        label: 'LİG')),
              ]),
              SizedBox(height: 14 * scale),
              Row(children: [
                Expanded(
                    child: _StatTile(
                        scale: scale,
                        icon: QuestIcon(
                            questKey: 'correct_five', size: 52 * scale),
                        value: '13',
                        label: 'KELİME')),
                SizedBox(width: 14 * scale),
                Expanded(
                    child: _StatTile(
                        scale: scale,
                        icon: QuestIcon(
                            questKey: 'learn_three', size: 52 * scale),
                        value: '5',
                        label: 'ARTİKEL')),
                SizedBox(width: 14 * scale),
                Expanded(
                    child: _StatTile(
                        scale: scale,
                        icon: TrophyIcon(size: 52 * scale),
                        value: '1.',
                        label: 'LİDERLİK')),
              ]),
              SizedBox(height: 26 * scale),
              _StreakCard(scale: scale),
              SizedBox(height: 20 * scale),
              _RevengeAction(scale: scale),
            ],
          ),
        ),
      );
    });
  }
}

// ──────────────────────────────────────────────────────────────── ÖNERİ B

/// Kimlik → eylem (rövanş) → seri hero → istatistik ızgarası.
/// Dokunulabilir öğe yukarı taşınıyor; sayılar aşağıda toplanıyor.
class _OptionB extends StatelessWidget {
  const _OptionB();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final scale = c.maxWidth / 750;
      return ColoredBox(
        color: _bg,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              38 * scale, 40 * scale, 38 * scale, 24 * scale),
          child: Column(
            children: [
              _IdentityRow(scale: scale),
              SizedBox(height: 28 * scale),
              _StreakCard(scale: scale),
              SizedBox(height: 20 * scale),
              _RevengeAction(scale: scale),
              SizedBox(height: 26 * scale),
              Row(children: [
                Expanded(
                    child: _StatTile(
                        scale: scale,
                        icon: PointsStarIcon(size: 52 * scale),
                        value: '101',
                        label: 'PUAN')),
                SizedBox(width: 14 * scale),
                Expanded(
                    child: _StatTile(
                        scale: scale,
                        icon: LevelBarsIcon(size: 52 * scale),
                        value: '2',
                        label: 'SEVİYE')),
                SizedBox(width: 14 * scale),
                Expanded(
                    child: _StatTile(
                        scale: scale,
                        icon: LeagueBadgeMark(
                            leagueKey: 'kosmoz', size: 52 * scale),
                        value: 'Kosmoz',
                        label: 'LİG')),
              ]),
              SizedBox(height: 14 * scale),
              Row(children: [
                Expanded(
                    child: _StatTile(
                        scale: scale,
                        icon: QuestIcon(
                            questKey: 'correct_five', size: 52 * scale),
                        value: '13',
                        label: 'KELİME')),
                SizedBox(width: 14 * scale),
                Expanded(
                    child: _StatTile(
                        scale: scale,
                        icon: QuestIcon(
                            questKey: 'learn_three', size: 52 * scale),
                        value: '5',
                        label: 'ARTİKEL')),
                SizedBox(width: 14 * scale),
                Expanded(
                    child: _StatTile(
                        scale: scale,
                        icon: TrophyIcon(size: 52 * scale),
                        value: '1.',
                        label: 'LİDERLİK')),
              ]),
            ],
          ),
        ),
      );
    });
  }
}
