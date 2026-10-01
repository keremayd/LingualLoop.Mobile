import 'helpers/preview_fonts.dart';
import 'package:lingualloop/ui/widgets/SwipableCard.dart';
import 'package:lingualloop/ui/widgets/karty_answer_actions.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lingualloop/models/Karty.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/responses/UpdateScoreResponse.dart';
import 'package:lingualloop/models/responses/GetKartyByScoreResponse.dart';
import 'package:lingualloop/providers/KartyProvider.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/services/PronunciationService.dart';
import 'package:lingualloop/ui/screens/karty_quiz_screen.dart';
import 'package:lingualloop/ui/widgets/karty_pause_overlay.dart';
import 'package:lingualloop/ui/widgets/karty_sound_button.dart';
import 'package:lingualloop/ui/widgets/karty_top_bar.dart';
import 'package:lingualloop/ui/widgets/karty_time_bar.dart';
import 'package:lingualloop/ui/widgets/karty_control_glyphs.dart';
import 'package:lingualloop/ui/widgets/speaker_mark.dart';
import 'package:lingualloop/ui/widgets/Buttons/secondary_action_button.dart';

class _Cards extends KartyProvider {
  _Cards(this.mode);
  final KartyCardMode mode;
  @override
  bool get isLoaded => true;
  @override
  List<Karty> get cards => [
        Karty(
          kartyId: 1,
          kartyUrl: 'assets/icons/mascot_hello.png',
          questionText: 'Koffer',
          correctText: 'Koffer',
          article: 'der',
          isCorrect: true,
          mode: mode,
        )
      ];
  @override
  void reset() {}
  @override
  Future<bool> loadKarty(BuildContext context,
          {bool reviewMode = false}) async =>
      true;
}

class _Audio extends Fake implements PronunciationService {
  @override
  final isMuted = ValueNotifier(false);
  @override
  final isSpeaking = ValueNotifier(false);
  int stops = 0;
  @override
  Future<void> play(String? url) async {}
  @override
  Future<void> stop() async {
    stops++;
    isSpeaking.value = false;
  }

  @override
  Future<void> setMuted(bool value) async {
    isMuted.value = value;
    if (value) isSpeaking.value = false;
  }
}

class _PendingUserService extends UserService {
  _PendingUserService() : super(Dio());
  final pending = Completer<ApiResponse<UpdateScoreResponse>>();
  @override
  Future<ApiResponse<UpdateScoreResponse>> updateScoreById(int point,
          {int? kartyId, bool boostActive = false}) =>
      pending.future;
}

Future<_Audio> _mountQuiz(WidgetTester tester,
    {KartyCardMode mode = KartyCardMode.spelling}) async {
  tester.view.physicalSize = const Size(320, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final audio = _Audio();
  addTearDown(audio.isMuted.dispose);
  addTearDown(audio.isSpeaking.dispose);
  await tester.pumpWidget(MultiProvider(providers: [
    ChangeNotifierProvider<KartyProvider>(create: (_) => _Cards(mode)),
    ChangeNotifierProvider(create: (_) => ScoreWithLivesProvider()),
    ChangeNotifierProvider(create: (_) => ProfileLearningStatsProvider()),
    Provider(create: (_) => KartyService(Dio())),
    Provider<UserService>(create: (_) => _PendingUserService()),
    Provider<PronunciationService>.value(value: audio),
  ], child: const MaterialApp(home: KartyQuizScreen())));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return audio;
}

void main() {
  setUpAll(loadPreviewFonts);
  testWidgets('Gerçek oyunda duraklatma süreyi tutar, ses menüde erişilebilir',
      (tester) async {
    final audio = await _mountQuiz(tester);
    expect(find.byType(KartyTopBar), findsOneWidget);
    expect(find.text('Seviye'), findsNothing);
    final topGlyph = find.descendant(
        of: find.byType(KartyTopBar), matching: find.byType(KartyControlMark));
    expect(tester.widget<KartyControlMark>(topGlyph).glyph,
        KartyControlGlyph.pause);
    audio.isSpeaking.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.widget<SpeakerMark>(find.byType(SpeakerMark)).wave,
        greaterThan(0));
    await tester.pump(const Duration(milliseconds: 2300));
    final timerState = tester.state(find.byType(KartyTimeBar));
    final cardRect = tester.getRect(find.byType(SwipableCard));
    final cardSize =
        tester.widget<SwipableCard>(find.byType(SwipableCard)).layout!.size;
    final actionsRect = tester.getRect(find.byType(KartyAnswerActions));
    await tester.tap(find.bySemanticsLabel('Oyunu duraklat'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(KartyPauseOverlay), findsOneWidget);
    expect(tester.widget<KartyControlMark>(topGlyph).glyph,
        KartyControlGlyph.play);
    expect(find.byType(SecondaryActionButton), findsOneWidget);
    expect(tester.widget<SpeakerMark>(find.byType(SpeakerMark)).wave, 0);
    expect(find.text('Seviye'), findsOneWidget);
    expect(audio.stops, greaterThan(0));
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Süre doldu'), findsNothing);
    await tester.tap(find.byType(KartySoundButton));
    await tester.pump();
    expect(audio.isMuted.value, isTrue);
    await tester.tap(find.bySemanticsLabel('Oyuna devam et'));
    await tester.pump();
    expect(find.byType(KartyPauseOverlay), findsNothing);
    expect(tester.widget<KartyControlMark>(topGlyph).glyph,
        KartyControlGlyph.pause);
    expect(tester.state(find.byType(KartyTimeBar)), same(timerState));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Süre doldu'), findsOneWidget);
    expect(find.text('TEKRAR DENE'), findsOneWidget);
    expect(tester.getRect(find.byType(SwipableCard)), cardRect);
    expect(tester.widget<SwipableCard>(find.byType(SwipableCard)).layout!.size,
        cardSize);
    expect(tester.getRect(find.byType(KartyAnswerActions)), actionsRect);
    expect(find.text('DOĞRU'), findsNothing);
    await tester.tap(find.text('TEKRAR DENE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('DOĞRU'), findsOneWidget);
    expect(tester.getRect(find.byType(SwipableCard)), cardRect);
    expect(tester.getRect(find.byType(KartyAnswerActions)), actionsRect);
    expect(find.text('Süre doldu'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Cevap gönderilirken süre doldu ve yeniden başlatma gösterilmez',
      (tester) async {
    await _mountQuiz(tester);
    await tester.tap(find.text('DOĞRU'));
    for (var i = 0; i < 32; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('Süre doldu'), findsNothing);
    expect(find.text('TEKRAR DENE'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Tanışmada yalnız Anladım vardır ve menüye erişilebilir',
      (tester) async {
    await _mountQuiz(tester, mode: KartyCardMode.introduce);
    expect(find.text('ANLADIM'), findsOneWidget);
    expect(find.text('Yeni kelime'), findsOneWidget);
    expect(find.byType(KartyTimeBar), findsNothing);
    expect(find.text('DOĞRU'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Oyunu duraklat'));
    await tester.pump();
    expect(find.text('Oyundan çık'), findsOneWidget);
    await tester.tap(find.text('DEVAM ET'));
    await tester.pump();
    expect(find.byType(KartyPauseOverlay), findsNothing);
    expect(find.text('ANLADIM'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
