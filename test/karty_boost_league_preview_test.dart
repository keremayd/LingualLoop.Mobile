import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/league_badge_mark.dart';
import 'package:lingualloop/ui/widgets/level_bars_icon.dart';

/// Boost'un **neyi** çarptığını anlatan üst şerit önerisi.
///
/// **Üretim kodu değil.** Onay alınana kadar ekrana bağlanmadı.
void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    loader.addFont(File('assets/fonts/Inter-SemiBold.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  });

  testWidgets('boost lig anlatimi', (tester) async {
    tester.view.physicalSize = const Size(1290, 2280);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _PreviewPage());
    await tester.pump(const Duration(milliseconds: 120));

    await expectLater(
      find.byType(_PreviewPage),
      matchesGoldenFile('goldens/karty_boost_league.png'),
    );
  });
}

const _bg = Color(0xFF041227);
const _panel = Color(0xFF0B2143);
const _muted = Color(0xFF8FA0B5);
const _cream = Color(0xFFE9EEF5);
const _accent = Color(0xFF1CB1F5);
const _accentDeep = Color(0xFF1B84B5);
const _gold = Color(0xFFFFC93A);
const _boltFace = Color(0xFFF6EDE4);
const _levelColor = Color(0xFF6BD1FF);
const _scale = 430 / 750;

class _PreviewPage extends StatelessWidget {
  const _PreviewPage();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: _bg,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _Block(
                title: 'ŞU AN',
                note: 'Üst şerit: seviye · seri. Boost açıldığında hiçbir şey '
                    'neyin çarpıldığını söylemiyor.',
                child: _TopBar(boost: false, showLeague: false),
              ),
              _Block(
                title: 'ÖNERİ · boost kapalı',
                note: 'Lig rozeti şeride giriyor. Sakin dururken de yerini '
                    'öğretiyor.',
                child: _TopBar(boost: false, showLeague: true),
              ),
              _Block(
                title: 'ÖNERİ · boost açık',
                note: 'Çarpan pili lig rozetinin yanında. Seviye kıpırdamıyor, '
                    'lig sayısı artıyor — eşleme metinsiz kuruluyor.',
                child: _TopBar(boost: true, showLeague: true),
              ),
              _Block(
                title: 'ÖNERİ · doğru cevap anı',
                note: '+3 karttan çıkıp lig rozetine iniyor. Ödülün gittiği '
                    'yer görünür oluyor.',
                child: _FlightScene(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.note, required this.child});

  final String title;
  final String note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: _accent,
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1)),
          const SizedBox(height: 4),
          Text(note,
              style: const TextStyle(
                  color: _muted,
                  fontFamily: 'Inter',
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.boost, required this.showLeague});

  final bool boost;
  final bool showLeague;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 18 * _scale),
      child: Row(
        children: [
          // Süre barı (temsili)
          Expanded(
            child: Container(
              height: 26 * _scale,
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(13 * _scale),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.62,
                child: Container(
                  decoration: BoxDecoration(
                    color: boost ? _gold : _accent,
                    borderRadius: BorderRadius.circular(13 * _scale),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 22 * _scale),
          if (showLeague) ...[
            _LeagueChip(boost: boost),
            SizedBox(width: 22 * _scale),
          ],
          LevelBarsIcon(size: 44 * _scale),
          SizedBox(width: 8 * _scale),
          Text('4',
              style: TextStyle(
                  color: _levelColor,
                  fontFamily: 'Inter',
                  fontSize: 26 * _scale,
                  fontWeight: FontWeight.w900)),
          SizedBox(width: 25 * _scale),
          _FlameDot(size: 44 * _scale),
          SizedBox(width: 8 * _scale),
          Text('7',
              style: TextStyle(
                  color: const Color(0xFFF52A2A),
                  fontFamily: 'Inter',
                  fontSize: 26 * _scale,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

/// Lig rozeti + oturumda kazanılan lig puanı. Boost açıkken yanına çarpan
/// pili geliyor.
class _LeagueChip extends StatelessWidget {
  const _LeagueChip({required this.boost});

  final bool boost;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LeagueBadgeMark(leagueKey: 'yildiz', size: 46 * _scale),
        SizedBox(width: 8 * _scale),
        Text(boost ? '128' : '119',
            style: TextStyle(
                color: _cream,
                fontFamily: 'Inter',
                fontSize: 26 * _scale,
                fontWeight: FontWeight.w900)),
        if (boost) ...[
          SizedBox(width: 8 * _scale),
          const _MultiplierPill(),
        ],
      ],
    );
  }
}

/// `⚡×3` — çarpanın kime ait olduğunu konumu söylüyor: lig sayısının yanında.
class _MultiplierPill extends StatelessWidget {
  const _MultiplierPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * _scale, vertical: 5 * _scale),
      decoration: BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.circular(14 * _scale),
        border: Border.all(color: _accentDeep, width: 2 * _scale),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: Size(18 * _scale, 24 * _scale),
            painter: _BoltPainter(),
          ),
          SizedBox(width: 5 * _scale),
          Text('×3',
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontSize: 22 * _scale,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _BoltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final path = Path()
      ..moveTo(58 * u, 0)
      ..lineTo(8 * u, 74 * u)
      ..lineTo(45 * u, 74 * u)
      ..lineTo(36 * u, 133 * u)
      ..lineTo(92 * u, 52 * u)
      ..lineTo(53 * u, 52 * u)
      ..close();
    canvas.drawPath(path, Paint()..color = _boltFace);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlameDot extends StatelessWidget {
  const _FlameDot({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF52A2A),
      ),
    );
  }
}

/// Doğru cevapta `+3`'ün lig rozetine doğru yol alması.
class _FlightScene extends StatelessWidget {
  const _FlightScene();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220 * _scale,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _TopBar(boost: true, showLeague: true),
          ),
          // Uçan ödül, hedefe yaklaşmış hâlde
          Positioned(
            right: 128 * _scale,
            top: 96 * _scale,
            child: _RewardChip(value: '+3'),
          ),
          Positioned(
            right: 40 * _scale,
            top: 168 * _scale,
            child: Opacity(
              opacity: 0.45,
              child: _RewardChip(value: '+3'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LeagueBadgeMark(leagueKey: 'yildiz', size: 34 * _scale),
        SizedBox(width: 5 * _scale),
        Text(value,
            style: TextStyle(
                color: _gold,
                fontFamily: 'Inter',
                fontSize: 30 * _scale,
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}
