import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Artikel hapı ve kartın zaman aşımı hâli: mevcut ve öneri.
///
/// **Üretim kodu değil.**
void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    loader.addFont(File('assets/fonts/Inter-SemiBold.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  });

  testWidgets('hap ve zaman asimi', (tester) async {
    tester.view.physicalSize = const Size(1290, 3450);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _Page());
    await tester.pump(const Duration(milliseconds: 120));

    await expectLater(
      find.byType(_Page),
      matchesGoldenFile('goldens/karty_pill_timeout.png'),
    );
  });

  testWidgets('zaman asimi yakin plan', (tester) async {
    tester.view.physicalSize = const Size(1290, 1450);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: _bg,
        body: Center(child: _ProposedTimeout()),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 120));

    await expectLater(
      find.byType(_ProposedTimeout),
      matchesGoldenFile('goldens/karty_timeout_proposed.png'),
    );
  });
}

const _bg = Color(0xFF041227);
const _panel = Color(0xFF0B2143);
const _muted = Color(0xFF8FA0B5);
const _cream = Color(0xFFE9EEF5);
const _accent = Color(0xFF1CB1F5);
const _accentDeep = Color(0xFF1B84B5);
const _s = 430 / 750;

// Pusulanın belgeli artikel paleti.
const _articles = <String, List<Color>>{
  'der': [Color(0xFF1CB1F5), Color(0xFF1B84B5)],
  'die': [Color(0xFFF52A2A), Color(0xFFAA1C1C)],
  'das': [Color(0xFFFFB000), Color(0xFFC97800)],
};

class _Page extends StatelessWidget {
  const _Page();

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
                title: 'ARTİKEL HAPI · ŞU AN',
                note: 'Koyu çip + küçük renkli nokta. Renk hapın içinde bir '
                    'ayrıntı; pusulada ise hapın kendisi.',
                child: _CurrentTitle(),
              ),
              _Block(
                title: 'ARTİKEL HAPI · ÖNERİ',
                note: 'Pusuladaki gövde küçültülmüş hâli: renk yüzü '
                    'dolduruyor, altında kendi koyusu, üstte açılan gradyan. '
                    'Ok yok — pusulada yön anlamı vardı, kartta yok.',
                child: _ProposedTitles(),
              ),
              _Block(
                title: 'ZAMAN AŞIMI · ŞU AN',
                note: 'Yarı saydam beyaz daire + Material\'ın hazır refresh '
                    'ikonu. Daire uygulamada yok, hazır ikon §2.5\'te reddedilmiş.',
                child: _CurrentTimeout(),
              ),
              _Block(
                title: 'ZAMAN AŞIMI · ÖNERİ',
                note: 'Kart karartılır, üstüne ne olduğunu söyleyen blok gelir: '
                    'çizilmiş kum saati + "Süre doldu" + depth-press buton. '
                    'Mavi seçildi, yeşil bu ekranda "doğru cevap" demek.',
                child: _ProposedTimeout(),
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
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
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
          const SizedBox(height: 16),
          Center(child: child),
        ],
      ),
    );
  }
}

class _CurrentTitle extends StatelessWidget {
  const _CurrentTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 42 * _s,
          padding: EdgeInsets.fromLTRB(11 * _s, 0, 13 * _s, 0),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(14 * _s),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 13 * _s,
                height: 13 * _s,
                decoration: const BoxDecoration(
                    color: Color(0xFFF52A2A), shape: BoxShape.circle),
              ),
              SizedBox(width: 7 * _s),
              Text('die',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontFamily: 'Inter',
                      fontSize: 21 * _s,
                      height: 1,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        SizedBox(width: 16 * _s),
        Text('Zahnbürste',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 58 * _s,
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _ProposedTitles extends StatelessWidget {
  const _ProposedTitles();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in _articles.entries) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ArticlePill(article: entry.key),
              SizedBox(width: 16 * _s),
              Text(
                  entry.key == 'die'
                      ? 'Zahnbürste'
                      : entry.key == 'der'
                          ? 'Löffel'
                          : 'Fenster',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontSize: 58 * _s,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          SizedBox(height: 18 * _s),
        ],
      ],
    );
  }
}

/// Pusuladaki hedef gövdesinin küçültülmüş hâli: taban dudağı + gradyanlı yüz.
class _ArticlePill extends StatelessWidget {
  const _ArticlePill({required this.article});
  final String article;

  @override
  Widget build(BuildContext context) {
    final face = _articles[article]![0];
    final base = _articles[article]![1];
    return Container(
      height: 50 * _s,
      padding: EdgeInsets.only(bottom: 5 * _s),
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(15 * _s),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15 * _s),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.lerp(face, Colors.white, 0.1)!, face],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(14 * _s),
        ),
        child: Text(article,
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 24 * _s,
                height: 1,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                      color: base,
                      offset: Offset(0, 2 * _s),
                      blurRadius: 2 * _s),
                ])),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400 * _s,
      height: 600 * _s,
      padding: EdgeInsets.all(14 * _s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(38 * _s),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26 * _s),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF8BD86B),
                    Color(0xFF56BEEA),
                    Color(0xFFA647F0),
                    Color(0xFFFDC041),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _CurrentTimeout extends StatelessWidget {
  const _CurrentTimeout();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Center(
        child: Container(
          width: 220 * _s,
          height: 220 * _s,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.refresh_rounded,
              color: Colors.white, size: 132 * _s),
        ),
      ),
    );
  }
}

class _ProposedTimeout extends StatelessWidget {
  const _ProposedTimeout();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Container(
        color: _bg.withValues(alpha: 0.72),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomPaint(
              size: Size(150 * _s, 150 * _s),
              painter: _HourglassPainter(),
            ),
            SizedBox(height: 26 * _s),
            Text('Süre doldu',
                style: TextStyle(
                    color: _cream,
                    fontFamily: 'Inter',
                    fontSize: 40 * _s,
                    fontWeight: FontWeight.w900)),
            SizedBox(height: 30 * _s),
            // Depth-press buton (§2.4)
            SizedBox(
              width: 260 * _s,
              height: 96 * _s,
              child: Stack(
                children: [
                  Positioned(
                    top: 10 * _s,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 86 * _s,
                      decoration: BoxDecoration(
                        color: _accentDeep,
                        borderRadius: BorderRadius.circular(24 * _s),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 86 * _s,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(24 * _s),
                      ),
                      child: Text('TEKRAR DENE',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontSize: 26 * _s,
                              fontWeight: FontWeight.w900)),
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
}

/// §2.5 reçetesiyle çizilmiş kum saati: kalınlık bandı → yüz → açık bölge →
/// sol üstte parlama. 100 birimlik kutu.
class _HourglassPainter extends CustomPainter {
  static const _light = Color(0xFFFFE071);
  static const _face = Color(0xFFFFC932);
  static const _depth = Color(0xFFCE8409);

  Path _body(double u, double dy) {
    return Path()
      ..moveTo(22 * u, 10 * u + dy)
      ..lineTo(78 * u, 10 * u + dy)
      ..lineTo(78 * u, 26 * u + dy)
      ..lineTo(54 * u, 50 * u + dy)
      ..lineTo(78 * u, 74 * u + dy)
      ..lineTo(78 * u, 90 * u + dy)
      ..lineTo(22 * u, 90 * u + dy)
      ..lineTo(22 * u, 74 * u + dy)
      ..lineTo(46 * u, 50 * u + dy)
      ..lineTo(22 * u, 26 * u + dy)
      ..close();
  }

  void _fillChunky(Canvas canvas, Path path, Color color, double u) {
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * u
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    _fillChunky(canvas, _body(u, 6 * u), _depth, u);
    _fillChunky(canvas, _body(u, 0), _face, u);

    canvas.save();
    canvas.clipPath(_body(u, 0));
    // Alt hazne dolmuş: kum aşağıda, yani süre bitmiş.
    canvas.drawRect(
      Rect.fromLTWH(0, 62 * u, 100 * u, 38 * u),
      Paint()..color = _light,
    );
    canvas.drawPath(
      Path()
        ..moveTo(50 * u, 50 * u)
        ..lineTo(56 * u, 66 * u)
        ..lineTo(44 * u, 66 * u)
        ..close(),
      Paint()..color = _light,
    );
    canvas.drawPath(
      Path()
        ..moveTo(26 * u, 14 * u)
        ..lineTo(74 * u, 14 * u)
        ..lineTo(50 * u, 42 * u)
        ..close(),
      Paint()..color = _depth.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      Offset(33 * u, 22 * u),
      5 * u,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
