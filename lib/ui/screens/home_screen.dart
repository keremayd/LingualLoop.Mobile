import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_button_style.dart';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:lingualloop/Utils/AppNotifier.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/providers/QuestsProvider.dart';
import 'package:lingualloop/ui/widgets/NavbarWidget.dart';
import 'package:lingualloop/ui/widgets/home_top_bar.dart';
import 'package:lingualloop/ui/widgets/Popups/out_of_tickets_popup.dart';
import 'package:lingualloop/models/responses/DailyActivityResponse.dart';
import 'package:lingualloop/models/responses/ProfileLearningStatsResponse.dart';
import 'package:lingualloop/ui/widgets/Popups/streak_at_risk_popup.dart';
import 'package:lingualloop/ui/widgets/article_practice_home_card.dart';
import 'package:lingualloop/ui/widgets/home_streak_strip.dart';
import 'package:lingualloop/ui/widgets/pressable_layered_card.dart';
import 'package:lingualloop/ui/widgets/streak_day_card.dart';
import 'package:lingualloop/ui/widgets/streak_day_scenes.dart';
import 'package:lingualloop/ui/flows/league_promotion_flow.dart';
import 'package:provider/provider.dart';

import '../../providers/ScoreWithLivesProvider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenScreenState();
}

class _HomeScreenScreenState extends State<HomeScreen> {
  bool isLoading = true;
  bool _isShowingLeaguePromotion = false;
  bool _isHoldingLearningCardState = false;
  ProfileLearningStatsResponse? _heldLearningStats;

  /// Tasarım aracı (yalnız debug): seri kartını "bugün oynanmamış" hâline
  /// zorlar, sonra bırakır — böylece geçiş yeniden oynar.
  ///
  /// Gerek var çünkü gün bir kez oynandıktan sonra `playedToday` kalıcı olarak
  /// true; gerçek `false → true` anı günde yalnızca **bir kez** yaşanıyor ve
  /// tasarımı denemek için ertesi günü beklemek gerekiyor.
  bool _debugForceNotPlayed = false;

  /// Kilometre taşı hâlini denemek için seriyi geçici olarak 7 yapar.
  bool _debugMilestone = false;

  /// Güne özel sahne kartını denemek için sahneyi elle seçer. Gerekli çünkü
  /// gerçek veriyle görmek o gün sayısına ulaşmayı beklemek demek.
  String? _debugSceneKey = 'kendi_rekorun';

  Future<void> _replayStreakTransition({required bool milestone}) async {
    setState(() {
      _debugForceNotPlayed = true;
      _debugMilestone = milestone;
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _debugForceNotPlayed = false);
  }

  static const _backgroundColor = Color(0xFF041227);
  static const _textColor = Colors.white;
  static const _soloColor = Color(0xFF1CB1F5);
  static const _kartyColor = _soloColor;
  static const _kartyBaseColor = Color(0xFF1B84B5);
  static const _reviewColor = Color(0xFF0C2244);
  static const _reviewBaseColor = Color(0xFF07182F);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
    });
    await Future.wait([
      _getScoreWithLives(context),
      context.read<ProfileLearningStatsProvider>().load(context),
    ]);

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getScoreWithLives(BuildContext context) async {
    final userService = Provider.of<UserService>(context, listen: false);
    await userService.scoreWithLivesById(context);
  }

  /// Rövanş bilet harcamaz; yanlışları tekrar ederek oyuna dönüş yolu açar.
  /// Dönüşte hem bilet hem seri/profil istatistikleri tazelenir.
  Future<void> _openReview() async {
    _holdLearningCardState();
    try {
      await Navigator.pushNamed(context, '/kartyreview');
      if (!mounted) return;
      final userService = context.read<UserService>();
      await _refreshAfterGameplayReturn(userService);
    } finally {
      _releaseLearningCardState();
    }
  }

  /// Biletin yetmediği durumda sunucu E4116 döndürür ve oyun açılmaz.
  static const _noLivesErrorCode = 'E4116';

  Future<void> _updateLivesAndRouter(String routeUrl) async {
    final userService = Provider.of<UserService>(context, listen: false);

    var apiResponse = await userService.updateLivesById();
    if (apiResponse.errorCode == null) {
      if (!mounted) return;
      // **Beklenmesi şart.** `pushNamed` route kapanınca tamamlanan bir Future
      // döndürüyor; beklenmezse tazeleme oyun *açılırken* çalışır ve
      // kullanıcı oynayıp döndüğünde hiçbir şey güncellenmez. Seri kartının
      // geçişi de bu yüzden hiç tetiklenemiyordu.
      _holdLearningCardState();
      try {
        await Navigator.pushNamed(context, '/$routeUrl');
        if (!mounted) return;
        await _refreshAfterGameplayReturn(userService);
      } finally {
        _releaseLearningCardState();
      }
      if (!mounted) return;
      await _showPendingLeaguePromotion();
      return;
    }

    // Giriş reddedildi. Bilet duvarı düz bir uyarı mesajı değil, kendi
    // penceresini hak ediyor: kullanıcıya neden oynayamadığını, ne zaman
    // oynayabileceğini ve beklemek istemiyorsa ne olduğunu birlikte anlatır.
    if (apiResponse.errorCode != _noLivesErrorCode) {
      AppNotifier.showMessage('Oyun açılamadı. Daha sonra tekrar dene.');
      return;
    }

    // Geri sayımı doğru gösterebilmek için önce güncel bileti çek.
    if (!mounted) return;
    await userService.scoreWithLivesById(context);
    if (!mounted) return;

    // Popup, yolların yalnız adını değil o anki gerçek değerini gösterir:
    // bekleyen Rövanş yoksa yol pasifleşir; görev satırında bugün hâlâ
    // kazanılabilecek toplam bilet görünür.
    final questsProvider = context.read<QuestsProvider>();
    final profileStatsProvider = context.read<ProfileLearningStatsProvider>();
    await Future.wait([
      questsProvider.load(silent: questsProvider.data != null),
      profileStatsProvider.refreshFromService(userService),
    ]);
    if (!mounted) return;

    final questTickets = questsProvider.data?.quests
        .where((quest) => !quest.isClaimed)
        .fold<int>(0, (total, quest) => total + quest.rewardTickets);
    final reviewAvailable =
        (profileStatsProvider.stats?.reviewPendingCount ?? 0) > 0;

    final scoreProvider = context.read<ScoreWithLivesProvider>();
    await showOutOfTicketsPopup(
      context,
      nextTicketAt: scoreProvider.scoreWithLives?.nextTicketAt,
      onRefreshTickets: () async {
        if (!mounted) return false;
        final refreshed = await userService.scoreWithLivesById(context);
        return (refreshed.data?.lives ?? 0) > 0;
      },
      questTickets: questTickets,
      reviewAvailable: reviewAvailable,
      onGoToReview: () => unawaited(_openReview()),
      onGoToQuests: () =>
          NavbarWidget.requestedTab.value = NavbarWidget.questsTabIndex,
      onGoPremium: () {
        // Premium akışı henüz yok; niyet kaydı burada duruyor ki pencere
        // hazır olduğunda tek yerden bağlansın.
        AppNotifier.showMessage('Premium yakında!');
      },
    );
  }

  /// `Navigator.push` dönüş değeri, üst rota kapanış animasyonunu bitirmeden
  /// tamamlanabilir. Veriyi o anda uygularsak ana ekrandaki etkinleşme
  /// animasyonları hâlâ kapanan ekranın arkasında oynar. Ana rotanın yeniden
  /// tamamen görünür olmasını bekleyip güncellemeyi ondan sonra başlatırız.
  Future<void> _waitUntilHomeIsVisible() async {
    final animation = ModalRoute.of(context)?.secondaryAnimation;
    if (animation != null && animation.status != AnimationStatus.dismissed) {
      final completer = Completer<void>();

      void listener(AnimationStatus status) {
        if (status == AnimationStatus.dismissed && !completer.isCompleted) {
          completer.complete();
        }
      }

      animation.addStatusListener(listener);
      try {
        if (animation.status == AnimationStatus.dismissed &&
            !completer.isCompleted) {
          completer.complete();
        }
        await completer.future.timeout(const Duration(milliseconds: 800));
      } on TimeoutException {
        // Özel bir rota animasyonu durum bildirmese bile akışı kilitleme.
      } finally {
        animation.removeStatusListener(listener);
      }
    }

    if (mounted) await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _refreshAfterGameplayReturn(UserService userService) async {
    final statsProvider = context.read<ProfileLearningStatsProvider>();

    // İki istek de kapanış geçişi sürerken çalışır. Rövanş sonucu çoğunlukla
    // Karty içinde zaten hazırlanmıştır; bu durumda Future anında tamamlanır.
    final statsFuture = statsProvider.consumePrefetchOrFetch(userService);
    final scoreFuture = userService.scoreWithLivesById(context);

    await _waitUntilHomeIsVisible();
    if (!mounted) return;

    final stats = await statsFuture;
    if (!mounted) return;
    if (stats != null) statsProvider.applyFetchedStats(stats);

    // Kartın kilidini bilet/üst çubuk isteğini beklemeden aç. Böylece Home
    // görünür olur olmaz pasif → aktif geçişi başlar.
    _releaseLearningCardState();
    await scoreFuture;
  }

  /// Home kapalıyken provider değişse bile rövanş kartının görünür durumu
  /// sabit kalır. Kilit Home yeniden görünür olduktan ve güncel veri alındıktan
  /// sonra açılır; böylece pasif → aktif animasyonu doğru sahnede başlar.
  void _holdLearningCardState() {
    if (!mounted) return;
    setState(() {
      _heldLearningStats = context.read<ProfileLearningStatsProvider>().stats;
      _isHoldingLearningCardState = true;
    });
  }

  void _releaseLearningCardState() {
    if (!mounted || !_isHoldingLearningCardState) return;
    setState(() {
      _isHoldingLearningCardState = false;
      _heldLearningStats = null;
    });
  }

  Future<void> _showPendingLeaguePromotion() async {
    if (!mounted || _isShowingLeaguePromotion) return;
    final promotion = context
        .read<ScoreWithLivesProvider>()
        .scoreWithLives
        ?.league
        ?.pendingPromotion;
    if (promotion == null) return;

    _isShowingLeaguePromotion = true;
    try {
      await showPendingLeaguePromotion(context);
    } finally {
      _isShowingLeaguePromotion = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: _soloColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      floatingActionButton: kDebugMode
          ? Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _replayStreakTransition(milestone: false),
                onLongPress: () => _replayStreakTransition(milestone: true),
                // Çift dokunuş: sahne kartları arasında dolaşır (kapalı →
                // sırayla bütün sahneler → kapalı).
                onDoubleTap: () => setState(() {
                  const cycle = [
                    null,
                    'gun_100',
                    'ritmi_koru',
                    'harika_gidiyorsun',
                    'hedefe_dogru',
                    'madalyani_kazan',
                    'ruzgari_yakala',
                    'istikrar_guclendirir',
                    'kendi_rekorun',
                    'serin_korundu',
                    'bugun_geri_don',
                    'beyni_esnet',
                    'seni_ozledik',
                  ];
                  _debugSceneKey =
                      cycle[(cycle.indexOf(_debugSceneKey) + 1) % cycle.length];
                }),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: _soloColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'SERİ',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: AppTypography.family,
                      fontSize: 15,
                      fontWeight: AppTypography.label,
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / 750;

          // İçerik hedef cihazda tam bir ekran. `SingleChildScrollView` yine
          // de duruyor: sığdığı sürece kaydırma olmuyor, daha kısa bir ekranda
          // ise taşma hatası vermek yerine kayıyor.
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                40 * scale,
                40 * scale,
                40 * scale,
                28 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileSummaryCard(scale: scale),
                  SizedBox(height: 34 * scale),

                  // Seri şeridi üst şeritle Karty arasında. Bilet şeridi buradan
                  // kaldırıldı: üst çubuktaki sayıyı tekrarlıyordu ve tavandayken
                  // hiçbir eylem önermiyordu. Bu şerit ise ekranda bugüne ait tek
                  // öğe — üst çubuktaki "2" serinin bugün kurtarılıp
                  // kurtarılmadığını söylemiyor.
                  Consumer<ScoreWithLivesProvider>(
                    builder: (context, provider, child) {
                      final data = provider.scoreWithLives;
                      final week =
                          data?.streakWeek ?? const <DailyActivityDay>[];

                      // Veri gelmeden boş bir kutu göstermek kartı "bozuk"
                      // gösteriyor; şerit yoksa hiç çizilmiyor
                      // (ProfileStreakCard ile aynı davranış).
                      if (week.isEmpty) return const SizedBox.shrink();

                      final streak = _debugMilestone ? 7 : (data?.streak ?? 0);
                      final doneToday = _debugForceNotPlayed
                          ? false
                          : (data?.playedToday ?? false);

                      // Hangi sahnenin gösterileceğine kural listesi karar
                      // veriyor; ekran filtreleri bilmiyor. Çakışma olduğunda
                      // öncelik kazanıyor (bkz. `StreakScene`).
                      final scene = _debugSceneKey != null
                          ? StreakScene.byKey(_debugSceneKey!)
                          : StreakScene.resolve(
                              StreakSceneContext(
                                streak: streak,
                                playedToday: doneToday,
                                // `score-with-lives` `longestStreak`
                                // taşımıyor; alan eklenene kadar "hiç seri
                                // olmamış" varsayılıyor, yani seri sıfırken
                                // hep `beyni_esnet` çıkıyor (bugünkü
                                // davranışın aynısı).
                                hasEverStreaked: false,
                                // Koruma bayrağı zaten şeritte geliyor
                                // (`user_daily_activity.frozen`); ek alan
                                // gerekmiyor.
                                freezeUsedRecently: week.freezeUsedRecently,
                                // `longestStreak` yanıtta yok; alan eklenene
                                // kadar rekor kartı yalnız debug'dan görünür.
                                isPersonalRecord: false,
                              ),
                            );

                      if (scene != null) {
                        return StreakDayCard(
                          scale: scale,
                          days: streak,
                          message: scene.message,
                          sceneAsset: scene.asset,
                          sceneAspect: scene.aspect,
                          cardColor: scene.cardColor,
                          sceneEdgeColor: scene.sceneEdgeColor,
                          faceOpacity: scene.faceOpacity,
                          sceneZoom: scene.zoom,
                          sceneAnchorY: scene.anchorY,
                          sceneFadeEnd: scene.fadeEnd,
                          week: week.toStrip(),
                          playedToday: doneToday,
                          onTap: () => NavbarWidget.requestedTab.value =
                              NavbarWidget.profileTabIndex,
                        );
                      }

                      return HomeStreakStrip(
                        scale: scale,
                        streak: streak,
                        days: week.toStrip(),
                        doneToday: doneToday,
                        onTap: () => NavbarWidget.requestedTab.value =
                            NavbarWidget.profileTabIndex,
                      );
                    },
                  ),
                  SizedBox(height: 34 * scale),
                  _KartyFeatureCard(
                    scale: scale,
                    onTap: () async {
                      await _updateLivesAndRouter('kartyquiz');
                    },
                  ),
                  SizedBox(height: 34 * scale),
                  Consumer<ProfileLearningStatsProvider>(
                    builder: (context, provider, child) {
                      final stats = _isHoldingLearningCardState
                          ? _heldLearningStats
                          : provider.stats;
                      final articlePracticeAvailable = stats != null &&
                          stats.learnedWordCount >= 2 &&
                          stats.learnedArticleCount < stats.learnedWordCount;
                      final articlePendingCount = stats == null
                          ? null
                          : stats.learnedWordCount - stats.learnedArticleCount;
                      final articleDisabledMessage = stats == null
                          ? 'Kelimelerin kontrol ediliyor.'
                          : stats.learnedWordCount < 2
                              ? '2 farklı Karty öğrenince açılır.'
                              : 'Yeni bir Karty öğrenince yeniden açılır.';
                      final reviewCount = stats?.reviewPendingCount;

                      return Row(
                        children: [
                          ArticlePracticeHomeCard(
                            scale: scale,
                            pendingCount: articlePendingCount,
                            disabledMessage: articleDisabledMessage,
                            onTap: articlePracticeAvailable
                                ? () async {
                                    await _updateLivesAndRouter(
                                      'articlepractice',
                                    );
                                  }
                                : null,
                          ),
                          SizedBox(width: 54 * scale),
                          _ReviewMistakesCard(
                            scale: scale,
                            reviewCount: reviewCount,
                            onTap: reviewCount != null && reviewCount > 0
                                ? _openReview
                                : null,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Ana ekranın üst şeridi.
///
/// Eskiden profil fotoğrafı + "Merhaba, {ad}" + lig rozeti taşıyan bir kart
/// vardı, altında bilet ve seviye. Selamlama ve fotoğraf yer kaplıyor ama
/// hiçbir karar verdirmiyordu; üst şerit "şimdi ne yapabilirim" sorusuna cevap
/// vermeli. Duolingo'nun üst şeridi gibi kart da kaldırıldı — öğeler doğrudan
/// sayfa zemininde duruyor.
///
/// **Seri buradan çıkarıldı, yerine lig kondu.** Seri artık kendi şeridine
/// sahip (`HomeStreakStrip`) ve orada yalnız sayıyı değil bugünün durumunu da
/// söylüyor; üst çubuktaki alev aynı sayıyı tekrarlıyordu. Lig bir ara "sayısı
/// olmayan tek öğe" diye çıkarılmıştı, o itiraz artık geçersiz: rozetin
/// yanında sıralama duruyor.
class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 670 * scale,
      child: Consumer<ScoreWithLivesProvider>(
        builder: (context, provider, child) {
          final data = provider.scoreWithLives;

          return HomeTopBar(
            scale: scale,
            leagueKey: data?.league?.leagueKey ?? 'kuyruklu',
            leagueRank: data?.league?.leaderboardRank,
            tickets: data?.lives ?? 0,
            level: data?.level ?? 1,
            freezeCount: data?.freezeCount ?? 0,
          );
        },
      ),
    );
  }
}

class _ReviewMistakesCard extends StatelessWidget {
  const _ReviewMistakesCard({
    required this.scale,
    required this.reviewCount,
    required this.onTap,
  });

  final double scale;
  final int? reviewCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isLoaded = reviewCount != null;
    final hasPendingReview = (reviewCount ?? 0) > 0;
    final isInteractive = onTap != null;
    final width = 307 * scale;
    final height = 438 * scale;
    final baseOffset = AppButtonStyle.tileDepth(8 * scale);
    final radius = BorderRadius.circular(AppButtonStyle.tileRadius(28 * scale));

    return PressableLayeredCard(
      width: width,
      height: height,
      shadowOffset: baseOffset,
      radius: radius,
      baseColor: _HomeScreenScreenState._reviewBaseColor,
      onPressed: onTap,
      face: Container(
        decoration: BoxDecoration(
          color: _HomeScreenScreenState._reviewColor,
          borderRadius: radius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 24 * scale,
              bottom: 28 * scale,
              child: Container(
                width: 259 * scale,
                height: 190 * scale,
                decoration: BoxDecoration(
                  color: _HomeScreenScreenState._backgroundColor,
                  borderRadius: BorderRadius.circular(24 * scale),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/review_history.png',
                    width: 204 * scale,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 23 * scale,
              top: 22 * scale,
              child: Text(
                "Karty\nRövanş",
                style: TextStyle(
                  color: _HomeScreenScreenState._textColor,
                  fontSize: 38 * scale,
                  fontWeight: AppTypography.heading,
                  fontFamily: AppTypography.displayFamily,
                  height: 0.98,
                ),
              ),
            ),
            Positioned(
              left: 24 * scale,
              top: 112 * scale,
              width: 252 * scale,
              child: Text(
                !isLoaded
                    ? 'Rövanşların kontrol\nediliyor.'
                    : hasPendingReview
                        ? '$reviewCount rövanş kartı\nseni bekliyor.'
                        : 'Rövanş kartın yok.\nYanlış cevapların\nburada birikir.',
                style: TextStyle(
                  color: _HomeScreenScreenState._textColor,
                  fontSize: 25 * scale,
                  fontWeight: AppTypography.body,
                  fontFamily: AppTypography.family,
                  height: 1.12,
                ),
              ),
            ),
            Positioned(
              right: 20 * scale,
              top: 22 * scale,
              child: Icon(
                Icons.refresh_rounded,
                color: isInteractive
                    ? const Color(0xFF93D334)
                    : const Color(0xFF8FA0B5),
                size: 52 * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartyFeatureCard extends StatelessWidget {
  const _KartyFeatureCard({
    required this.scale,
    required this.onTap,
  });

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = 670 * scale;
    final height = 438 * scale;
    final baseOffset = AppButtonStyle.tileDepth(8 * scale);
    final radius = BorderRadius.circular(AppButtonStyle.tileRadius(28 * scale));

    return PressableLayeredCard(
      width: width,
      height: height,
      shadowOffset: baseOffset,
      radius: radius,
      baseColor: _HomeScreenScreenState._kartyBaseColor,
      onPressed: onTap,
      face: Container(
        decoration: BoxDecoration(
          color: _HomeScreenScreenState._kartyColor,
          borderRadius: radius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 44 * scale,
              width: 350 * scale,
              height: 350 * scale,
              child: Transform.translate(
                offset: Offset(7 * scale, 13 * scale),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 12 * scale,
                    sigmaY: 12 * scale,
                  ),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.28),
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/images/karty.png',
                      width: 350 * scale,
                      height: 350 * scale,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 44 * scale,
              width: 350 * scale,
              height: 350 * scale,
              child: Transform.translate(
                offset: Offset(3 * scale, 7 * scale),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 5 * scale,
                    sigmaY: 5 * scale,
                  ),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.2),
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/images/karty.png',
                      width: 350 * scale,
                      height: 350 * scale,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 44 * scale,
              width: 350 * scale,
              height: 350 * scale,
              child: Center(
                child: Image.asset(
                  'assets/images/karty.png',
                  width: 350 * scale,
                  height: 350 * scale,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              right: 18 * scale,
              top: 18 * scale,
              child: Image.asset(
                'assets/icons/ticket-one.png',
                width: 68 * scale,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: 30 * scale,
              top: 118 * scale,
              width: 324 * scale,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Karty",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _HomeScreenScreenState._textColor,
                      fontSize: 64 * scale,
                      fontWeight: AppTypography.heading,
                      fontFamily: AppTypography.displayFamily,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                  Text(
                    "Kartları kaydır,\nyeni kelimeler\nöğren!",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _HomeScreenScreenState._textColor,
                      fontSize: 31 * scale,
                      fontWeight: AppTypography.body,
                      fontFamily: AppTypography.family,
                      height: 1.22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
