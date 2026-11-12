import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/Karty.dart';
import 'package:lingualloop/models/responses/GetKartyByScoreResponse.dart';
import 'package:lingualloop/models/responses/LeagueProgressResponse.dart';
import 'package:lingualloop/models/responses/ScoreWithLivesResponse.dart';
import 'package:lingualloop/models/responses/UpdateScoreResponse.dart';
import 'package:lingualloop/providers/KartyProvider.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/GameFeedbackService.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:lingualloop/services/PronunciationService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/screens/karty_quiz_screen.dart';
import 'package:lingualloop/ui/widgets/karty_question_parts.dart';
import 'package:provider/provider.dart';

import 'helpers/preview_fonts.dart';
import 'helpers/silent_game_feedback.dart';

/// Karty'nin kelime pekiştikçe zorlaşan dört sorusu, gerçek oyun ekranıyla.
///
///   flutter test --update-goldens test/karty_question_types_preview_test.dart
String _path(String word) => '${Directory.current.path}'
    '/test/fixtures/karty_words/$word.png';

/// `FileImage` gerçek dosyayı `ImmutableBuffer.fromFilePath` ile okuyor ve bu
/// çağrı test ortamında dönmüyor; sarmalayıcı onu `readAsBytes` yoluna sokar.
class _FixtureFile implements File {
  _FixtureFile(this.path, this._bytes);

  @override
  final String path;
  final Uint8List _bytes;

  @override
  Future<int> length() async => _bytes.length;
  @override
  Future<Uint8List> readAsBytes() async => _bytes;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FixtureFiles extends IOOverrides {
  @override
  File createFile(String path) {
    final file = super.createFile(path);
    return path.contains('karty_words/')
        ? _FixtureFile(path, file.readAsBytesSync())
        : file;
  }
}

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
  @override
  final isMuted = ValueNotifier(false);
  @override
  final isSpeaking = ValueNotifier(false);
  @override
  Future<void> play(String? url) async {}
  @override
  Future<void> stop() async {}
}

class _Scores extends UserService {
  _Scores() : super(Dio());
  final _never = Completer<ApiResponse<UpdateScoreResponse>>();
  @override
  Future<ApiResponse<UpdateScoreResponse>> updateScoreById(int point,
          {int? kartyId, bool boostActive = false}) =>
      _never.future;
}

Karty _card(
  int id,
  KartyCardMode mode,
  String image,
  String word,
  String article, {
  List<String> options = const [],
}) =>
    Karty(
      kartyId: id,
      kartyUrl: _path(image),
      correctText: word,
      article: article,
      audioUrl: 'ses',
      mode: mode,
      options: [
        for (final (i, option) in options.indexed)
          KartyOption(
            // Doğru seçenek kartın kendisi; diğerleri aynı ekranda benzersiz.
            kartyId: option == image ? id : id * 10 + i,
            imagePath: _path(option),
          ),
      ],
    );

void main() {
  setUpAll(() async {
    await loadPreviewFonts();
    IOOverrides.global = _FixtureFiles();
  });
  tearDownAll(() => IOOverrides.global = null);

  final score = ScoreWithLivesProvider()
    ..setScoreWithLives(ScoreWithLivesResponse(
      score: 0,
      experience: 0,
      lives: 12,
      maxLives: 15,
      league: LeagueProgressResponse(
        leagueKey: 'yildiz',
        leagueName: 'Yıldız',
        rank: 3,
        points: 24,
        minPoints: 20,
        maxPoints: 30,
        pointsToNextLeague: 6,
        progressRatio: .4,
        seasonKey: 1,
        seasonStartsAtUtc: DateTime.utc(2026, 11, 1),
        seasonEndsAtUtc: DateTime.utc(2026, 12, 1),
        leaderboardRank: 5,
        leagueUserCount: 30,
      ),
    ));

  Widget phone(Karty card) => ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: SizedBox(
          width: 430,
          height: 932,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(430, 932),
              padding: EdgeInsets.only(top: 59, bottom: 34),
              devicePixelRatio: 2,
            ),
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider<KartyProvider>(
                    create: (_) => _Cards(card)),
                ChangeNotifierProvider<ScoreWithLivesProvider>.value(
                    value: score),
                ChangeNotifierProvider(
                    create: (_) => ProfileLearningStatsProvider()),
                Provider(create: (_) => KartyService(Dio())),
                Provider<UserService>(create: (_) => _Scores()),
                Provider<PronunciationService>(create: (_) => _Audio()),
                Provider<GameFeedbackService>.value(
                    value: SilentGameFeedback()),
              ],
              child: const KartyQuizScreen(),
            ),
          ),
        ),
      );

  Widget board(List<(String, String, Karty)> frames) => Material(
        color: const Color(0xFF020A18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 34, 40, 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, (title, subtitle, card)) in frames.indexed) ...[
                if (i > 0) const SizedBox(width: 40),
                Column(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: AppTypography.heading,
                        fontFamily: AppTypography.displayFamily,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8FA0B5),
                        fontSize: 16,
                        fontWeight: AppTypography.body,
                        fontFamily: AppTypography.family,
                      ),
                    ),
                    const SizedBox(height: 22),
                    phone(card),
                  ],
                ),
              ],
            ],
          ),
        ),
      );

  Future<void> mount(
    WidgetTester tester,
    List<(String, String, Karty)> frames,
  ) async {
    const size = Size(40 + 4 * 430 + 3 * 40 + 40, 34 + 90 + 932 + 40);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: board(frames),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final context = tester.element(find.byType(Row).first);
    await tester.runAsync(() async {
      final files = {
        for (final (_, _, card) in frames) ...[
          card.kartyUrl,
          for (final option in card.options) option.imagePath,
        ],
      };
      for (final file in files) {
        // ignore: use_build_context_synchronously
        await precacheImage(FileImage(File(file)), context);
      }
    });
    await precachePreviewImages(tester);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    expect(tester.takeException(), isNull);
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  }

  const options = ['apfel', 'koffer', 'lampe', 'katze'];

  Future<void> tapLetters(WidgetTester tester, Karty card, String word) async {
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

  testWidgets('dört soru tipi', (tester) async {
    final letters =
        _card(3, KartyCardMode.arrangeLetters, 'apfel', 'Apfel', 'der');
    await mount(tester, [
      (
        '1 · Anlam',
        'Yeni kelimenin ilk sınaması',
        _card(1, KartyCardMode.pickImage, 'apfel', 'Apfel', 'der',
            options: options),
      ),
      (
        '2 · Artikel',
        'Kelime bir kez bilindikten sonra',
        _card(2, KartyCardMode.pickArticle, 'apfel', 'Apfel', 'der'),
      ),
      ('3 · Yazım', 'Kelime pekişirken', letters),
      (
        '4 · Dinleme',
        'İyi bilinen kelimeler',
        _card(4, KartyCardMode.listen, 'lampe', 'Lampe', 'die',
            options: options),
      ),
    ]);
    await tapLetters(tester, letters, 'Ap');
    await tester.pump(const Duration(milliseconds: 200));
    await shoot(tester, 'karty_question_types');
  });

  testWidgets('cevap sonrası', (tester) async {
    final letters = _card(7, KartyCardMode.arrangeLetters, 'staubsauger',
        'Staubsauger', 'der');
    await mount(tester, [
      (
        'Yanlış seçim',
        'Doğrusu gösterilir',
        _card(5, KartyCardMode.pickImage, 'apfel', 'Apfel', 'der',
            options: options),
      ),
      (
        'Doğru artikel',
        'Boşluk artikelle dolar',
        _card(6, KartyCardMode.pickArticle, 'apfel', 'Apfel', 'der'),
      ),
      ('Yazım tamam', 'En uzun kelimede harfler küçülür', letters),
      (
        'Dinleme sonrası',
        'Kelime ancak cevaptan sonra yazılır',
        _card(8, KartyCardMode.listen, 'lampe', 'Lampe', 'die',
            options: options),
      ),
    ]);

    await tester.tap(find.byKey(const ValueKey('karty-option-52')));
    await tester.pump();
    await tester.tap(find.descendant(
        of: find.byType(KartyArticleChoices), matching: find.text('der')));
    await tester.pump();
    await tapLetters(tester, letters, 'Staubsauger');
    await tester.tap(find.byKey(const ValueKey('karty-option-8')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    await shoot(tester, 'karty_question_types_result');
  });
}
