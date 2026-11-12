import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/models/karty_session.dart';
import 'package:lingualloop/models/responses/KartyPathResponse.dart';
import 'package:lingualloop/models/responses/ProfileLearningStatsResponse.dart';
import 'package:lingualloop/providers/ArticlePracticeProvider.dart';
import 'package:lingualloop/providers/KartyPathProvider.dart';
import 'package:lingualloop/providers/KartyProvider.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:lingualloop/services/DailyReminders.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/flows/league_promotion_flow.dart';
import 'package:lingualloop/ui/flows/ticketed_game_flow.dart';
import 'package:lingualloop/ui/screens/karty_path_screen.dart';
import 'package:lingualloop/ui/screens/karty_unit_unlock_screen.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/NavbarWidget.dart';
import 'package:lingualloop/ui/widgets/home_top_bar.dart';
import 'package:lingualloop/ui/widgets/practice_station_marks.dart';
import 'package:lingualloop/ui/widgets/streak_sheet.dart';
import 'package:lingualloop/ui/widgets/ticket_spend_scene.dart';
import 'package:provider/provider.dart';

/// Ana ekran Karty Yolu'nun kendisi: üstte lig · seri · bilet · koruma, altında
/// patika. Şu anki destenin iki yanında Artikel Pusulası ve Rövanş durur;
/// oyunlara buradan tek dokunuşla girilir (`docs/KARTY_PATIKA.md` §11).
///
/// Görünüş [KartyPathScreen]'de; bu ekran veriyi yükler ve tazeler, bileti
/// harcayıp oyunları açar, dönüşte sırasıyla seri penceresini, lig terfisini
/// ve ünite açılışını gösterir. Ağ hatası ekranı bozmaz; eldeki son veriyle
/// devam edilir (§3.1).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late bool _loading;
  bool _starting = false;
  bool _gameOpen = false;
  bool _isShowingLeaguePromotion = false;

  /// Bilet sahnesinin iki ucu: sayaçtan dokunulan karoya.
  final _ticketIconKey = GlobalKey();
  final _currentNodeKey = GlobalKey<TicketTargetState>();
  final _articleTileKey = GlobalKey<TicketTargetState>();

  /// Gelişi süren ünite; patika onu açılmamış gibi çizer.
  int? _arrivalUnit;
  bool _playArrival = false;

  /// Bu ekranda kutlaması gösterilen ünite: onay yeniden yüklenmeden önceki
  /// tazelemeler aynı kutlamayı ikinci kez açmasın.
  int? _shownUnlock;

  KartyPathResponse? _source;
  KartyPathData? _data;

  /// Debug: `SERİ` düğmesinin sıradaki sahnesi.
  int _debugScene = 0;

  static const _debugScenes = [
    'gun_100',
    'ritmi_koru',
    'harika_gidiyorsun',
    'hedefe_dogru',
    'madalyani_kazan',
    'ruzgari_yakala',
    'istikrar_guclendirir',
    'kendi_rekorun',
    'gunluk_seri',
    'serin_korundu',
    'gunluk_seri_bekliyor',
    'beyni_esnet',
    'seni_ozledik',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Sekmeler her geçişte yeniden kurulur: veri eldeyse ekran beklemeden
    // gelir, arkada tazelenir.
    _loading = context.read<KartyPathProvider>().data == null ||
        context.read<ScoreWithLivesProvider>().scoreWithLives == null ||
        context.read<ProfileLearningStatsProvider>().stats == null;
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Gece yarısı geçmiş olabilir: vadesi gelen tekrarlar ve seri değişir.
    if (state != AppLifecycleState.resumed) return;
    unawaited(_refresh().then((_) => _maybeShowUnlock()));
  }

  Future<void> _load() async {
    final path = context.read<KartyPathProvider>();
    final stats = context.read<ProfileLearningStatsProvider>();
    final userService = context.read<UserService>();
    try {
      await Future.wait([
        path.load(silent: path.data != null),
        userService.scoreWithLivesById(context),
        stats.load(context),
      ]);
    } catch (_) {
      // Üst şerit ve duraklar destek verisi; patika varsa ekran açılır.
    }
    if (!mounted) return;
    setState(() => _loading = false);
    await _maybeShowUnlock();
  }

  Future<void> _refresh() async {
    final userService = context.read<UserService>();
    final stats = context.read<ProfileLearningStatsProvider>();
    try {
      await Future.wait([
        context.read<KartyPathProvider>().load(silent: true),
        userService.scoreWithLivesById(context),
        stats.consumePrefetchOrFetch(userService).then((fresh) {
          if (fresh != null) stats.applyFetchedStats(fresh);
        }),
      ]);
    } catch (_) {
      // Eldeki son veriyle devam.
    }
  }

  /// `Navigator.push` dönüş değeri, üst rota kapanış animasyonunu bitirmeden
  /// tamamlanabilir. Pencereler ve kutlamalar kapanan oyunun arkasında
  /// açılmasın diye ana ekranın yeniden görünmesini bekleriz.
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

  /// Oyunu açar; **beklenmesi şart** (§4.4): `pushNamed` route kapanınca
  /// tamamlanır, tazeleme ancak o zaman anlamlı. Tazeleme bitene kadar yeni
  /// oyun açılmaz: patikanın şu anki destesi eskimiş olabilir.
  Future<void> _openGame(
    String route, {
    Object? arguments,
    GamePortal? portal,
  }) async {
    if (_gameOpen) return;
    _gameOpen = true;
    final playedBefore =
        context.read<ScoreWithLivesProvider>().scoreWithLives?.playedToday;
    try {
      await _pushGame(route, arguments, portal);
      if (!mounted) return;
      final refreshed = _refresh();
      await _waitUntilHomeIsVisible();
      await refreshed;
    } finally {
      _gameOpen = false;
    }
    if (!mounted) return;
    await _presentAfterGame(firstGameToday: playedBefore == false);
  }

  /// İlk içerik bilet sahnesi sürerken inmeye başlar; oyun açıldığında hazır
  /// olsun, yükleniyor simgesi görünmesin.
  void _prepareGame(String route, Object? arguments) {
    if (route == '/articlepractice') {
      context.read<ArticlePracticeProvider>().prepareFirstTask();
      return;
    }
    final session = arguments as KartySessionArgs?;
    context.read<KartyProvider>().prepareSession(
          context,
          unit: session?.unit.number,
          deck: session?.deck,
        );
  }

  void _discardPreparedGame(String route) {
    if (route == '/articlepractice') {
      context.read<ArticlePracticeProvider>().discardPreparedTask();
    } else {
      context.read<KartyProvider>().reset();
    }
  }

  /// Bilet harcanan oyun, biletin girdiği düğümün içinden açılır.
  Future<Object?> _pushGame(
    String route,
    Object? arguments,
    GamePortal? portal,
  ) {
    final builder =
        context.findAncestorWidgetOfExactType<MaterialApp>()?.routes?[route];
    if (portal == null || builder == null) {
      return Navigator.pushNamed(context, route, arguments: arguments);
    }
    return Navigator.of(context).push<Object?>(
      GamePortalRoute<Object?>(
        settings: RouteSettings(name: route, arguments: arguments),
        builder: builder,
        portal: portal,
      ),
    );
  }

  /// Oyundan dönüşte bekleyenler, biri kapanınca sıradaki: seri penceresi,
  /// lig terfisi, ünite açılışı. Ünite en sonda çünkü kutlamasından sonra
  /// patikada gelişi oynuyor; o an üstünde başka bir şey olmamalı.
  Future<void> _presentAfterGame({required bool firstGameToday}) async {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final playedNow =
        context.read<ScoreWithLivesProvider>().scoreWithLives?.playedToday ??
            false;
    if (firstGameToday && playedNow) {
      await showStreakSheet(context);
      if (!mounted) return;
    }
    await _showPendingLeaguePromotion();
    if (!mounted) return;
    await _maybeShowUnlock();
    if (firstGameToday && playedNow) await DailyReminders.askPermissionOnce();
  }

  /// Giriş bedeli olan oyun: bilet harcandıysa açılır. Bilet yetmezse
  /// "bilet bitti" penceresi çıkar ve yollarından biri seçilebilir.
  Future<void> _startTicketed(
    String route, {
    Object? arguments,
    required GlobalKey<TicketTargetState> tile,
  }) async {
    if (_starting || _gameOpen) return;
    // Sahne sürerken düğüm zıplamasın.
    setState(() => _starting = true);
    TicketSpendPlayback? playback;
    try {
      final entered = await spendTicketForGame(
        context,
        playEntrance: () {
          _prepareGame(route, arguments);
          return playback =
              playTicketSpend(context, from: _ticketIconKey, to: tile);
        },
        onGoToReview: () => unawaited(_openGame('/kartyreview')),
        onGoToQuests: () =>
            NavbarWidget.requestedTab.value = NavbarWidget.questsTabIndex,
      );
      if (!mounted) return;
      if (!entered) {
        _discardPreparedGame(route);
        return;
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
    playback?.removeWhenCovered();
    await _openGame(route, arguments: arguments, portal: playback?.portal);
  }

  /// Şu anki adımın oyunu: hangi ünitenin hangi destesi (yoksa yalnız
  /// tekrar). Oyun yeni kelimeyi yalnız bu desteden ister ve bitişini sorar.
  KartySessionArgs? _session() {
    final data = _data;
    if (data == null) return null;
    for (final unit in data.units) {
      for (final step in unit.steps) {
        if (step.state != KartyStepState.current) continue;
        return KartySessionArgs(
          unit: unit,
          deck: step.deck,
          reviewCount: step.reviewCount,
        );
      }
    }
    return null;
  }

  Future<void> _showPendingLeaguePromotion() async {
    if (_isShowingLeaguePromotion) return;
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

  /// Bekleyen ünite açılışını gösterir: patika üniteyi açılmamış gibi
  /// çizer, kutlama ekranı açılır; DEVAM ET'ten sonra kamera üniteye kayar
  /// ve açılış patikada oynar. Ana ekran o sırada en üstte değilse (oyun
  /// açıkken tazelendiyse) dönüşte yakalanır.
  Future<void> _maybeShowUnlock({KartyUnitUnlock? simulated}) async {
    if (!mounted || _arrivalUnit != null) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final response = context.read<KartyPathProvider>().data;
    if (response == null) return;
    final unlock = simulated ?? _dataFor(response).pendingUnlock;
    if (unlock == null) return;
    if (simulated == null && _shownUnlock == unlock.unlocked.number) return;
    _shownUnlock = unlock.unlocked.number;

    setState(() => _arrivalUnit = unlock.unlocked.number);
    final kartyService = context.read<KartyService>();
    final route = MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (_) => KartyUnitUnlockScreen(
        unlock: unlock,
        // Tasarım simülasyonu gerçek kaydı kapatmaz.
        onContinue: simulated != null
            ? () async => true
            : () async {
                final ack = await kartyService.acknowledgeUnitUnlock();
                return ack.errorCode == null;
              },
      ),
    );
    final shown = await Navigator.of(context).push(route) ?? false;
    // Kutlama ekranının çıkışı bitsin: kamera görünen patikada kaysın.
    await route.completed;
    if (!mounted) return;
    if (!shown) {
      setState(() => _arrivalUnit = null);
      return;
    }
    setState(() => _playArrival = true);
  }

  void _arrivalDone() {
    if (!mounted) return;
    setState(() {
      _arrivalUnit = null;
      _playArrival = false;
    });
  }

  /// Debug: en ileri açık ünitenin açılışını sunucuya dokunmadan oynatır
  /// (lig ekranındaki TERFİ düğmesinin karşılığı).
  void _simulateUnlock(KartyPathData data) {
    for (final unit in data.units.reversed) {
      if (unit.state == KartyUnitState.locked) continue;
      final unlock = data.unlockFor(unit.number);
      if (unlock == null) continue;
      unawaited(_maybeShowUnlock(simulated: unlock));
      return;
    }
  }

  void _debugNextScene() {
    final scene = _debugScenes[_debugScene % _debugScenes.length];
    _debugScene += 1;
    unawaited(showStreakSheet(context, sceneKey: scene));
  }

  /// Aynı yanıt her yeniden çizimde yeniden çevrilmesin: yerleşim buna bağlı.
  KartyPathData _dataFor(KartyPathResponse response) {
    if (!identical(_source, response)) {
      _source = response;
      _data = KartyPathData.fromResponse(response);
    }
    return _data!;
  }

  KartyPathStations _stations(ProfileLearningStatsResponse? stats) {
    final learned = stats?.learnedWordCount ?? 0;
    final articles = stats == null ? 0 : learned - stats.learnedArticleCount;
    final articleOpen = learned >= 2 && articles > 0;
    final reviews = stats?.reviewPendingCount;

    return KartyPathStations(
      article: KartyPathStation(
        title: 'Artikel',
        spokenName: 'Artikel Pusulası',
        icon: (tile) => ArticleDragMark(size: tile * 0.8),
        detail: stats == null
            ? ''
            : articleOpen
                ? '$articles kart'
                : learned < 2
                    ? '${2 - learned} kelime öğren'
                    : 'Yeni kelime öğren',
        onTap: articleOpen
            ? () => unawaited(
                  _startTicketed('/articlepractice', tile: _articleTileKey),
                )
            : null,
        tileKey: _articleTileKey,
      ),
      // Rövanş bilet harcamaz; yanlışları tekrar ederek oyuna dönüş yolu açar.
      review: KartyPathStation(
        title: 'Rövanş',
        spokenName: 'Karty Rövanş',
        icon: (tile) => RevengeCardMark(size: tile * 0.66),
        detail: reviews == null
            ? ''
            : reviews > 0
                ? '$reviews kart'
                : 'Hatan yok',
        onTap: (reviews ?? 0) > 0
            ? () => unawaited(_openGame('/kartyreview'))
            : null,
      ),
    );
  }

  Widget _topBar(double scale) => Consumer<ScoreWithLivesProvider>(
        builder: (context, provider, _) {
          final data = provider.scoreWithLives;
          return HomeTopBar(
            scale: scale,
            leagueKey: data?.league?.leagueKey ?? 'kuyruklu',
            leagueRank: data?.league?.leaderboardRank,
            streakDays: data?.streak ?? 0,
            playedToday: data?.playedToday ?? false,
            tickets: data?.lives ?? 0,
            freezeCount: data?.freezeCount ?? 0,
            onStreakTap: () => unawaited(showStreakSheet(context)),
            ticketIconKey: _ticketIconKey,
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KartyPathProvider>();
    final stats = context.watch<ProfileLearningStatsProvider>().stats;
    final hopCurrent = context.select<ScoreWithLivesProvider, bool>(
      (provider) => provider.scoreWithLives?.playedToday == false,
    );
    final response = provider.data;

    if (_loading || response == null) {
      return _HomePlaceholder(
        loading: _loading || provider.status != KartyPathStatus.error,
        onRetry: () {
          setState(() => _loading = true);
          unawaited(_load());
        },
      );
    }

    final data = _dataFor(response);
    // Bekleyen açılış: kutlaması gösterilene kadar ünite açılmamış çizilir.
    // Oyundan dönüşte önce seri penceresi ve lig terfisi gelebilir; ünite
    // onların arkasında açılmış görünmesin.
    final pending = data.pendingUnlock?.unlocked.number;
    final screen = KartyPathScreen(
      data: data,
      header: _topBar,
      stations: _stations(stats),
      onContinue: () => unawaited(
        _startTicketed(
          '/kartyquiz',
          arguments: _session(),
          tile: _currentNodeKey,
        ),
      ),
      currentNodeKey: _currentNodeKey,
      hopCurrent: hopCurrent && !_starting,
      onRefresh: () async {
        await _refresh();
        unawaited(_maybeShowUnlock());
      },
      arrivalUnit: _arrivalUnit ?? (pending != _shownUnlock ? pending : null),
      playArrival: _playArrival,
      onArrivalDone: _arrivalDone,
    );
    if (!kDebugMode) return screen;
    return Stack(
      children: [
        screen,
        Positioned(
          right: 16,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _DebugButton(label: 'SERİ', onTap: _debugNextScene),
              const SizedBox(height: 10),
              _DebugButton(
                label: 'AÇILIŞ',
                onTap: () => _simulateUnlock(data),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Debug: yayından önce kaldırılacak (CLAUDE.md §8).
class _DebugButton extends StatelessWidget {
  const _DebugButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Scaffold'un dışında; Material olmadan metin sarı çizgiyle çizilir.
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1CB1F5),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Color(0xFF1B84B5), offset: Offset(0, 5)),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: AppTypography.family,
              fontSize: 15,
              fontWeight: AppTypography.action,
            ),
          ),
        ),
      ),
    );
  }
}

/// İlk yükleme ve ilk yüklemede hata. Sonraki tazelemeler ekranı
/// değiştirmez, eldeki veriyle devam eder.
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder({required this.loading, required this.onRetry});

  final bool loading;
  final VoidCallback onRetry;

  static const _bg = Color(0xFF041227);
  static const _accent = Color(0xFF1CB1F5);
  static const _accentDepth = Color(0xFF1B84B5);
  static const _muted = Color(0xFF8FA0B5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / 750;
          return Center(
            child: loading
                ? const CircularProgressIndicator(color: _accent)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Karty Yolu yüklenemedi.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 28 * scale,
                          fontWeight: AppTypography.body,
                          fontFamily: AppTypography.family,
                        ),
                      ),
                      SizedBox(height: 32 * scale),
                      DepthPressableButton(
                        text: 'TEKRAR DENE',
                        width: 420 * scale,
                        height: 96 * scale,
                        radius: 26 * scale,
                        shadowOffset: 10 * scale,
                        backgroundColor: _accent,
                        shadowColor: _accentDepth,
                        fontSize: 28 * scale,
                        onPressed: onRetry,
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
