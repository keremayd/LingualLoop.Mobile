import 'dart:io';
import 'helpers/preview_fonts.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lingualloop/models/Karty.dart';
import 'package:lingualloop/models/responses/ScoreWithLivesResponse.dart';
import 'package:lingualloop/models/responses/LeagueProgressResponse.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/ui/widgets/SwipableCard.dart';
import 'package:lingualloop/ui/widgets/karty_top_bar.dart';
import 'package:lingualloop/ui/widgets/karty_league_score.dart';
import 'package:lingualloop/ui/widgets/karty_play_surface.dart';
import 'package:lingualloop/ui/widgets/karty_answer_actions.dart';
import 'package:lingualloop/ui/widgets/karty_pause_overlay.dart';
import 'package:lingualloop/ui/widgets/karty_sound_button.dart';
import 'package:lingualloop/ui/widgets/karty_time_bar.dart';
import 'package:lingualloop/ui/widgets/karty_boost_activation_effect.dart';

// Tam ekran görseli için --dart-define=KARTY_PREVIEW_IMAGE=<yerel kart PNG>
// verilirse gerçek içerikle golden üretir; normal koşuda yerleşimi sınar.
const _imagePath = String.fromEnvironment('KARTY_PREVIEW_IMAGE',
    defaultValue: 'assets/icons/mascot_hello.png');
const _capture = bool.fromEnvironment('KARTY_CAPTURE');
const _framesPath = String.fromEnvironment('KARTY_MOTION_FRAMES');

void main() {
  setUpAll(loadPreviewFonts);

  for (final width in [320.0, 402.0, 430.0]) {
    testWidgets('Tek üst satırda lig puanı ve altındaki çarpan: $width',
        (tester) async {
      tester.view.physicalSize = Size(width, width * 2.17);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final points in [107, 99999]) {
        await tester.pumpWidget(_Screen(points: points));
        await tester.pump(const Duration(milliseconds: 600));
        final bar = tester.getRect(find.byType(KartyTimeBar));
        await tester.pumpWidget(_Screen(points: points, active: true));
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.getRect(find.byType(KartyTimeBar)), bar);
        expect(find.text('$points'), findsOneWidget);
        final multiplier = tester.getRect(find.text('×3'));
        final number = tester.getRect(find.text('$points'));
        final screen = tester.state<_ScreenState>(find.byType(_Screen));
        expect(tester.getRect(find.byKey(screen.target)), number);
        expect(multiplier.center.dx, closeTo(number.center.dx, .01));
        expect(multiplier.top, greaterThan(number.bottom));
        expect(bar.width, greaterThan(64));
        final score = tester.getRect(find.byType(KartyLeagueScore));
        expect(score.left, greaterThan(bar.right));
        expect(
            find.descendant(
                of: find.byType(SwipableCard), matching: find.text('×3')),
            findsNothing);
        final sound = tester.getRect(find.byType(KartySoundButton));
        expect(sound.width, greaterThanOrEqualTo(44));
        expect(score.right, lessThan(sound.left));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const _Screen(active: true, timeout: true));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('×3'), findsNothing);
      expect(find.text('TEKRAR DENE'), findsOneWidget);
      expect(find.text('DOĞRU'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Kısa ekranda deste, cevaplar ve test alanı çakışmaz',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const _Screen());
    await tester.pump(const Duration(milliseconds: 300));
    final card = tester.getRect(find.byType(SwipableCard));
    final actions = tester.getRect(find.byType(KartyAnswerActions));
    final debug = tester.getRect(find.byKey(const ValueKey('debug-answer')));
    expect(card.bottom, lessThan(actions.top));
    expect(actions.bottom, lessThan(debug.top));
    expect(debug.bottom, lessThanOrEqualTo(568 - 34));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Boost iptal edildiğinde bekleyen işlem tamamlanır',
      (tester) async {
    await tester.pumpWidget(const _Screen());
    final screen = tester.state<_ScreenState>(find.byType(_Screen));
    final completion = screen.activationKey.currentState!.play();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    screen.activationKey.currentState!.stop();
    expect(await completion, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('İlk kareden önce iptal edilen boost başlamaz', (tester) async {
    final key = GlobalKey<KartyBoostActivationEffectState>();
    await tester.pumpWidget(
        MaterialApp(home: KartyBoostActivationEffect(key: key, scale: .5)));
    final completion = key.currentState!.play();
    key.currentState!.stop();
    await tester.pump();
    expect(await completion, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Hareket azaltma açıkken kısa geri bildirim tamamlanır',
      (tester) async {
    final key = GlobalKey<KartyBoostActivationEffectState>();
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: KartyBoostActivationEffect(key: key, scale: .5))));
    var completed = false;
    final completion =
        key.currentState!.play().then((value) => completed = value);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));
    expect(completed, isFalse);
    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<KartyBoostActivationPainter>();
    expect(painters.single.reducedMotion, isTrue);
    await tester.pump(const Duration(milliseconds: 160));
    await completion;
    expect(completed, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  if (_framesPath.isNotEmpty) {
    testWidgets('Gerçek boost hareketi: 60 fps kare kaydı', (tester) async {
      tester.view.physicalSize = const Size(804, 1748);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(SizedBox).first);
        await precacheImage(FileImage(File(_imagePath)), context);
        await precacheImage(
            const ResizeImage(AssetImage('assets/icons/boost-bolt.png'),
                height: 270),
            context);
        await Directory(_framesPath).create(recursive: true);
      });
      final captureKey = GlobalKey();
      await tester
          .pumpWidget(RepaintBoundary(key: captureKey, child: const _Screen()));
      await tester.pump(const Duration(milliseconds: 4800));
      await tester.pump(const Duration(milliseconds: 120));
      Future<void>? activation;
      for (var frame = 0; frame < 156; frame++) {
        if (frame == 18) {
          activation =
              tester.state<_ScreenState>(find.byType(_Screen)).fireBoost();
          await tester.pump();
          await tester.pump();
        }
        await tester.pump(const Duration(microseconds: 16667));
        final boundary = captureKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
                  '$_framesPath/frame-${frame.toString().padLeft(3, '0')}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        expect(tester.takeException(), isNull);
      }
      await activation;
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  if (_capture) {
    for (final stage in [
      'hazir',
      'birlesme',
      'aktif',
      'sure-doldu',
      'ses-kapali',
      'tanisma',
      'duraklatma'
    ]) {
      testWidgets('Gerçek ekran: $stage', (tester) async {
        tester.view.physicalSize = const Size(1206, 2622);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        await tester.runAsync(() async {
          final context = tester.element(find.byType(SizedBox).first);
          await precacheImage(FileImage(File(_imagePath)), context)
              .timeout(const Duration(seconds: 10));
          await precacheImage(
                  const ResizeImage(AssetImage('assets/icons/boost-bolt.png'),
                      height: 270),
                  context)
              .timeout(const Duration(seconds: 10));
        });
        await tester.pumpWidget(_Screen(
            active: stage == 'aktif' || stage == 'sure-doldu',
            soundMuted: stage == 'ses-kapali',
            introducing: stage == 'tanisma',
            menuOpen: stage == 'duraklatma',
            timeout: stage == 'sure-doldu'));
        await tester.pump(Duration(
            milliseconds: stage == 'sure-doldu'
                ? 17000
                : stage == 'aktif'
                    ? 6400
                    : 4800));
        await tester.pump(const Duration(milliseconds: 120));
        Future<void>? activation;
        if (stage == 'birlesme') {
          activation =
              tester.state<_ScreenState>(find.byType(_Screen)).fireBoost();
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 650));
        }
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('goldens/karty_boost_full_$stage.png'));
        expect(tester.takeException(), isNull);
        if (activation != null) {
          await tester.pump(const Duration(milliseconds: 1200));
          await activation;
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}

class _Screen extends StatefulWidget {
  const _Screen(
      {this.active = false,
      this.timeout = false,
      this.introducing = false,
      this.menuOpen = false,
      this.points = 107,
      this.soundMuted = false});
  final bool active;
  final bool timeout;
  final bool introducing;
  final bool menuOpen;
  final int points;
  final bool soundMuted;
  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  final progress = ValueNotifier(.65);
  final duration = ValueNotifier(12);
  final reset = ValueNotifier(0);
  final paused = ValueNotifier(false);
  final finished = ValueNotifier(false);
  final correct = ValueNotifier(false);
  final wrong = ValueNotifier(false);
  final target = GlobalKey();
  final topSource = GlobalKey();
  final bottomSource = GlobalKey();
  final activationKey = GlobalKey<KartyBoostActivationEffectState>();
  bool firing = false;
  bool activated = false;

  bool get active => widget.active || activated;

  Future<void> fireBoost() async {
    setState(() => firing = true);
    paused.value = true;
    final completed = await activationKey.currentState!.play();
    if (!completed) return;
    paused.value = false;
    if (mounted) {
      setState(() {
        firing = false;
        activated = true;
      });
    }
  }

  final provider = ScoreWithLivesProvider();

  void sync() {
    finished.value = widget.timeout;
    provider.setScoreWithLives(ScoreWithLivesResponse(
        score: 107,
        experience: 107,
        level: 3,
        levelProgress: 7,
        levelBandSize: 50,
        lives: 15,
        maxLives: 15,
        league: LeagueProgressResponse(
            leagueKey: 'yildiz',
            leagueName: 'Yıldız',
            rank: 3,
            points: widget.points,
            minPoints: 0,
            maxPoints: 500,
            pointsToNextLeague: 393,
            progressRatio: .2,
            seasonKey: 1,
            seasonStartsAtUtc: DateTime.utc(2026, 9, 1),
            seasonEndsAtUtc: DateTime.utc(2026, 10, 1),
            leaderboardRank: 5,
            leagueUserCount: 30)));
  }

  @override
  void initState() {
    super.initState();
    sync();
  }

  @override
  void didUpdateWidget(_Screen old) {
    super.didUpdateWidget(old);
    sync();
  }

  @override
  void dispose() {
    for (final notifier in [
      progress,
      duration,
      reset,
      paused,
      finished,
      correct,
      wrong
    ]) {
      notifier.dispose();
    }
    provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: const Color(0xFF041227),
            body: Builder(builder: (context) {
              final s = MediaQuery.sizeOf(context).width / 750;
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    padding: const EdgeInsets.only(top: 62, bottom: 34)),
                child: KartyPlaySurface(
                  isIntroducing: widget.introducing,
                  header: KartyTopBar(
                    scale: s,
                    duration: duration,
                    timeBarResetNotifier: reset,
                    isFinished: finished,
                    isPaused: paused,
                    isBoostActive: active,
                    isIntroducing: widget.introducing,
                    reviewMode: false,
                    reviewTotalStack: 0,
                    reviewCompletedStack: 0,
                    leaguePointsAnchorKey: target,
                    muted: widget.soundMuted,
                    pauseMenuOpen: widget.menuOpen,
                    onToggleSound: () {},
                    onPause: () {},
                  ),
                  cardBuilder: (layout) => SwipableCard(
                    layout: layout,
                    showInlineRestartAction: false,
                    karty: Karty(
                        kartyId: 7,
                        kartyUrl: _imagePath,
                        questionText: 'Koffer',
                        correctText: 'Koffer',
                        article: 'der',
                        isCorrect: true),
                    position: Offset.zero,
                    rotation: 0,
                    showRestartState: widget.timeout,
                    isAdvancingDeck: false,
                    boostEnabled: !widget.introducing,
                    boostCharge: active ? 0 : 5,
                    boostChargeGoal: 5,
                    isBoostReady: !active && !firing,
                    isBoostActive: active && !widget.timeout,
                    isBoostActivating: firing,
                    topLeftBoostAnchorKey: topSource,
                    bottomRightBoostAnchorKey: bottomSource,
                    boostProgress: progress,
                    onRestart: () {},
                    onBoostTap: () {},
                    onPanUpdate: (_) {},
                    onPanEnd: (_) {},
                    isTrueAnswerBlurActive: correct,
                    isFalseAnswerBlurActive: wrong,
                  ),
                  actions: KartyAnswerActions(
                    scale: s,
                    isIntroducing: widget.introducing,
                    isTimedOut: widget.timeout,
                    onWrong: () {},
                    onCorrect: () {},
                    onContinue: () {},
                  ),
                  debugAction: widget.introducing || widget.timeout
                      ? null
                      : TextButton(
                          key: const ValueKey('debug-answer'),
                          onPressed: () {},
                          style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF8FA0B5)),
                          child: KartyDebugAnswerLabel(scale: s),
                        ),
                  overlays: [
                    KartyBoostActivationEffect(
                        key: activationKey,
                        scale: s,
                        topLeftSourceKey: topSource,
                        bottomRightSourceKey: bottomSource,
                        targetKey: target),
                    if (widget.menuOpen)
                      KartyPauseOverlay(
                          scale: s,
                          level: 3,
                          streak: 5,
                          onResume: () {},
                          onExit: () {}),
                  ],
                ),
              );
            }),
          ),
        ),
      );
}
