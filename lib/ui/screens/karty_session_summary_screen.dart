import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/models/karty_session_summary.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/Buttons/secondary_action_button.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'package:lingualloop/ui/widgets/karty_unit_header.dart';
import 'package:lingualloop/ui/widgets/karty_unit_marks.dart';
import 'package:lingualloop/ui/widgets/league_badge_mark.dart';
import 'package:lingualloop/ui/widgets/no_top_border_painter.dart';
import 'package:lingualloop/ui/widgets/points_star_icon.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

/// Özetten çıkış: patikaya dönmek ya da aynı oturumda pratiğe devam etmek.
enum KartySummaryChoice { path, practice }

/// Bir oyun (bir deste) bittiğinde Karty'nin "tamam" anı.
///
/// Sonsuz akışta "bitirdim" diye bir an yoktu (`docs/DUOLINGO_ARASTIRMA.md`
/// §4). Bu ekran oturumu **öğrenilenle** kapatır, puanla değil: ana öğe
/// destenin kelimeleri ve ünitenin %80 hedefine doğru ilerleyen çubuktur. Puan tek sayıdır, çünkü Karty'de XP ile lig puanı aynı
/// miktarda artar. Kelimeler patika penceresinde yarının silüetleriydi;
/// burada aynı karolarda renge dönerek açılır.
///
/// Giriş ~2.2 sn; ekrana dokunmak son hâle atlatır. DEVAM ET patikaya
/// döner, PRATİK YAP aynı oturumu yeni bilet istemeden on soruluk bir
/// pratik turuyla sürdürür; tur bitince "Pratik tamam!" ve BİR TUR DAHA.
class KartySessionSummaryScreen extends StatefulWidget {
  const KartySessionSummaryScreen({super.key, required this.summary});

  final KartySessionSummary summary;

  @override
  State<KartySessionSummaryScreen> createState() =>
      _KartySessionSummaryScreenState();
}

class _KartySessionSummaryScreenState extends State<KartySessionSummaryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Hareket azaltılmışsa ekran doğrudan son hâliyle açılır.
    if (MediaQuery.disableAnimationsOf(context)) _entrance.value = 1;
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _close(KartySummaryChoice choice) => Navigator.of(context).pop(choice);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_entrance.value < 1) _entrance.value = 1;
          },
          child: AnimatedBuilder(
            animation: _entrance,
            builder: (context, _) => KartySessionSummaryScene(
              summary: widget.summary,
              progress: _entrance.value,
              onContinue: () => _close(KartySummaryChoice.path),
              onPractice: () => _close(KartySummaryChoice.practice),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ekranın kendisi; zamanı dışarıdan alır ki önizleme her kareyi çizebilsin.
///
/// Zaman çizelgesi (giriş 0–1):
///
/// | Aralık | Ne olur |
/// |---|---|
/// | 0.00–0.19 | Başlık ve alt satır yükselir |
/// | 0.10–0.22 | Kelime karoları silüet olarak belirir |
/// | 0.18–0.66 | Karolar sırayla renge döner, adları altında açılır |
/// | 0.50–0.84 | Ünite kartı gelir, çubuk eski değerden yenisine dolar |
/// | 0.66–0.90 | Sayılar sayarak gelir, lig satırı belirir |
/// | 0.82–0.96 | Düğmeler yükselir; 0.9'dan sonra basılabilir |
class KartySessionSummaryScene extends StatelessWidget {
  const KartySessionSummaryScene({
    super.key,
    required this.summary,
    required this.progress,
    this.onContinue,
    this.onPractice,
  });

  final KartySessionSummary summary;
  final double progress;
  final VoidCallback? onContinue;
  final VoidCallback? onPractice;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final t = progress;
    final ready = t >= 0.9;

    return ColoredBox(
      color: _C.bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final s = constraints.maxWidth / 750;
          final fill = _phase(t, 0.60, 0.84, Curves.easeOutCubic);
          final count = _phase(t, 0.70, 0.88, Curves.easeOutCubic);
          final league = summary.league;

          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: KartyStarfieldPainter(scale: s)),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  40 * s,
                  padding.top + 28 * s,
                  40 * s,
                  padding.bottom + 32 * s,
                ),
                child: Column(
                  children: [
                    Expanded(
                      // Kısa ekranda içerik kayar; düğmeler hep altta kalır.
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _Rise(
                              progress: _phase(t, 0, 0.14, Curves.easeOutCubic),
                              distance: 30 * s,
                              // Uzun ünite numarasında da tek satır kalır.
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  summary.practice
                                      ? 'Pratik tamam!'
                                      : summary.deck != null
                                          ? 'Deste ${summary.deck} tamam!'
                                          : 'Tekrar tamam!',
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 80 * s,
                                    fontWeight: AppTypography.heading,
                                    fontFamily: AppTypography.displayFamily,
                                    height: 1.05,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10 * s),
                            _Rise(
                              progress:
                                  _phase(t, 0.05, 0.19, Curves.easeOutCubic),
                              distance: 30 * s,
                              child: Text(
                                _subtitle(summary),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: TextStyle(
                                  color: _C.muted,
                                  fontSize: 29 * s,
                                  fontWeight: AppTypography.body,
                                  fontFamily: AppTypography.family,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            SizedBox(height: 28 * s),
                            _WordGrid(
                              words: summary.words,
                              scale: s,
                              progress: t,
                            ),
                            SizedBox(height: 28 * s),
                            _Rise(
                              progress:
                                  _phase(t, 0.50, 0.62, Curves.easeOutCubic),
                              distance: 40 * s,
                              child: SizedBox(
                                height: KartyUnitHeader.height * s,
                                child: IgnorePointer(
                                  child: KartyUnitHeader(
                                    unit: summary.unit,
                                    scale: s,
                                    onTap: () {},
                                    consolidated: lerpDouble(
                                      summary.consolidatedBefore.toDouble(),
                                      summary.unit.consolidatedCount.toDouble(),
                                      fill,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 26 * s),
                            _Rise(
                              progress:
                                  _phase(t, 0.66, 0.78, Curves.easeOutCubic),
                              distance: 40 * s,
                              child: _Stats(
                                summary: summary,
                                scale: s,
                                count: count,
                              ),
                            ),
                            if (league != null) ...[
                              SizedBox(height: 22 * s),
                              _Rise(
                                progress:
                                    _phase(t, 0.78, 0.90, Curves.easeOutCubic),
                                distance: 24 * s,
                                child: _LeagueLine(note: league, scale: s),
                              ),
                            ],
                            SizedBox(height: 28 * s),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20 * s),
                    _Rise(
                      progress: _phase(t, 0.82, 0.94, Curves.easeOutCubic),
                      distance: 40 * s,
                      child: DepthPressableButton(
                        key: const Key('karty-summary-continue'),
                        text: 'DEVAM ET',
                        width: 670 * s,
                        height: 112 * s,
                        radius: 26 * s,
                        shadowOffset: 12 * s,
                        backgroundColor: _C.green,
                        shadowColor: _C.greenDepth,
                        fontSize: 32 * s,
                        enabled: ready && onContinue != null,
                        onPressed: onContinue ?? () {},
                      ),
                    ),
                    SizedBox(height: 18 * s),
                    _Rise(
                      progress: _phase(t, 0.85, 0.96, Curves.easeOutCubic),
                      distance: 40 * s,
                      child: IgnorePointer(
                        ignoring: !ready,
                        child: SecondaryActionButton(
                          key: const Key('karty-summary-practice'),
                          text:
                              summary.practice ? 'BİR TUR DAHA' : 'PRATİK YAP',
                          scale: s,
                          width: 670 * s,
                          onPressed: onPractice ?? () {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// "8 kelimeyle tanıştın, 5 kelime pekişti." Yeni kelimeler aynı gün
  /// pekişmez (kutu ancak ertesi gün ilerler); ilk günlerde çubuk
  /// kıpırdamadığında neden kıpırdamadığı burada söylenir.
  static String _subtitle(KartySessionSummary summary) {
    // Pratik kutuyu ilerletmiyor: on dakika pratik yapıp ünitenin neden
    // ilerlemediğini sormak zorunda kalınmasın (kullanıcı, 12 Kas 2026).
    if (summary.practice) {
      return '${summary.words.length} kelimeyle pratik yaptın.\n'
          'Kelimeler tekrar vakti gelince pekişir.';
    }
    final learned = summary.deck != null
        ? '${summary.newCount} kelimeyle tanıştın'
        : '${summary.reviewCount} kelimeyi tekrar ettin';
    final consolidated = summary.consolidatedToday;
    if (consolidated > 0) return '$learned, $consolidated kelime pekişti.';
    if (summary.deck != null) {
      return '$learned.\nYarın tekrar edince pekişecekler.';
    }
    return '$learned.';
  }
}

abstract final class _C {
  static const bg = Color(0xFF041227);
  static const panel = Color(0xFF0B2143);
  static const tile = Color(0xFF0C2244);
  static const raised = Color(0xFF163258);
  static const accent = Color(0xFF1CB1F5);
  static const green = Color(0xFF93D334);
  static const greenDepth = Color(0xFF628C22);
  static const muted = Color(0xFF8FA0B5);
}

double _phase(double t, double begin, double end,
        [Curve curve = Curves.linear]) =>
    curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

/// Bugünün kelimeleri: patika penceresindeki yarının silüet karolarıyla
/// aynı karo; silüet sırayla renge döner, adı artikel rengiyle altında açılır.
/// En çok sekiz karo; fazlası son karoda "+N".
class _WordGrid extends StatelessWidget {
  const _WordGrid({
    required this.words,
    required this.scale,
    required this.progress,
  });

  final List<KartyWord> words;
  final double scale;
  final double progress;

  static const _columns = 4;
  static const _maxTiles = 8;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final gap = 18 * s;
    final size = (670 * s - gap * (_columns - 1)) / _columns;
    final overflow = words.length > _maxTiles;
    final shown = words.take(overflow ? _maxTiles - 1 : _maxTiles).toList();
    final appear = _phase(progress, 0.10, 0.22);

    double reveal(int i) => _phase(
          progress,
          0.18 + i * 0.045,
          0.34 + i * 0.045,
          Curves.easeOutCubic,
        );

    return Wrap(
      spacing: gap,
      runSpacing: 20 * s,
      alignment: WrapAlignment.center,
      children: [
        for (final (i, word) in shown.indexed)
          _WordTile(
            word: word,
            size: size,
            scale: s,
            appear: appear,
            reveal: reveal(i),
          ),
        if (overflow)
          _MoreTile(
            count: words.length - shown.length,
            size: size,
            scale: s,
            appear: reveal(shown.length),
          ),
      ],
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({
    required this.word,
    required this.size,
    required this.scale,
    required this.appear,
    required this.reveal,
  });

  final KartyWord word;
  final double size;
  final double scale;
  final double appear;
  final double reveal;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final inset = 18 * s;
    final inner = size - inset * 2;
    final bump = 1 + 0.14 * math.sin(math.pi * reveal);

    return SizedBox(
      width: size,
      child: Column(
        children: [
          Opacity(
            opacity: appear,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: _C.tile,
                borderRadius: BorderRadius.circular(24 * s),
                boxShadow: [
                  BoxShadow(color: _C.panel, offset: Offset(0, 6 * s)),
                ],
              ),
              padding: EdgeInsets.all(inset),
              child: Transform.scale(
                scale: bump,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    KartySilhouette(image: word.image, color: _C.raised),
                    ClipOval(
                      clipper: KartyCircleReveal(
                        center: Offset(inner / 2, inner / 2),
                        radius: reveal * inner * 0.75,
                      ),
                      child: Image(image: word.image, fit: BoxFit.contain),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 12 * s),
          Opacity(
            opacity: reveal,
            child: SizedBox(
              width: size,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${word.article} ',
                        style: TextStyle(
                          color: _articleColor(word.article),
                          fontWeight: AppTypography.label,
                        ),
                      ),
                      TextSpan(
                        text: word.word,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: AppTypography.word,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 24 * s,
                    fontFamily: AppTypography.family,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Artikel renkleri her yerde aynı (§2.0): der mavi, die kırmızı, das turuncu.
  static Color _articleColor(String article) => switch (article.toLowerCase()) {
        'der' => _C.accent,
        'die' => const Color(0xFFF52A2A),
        _ => const Color(0xFFFF9300),
      };
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.count,
    required this.size,
    required this.scale,
    required this.appear,
  });

  final int count;
  final double size;
  final double scale;
  final double appear;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Opacity(
      opacity: appear,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _C.tile,
          borderRadius: BorderRadius.circular(24 * s),
          boxShadow: [BoxShadow(color: _C.panel, offset: Offset(0, 6 * s))],
        ),
        child: Text(
          '+$count',
          style: TextStyle(
            color: _C.muted,
            fontSize: 40 * s,
            fontWeight: AppTypography.number,
            fontFamily: AppTypography.family,
          ),
        ),
      ),
    );
  }
}

/// Profildeki "TOPLAM" satırının biçimi: üstsüz konturlu statik kart, her
/// hücrede simge, sayı ve küçük etiket.
class _Stats extends StatelessWidget {
  const _Stats({
    required this.summary,
    required this.scale,
    required this.count,
  });

  final KartySessionSummary summary;
  final double scale;

  /// Sayıların sıfırdan gerçek değerlerine sayma ilerlemesi (0–1).
  final double count;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    int counted(int value) => (value * count).round();

    return Container(
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(AppShapeStyle.cardRadius(24 * s)),
        boxShadow: [
          BoxShadow(
            color: _C.panel,
            offset: Offset(0, AppShapeStyle.cardDepth(6 * s)),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20 * s, horizontal: 10 * s),
            child: Row(
              children: [
                _cell(s, PointsStarIcon(size: 48 * s),
                    '+${counted(summary.points)}', 'PUAN'),
                _cell(s, QuestCheckMark(size: 46 * s),
                    '${counted(summary.correct)}/${summary.answered}', 'DOĞRU'),
                _cell(s, QuestIcon(questKey: 'review_two', size: 48 * s),
                    '${counted(summary.revenge)}', 'RÖVANŞ'),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: NoTopBorderPainter(
                  color: _C.panel,
                  strokeWidth: AppShapeStyle.outline(2 * s),
                  radius: AppShapeStyle.cardRadius(24 * s),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(double s, Widget icon, String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 48 * s, child: Center(child: icon)),
          SizedBox(height: 12 * s),
          Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: Colors.white,
              fontFamily: AppTypography.family,
              fontSize: 34 * s,
              fontWeight: AppTypography.number,
              height: 1,
            ),
          ),
          SizedBox(height: 6 * s),
          Text(
            label,
            style: TextStyle(
              color: _C.muted,
              fontFamily: AppTypography.family,
              fontSize: 18 * s,
              fontWeight: AppTypography.caption,
              letterSpacing: 0.5 * s,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lig ekranındaki cümlenin aynısı, sıradaki ligin kilitli rozetiyle.
class _LeagueLine extends StatelessWidget {
  const _LeagueLine({required this.note, required this.scale});

  final KartyLeagueNote note;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final message = TextStyle(
      color: _C.muted,
      fontFamily: AppTypography.family,
      fontSize: 26 * s,
      fontWeight: AppTypography.body,
      height: 1.2,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LeagueBadgeMark(
          leagueKey: note.nextLeagueKey,
          size: 52 * s,
          locked: true,
        ),
        SizedBox(width: 14 * s),
        Text.rich(
          TextSpan(
            style: message,
            children: [
              TextSpan(text: '${note.nextLeagueName} Ligi\'ne '),
              TextSpan(
                text: '${note.pointsLeft} puan',
                style: message.copyWith(
                  color: _C.accent,
                  fontWeight: AppTypography.number,
                ),
              ),
              const TextSpan(text: ' kaldı'),
            ],
          ),
          maxLines: 1,
        ),
      ],
    );
  }
}

class _Rise extends StatelessWidget {
  const _Rise({
    required this.progress,
    required this.distance,
    required this.child,
  });

  final double progress;
  final double distance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - progress) * distance),
        child: child,
      ),
    );
  }
}
