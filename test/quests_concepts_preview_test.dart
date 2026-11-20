import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stelinda/ui/app_typography.dart';
import 'package:stelinda/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:stelinda/ui/widgets/app_bottom_nav_bar.dart';
import 'package:stelinda/ui/widgets/countdown_pill.dart';
import 'package:stelinda/ui/widgets/quest_icons.dart';
import 'package:stelinda/ui/widgets/streak_freeze_flake.dart';
import 'package:stelinda/ui/widgets/surface_gloss.dart';
import 'package:stelinda/ui/widgets/ticket_with_count.dart';

import 'helpers/preview_fonts.dart';

/// Görevler ekranı için üç yerleşim taslağı (15 Kas 2026). **Yalnız çizim:**
/// uygulamadaki ekrana dokunmaz; kullanıcı yönü seçince uygulanır.
///
///   A · Sahneli hedef kartı + tek liste
///   B · Izgara (görevler büyük simgeli kareler, 6. kare bonus)
///   C · Odak (öne çıkan görev + sıradakiler)
///
/// Veri üçünde aynı: 5 görevden biri alınmış, biri hazır, üçü sürüyor;
/// 13/15 bilet; seri koruması 2/5. A'daki sahne görseli **yer tutucu**
/// (seri penceresinin kupa sahnesi); görevlere özel sahne üretilecek.
///
///   CONCEPTS_CAPTURE=true flutter test --update-goldens \
///     test/quests_concepts_preview_test.dart
final _capture = Platform.environment['CONCEPTS_CAPTURE'] == 'true';

const _phone = Size(402, 874);

// Palet (§2.2) — yeni ton yok.
const _bg = Color(0xFF041227);
const _panel = Color(0xFF0B2143);
const _tile = Color(0xFF0C2244);
const _raised = Color(0xFF163258);
const _base = Color(0xFF07182F);
const _gold = Color(0xFFFFC93A);
const _goldDim = Color(0xFFB87E00);
const _onGold = Color(0xFF4A3400);
const _green = Color(0xFF93D334);
const _greenDepth = Color(0xFF628C22);
const _muted = Color(0xFF8FA0B5);

class _Quest {
  const _Quest(this.key, this.title, this.target, this.progress, this.reward,
      {this.claimed = false});

  final String key;
  final String title;
  final int target;
  final int progress;
  final int reward;
  final bool claimed;

  bool get done => progress >= target;
  bool get ready => done && !claimed;
}

const _ready = _Quest('correct_five', '5 kelimeyi doğru bil', 5, 5, 2);
const _going = [
  _Quest('learn_three', '3 yeni kelime öğren', 3, 1, 2),
  _Quest('review_two', '2 rövanş kartını geri kazan', 2, 0, 2),
  _Quest('streak_three', 'Serini sürdür', 1, 0, 3),
];
const _claimed = _Quest('checkin', 'Güne başla', 1, 1, 1, claimed: true);
const _doneCount = 2;
const _total = 5;

TextStyle _heading(double size, {Color color = Colors.white}) => TextStyle(
      color: color,
      fontSize: size,
      fontWeight: AppTypography.heading,
      fontFamily: AppTypography.displayFamily,
      height: 1.05,
    );

TextStyle _text(double size,
        {Color color = Colors.white,
        FontWeight weight = AppTypography.label,
        double height = 1.15,
        double spacing = 0}) =>
    TextStyle(
      color: color,
      fontSize: size,
      fontWeight: weight,
      fontFamily: AppTypography.family,
      height: height,
      letterSpacing: spacing,
    );

// ---------------------------------------------------------------------------
// Ortak parçalar
// ---------------------------------------------------------------------------

/// Bilet bakiyesi: yıldızlı bilet + sayı + tavan (§4.3).
class _Balance extends StatelessWidget {
  const _Balance({required this.s, this.ticket = 92});

  final double s;
  final double ticket;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset('assets/icons/ticket.png', width: ticket * s),
        SizedBox(width: 10 * s),
        Text('13', style: _text(40 * s, weight: AppTypography.number)),
        Padding(
          padding: EdgeInsets.only(top: 12 * s),
          child: Text('/15',
              style:
                  _text(24 * s, color: _muted, weight: AppTypography.caption)),
        ),
      ],
    );
  }
}

/// Görev çubuğu: altın dolgu, ortada x/y (dolu kısımda koyu yazı, §2.9).
class _Bar extends StatelessWidget {
  const _Bar({
    required this.s,
    required this.progress,
    required this.target,
    this.height = 24,
    this.track = _bg,
    this.label = true,
  });

  final double s;
  final int progress;
  final int target;
  final double height;
  final Color track;
  final bool label;

  @override
  Widget build(BuildContext context) {
    final f = (progress / target).clamp(0.0, 1.0);
    final h = height * s;
    final text = Text('$progress/$target',
        style: _text(h * 0.72, weight: AppTypography.number, height: 1));
    return ClipRRect(
      borderRadius: BorderRadius.circular(h / 2),
      child: SizedBox(
        height: h,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: track)),
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: f,
                child: const ColoredBox(color: _gold),
              ),
            ),
            if (label)
              Center(
                child: f >= 0.55
                    ? DefaultTextStyle.merge(
                        style: const TextStyle(color: _onGold),
                        child: Text('$progress/$target',
                            style: _text(h * 0.72,
                                color: _onGold,
                                weight: AppTypography.number,
                                height: 1)),
                      )
                    : text,
              ),
          ],
        ),
      ),
    );
  }
}

/// Hazır ödül: uygulamadaki reçete (`_ClaimButton`) — hâle biletin kendi
/// silüetinden: `ticket.png` altına boyanıp bulanıklaştırılır (%55); altında
/// koyu altın kalınlık bandı. Yarı saydam düz altın lacivertte zeytine
/// dönüyor (§4.3), bu yüzden kutu gölgesi değil.
class _ReadyTicket extends StatelessWidget {
  const _ReadyTicket({required this.s, required this.count, this.width = 70});

  final double s;
  final int count;
  final double width;

  @override
  Widget build(BuildContext context) {
    final w = width * s;
    final pad = 13 * s;
    final band = 6 * s;
    Widget silhouette(Color color, double size) => ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) =>
              LinearGradient(colors: [color, color]).createShader(rect),
          child: Image.asset('assets/icons/ticket.png', width: size),
        );
    return SizedBox(
      width: w,
      height: w * 110 / 172 + band,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -pad,
            top: -pad,
            child: Opacity(
              opacity: 0.55,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 9 * s, sigmaY: 9 * s),
                child: silhouette(_gold, w + 2 * pad),
              ),
            ),
          ),
          Positioned(left: 0, top: band, child: silhouette(_goldDim, w)),
          Positioned(
            left: 0,
            top: 0,
            child: TicketWithCount(
                scale: s, count: count, ticketWidth: width, badgeSize: 32),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.s, this.trailing});

  final String text;
  final double s;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text,
            style: _text(21 * s,
                color: _muted, weight: AppTypography.number, spacing: 1.6 * s)),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Kalan süre: küçük saat + değer (bölüm başlığının sağında).
class _SmallCountdown extends StatelessWidget {
  const _SmallCountdown({required this.s});

  final double s;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, color: _muted, size: 24 * s),
        SizedBox(width: 6 * s),
        Text('8 SA 59 DK',
            style: _text(21 * s,
                color: _muted, weight: AppTypography.number, spacing: 1.2 * s)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// A · Sahneli hedef kartı + tek liste
// ---------------------------------------------------------------------------

class _ConceptA extends StatelessWidget {
  const _ConceptA({required this.s, this.bottom});

  final double s;

  /// Bölüm başlığının altı. Verilmezse ilk taslaktaki tek kutulu liste.
  final List<Widget> Function(double s)? bottom;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(34 * s, 14 * s, 34 * s, 0),
          child: Row(
            children: [
              Text('Görevler', style: _heading(46 * s)),
              const Spacer(),
              _Balance(s: s, ticket: 84),
            ],
          ),
        ),
        SizedBox(height: 22 * s),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 34 * s),
          child: _SceneGoalCard(s: s),
        ),
        SizedBox(height: 36 * s),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40 * s),
          child: _SectionLabel('GÜNLÜK GÖREVLER',
              s: s, trailing: _SmallCountdown(s: s)),
        ),
        ...?bottom?.call(s),
        if (bottom == null) ...[
          SizedBox(height: 14 * s),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 34 * s),
            child: _GroupedList(s: s, quests: const [_ready, ..._going]),
          ),
          SizedBox(height: 34 * s),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40 * s),
            child: _SectionLabel('TAMAMLANANLAR', s: s),
          ),
          SizedBox(height: 14 * s),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 34 * s),
            child: _GroupedList(s: s, quests: const [_claimed], dim: true),
          ),
        ],
      ],
    );
  }
}

/// Günün hedefi bir sahne kartı: solda hedef ve beş görev adımı, sonunda
/// seri koruması; sağda maskot sahnesi (seri penceresindeki sahneli kartın
/// kuruluşu: görsel sola doğru kartın rengine söner).
class _SceneGoalCard extends StatelessWidget {
  const _SceneGoalCard({required this.s});

  final double s;

  // Kupa sahnesinin ölçülmüş kart rengi (streak_day_scenes.dart).
  static const _face = Color(0xFFF2822E);
  static const _edge = Color(0xFFFD8B36);

  @override
  Widget build(BuildContext context) {
    final h = 300 * s;
    final r = 36 * s;
    return SizedBox(
      height: h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_face, _edge],
                    stops: const [0.45, 1],
                  ),
                ),
              ),
            ),
            // Sahne sağda, sola doğru kendi alfasıyla söner.
            Positioned(
              right: -40 * s,
              top: -6 * s,
              bottom: -6 * s,
              width: h * 1.78,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Colors.transparent, Colors.black],
                  stops: [0.0, 0.34],
                ).createShader(rect),
                child: Image.asset(
                  'assets/scenes/harika_gidiyorsun.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: TopRimPainter(
                  color: Colors.white.withValues(alpha: 0.42),
                  radius: r,
                  strokeWidth: 3 * s,
                ),
              ),
            ),
            Positioned(
              left: 34 * s,
              top: 30 * s,
              width: 372 * s,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BUGÜNÜN HEDEFİ',
                      style: _text(20 * s,
                          color: Colors.white.withValues(alpha: 0.86),
                          weight: AppTypography.number,
                          spacing: 1.6 * s)),
                  SizedBox(height: 8 * s),
                  Text('Tüm görevleri bitir',
                      maxLines: 1, style: _heading(35 * s)),
                  SizedBox(height: 26 * s),
                  Row(
                    children: [
                      for (var i = 0; i < _total; i++) ...[
                        if (i > 0) SizedBox(width: 9 * s),
                        _StepPip(s: s, done: i < _doneCount),
                      ],
                      SizedBox(width: 12 * s),
                      _FreezeGoal(s: s, size: 70),
                    ],
                  ),
                  SizedBox(height: 18 * s),
                  Text('$_doneCount/$_total görev · ödül: seri koruması',
                      style: _text(21 * s,
                          color: Colors.white.withValues(alpha: 0.92))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Görev adımı: biten beyaz dolu ve onaylı, kalan beyaz çerçeve izi.
class _StepPip extends StatelessWidget {
  const _StepPip({required this.s, required this.done});

  final double s;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final size = 38 * s;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: done ? Colors.white : Colors.white.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(11 * s),
      ),
      alignment: Alignment.center,
      child: done
          ? Icon(Icons.check_rounded,
              color: const Color(0xFFE0701E), size: 28 * s)
          : null,
    );
  }
}

/// Hedefin ödülü: lacivert karo içinde seri koruması.
class _FreezeGoal extends StatelessWidget {
  const _FreezeGoal({required this.s, required this.size});

  final double s;
  final double size;

  @override
  Widget build(BuildContext context) {
    final w = size * s;
    final depth = 7 * s;
    return SizedBox(
      width: w,
      height: w,
      child: Stack(
        children: [
          Positioned.fill(
            top: depth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _base,
                borderRadius: BorderRadius.circular(w * 0.29),
              ),
            ),
          ),
          Positioned.fill(
            bottom: depth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _tile,
                borderRadius: BorderRadius.circular(w * 0.29),
              ),
              child: Center(
                child: Opacity(
                  opacity: 0.6,
                  child: StreakFreezeFlake(size: w * 0.74),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tek kutuda görev satırları, aralarında ince ayraç (Duolingo'nun ağır
/// kutular yerine boşluk ilkesi).
class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.s, required this.quests, this.dim = false});

  final double s;
  final List<_Quest> quests;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(30 * s);
    return Container(
      decoration: BoxDecoration(color: dim ? _base : _panel, borderRadius: r),
      padding: EdgeInsets.only(bottom: 8 * s),
      child: Container(
        decoration: BoxDecoration(color: dim ? _bg : _tile, borderRadius: r),
        child: Column(
          children: [
            for (final (i, q) in quests.indexed) ...[
              if (i > 0)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 26 * s),
                  child: Container(height: 2 * s, color: _panel),
                ),
              dim ? _DoneRow(s: s, q: q) : _ListRow(s: s, q: q),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({required this.s, required this.q});

  final double s;
  final _Quest q;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(26 * s, 24 * s, 22 * s, 24 * s),
      child: Row(
        children: [
          SizedBox(
            width: 64 * s,
            child: Center(child: QuestIcon(questKey: q.key, size: 58 * s)),
          ),
          SizedBox(width: 22 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.title, style: _text(25 * s)),
                SizedBox(height: 14 * s),
                Row(
                  children: [
                    Expanded(
                      child: _Bar(s: s, progress: q.progress, target: q.target),
                    ),
                    SizedBox(width: 10 * s),
                    SizedBox(
                      width: 74 * s,
                      height: 52 * s,
                      child: Center(
                        child: q.ready
                            ? _ReadyTicket(s: s, count: q.reward, width: 66)
                            : TicketWithCount(
                                scale: s,
                                count: q.reward,
                                ticketWidth: 56,
                                badgeSize: 28,
                                dim: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneRow extends StatelessWidget {
  const _DoneRow({required this.s, required this.q});

  final double s;
  final _Quest q;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(26 * s, 18 * s, 22 * s, 18 * s),
      child: Row(
        children: [
          SizedBox(
            width: 64 * s,
            child: Center(child: QuestIcon(questKey: q.key, size: 38 * s)),
          ),
          SizedBox(width: 22 * s),
          Expanded(
            child: Text(q.title,
                style: _text(24 * s, color: const Color(0xFFC7D2E0))),
          ),
          Text('+${q.reward}',
              style:
                  _text(21 * s, color: _muted, weight: AppTypography.number)),
          SizedBox(width: 12 * s),
          QuestCheckMark(size: 40 * s),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// B · Izgara
// ---------------------------------------------------------------------------

class _ConceptB extends StatelessWidget {
  const _ConceptB({required this.s});

  final double s;

  @override
  Widget build(BuildContext context) {
    final gap = 22 * s;
    final cells = <Widget>[
      _GridCell(s: s, q: _ready),
      for (final q in _going) _GridCell(s: s, q: q),
      _GridCell(s: s, q: _claimed),
      _BonusCell(s: s),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(34 * s, 14 * s, 34 * s, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Günlük Görevler', style: _heading(44 * s)),
                    SizedBox(height: 12 * s),
                    CountdownPill(
                        scale: s, value: '8 sa 59 dk', semanticLabel: ''),
                  ],
                ),
              ),
              _Balance(s: s, ticket: 84),
            ],
          ),
          SizedBox(height: 30 * s),
          for (var row = 0; row < 3; row++) ...[
            if (row > 0) SizedBox(height: gap),
            Row(
              children: [
                Expanded(child: cells[row * 2]),
                SizedBox(width: gap),
                Expanded(child: cells[row * 2 + 1]),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Izgaradaki görev karesi: büyük simge, başlık, altta çubuk ve ucunda ödül.
class _GridCell extends StatelessWidget {
  const _GridCell({required this.s, required this.q});

  final double s;
  final _Quest q;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(32 * s);
    final claimed = q.claimed;
    return Container(
      height: 312 * s,
      decoration: BoxDecoration(
        color: q.ready ? _goldDim : (claimed ? _base : _panel),
        borderRadius: r,
      ),
      padding: EdgeInsets.only(bottom: 8 * s),
      child: Container(
        decoration: BoxDecoration(
          color: claimed ? _bg : _tile,
          borderRadius: r,
          border: q.ready ? Border.all(color: _gold, width: 4 * s) : null,
        ),
        padding: EdgeInsets.fromLTRB(24 * s, 24 * s, 20 * s, 22 * s),
        child: Opacity(
          opacity: claimed ? 0.62 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 96 * s,
                    height: 96 * s,
                    decoration: BoxDecoration(
                      color: claimed ? _tile : _raised,
                      borderRadius: BorderRadius.circular(28 * s),
                    ),
                    alignment: Alignment.center,
                    child: QuestIcon(questKey: q.key, size: 66 * s),
                  ),
                  const Spacer(),
                  if (claimed) QuestCheckMark(size: 48 * s),
                ],
              ),
              SizedBox(height: 18 * s),
              Text(q.title, maxLines: 2, style: _text(25 * s)),
              const Spacer(),
              claimed
                  ? Text('+${q.reward} bilet alındı',
                      style: _text(21 * s,
                          color: _muted, weight: AppTypography.number))
                  : Row(
                      children: [
                        Expanded(
                          child: _Bar(
                              s: s, progress: q.progress, target: q.target),
                        ),
                        SizedBox(width: 8 * s),
                        SizedBox(
                          width: 66 * s,
                          height: 50 * s,
                          child: Center(
                            child: q.ready
                                ? _ReadyTicket(s: s, count: q.reward, width: 60)
                                : TicketWithCount(
                                    scale: s,
                                    count: q.reward,
                                    ticketWidth: 52,
                                    badgeSize: 26,
                                    dim: true),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Altıncı kare: bütün görevlerin ödülü.
class _BonusCell extends StatelessWidget {
  const _BonusCell({required this.s});

  final double s;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(32 * s);
    return Container(
      height: 312 * s,
      decoration: BoxDecoration(color: _panel, borderRadius: r),
      padding: EdgeInsets.only(bottom: 8 * s),
      child: Container(
        decoration: BoxDecoration(
          color: _tile,
          borderRadius: r,
        ),
        padding: EdgeInsets.fromLTRB(24 * s, 22 * s, 20 * s, 22 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: 0.6,
              child: StreakFreezeFlake(size: 104 * s),
            ),
            SizedBox(height: 10 * s),
            Text('Hepsini bitir', style: _text(25 * s)),
            SizedBox(height: 4 * s),
            Text('Ödül: seri koruması',
                style: _text(20 * s,
                    color: _muted, weight: AppTypography.caption)),
            const Spacer(),
            Row(
              children: [
                for (var i = 0; i < _total; i++) ...[
                  if (i > 0) SizedBox(width: 7 * s),
                  Expanded(
                    child: Container(
                      height: 18 * s,
                      decoration: BoxDecoration(
                        color: i < _doneCount ? _gold : _panel,
                        borderRadius: BorderRadius.circular(9 * s),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// C · Odak
// ---------------------------------------------------------------------------

class _ConceptC extends StatelessWidget {
  const _ConceptC({required this.s});

  final double s;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(34 * s, 14 * s, 34 * s, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Günlük Görevler', style: _heading(44 * s)),
                    SizedBox(height: 12 * s),
                    CountdownPill(
                        scale: s, value: '8 sa 59 dk', semanticLabel: ''),
                  ],
                ),
              ),
              _Balance(s: s, ticket: 84),
            ],
          ),
          SizedBox(height: 28 * s),
          _FocusCard(s: s),
          SizedBox(height: 34 * s),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6 * s),
            child: _SectionLabel('SIRADAKİLER', s: s),
          ),
          SizedBox(height: 12 * s),
          for (final q in _going) ...[
            _CompactRow(s: s, q: q),
            SizedBox(height: 12 * s),
          ],
          SizedBox(height: 14 * s),
          _BonusStrip(s: s),
        ],
      ),
    );
  }
}

/// Öne çıkan görev: ödülü hazır olan, yoksa bitmeye en yakın görev.
class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.s});

  final double s;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(38 * s);
    return Container(
      decoration: BoxDecoration(color: _panel, borderRadius: r),
      padding: EdgeInsets.only(bottom: 10 * s),
      child: Container(
        decoration: BoxDecoration(color: _raised, borderRadius: r),
        padding: EdgeInsets.fromLTRB(30 * s, 30 * s, 30 * s, 30 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 132 * s,
                  height: 132 * s,
                  decoration: BoxDecoration(
                    color: _tile,
                    borderRadius: BorderRadius.circular(36 * s),
                  ),
                  alignment: Alignment.center,
                  child: QuestIcon(questKey: _ready.key, size: 96 * s),
                ),
                SizedBox(width: 26 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ÖDÜLÜN HAZIR',
                          style: _text(20 * s,
                              color: _gold,
                              weight: AppTypography.number,
                              spacing: 1.6 * s)),
                      SizedBox(height: 8 * s),
                      Text(_ready.title, style: _heading(38 * s)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 26 * s),
            Row(
              children: [
                Expanded(
                  child: _Bar(
                      s: s,
                      progress: _ready.progress,
                      target: _ready.target,
                      height: 30,
                      track: _bg),
                ),
                SizedBox(width: 14 * s),
                _ReadyTicket(s: s, count: _ready.reward, width: 80),
              ],
            ),
            SizedBox(height: 28 * s),
            DepthPressableButton(
              text: 'ÖDÜLÜ AL',
              width: 542 * s,
              height: 92 * s,
              radius: 26 * s,
              shadowOffset: 10 * s,
              backgroundColor: _green,
              shadowColor: _greenDepth,
              fontSize: 30 * s,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactRow extends StatelessWidget {
  const _CompactRow({required this.s, required this.q});

  final double s;
  final _Quest q;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _tile,
        borderRadius: BorderRadius.circular(26 * s),
      ),
      padding: EdgeInsets.fromLTRB(22 * s, 18 * s, 22 * s, 18 * s),
      child: Row(
        children: [
          QuestIcon(questKey: q.key, size: 50 * s),
          SizedBox(width: 20 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.title, style: _text(24 * s)),
                SizedBox(height: 10 * s),
                _Bar(
                    s: s,
                    progress: q.progress,
                    target: q.target,
                    height: 14,
                    label: false),
              ],
            ),
          ),
          SizedBox(width: 18 * s),
          Text('${q.progress}/${q.target}',
              style:
                  _text(22 * s, color: _muted, weight: AppTypography.number)),
          SizedBox(width: 14 * s),
          TicketWithCount(
              scale: s,
              count: q.reward,
              ticketWidth: 50,
              badgeSize: 26,
              dim: true),
        ],
      ),
    );
  }
}

class _BonusStrip extends StatelessWidget {
  const _BonusStrip({required this.s});

  final double s;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(26 * s),
      ),
      padding: EdgeInsets.fromLTRB(18 * s, 16 * s, 24 * s, 16 * s),
      child: Row(
        children: [
          _FreezeGoal(s: s, size: 76),
          SizedBox(width: 20 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hepsini bitir, seri koruması kazan',
                    style: _text(23 * s)),
                SizedBox(height: 10 * s),
                Row(
                  children: [
                    for (var i = 0; i < _total; i++) ...[
                      if (i > 0) SizedBox(width: 7 * s),
                      Expanded(
                        child: Container(
                          height: 14 * s,
                          decoration: BoxDecoration(
                            color: i < _doneCount ? _gold : _tile,
                            borderRadius: BorderRadius.circular(7 * s),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// A'nın alt kısmı — iki seçenek (üst kısım onaylı, 15 Kas 2026)
// ---------------------------------------------------------------------------

/// Görevin adımları: başlık kartındaki adım karelerinin dili. Biten altın,
/// kalan koyu yuva.
class _Pips extends StatelessWidget {
  const _Pips({
    required this.s,
    required this.done,
    required this.total,
    this.slot = _base,
  });

  final double s;
  final int done;
  final int total;
  final Color slot;

  static const _size = 22.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) SizedBox(width: 7 * s),
          Container(
            width: _size * s,
            height: _size * s,
            decoration: BoxDecoration(
              color: i < done ? _gold : slot,
              borderRadius: BorderRadius.circular(_size * 0.3 * s),
            ),
          ),
        ],
        SizedBox(width: 12 * s),
        Text('$done/$total',
            style: _text(20 * s, color: _muted, weight: AppTypography.number)),
      ],
    );
  }
}

/// Kupon biçimi: köşeleri yuvarlak dikdörtgen, koçan çizgisinde üstte ve
/// altta yarım daire çentik (bilet simgesinin çentiklerinin dili).
Path _couponPath(Size size, double radius, double stubX, double notch) {
  final base = Path()
    ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
  final cuts = Path()
    ..addOval(Rect.fromCircle(center: Offset(stubX, 0), radius: notch))
    ..addOval(
        Rect.fromCircle(center: Offset(stubX, size.height), radius: notch));
  return Path.combine(PathOperation.difference, base, cuts);
}

class _CouponPainter extends CustomPainter {
  _CouponPainter({
    required this.s,
    required this.stubWidth,
    required this.face,
    required this.depth,
    required this.stubFace,
    this.perforation = true,
  });

  final double s;
  final double stubWidth;
  final Color face;
  final Color depth;
  final Color stubFace;
  final bool perforation;

  @override
  void paint(Canvas canvas, Size size) {
    final band = 8 * s;
    final faceSize = Size(size.width, size.height - band);
    final radius = 28 * s;
    final notch = 15 * s;
    final stubX = size.width - stubWidth * s;
    final shape = _couponPath(faceSize, radius, stubX, notch);
    // Kalınlık: aynı biçim aşağı kaydırılmış (§2.4 dili). Alt çentik bandı
    // da boydan boya keser; yoksa bandın ucu çentiğin içinde leke kalıyor.
    final through = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(stubX - notch, faceSize.height - notch, stubX + notch,
            faceSize.height + band + notch),
        Radius.circular(notch),
      ));
    canvas.drawPath(
      Path.combine(
          PathOperation.difference, shape.shift(Offset(0, band)), through),
      Paint()..color = depth,
    );
    canvas.drawPath(shape, Paint()..color = face);
    canvas.save();
    canvas.clipPath(shape);
    canvas.drawRect(
      Rect.fromLTWH(stubX, 0, size.width - stubX, faceSize.height),
      Paint()..color = stubFace,
    );
    canvas.restore();
    if (perforation) {
      final dash = Paint()
        ..color = _bg
        ..strokeWidth = 3.5 * s
        ..strokeCap = StrokeCap.round;
      for (var y = notch + 10 * s;
          y < faceSize.height - notch - 8 * s;
          y += 16 * s) {
        canvas.drawLine(Offset(stubX, y), Offset(stubX, y + 7 * s), dash);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CouponPainter old) => true;
}

/// Görev kuponu: solda görev ve adımları, sağdaki koçanda ödül. Ödül
/// hazırsa koçan açılır, bilet parlar ve "AL" yazar; alınınca koçan
/// koparılmış gibi yerini onay alır.
class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.s, required this.q});

  final double s;
  final _Quest q;

  static const _stub = 148.0;

  @override
  Widget build(BuildContext context) {
    final claimed = q.claimed;
    final height = (claimed ? 104 : 158) * s;
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _CouponPainter(
          s: s,
          stubWidth: _stub,
          face: claimed ? _base : _tile,
          depth: claimed ? _bg : _base,
          stubFace: claimed ? _base : (q.ready ? _raised : _tile),
          perforation: !claimed,
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: 8 * s),
          child: Row(
            children: [
              SizedBox(width: 24 * s),
              Opacity(
                opacity: claimed ? 0.55 : 1,
                child:
                    QuestIcon(questKey: q.key, size: (claimed ? 44 : 62) * s),
              ),
              SizedBox(width: 20 * s),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.title,
                        maxLines: 2,
                        style: _text(claimed ? 23 * s : 25 * s,
                            color: claimed
                                ? const Color(0xFF8FA0B5)
                                : Colors.white)),
                    if (!claimed) ...[
                      SizedBox(height: 14 * s),
                      _Pips(s: s, done: q.progress, total: q.target),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 12 * s),
              SizedBox(
                width: _stub * s,
                child: Center(
                  child: claimed
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('+${q.reward}',
                                style: _text(21 * s,
                                    color: _muted,
                                    weight: AppTypography.number)),
                            SizedBox(width: 10 * s),
                            QuestCheckMark(size: 40 * s),
                          ],
                        )
                      : q.ready
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ReadyTicket(s: s, count: q.reward, width: 70),
                                SizedBox(height: 10 * s),
                                Text('AL',
                                    style: _text(22 * s,
                                        color: _gold,
                                        weight: AppTypography.number,
                                        spacing: 1.4 * s)),
                              ],
                            )
                          : TicketWithCount(
                              scale: s,
                              count: q.reward,
                              ticketWidth: 62,
                              badgeSize: 30,
                              dim: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ödülü alınmış kupon: koçanı koparılmış gibi. Sağ kenar tırtıklı (yırtma
/// çizgisinin yarısı), koçanın yeri boş; ödül ve onay gövdenin içinde.
class _TornPainter extends CustomPainter {
  _TornPainter({required this.s});

  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final band = 8 * s;
    final faceSize = Size(size.width, size.height - band);
    final r = 28 * s;
    final bite = 7 * s;
    Path shape(double dy) {
      final body = Path()
        ..addRRect(RRect.fromRectAndCorners(
          Rect.fromLTWH(0, dy, faceSize.width, faceSize.height),
          topLeft: Radius.circular(r),
          bottomLeft: Radius.circular(r),
        ));
      final bites = Path();
      for (var y = bite; y < faceSize.height; y += bite * 2.6) {
        bites.addOval(Rect.fromCircle(
            center: Offset(faceSize.width, dy + y), radius: bite));
      }
      return Path.combine(PathOperation.difference, body, bites);
    }

    canvas.drawPath(shape(band), Paint()..color = _bg.withValues(alpha: 1));
    canvas.drawPath(shape(band), Paint()..color = const Color(0xFF030D1D));
    canvas.drawPath(shape(0), Paint()..color = _base);
  }

  @override
  bool shouldRepaint(covariant _TornPainter old) => false;
}

class _TornCoupon extends StatelessWidget {
  const _TornCoupon({required this.s, required this.q});

  final double s;
  final _Quest q;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: (_CouponCard._stub - 30) * s),
      child: SizedBox(
        height: 104 * s,
        child: CustomPaint(
          painter: _TornPainter(s: s),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8 * s, right: 26 * s),
            child: Row(
              children: [
                SizedBox(width: 24 * s),
                Opacity(
                  opacity: 0.55,
                  child: QuestIcon(questKey: q.key, size: 44 * s),
                ),
                SizedBox(width: 20 * s),
                Expanded(
                  child: Text(q.title,
                      maxLines: 1, style: _text(23 * s, color: _muted)),
                ),
                Text('+${q.reward}',
                    style: _text(21 * s,
                        color: _muted, weight: AppTypography.number)),
                SizedBox(width: 10 * s),
                QuestCheckMark(size: 40 * s),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> _couponBottom(double s) => [
      SizedBox(height: 16 * s),
      for (final q in const [_ready, ..._going]) ...[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 34 * s),
          child: _CouponCard(s: s, q: q),
        ),
        SizedBox(height: 18 * s),
      ],
      SizedBox(height: 16 * s),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 40 * s),
        child: _SectionLabel('TAMAMLANANLAR', s: s),
      ),
      SizedBox(height: 14 * s),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 34 * s),
        child: _TornCoupon(s: s, q: _claimed),
      ),
    ];

/// Kutusuz satır: büyük simge, başlık ve adımlar, sağda ödül. Satırlar
/// arasında yalnız ince ayraç; ağır kutu yok.
class _LightRow extends StatelessWidget {
  const _LightRow({required this.s, required this.q});

  final double s;
  final _Quest q;

  @override
  Widget build(BuildContext context) {
    final claimed = q.claimed;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: (claimed ? 16 : 24) * s),
      child: Row(
        children: [
          Container(
            width: (claimed ? 64 : 96) * s,
            height: (claimed ? 64 : 96) * s,
            decoration: BoxDecoration(
              color: q.ready ? _raised : _tile,
              borderRadius: BorderRadius.circular((claimed ? 20 : 28) * s),
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: claimed ? 0.55 : 1,
              child: QuestIcon(questKey: q.key, size: (claimed ? 40 : 62) * s),
            ),
          ),
          SizedBox(width: 24 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.title,
                    maxLines: 2,
                    style: _text(claimed ? 23 * s : 26 * s,
                        color: claimed ? _muted : Colors.white)),
                if (!claimed) ...[
                  SizedBox(height: 14 * s),
                  _Pips(s: s, done: q.progress, total: q.target, slot: _tile),
                ],
              ],
            ),
          ),
          SizedBox(width: 14 * s),
          SizedBox(
            width: 96 * s,
            child: Center(
              child: claimed
                  ? QuestCheckMark(size: 42 * s)
                  : q.ready
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ReadyTicket(s: s, count: q.reward, width: 70),
                            SizedBox(height: 8 * s),
                            Text('AL',
                                style: _text(22 * s,
                                    color: _gold,
                                    weight: AppTypography.number,
                                    spacing: 1.4 * s)),
                          ],
                        )
                      : TicketWithCount(
                          scale: s,
                          count: q.reward,
                          ticketWidth: 62,
                          badgeSize: 30,
                          dim: true),
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _lightBottom(double s) {
  Widget divider() => Padding(
        padding: EdgeInsets.only(left: (34 + 96 + 24) * s, right: 34 * s),
        child: Container(height: 2 * s, color: _panel),
      );
  const active = [_ready, ..._going];
  return [
    SizedBox(height: 4 * s),
    for (final (i, q) in active.indexed) ...[
      if (i > 0) divider(),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 34 * s),
        child: _LightRow(s: s, q: q),
      ),
    ],
    SizedBox(height: 22 * s),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 40 * s),
      child: _SectionLabel('TAMAMLANANLAR', s: s),
    ),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 34 * s),
      child: _LightRow(s: s, q: _claimed),
    ),
  ];
}

// ---------------------------------------------------------------------------
// Sayfa
// ---------------------------------------------------------------------------

Widget _phoneFrame(String label, Widget Function(double s) body,
    {double scroll = 0}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(label,
            style:
                _text(17, color: Colors.white, weight: AppTypography.number)),
      ),
      SizedBox.fromSize(
        size: _phone,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: MediaQuery(
            data: const MediaQueryData(
              size: _phone,
              devicePixelRatio: 2,
              padding: EdgeInsets.only(top: 62, bottom: 34),
            ),
            child: Material(
              color: _bg,
              child: Column(
                children: [
                  const SizedBox(height: 62),
                  Expanded(
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        maxHeight: double.infinity,
                        child: Transform.translate(
                          offset: Offset(0, -scroll),
                          child: body(_phone.width / 670),
                        ),
                      ),
                    ),
                  ),
                  AppBottomNavBar(selectedIndex: 1, onTap: (_) {}),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

void main() {
  setUpAll(loadPreviewFonts);

  testWidgets('Taslak: Görevler için üç yerleşim', (tester) async {
    const gap = 36.0;
    final width = _phone.width * 3 + gap * 2 + 48;
    final height = _phone.height + 70;
    tester.view.physicalSize = Size(width * 2, height * 2);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.black,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: const ValueKey('quests-concepts'),
            child: SizedBox(
              width: width * 2,
              height: height * 2,
              child: Transform.scale(
                scale: 2,
                alignment: Alignment.topLeft,
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: width,
                  maxWidth: width,
                  minHeight: height,
                  maxHeight: height,
                  child: Container(
                    color: Colors.black,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _phoneFrame('A · Sahneli hedef kartı + tek liste',
                            (s) => _ConceptA(s: s)),
                        const SizedBox(width: gap),
                        _phoneFrame('B · Izgara (6. kare bonus)',
                            (s) => _ConceptB(s: s)),
                        const SizedBox(width: gap),
                        _phoneFrame('C · Odak (öne çıkan görev)',
                            (s) => _ConceptC(s: s)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    await precachePreviewImages(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byKey(const ValueKey('quests-concepts')),
      matchesGoldenFile('goldens/quests_concepts.png'),
    );
  }, skip: !_capture);
  testWidgets('Taslak A: alt kısım için iki seçenek', (tester) async {
    const gap = 36.0;
    final width = _phone.width * 3 + gap * 2 + 48;
    final height = _phone.height + 70;
    tester.view.physicalSize = Size(width * 2, height * 2);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.black,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: const ValueKey('quests-concept-a'),
            child: SizedBox(
              width: width * 2,
              height: height * 2,
              child: Transform.scale(
                scale: 2,
                alignment: Alignment.topLeft,
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: width,
                  maxWidth: width,
                  minHeight: height,
                  maxHeight: height,
                  child: Container(
                    color: Colors.black,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _phoneFrame('A1 · Görev kuponları',
                            (s) => _ConceptA(s: s, bottom: _couponBottom)),
                        const SizedBox(width: gap),
                        _phoneFrame('A1 · aşağı kaydırınca',
                            (s) => _ConceptA(s: s, bottom: _couponBottom),
                            scroll: 300),
                        const SizedBox(width: gap),
                        _phoneFrame('A2 · Hafif liste',
                            (s) => _ConceptA(s: s, bottom: _lightBottom)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    await precachePreviewImages(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byKey(const ValueKey('quests-concept-a')),
      matchesGoldenFile('goldens/quests_concept_a.png'),
    );
  }, skip: !_capture);
}
