import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

/// Seri kartı — **gün gün** durumlar, kullanıcının tasarlattığı sete göre.
///
/// Referans setin bizimkinden yapısal farkı: orada **tek düzen** var
/// (alev + N Gün + mesaj + hafta şeridi + maskot), bizde üç ayrı düzen
/// vardı. Tek düzen daha tutarlı; kart durumdan duruma yer değiştirmiyor,
/// yalnızca içeriği değişiyor.
///
/// Renk: referans setteki her kart ayrı bir zemin rengi kullanıyor. Burada
/// **uygulamanın koyu laciverti korundu** — §2.2 kaplama katmanı için palet
/// dışı renk yasağı geçerli. Durum farkı zeminden değil, **alev tonundan ve
/// mesajdan** geliyor.
///
///   flutter test --update-goldens test/streak_card_days_test.dart
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

  testWidgets('seri karti gun gun', (tester) async {
    const size = Size(1460, 1560);
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

    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/streak_card_days.png'),
    );
  });
}

const _bg = Color(0xFF041227);
const _border = Color(0xFF0B2143);
const _track = Color(0xFF0C2244);
const _muted = Color(0xFF8FA0B5);
const _flame = Color(0xFFFF6536);
const _gold = Color(0xFFFFC93A);
const _ice = Color(0xFF6BD1FF);

/// Bir kart durumu.
class _S {
  const _S(this.days, this.msg, this.filled, this.pose, {this.broken = false});

  final int days;
  final String msg;

  /// Hafta şeridinde kaç gün dolu.
  final int filled;

  /// Bu durum için gereken maskot pozu — henüz çizilmedi, not olarak duruyor.
  final String pose;

  final bool broken;
}

const _states = <_S>[
  _S(0, 'Haydi, bir adım at!', 0, 'yatmış, tembel ama sevimli'),
  _S(1, 'Bugün harika bir gün!', 1, 'ampul, fikir anı'),
  _S(3, 'Harika bir alışkanlık!', 3, 'fidan suluyor'),
  _S(7, 'Güzel bir başlangıç!', 7, 'zıplıyor, kıvılcımlar'),
  _S(0, 'Bize geri dön!', 3, 'ağlıyor', broken: true),
  _S(15, 'İstikrarını koru!', 6, 'halter kaldırıyor'),
  _S(30, 'Muhteşem!', 7, 'kupa tutuyor'),
  _S(50, 'Yarım asır!', 7, 'gözleri yıldız'),
  _S(100, 'Efsane!', 7, 'güneş gözlüğü, başparmak'),
  _S(200, 'İkonik bir başarı!', 7, 'gözlük + parıltı'),
];

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var row = 0; row < 5; row++) ...[
            if (row > 0) const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Cell(_states[row * 2])),
                const SizedBox(width: 24),
                Expanded(child: _Cell(_states[row * 2 + 1])),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.s);

  final _S s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.broken ? 'SERİ KIRILDI' : '${s.days} GÜN',
          style: const TextStyle(
            color: Color(0xFF5C6C80),
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'poz: ${s.pose}',
          style: const TextStyle(
            color: Color(0xFF3D4B5E),
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _StreakCard(s),
      ],
    );
  }
}

/// Tek düzen: solda alev + sayı + mesaj + şerit, sağda maskot.
class _StreakCard extends StatelessWidget {
  const _StreakCard(this.s);

  final _S s;

  /// Kilometre taşında kart altın kontur alır — mevcut kuralı koruyor.
  static const _milestones = [3, 7, 14, 30, 50, 100, 200, 365];

  @override
  Widget build(BuildContext context) {
    final isMilestone = _milestones.contains(s.days) && !s.broken;
    final rim = isMilestone ? _gold : _border;

    return Container(
      height: 196,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: rim, width: isMilestone ? 3 : 2),
        boxShadow: [
          BoxShadow(color: _border, offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          // Maskot sağda ve **kartın tabanına basıyor** — görsel içerik
          // sınırlarına kırpıldığı için alt hizalama yeterli.
          Positioned(
            right: 10,
            bottom: 0,
            child: Image.asset(
              'assets/icons/mascot_flex.png',
              height: 168,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 200, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    // Alev kırık seride sönük: renk durumu taşıyor,
                    // zemin değil.
                    Opacity(
                      opacity: s.broken || s.days == 0 ? 0.45 : 1,
                      child: QuestIcon(
                        questKey: 'streak_three',
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      '${s.days}',
                      style: TextStyle(
                        color: s.broken || s.days == 0 ? _muted : _flame,
                        fontFamily: 'Inter',
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'gün',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.msg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isMilestone ? _gold : Colors.white,
                    fontFamily: 'Inter',
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 14),
                _Week(filled: s.filled),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Week extends StatelessWidget {
  const _Week({required this.filled});

  final int filled;

  static const _labels = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pa'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _labels[i],
                style: TextStyle(
                  color: i == 6 ? Colors.white : _muted,
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: i == 6 ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 24,
                height: 24,
                child: CustomPaint(painter: _Day(filled: i < filled)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Day extends CustomPainter {
  const _Day({required this.filled});

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
            i * math.pi / 6, math.pi / 11, false, dash);
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
  bool shouldRepaint(covariant _Day old) => old.filled != filled;
}
