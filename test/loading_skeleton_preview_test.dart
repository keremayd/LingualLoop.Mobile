import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/ArticlePractice.dart';
import 'package:lingualloop/models/User.dart';
import 'package:lingualloop/models/responses/DailyActivityResponse.dart';
import 'package:lingualloop/models/responses/DailyQuestsResponse.dart';
import 'package:lingualloop/models/responses/KartyPathResponse.dart';
import 'package:lingualloop/models/responses/ProfileLearningStatsResponse.dart';
import 'package:lingualloop/models/responses/ScoreWithLivesResponse.dart';
import 'package:lingualloop/models/responses/word_collection_response.dart';
import 'package:lingualloop/providers/ArticlePracticeProvider.dart';
import 'package:lingualloop/providers/KartyPathProvider.dart';
import 'package:lingualloop/providers/KartyProvider.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/providers/QuestsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/providers/UserProvider.dart';
import 'package:lingualloop/services/ArticlePracticeService.dart';
import 'package:lingualloop/services/FileService.dart';
import 'package:lingualloop/services/GameFeedbackService.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:lingualloop/services/PronunciationService.dart';
import 'package:lingualloop/services/QuestService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/screens/article_practice_screen.dart';
import 'package:lingualloop/ui/screens/home_screen.dart';
import 'package:lingualloop/ui/screens/karty_quiz_screen.dart';
import 'package:lingualloop/ui/screens/profile_screen.dart';
import 'package:lingualloop/ui/screens/quests_screen.dart';
import 'package:lingualloop/ui/screens/word_collection_screen.dart';
import 'package:lingualloop/ui/widgets/app_bottom_nav_bar.dart';
import 'package:lingualloop/ui/widgets/loading_skeleton.dart';
import 'package:provider/provider.dart';

import 'helpers/preview_fonts.dart';
import 'helpers/silent_game_feedback.dart';

/// Ekranlar yüklenirken spinner yerine kendi düzenlerini, içleri boş
/// gösterir (iskelet). Sunucu hiç cevap vermiyor: her ekran yükleme
/// hâlinde kalır.
Future<T> _never<T>() => Completer<T>().future;

class _User extends Fake implements UserService {
  @override
  Future<ApiResponse<ScoreWithLivesResponse>> scoreWithLivesById(
    BuildContext context,
  ) =>
      _never();

  @override
  Future<ApiResponse<ProfileLearningStatsResponse>>
      profileLearningStatsById() => _never();

  @override
  Future<ApiResponse<DailyActivityResponse>?> recordDailyActivity() =>
      _never();

  @override
  Future<ApiResponse<WordCollectionResponse>> wordCollection({
    String category = 'all',
    int page = 1,
  }) =>
      _never();
}

class _Karty extends Fake implements KartyService {
  @override
  Future<ApiResponse<KartyPathResponse>> path() => _never();
}

class _Quests extends Fake implements QuestService {
  @override
  Future<ApiResponse<DailyQuestsResponse>> getDailyQuests() => _never();
}

class _Articles extends Fake implements ArticlePracticeService {
  @override
  Future<ApiResponse<ArticlePracticeLoadResult>> getNextTask({
    int? preferredKartyId,
  }) =>
      _never();
}

/// İlk kart hiç inmiyor.
class _Cards extends KartyProvider {
  @override
  Future<bool> loadKarty(BuildContext context, {bool reviewMode = false}) =>
      _never();
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

void main() {
  setUpAll(loadPreviewFonts);

  const phoneSize = Size(430, 932);

  Widget phone(Widget screen) => ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: SizedBox.fromSize(
          size: phoneSize,
          child: MediaQuery(
            data: const MediaQueryData(
              size: phoneSize,
              padding: EdgeInsets.only(top: 59, bottom: 34),
              devicePixelRatio: 2,
            ),
            child: MultiProvider(
              providers: [
                Provider<UserService>(create: (_) => _User()),
                Provider<KartyService>(create: (_) => _Karty()),
                Provider<LocalFileService>(create: (_) => LocalFileService()),
                Provider<PronunciationService>(create: (_) => _Audio()),
                Provider<GameFeedbackService>.value(
                    value: SilentGameFeedback()),
                ChangeNotifierProvider(create: (_) => ScoreWithLivesProvider()),
                ChangeNotifierProvider(
                    create: (_) => ProfileLearningStatsProvider()),
                ChangeNotifierProvider(
                    create: (c) => KartyPathProvider(c.read<KartyService>())),
                ChangeNotifierProvider<KartyProvider>(create: (_) => _Cards()),
                ChangeNotifierProvider(
                    create: (_) => ArticlePracticeProvider(_Articles())),
                ChangeNotifierProvider(
                    create: (_) => QuestsProvider(_Quests())),
                ChangeNotifierProvider(
                  create: (_) => UserProvider()
                    ..setUser(User(
                      userId: 'onizleme',
                      firstName: 'Deniz',
                      lastName: 'Yılmaz',
                      displayName: 'Deniz Yılmaz',
                      profilePhotoUrl: null,
                      userNickname: 'deniz',
                      userName: 'onizleme',
                      userRank: 3,
                    )),
                ),
              ],
              child: screen,
            ),
          ),
        ),
      );

  /// Sekme ekranları navbar'ın içinde durur (`NavbarWidget`).
  Widget tab(int index, Widget screen) => Scaffold(
        backgroundColor: const Color(0xFF041227),
        body: SafeArea(bottom: false, child: screen),
        bottomNavigationBar:
            AppBottomNavBar(selectedIndex: index, onTap: (_) {}),
      );

  final frames = <(String, Widget)>[
    ('Ana sayfa', tab(0, const HomeScreen())),
    ('Görevler', tab(1, const QuestsScreen())),
    ('Profil', tab(3, const ProfileScreen())),
    ('Karty', const KartyQuizScreen()),
    ('Artikel', const ArticlePracticeScreen()),
    ('Kelimelerim', const WordCollectionScreen()),
  ];

  testWidgets('yüklenirken ekranlar iskeletini gösterir', (tester) async {
    const gap = 40.0;
    final size = Size(
      gap + frames.length * (phoneSize.width + gap),
      34 + 60 + phoneSize.height + 40,
    );
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: const Color(0xFF020A18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(gap, 34, gap, 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, (title, screen)) in frames.indexed) ...[
                if (i > 0) const SizedBox(width: gap),
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
                    const SizedBox(height: 14),
                    phone(screen),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ));

    // Yarım saniye dolmadan iskelet görünmez: hızlı yüklemede ekran
    // hiçbir şey göstermeden dolsun.
    await tester.pump(const Duration(milliseconds: 300));
    final reveals = find.byType(SkeletonReveal);
    expect(reveals, findsNWidgets(frames.length));
    for (final element in reveals.evaluate()) {
      final fade = find.descendant(
        of: find.byWidget(element.widget),
        matching: find.byType(FadeTransition),
      );
      expect(tester.widget<FadeTransition>(fade.first).opacity.value, 0);
    }
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pump(const Duration(milliseconds: 600));
    await precachePreviewImages(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/loading_skeletons.png'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
