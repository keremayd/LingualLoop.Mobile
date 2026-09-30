import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

/// Seri **0** hâli — motivasyon önerileri.
///
/// Şimdiki hâlin metni koşulsuz: `'${streak} günlük serini sürdür'`. Seri
/// 0'ken "0 günlük serini sürdür" çıkıyor — sıfır günlük bir seri
/// sürdürülemez, henüz başlamamıştır.
///
/// Görsel tarafta soru: uygulamada hiç karakter yok (CLAUDE.md: "bizde
/// maskot yok, alev serinin tek simgesi"). Aşağıda üç yol var; üçüncüsü
/// maskotu **rastgele bir yaratıktan değil uygulamanın kendi simgesinden**
/// (loop şimşeği) türetiyor.
///
///   flutter test --update-goldens test/streak_zero_state_test.dart
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

  testWidgets('seri sifir hali', (tester) async {
    const size = Size(800, 1180);
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
      matchesGoldenFile('goldens/streak_zero_state.png'),
    );
  });
}

enum _Z { current, spark, face, mascot }

const _bg = Color(0xFF041227);
const _face = Color(0xFF041227);
const _border = Color(0xFF0B2143);
const _tile = Color(0xFF0C2244);
const _muted = Color(0xFF8FA0B5);
const _flame = Color(0xFFFF6536);
const _bolt = Color(0xFFFFC93A);

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Block(
            z: _Z.current,
            label: 'ŞİMDİKİ',
            note: '"0 günlük serini sürdür" — sıfır seri sürdürülemez.',
          ),
          SizedBox(height: 24),
          _Block(
            z: _Z.spark,
            label: '1 — KIVILCIM',
            note: 'Alev henüz yanmamış: küçük bir kıvılcım. Yeni karakter '
                'icat edilmiyor, mevcut simge "başlangıç" hâline giriyor.',
          ),
          SizedBox(height: 24),
          _Block(
            z: _Z.face,
            label: '2 — ALEV KARAKTER OLUYOR',
            note: 'CLAUDE.md zaten "bizim ankamız alevin kendisi" diyor. '
                'Aleve ifade veriliyor; uygulamaya yabancı bir şey girmiyor.',
          ),
          SizedBox(height: 24),
          _Block(
            z: _Z.mascot,
            label: '3 — MASKOT (loop şimşeğinden)',
            note: 'Rastgele bir yaratık değil, uygulamanın kimlik simgesi '
                'karaktere dönüyor. Painter dilinde maskot böyle durur.',
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.z, required this.label, required this.note});

  final _Z z;
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          note,
          style: const TextStyle(
            color: _muted,
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        _Card(z: z),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.z});

  final _Z z;

  @override
  Widget build(BuildContext context) {
    // Ana ekrandaki şeridin ölçüleri: 670 birim, radius 28, dolgu 26/20/26/22.
    const scale = 740 / 670;

    return Container(
      width: 740,
      decoration: BoxDecoration(
        color: _face,
        borderRadius: BorderRadius.circular(28 * scale),
        border: Border.all(color: _border, width: 2 * scale),
      ),
      padding: EdgeInsets.fromLTRB(26 * scale, 20 * scale, 26 * scale, 22 * scale),
      child: Row(
        children: [
          SizedBox(
            width: 84 * scale,
            height: 84 * scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _tile,
                borderRadius: BorderRadius.circular(22 * scale),
              ),
              child: Center(child: _icon(scale)),
            ),
          ),
          SizedBox(width: 16 * scale),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontSize: 27 * scale,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 9 * scale),
                Text(
                  _subtitle,
                  style: TextStyle(
                    color: _flame,
                    fontFamily: 'Inter',
                    fontSize: 22 * scale,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12 * scale),
          _WeekStrip(scale: scale),
        ],
      ),
    );
  }

  String get _title => switch (z) {
        _Z.current => 'Bugün henüz oynamadın',
        _ => 'Serine başla',
      };

  String get _subtitle => switch (z) {
        _Z.current => '0 günlük serini sürdür',
        _Z.spark => 'İlk günü bugün yak',
        _Z.face => 'İlk günü bugün yak',
        _Z.mascot => 'Bir tur at, alevi yak',
      };

  Widget _icon(double scale) {
    final size = 48 * scale;
    return switch (z) {
      // Şimdiki: soluk alev (gri tonlama + %55 opaklık).
      _Z.current => Opacity(
          opacity: 0.55,
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126, 0.7152, 0.0722, 0, 0, //
              0.2126, 0.7152, 0.0722, 0, 0, //
              0.2126, 0.7152, 0.0722, 0, 0, //
              0, 0, 0, 1, 0,
            ]),
            child: QuestIcon(questKey: 'streak_three', size: size),
          ),
        ),
      _Z.spark => CustomPaint(size: Size.square(size), painter: _SparkPainter()),
      _Z.face =>
        CustomPaint(size: Size.square(size), painter: _FlameFacePainter()),
      _Z.mascot =>
        CustomPaint(size: Size.square(size * 1.1), painter: _BoltMascotPainter()),
    };
  }
}

/// 1 — Kıvılcım: alev henüz yanmamış. Küçük bir kor ve etrafında ilk
/// kıvılcımlar. §2.5 reçetesi: kalınlık bandı, net iki ton, sol üstte parlama.
class _SparkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;

    // Kor: alevin küçültülmüş çekirdeği.
    final ember = Path()
      ..addOval(Rect.fromCircle(center: Offset(50 * u, 62 * u), radius: 20 * u));

    canvas.drawPath(ember.shift(Offset(0, 6 * u)), Paint()..color = const Color(0xFF9A1414));
    canvas.drawPath(ember, Paint()..color = const Color(0xFFF52A2A));

    canvas.save();
    canvas.clipPath(ember);
    canvas.drawCircle(
      Offset(42 * u, 54 * u),
      15 * u,
      Paint()..color = const Color(0xFFFF7A5C),
    );
    canvas.restore();

    // Sıçrayan kıvılcımlar: "yanmak üzere" hissi.
    final spark = Paint()..color = const Color(0xFFFFC93A);
    for (final p in const [
      [30.0, 30.0, 5.0],
      [66.0, 24.0, 6.5],
      [50.0, 14.0, 4.0],
      [76.0, 44.0, 4.0],
    ]) {
      canvas.drawCircle(Offset(p[0] * u, p[1] * u), p[2] * u, spark);
    }

    canvas.drawCircle(
      Offset(43 * u, 53 * u),
      4 * u,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2 — Alevin kendisi karakter oluyor: aynı gövde, üstüne göz.
/// Yeni bir yaratık icat edilmiyor.
class _FlameFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final body = streakFlameBody(u);

    void fillChunky(Path path, Color color) {
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

    fillChunky(body.shift(Offset(0, 6 * u)), const Color(0xFF9A1414));
    fillChunky(body, const Color(0xFFF52A2A));

    canvas.save();
    canvas.clipPath(body);
    fillChunky(streakFlameInner(u), const Color(0xFFFF7A5C));
    canvas.restore();

    // Göz: beyaz ak + koyu bebek. Alevin iç dilinin üstüne oturur.
    for (final dx in const [40.0, 60.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dx * u, 66 * u),
          width: 13 * u,
          height: 16 * u,
        ),
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset((dx + 1) * u, 68 * u),
        4.2 * u,
        Paint()..color = const Color(0xFF3A0A0A),
      );
      canvas.drawCircle(
        Offset((dx - 1.5) * u, 64 * u),
        1.8 * u,
        Paint()..color = Colors.white,
      );
    }

    // Ağız: küçük, kararlı bir gülümseme.
    canvas.drawArc(
      Rect.fromCenter(center: Offset(50 * u, 76 * u), width: 16 * u, height: 12 * u),
      0.15 * math.pi,
      0.7 * math.pi,
      false,
      Paint()
        ..color = const Color(0xFF3A0A0A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4 * u
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3 — Maskot: uygulamanın kimlik simgesi olan **loop şimşeği** karaktere
/// dönüyor. Rastgele bir hayvan değil; markadan türüyor.
class _BoltMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;

    Path bolt() => Path()
      ..moveTo(58 * u, 8 * u)
      ..lineTo(26 * u, 52 * u)
      ..lineTo(46 * u, 52 * u)
      ..lineTo(40 * u, 92 * u)
      ..lineTo(74 * u, 46 * u)
      ..lineTo(53 * u, 46 * u)
      ..close();

    void fillChunky(Path path, Color color, double w) {
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    // Kollar: "hadi gel" der gibi, gövdenin arkasından çıkar.
    final armPaint = Paint()
      ..color = const Color(0xFFB87E00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * u
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(30 * u, 58 * u), Offset(14 * u, 46 * u), armPaint);
    canvas.drawLine(Offset(70 * u, 42 * u), Offset(86 * u, 30 * u), armPaint);

    fillChunky(bolt().shift(Offset(0, 7 * u)), const Color(0xFFB87E00), 9 * u);
    fillChunky(bolt(), _bolt, 9 * u);

    // Üst kol ışıkta (§2.5/4: ışık anlamdan gelir).
    canvas.save();
    canvas.clipPath(bolt());
    canvas.drawPath(
      Path()
        ..moveTo(-10 * u, -10 * u)
        ..lineTo(110 * u, -10 * u)
        ..lineTo(110 * u, 26 * u)
        ..lineTo(-10 * u, 56 * u)
        ..close(),
      Paint()..color = const Color(0xFFFFE071),
    );
    canvas.restore();

    // Yüz: şimşeğin geniş üst gövdesine oturur.
    for (final dx in const [43.0, 60.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dx * u, 33 * u),
          width: 12 * u,
          height: 15 * u,
        ),
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(dx * u, 35 * u),
        4 * u,
        Paint()..color = const Color(0xFF3A2A00),
      );
      canvas.drawCircle(
        Offset((dx - 1.5) * u, 31 * u),
        1.7 * u,
        Paint()..color = Colors.white,
      );
    }

    canvas.drawArc(
      Rect.fromCenter(center: Offset(50 * u, 42 * u), width: 15 * u, height: 11 * u),
      0.15 * math.pi,
      0.7 * math.pi,
      false,
      Paint()
        ..color = const Color(0xFF3A2A00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2 * u
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.scale});

  final double scale;

  static const _labels = ['P', 'P', 'S', 'Ç', 'P', 'C', 'C'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230 * scale,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < 7; i++)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _labels[i],
                  style: TextStyle(
                    color: _muted,
                    fontFamily: 'Inter',
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5 * scale),
                SizedBox(
                  width: 24 * scale,
                  height: 24 * scale,
                  child: CustomPaint(painter: _DayPainter(filled: i < 2)),
                ),
              ],
            ),
        ],
      ),
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
        final a0 = i * math.pi / 6;
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r - 1),
          a0,
          math.pi / 11,
          false,
          dash,
        );
      }
      return;
    }

    canvas.drawCircle(c, r, Paint()..color = _flame);
    final check = Path()
      ..moveTo(r * 0.55, r * 1.02)
      ..lineTo(r * 0.88, r * 1.35)
      ..lineTo(r * 1.45, r * 0.68);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DayPainter oldDelegate) =>
      oldDelegate.filled != filled;
}
