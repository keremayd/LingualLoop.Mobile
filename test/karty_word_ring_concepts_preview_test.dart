import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_button_style.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';
import 'package:lingualloop/ui/widgets/surface_gloss.dart';

import 'helpers/preview_fonts.dart';

/// Şu anki destenin kelime halkası için taslaklar (19 Kas 2026). **Yalnız
/// çizim:** patikaya dokunmaz; kullanıcı seçince uygulanır.
///
/// 1. Kelime başına kaç doğru (`karty_word_ring_concepts.png`): üç biçim,
///    iki eşik. A eşit parçalar, B kelimeye göre gruplu, C her kelime dolar.
///    Cevaplar hepsinde aynı: 8 kelimenin doğru sayıları 3·3·3·2·1·1·0·0.
/// 2. İki oyunluk deste (`karty_deck_two_games.png`, kullanıcı Duolingo
///    gibi "deste birkaç oyunda biter"i seçti): 1. oyun tanışma + anlam,
///    2. oyun artikel + yazım. Her kelimenin parçası anlamla yarıya,
///    artikelle dörtte üçe, yazımla tama dolar: 1. oyun bitince halka tam
///    yarım.
///
/// Düğüm ve halka patikadaki ölçülerle (`_PathLayout.currentWidth`,
/// `_NodeGeometry.ringGap/ringStroke`), gerçek cihaz genişliğinde.
///
///   CONCEPTS_CAPTURE=true flutter test --update-goldens \
///     test/karty_word_ring_concepts_preview_test.dart
final _capture = Platform.environment['CONCEPTS_CAPTURE'] == 'true';

const _phoneWidth = 402.0;
const _s = _phoneWidth / 750;

// Palet (§2.2) — yeni ton yok.
const _bg = Color(0xFF041227);
const _raised = Color(0xFF163258);
const _accent = Color(0xFF1CB1F5);
const _accentDepth = Color(0xFF1B84B5);
const _muted = Color(0xFF8FA0B5);
const _value = Color(0xFFE9EEF5);

// Patikadaki şu anki düğüm ve halkası (karty_path_screen.dart).
const _width = 150.0;
const _gap = 16.0;
const _stroke = 12.0;
const _total = _width * 89.625 / 84.75;
final _button = AppButtonStyle.resolve(
  width: _width,
  totalHeight: _total,
  legacyRadius: _width * 0.29,
  legacyDepth: _total * 0.14,
  icon: true,
);

/// 8 kelimenin doğru sayıları, deste sırasıyla.
const _answers = [3, 3, 3, 2, 1, 1, 0, 0];

enum _Style { single, equal, grouped, fill }

void main() {
  setUpAll(loadPreviewFonts);

  Future<void> capture(WidgetTester tester, Widget board, String name) async {
    // Golden mantıksal pikselle yakalanıyor: pano 3 kat büyütülüp
    // çiziliyor ki cihazdaki keskinlikte görünsün.
    tester.view.physicalSize = const Size(_phoneWidth * 3, 1000 * 3);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const key = ValueKey('board');
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          color: _bg,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: _phoneWidth * 3,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topLeft,
                  child: board,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(find.byKey(key), matchesGoldenFile('goldens/$name'));
  }

  testWidgets('kelime halkası taslakları', (tester) async {
    await capture(tester, const _Board(), 'karty_word_ring_concepts.png');
  }, skip: !_capture);

  testWidgets('iki oyunluk deste', (tester) async {
    await capture(tester, const _TwoGameBoard(), 'karty_deck_two_games.png');
  }, skip: !_capture);
}

class _Board extends StatelessWidget {
  const _Board();

  @override
  Widget build(BuildContext context) {
    List<int> steps(int goal) =>
        [for (final count in _answers) math.min(count, goal)]
          ..sort((a, b) => b.compareTo(a));
    String words(int goal) =>
        '${_answers.where((count) => count >= goal).length}/8 yeni';
    String answers(int goal) =>
        '${steps(goal).fold(0, (sum, step) => sum + step)}/${8 * goal} doğru';
    CustomPainter ring(int goal, _Style style) =>
        _RingPainter(steps: steps(goal), goal: goal, style: style);

    Widget row(int goal) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Cell(
              caption: 'A · Eşit parçalar',
              painter: ring(goal, _Style.equal),
              detail: answers(goal),
            ),
            _Cell(
              caption: 'B · Kelimeye göre gruplu',
              painter: ring(goal, _Style.grouped),
              detail: words(goal),
            ),
            _Cell(
              caption: 'C · Her kelime dolar',
              painter: ring(goal, _Style.fill),
              detail: words(goal),
            ),
          ],
        );

    return _Sheet(
      children: [
        const _Section('ŞİMDİ · HER KELİME 1 KEZ DOĞRU'),
        _Cell(
          caption: '8 parça',
          painter: ring(1, _Style.single),
          detail: words(1),
        ),
        const SizedBox(height: 18),
        const _Section('HER KELİME 2 KEZ DOĞRU · 16 ADIM'),
        row(2),
        const SizedBox(height: 18),
        const _Section('HER KELİME 3 KEZ DOĞRU · 24 ADIM'),
        row(3),
        const SizedBox(height: 16),
        const _Note(
          'Cevaplar hepsinde aynı: 8 kelimenin doğru sayısı 3·3·3·2·1·1·0·0',
        ),
      ],
    );
  }
}

/// İki oyunluk deste: her kelimenin adımı 0 tanışıldı, 1 anlam, 2 artikel,
/// 3 yazım. Parça anlamla yarıya, artikelle dörtte üçe, yazımla tama dolar.
class _TwoGameBoard extends StatelessWidget {
  const _TwoGameBoard();

  static const _fill = [0.0, 0.5, 0.75, 1.0];

  @override
  Widget build(BuildContext context) {
    CustomPainter ring(List<int> steps) => _FillRingPainter(
          fills: [for (final step in steps) _fill[step]]
            ..sort((a, b) => b.compareTo(a)),
        );

    return _Sheet(
      children: [
        const _Section('DESTE İKİ OYUNDA BİTER'),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Phase(title: '1. oyun', body: 'Tanış ve görseli bul'),
            _Phase(title: '2. oyun', body: 'Artikeli seç ve harfleri diz'),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Cell(
              caption: '1. oyun sürüyor\n5 kelimenin anlamı bilindi',
              painter: ring(const [1, 1, 1, 1, 1, 0, 0, 0]),
              detail: '1. oyun · 5/8',
            ),
            _Cell(
              caption: '1. oyun bitti\nhalka yarım',
              painter: ring(const [1, 1, 1, 1, 1, 1, 1, 1]),
              detail: '2. oyun · 0/8',
            ),
            _Cell(
              caption: '2. oyun sürüyor\n3 kelime tamam,\n2 kelime artikelde',
              painter: ring(const [3, 3, 3, 2, 2, 1, 1, 1]),
              detail: '2. oyun · 3/8',
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _Note(
          'Halka tamamen dolunca Deste 2 açılır. Pekiştirme kapısı aynı.',
        ),
      ],
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _phoneWidth,
      color: _bg,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _Phase extends StatelessWidget {
  const _Phase({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _value,
              fontSize: 14,
              fontWeight: AppTypography.number,
              fontFamily: AppTypography.family,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 11.5,
              fontWeight: AppTypography.caption,
              fontFamily: AppTypography.family,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: _muted,
        fontSize: 11,
        fontWeight: AppTypography.caption,
        fontFamily: AppTypography.family,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: _muted,
          fontSize: 11.5,
          letterSpacing: 1.2,
          fontWeight: AppTypography.label,
          fontFamily: AppTypography.family,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.caption,
    required this.painter,
    required this.detail,
  });

  final String caption;
  final CustomPainter painter;
  final String detail;

  @override
  Widget build(BuildContext context) {
    const half = _stroke * _s / 2;
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          SizedBox(
            width: (_width + 2 * _gap) * _s + 2 * half,
            height: (_total + 2 * _gap) * _s + 2 * half,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: painter)),
                const Positioned(
                  left: half + _gap * _s,
                  top: half + _gap * _s,
                  child: _Node(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Deste 1',
            style: TextStyle(
              color: _value,
              fontSize: 28 * _s,
              fontWeight: AppTypography.number,
              fontFamily: AppTypography.family,
              height: 1.1,
            ),
          ),
          SizedBox(height: 6 * _s),
          Text(
            detail,
            style: TextStyle(
              color: _accent,
              fontSize: 22 * _s,
              fontWeight: AppTypography.label,
              fontFamily: AppTypography.family,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 10.5,
              fontWeight: AppTypography.caption,
              fontFamily: AppTypography.family,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Patikadaki şu anki deste düğümü (`_NodeTile` + şimşek).
class _Node extends StatelessWidget {
  const _Node();

  @override
  Widget build(BuildContext context) {
    return DepthPressableButton(
      width: _width * _s,
      height: (_total - _button.depth) * _s,
      radius: _width * 0.29 * _s,
      shadowOffset: _button.depth * _s,
      backgroundColor: _accent,
      shadowColor: _accentDepth,
      fontSize: 0,
      onPressed: () {},
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: FaceGlossPainter(radius: _button.radius * _s),
              ),
            ),
            QuestIcon(questKey: 'correct_five', size: _width * 0.56 * _s),
          ],
        ),
      ),
    );
  }
}

/// Halkanın yolu ve parça çizimi; iki ressam paylaşır.
abstract class _RingBase extends CustomPainter {
  const _RingBase();

  void paintRing(
    Canvas canvas,
    Size size,
    void Function(
      double length,
      void Function(double from, double to, Color color) piece,
    ) draw,
  ) {
    const half = _stroke * _s / 2;
    final rect = Rect.fromLTWH(
      half,
      half,
      size.width - 2 * half,
      size.height - 2 * half,
    );
    final metric = _clockwiseFromTop(rect, (_button.radius + _gap) * _s)
        .computeMetrics()
        .first;
    draw(
      metric.length,
      (from, to, color) => canvas.drawPath(
        metric.extractPath(from, to),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke * _s
          ..strokeCap = StrokeCap.round,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RingPainter extends _RingBase {
  const _RingPainter({
    required this.steps,
    required this.goal,
    required this.style,
  });

  /// Kelime başına doğru (en çok [goal]), büyükten küçüğe: halka tepeden
  /// saat yönünde dolar.
  final List<int> steps;
  final int goal;
  final _Style style;

  @override
  void paint(Canvas canvas, Size size) {
    paintRing(canvas, size, (length, piece) {
      final words = steps.length;
      switch (style) {
        case _Style.single:
          final slot = length / words;
          const cut = 16 * _s;
          for (var i = 0; i < words; i++) {
            piece(i * slot + cut / 2, (i + 1) * slot - cut / 2,
                steps[i] > 0 ? _accent : _raised);
          }
        case _Style.equal:
          final n = words * goal;
          final lit = steps.fold(0, (sum, step) => sum + step);
          final slot = length / n;
          // Bugünkü 16 birimlik kesik (görünen ~4) 16 parçada çentiğe
          // dönüşüyor; parçalar ayrı okunsun diye açıldı.
          final cut = (goal == 2 ? 20 : 18) * _s;
          for (var i = 0; i < n; i++) {
            piece(i * slot + cut / 2, (i + 1) * slot - cut / 2,
                i < lit ? _accent : _raised);
          }
        case _Style.grouped:
          final slot = length / words;
          const outer = 26 * _s;
          const inner = 16 * _s;
          final sub = (slot - outer - (goal - 1) * inner) / goal;
          for (var w = 0; w < words; w++) {
            for (var j = 0; j < goal; j++) {
              final from = w * slot + outer / 2 + j * (sub + inner);
              piece(from, from + sub, j < steps[w] ? _accent : _raised);
            }
          }
        case _Style.fill:
          _paintFills(
              length, piece, [for (final step in steps) step / goal]);
      }
    });
  }
}

/// Her kelimenin parçası kendi oranında dolar ([fills], 0–1).
class _FillRingPainter extends _RingBase {
  const _FillRingPainter({required this.fills});

  final List<double> fills;

  @override
  void paint(Canvas canvas, Size size) {
    paintRing(canvas, size, (length, piece) {
      _paintFills(length, piece, fills);
    });
  }
}

void _paintFills(
  double length,
  void Function(double from, double to, Color color) piece,
  List<double> fills,
) {
  final slot = length / fills.length;
  const cut = 16 * _s;
  for (var w = 0; w < fills.length; w++) {
    final from = w * slot + cut / 2;
    final to = (w + 1) * slot - cut / 2;
    piece(from, to, _raised);
    if (fills[w] > 0) piece(from, from + (to - from) * fills[w], _accent);
  }
}

/// Patikadaki halkanın yolu: tepe ortasından saat yönünde.
Path _clockwiseFromTop(Rect rect, double radius) {
  final r = Radius.circular(radius);
  return Path()
    ..moveTo(rect.center.dx, rect.top)
    ..lineTo(rect.right - radius, rect.top)
    ..arcToPoint(Offset(rect.right, rect.top + radius), radius: r)
    ..lineTo(rect.right, rect.bottom - radius)
    ..arcToPoint(Offset(rect.right - radius, rect.bottom), radius: r)
    ..lineTo(rect.left + radius, rect.bottom)
    ..arcToPoint(Offset(rect.left, rect.bottom - radius), radius: r)
    ..lineTo(rect.left, rect.top + radius)
    ..arcToPoint(Offset(rect.left + radius, rect.top), radius: r)
    ..close();
}
