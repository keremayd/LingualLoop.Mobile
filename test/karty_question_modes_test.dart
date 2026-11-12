import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/Karty.dart';
import 'package:lingualloop/models/responses/GetKartyByScoreResponse.dart';
import 'package:lingualloop/models/responses/UpdateScoreResponse.dart';
import 'package:lingualloop/providers/KartyProvider.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/GameFeedbackService.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:lingualloop/services/PronunciationService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/screens/karty_quiz_screen.dart';
import 'package:lingualloop/ui/widgets/karty_question_card.dart';
import 'package:lingualloop/ui/widgets/karty_question_parts.dart';
import 'package:lingualloop/ui/widgets/karty_time_bar.dart';
import 'package:provider/provider.dart';

import 'helpers/preview_fonts.dart';
import 'helpers/silent_game_feedback.dart';

const _image = 'assets/icons/mascot_hello.png';

Karty _card(KartyCardMode mode, {String word = 'Apfel'}) => Karty(
      kartyId: 1,
      kartyUrl: _image,
      correctText: word,
      article: 'der',
      audioUrl: 'https://ses/apfel.mp3',
      mode: mode,
      options: const [
        KartyOption(kartyId: 2, imagePath: _image),
        KartyOption(kartyId: 1, imagePath: _image),
        KartyOption(kartyId: 3, imagePath: _image),
        KartyOption(kartyId: 4, imagePath: _image),
      ],
    );

class _Cards extends KartyProvider {
  _Cards(this.card);
  final Karty card;
  @override
  bool get isLoaded => true;
  @override
  List<Karty> get cards => [card];
  @override
  void reset() {}
  @override
  Future<bool> loadKarty(BuildContext context,
          {bool reviewMode = false}) async =>
      true;
}

class _Audio extends Fake implements PronunciationService {
  _Audio(bool muted) : isMuted = ValueNotifier(muted);
  @override
  final ValueNotifier<bool> isMuted;
  @override
  final isSpeaking = ValueNotifier(false);
  final played = <String?>[];
  final playedSlowly = <String?>[];
  @override
  Future<void> play(String? url) async => played.add(url);
  @override
  Future<void> playSlowly(String? url) async => playedSlowly.add(url);
  @override
  Future<void> stop() async {}
  @override
  Future<void> setMuted(bool value) async => isMuted.value = value;
}

class _Scores extends UserService {
  _Scores() : super(Dio());
  final points = <int>[];
  final _never = Completer<ApiResponse<UpdateScoreResponse>>();
  @override
  Future<ApiResponse<UpdateScoreResponse>> updateScoreById(int point,
      {int? kartyId, bool boostActive = false}) {
    points.add(point);
    return _never.future;
  }
}

Future<(_Scores, _Audio)> _mount(
  WidgetTester tester,
  Karty card, {
  bool muted = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final scores = _Scores();
  final audio = _Audio(muted);
  await tester.pumpWidget(MultiProvider(providers: [
    ChangeNotifierProvider<KartyProvider>(create: (_) => _Cards(card)),
    ChangeNotifierProvider(create: (_) => ScoreWithLivesProvider()),
    ChangeNotifierProvider(create: (_) => ProfileLearningStatsProvider()),
    Provider(create: (_) => KartyService(Dio())),
    Provider<UserService>.value(value: scores),
    Provider<PronunciationService>.value(value: audio),
    Provider<GameFeedbackService>.value(value: SilentGameFeedback()),
  ], child: const MaterialApp(home: KartyQuizScreen())));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return (scores, audio);
}

/// Bekleyen geri bildirim sayaçları bitsin, ağaç temiz kapansın.
Future<void> _finish(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpWidget(const SizedBox.shrink());
}

int _seconds(WidgetTester tester) =>
    tester.widget<KartyTimeBar>(find.byType(KartyTimeBar)).duration.value;

Future<void> _tapLetters(WidgetTester tester, Karty card, String word) async {
  final tiles = kartyShuffledLetters(card.correctText, card.kartyId);
  final used = <int>{};
  for (final letter in word.split('')) {
    final index = List.generate(tiles.length, (i) => i)
        .firstWhere((i) => tiles[i] == letter && !used.contains(i));
    used.add(index);
    await tester.tap(find.byKey(ValueKey('karty-letter-$index')));
    await tester.pump();
  }
}

void main() {
  setUpAll(loadPreviewFonts);

  group('Görsel seçme', () {
    testWidgets('kelime yazılı, doğru görsel +1', (tester) async {
      final (scores, _) = await _mount(tester, _card(KartyCardMode.pickImage));
      expect(find.text('Görseli bul'), findsOneWidget);
      expect(find.text('Apfel'), findsOneWidget);
      expect(find.byType(KartyImageOptions), findsOneWidget);
      expect(_seconds(tester), 10);

      await tester.tap(find.byKey(const ValueKey('karty-option-1')));
      await tester.pump();
      expect(scores.points, [1]);

      // Cevap kilitlidir: ikinci dokunuş yeni bir cevap değildir.
      await tester.tap(find.byKey(const ValueKey('karty-option-2')),
          warnIfMissed: false);
      await tester.pump();
      expect(scores.points, [1]);
      await _finish(tester);
    });

    testWidgets('yanlış görsel −1', (tester) async {
      final (scores, _) = await _mount(tester, _card(KartyCardMode.pickImage));
      await tester.tap(find.byKey(const ValueKey('karty-option-3')));
      await tester.pump();
      expect(scores.points, [-1]);
      await _finish(tester);
    });
  });

  group('Artikel', () {
    testWidgets('cevaptan önce artikel görünmez, doğrusu +1', (tester) async {
      final (scores, _) =
          await _mount(tester, _card(KartyCardMode.pickArticle));
      expect(find.text('Artikeli seç'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
      expect(find.text('der'), findsOneWidget); // yalnız düğme

      await tester.tap(find.text('der'));
      await tester.pump();
      expect(scores.points, [1]);
      expect(find.text('?'), findsNothing);
      expect(find.text('der'), findsNWidgets(2)); // düğme + başlık
      await _finish(tester);
    });

    testWidgets('yanlış artikel −1, doğrusu açılır', (tester) async {
      final (scores, _) =
          await _mount(tester, _card(KartyCardMode.pickArticle));
      await tester.tap(find.text('die'));
      await tester.pump();
      expect(scores.points, [-1]);
      expect(find.text('der'), findsNWidgets(2));
      await _finish(tester);
    });
  });

  group('Harf dizme', () {
    testWidgets('kelime yazılmaz, sırayla dizilince +1', (tester) async {
      final card = _card(KartyCardMode.arrangeLetters);
      final (scores, _) = await _mount(tester, card);
      expect(find.text('Harfleri diz'), findsOneWidget);
      expect(find.text('Apfel'), findsNothing);
      expect(_seconds(tester), 15);

      await _tapLetters(tester, card, 'Apfe');
      expect(scores.points, isEmpty);
      await _tapLetters(tester, card, 'l');
      expect(scores.points, [1]);
      await _finish(tester);
    });

    testWidgets('yanlış harf yuvasına dokunulunca geri alınır', (tester) async {
      final card = _card(KartyCardMode.arrangeLetters);
      final (scores, _) = await _mount(tester, card);
      await _tapLetters(tester, card, 'p');
      expect(scores.points, isEmpty);
      expect(find.byType(KartyLetterTiles), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('karty-slot-0')));
      await tester.pump();
      expect(find.byKey(const ValueKey('karty-slot-0')), findsNothing);

      await _tapLetters(tester, card, 'Apfel');
      expect(scores.points, [1]);
      await _finish(tester);
    });

    testWidgets('ortadan geri alınan harfin yerine sağdakiler kayar',
        (tester) async {
      final card = _card(KartyCardMode.arrangeLetters);
      final (scores, _) = await _mount(tester, card);
      await _tapLetters(tester, card, 'Afp');
      await tester.tap(find.byKey(const ValueKey('karty-slot-1')));
      await tester.pump();
      // "A p" kaldı; sıradaki harfler kelimeyi tamamlar.
      final tiles = kartyShuffledLetters('Apfel', 1);
      for (final letter in ['f', 'e', 'l']) {
        await tester
            .tap(find.byKey(ValueKey('karty-letter-${tiles.indexOf(letter)}')));
        await tester.pump();
      }
      expect(scores.points, [1]);
      await _finish(tester);
    });

    testWidgets('yuvalar yanlış dolunca −1, doğru yazılış görünür',
        (tester) async {
      final card = _card(KartyCardMode.arrangeLetters);
      final (scores, _) = await _mount(tester, card);
      await _tapLetters(tester, card, 'Apfle');
      expect(scores.points, [-1]);
      expect(find.byType(KartyLetterTiles), findsNothing);
      expect(find.byKey(const ValueKey('karty-slot-0')), findsNothing);
      for (final letter in ['A', 'p', 'f', 'e', 'l']) {
        expect(find.text(letter), findsOneWidget);
      }
      await _finish(tester);
    });

    testWidgets('aynı harften ikisi birbirinin yerine geçer', (tester) async {
      final card = _card(KartyCardMode.arrangeLetters, word: 'Anna');
      final (scores, _) = await _mount(tester, card);
      final tiles = kartyShuffledLetters('Anna', 1);
      final ordered = [
        tiles.indexOf('A'),
        tiles.lastIndexOf('n'),
        tiles.indexOf('n'),
        tiles.indexOf('a'),
      ];
      for (final index in ordered) {
        await tester.tap(find.byKey(ValueKey('karty-letter-$index')));
        await tester.pump();
      }
      expect(scores.points, [1]);
      await _finish(tester);
    });

    test('karışım harfleri korur, kelimeyi vermez, kartta sabittir', () {
      for (final word in ['Ei', 'Apfel', 'Staubsauger']) {
        for (var seed = 0; seed < 50; seed++) {
          final tiles = kartyShuffledLetters(word, seed);
          expect(tiles.join(), isNot(word));
          expect([...tiles]..sort(), [...word.split('')]..sort());
          expect(kartyShuffledLetters(word, seed), tiles);
        }
      }
    });
  });

  group('Dinleme', () {
    testWidgets('kelime duyulur, cevaptan önce yazılmaz', (tester) async {
      final (scores, audio) = await _mount(tester, _card(KartyCardMode.listen));
      expect(find.text('Duyduğunu bul'), findsOneWidget);
      expect(find.text('Apfel'), findsNothing);
      expect(find.byType(KartyQuestionCard), findsOneWidget);
      expect(audio.played, ['https://ses/apfel.mp3']);
      expect(_seconds(tester), 12);

      await tester.tap(find.byKey(const ValueKey('karty-listen')));
      await tester.pump();
      expect(audio.played, hasLength(2));

      // Salyangoz aynı kelimeyi yavaş çalar.
      await tester.tap(find.byKey(const ValueKey('karty-listen-slow')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(audio.playedSlowly, ['https://ses/apfel.mp3']);
      expect(audio.played, hasLength(2));

      await tester.tap(find.byKey(const ValueKey('karty-option-1')));
      await tester.pump();
      expect(scores.points, [1]);
      expect(find.text('Apfel'), findsOneWidget);
      await _finish(tester);
    });

    testWidgets('ses kapalıysa harf dizmeye düşer', (tester) async {
      await _mount(tester, _card(KartyCardMode.listen), muted: true);
      expect(find.text('Harfleri diz'), findsOneWidget);
      expect(find.byType(KartyLetterTiles), findsOneWidget);
      expect(find.byKey(const ValueKey('karty-listen')), findsNothing);
      await _finish(tester);
    });
  });

  testWidgets('süre dolunca soru kartında yeniden denenir, cevap sızmaz',
      (tester) async {
    final (scores, _) = await _mount(tester, _card(KartyCardMode.listen));
    await tester.pump(const Duration(seconds: 13));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Süre doldu'), findsOneWidget);
    expect(find.text('Apfel'), findsNothing);
    // Düğmeler yerinde kalır ama basılmaz.
    expect(find.byType(KartyImageOptions), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('karty-option-1')),
        warnIfMissed: false);
    await tester.pump();
    expect(scores.points, isEmpty);

    await tester.tap(find.text('TEKRAR DENE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Süre doldu'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('karty-option-1')));
    await tester.pump();
    expect(scores.points, [1]);
    await _finish(tester);
  });
}
