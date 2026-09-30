import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:lingualloop/Utils/AppNotifier.dart';
import 'package:lingualloop/models/responses/GetKartyByScoreResponse.dart';
import 'package:lingualloop/providers/KartyProvider.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:lingualloop/services/PronunciationService.dart';
import 'package:lingualloop/ui/widgets/SwipableCard.dart';
import 'package:lingualloop/ui/widgets/karty_top_bar.dart';
import 'package:lingualloop/ui/widgets/karty_boost_activation_effect.dart';
import 'package:lingualloop/ui/widgets/karty_review_complete_state.dart';
import 'package:lingualloop/ui/widgets/karty_success_celebration.dart';
import 'package:provider/provider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/ui/widgets/karty_play_surface.dart';
import 'package:lingualloop/ui/widgets/karty_answer_actions.dart';
import 'package:lingualloop/ui/widgets/karty_pause_overlay.dart';

import '../../services/UserService.dart';

class KartyQuizScreen extends StatefulWidget {
  final bool reviewMode;

  const KartyQuizScreen({super.key, this.reviewMode = false});

  @override
  _KartyQuizScreenState createState() => _KartyQuizScreenState();
}

class _KartyQuizScreenState extends State<KartyQuizScreen> {
  static const _backgroundColor = Color(0xFF041227);
  static const _progressColor = Color(0xFF93D334);

  static const _boostChargeGoal = 5;
  static const _boostDurationMilliseconds = 20000;

  Offset _position = Offset.zero;
  double _rotation = 0;
  bool _regionAccepted = false; // Bölge kontrolü için flag
  bool _isDeckAdvancing = false;
  bool _isReviewEmpty = false;
  int _boostCharge = 0;
  int _boostRemainingMilliseconds = 0;
  int _reviewTotalStack = 0;
  int _reviewCompletedStack = 0;
  int _reviewRewardTickets = 0;
  bool _isBoostReady = false;
  bool _isBoostActive = false;
  bool _isBoostActivating = false;
  bool _didPrecacheReviewCompleteScene = false;
  Timer? _boostTimer;
  int streak = 0;
  final ValueNotifier<int> timeBarResetNotifier = ValueNotifier<int>(1);
  late ValueNotifier<int> duration = ValueNotifier<int>(0);
  final ValueNotifier<bool> isFinished = ValueNotifier(false);
  final ValueNotifier<bool> isPaused = ValueNotifier(false);
  final ValueNotifier<bool> isTrueAnswerBlurActive = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isFalseAnswerBlurActive =
      ValueNotifier<bool>(false);
  final ValueNotifier<double> boostProgress = ValueNotifier<double>(0);

  late KartyProvider kartyProvider;
  late KartyService kartyService;
  late UserService userService;
  late ProfileLearningStatsProvider profileLearningStatsProvider;
  late PronunciationService pronunciationService;

  /// Tanışma kartında sesin **bir kez** otomatik çalınmasını sağlar: aynı
  /// kart için ikinci kez tetiklenmesin diye son çalınan kart tutuluyor.
  /// `build` her setState'te koştuğu için bu koruma olmadan ses üst üste
  /// binerdi.
  int? _autoPlayedKartyId;

  /// Deste **bu ekran oturumu için** yüklendi mi.
  ///
  /// `KartyProvider` uygulama ömürlü ve destesini hafızada tutuyor;
  /// `initState` içindeki `reset()` bir `Future.microtask` içinde koştuğu
  /// için **ilk `build` ondan önce** çalışıyor ve `cards` hâlâ bir önceki
  /// oturumun kartını taşıyor. Otomatik seslendirme `build`'den tetiklendiği
  /// için o eski kartın sesini çalıyordu: kullanıcı Karty'den çıkıp
  /// girdiğinde önce bir önceki kelimeyi, sonra yenisini duyuyordu.
  ///
  /// Bayrak, yükleme bitene kadar seslendirmeyi kilitliyor.
  bool _deckReady = false;
  final GlobalKey<KartySuccessCelebrationState> _successCelebrationKey =
      GlobalKey();
  final GlobalKey<KartyBoostActivationEffectState> _boostActivationKey =
      GlobalKey();
  final GlobalKey _boostTopLeftAnchorKey = GlobalKey();
  final GlobalKey _boostBottomRightAnchorKey = GlobalKey();
  final GlobalKey _boostLeagueTargetKey = GlobalKey();
  bool _pauseMenuOpen = false;

  @override
  void initState() {
    super.initState();
    kartyProvider = Provider.of<KartyProvider>(context, listen: false);
    kartyService = Provider.of<KartyService>(context, listen: false);
    userService = Provider.of<UserService>(context, listen: false);
    profileLearningStatsProvider =
        Provider.of<ProfileLearningStatsProvider>(context, listen: false);
    pronunciationService =
        Provider.of<PronunciationService>(context, listen: false);

    Future.microtask(() async {
      kartyProvider.reset();
      if (widget.reviewMode) {
        setState(() {
          _reviewTotalStack =
              profileLearningStatsProvider.stats?.reviewPendingCount ?? 0;
          _reviewCompletedStack = 0;
        });
      }

      final isLoaded = await kartyProvider.loadKarty(
        context,
        reviewMode: widget.reviewMode,
      );
      if (isLoaded) {
        if (mounted) setState(() => _deckReady = true);
        if (widget.reviewMode) {
          unawaited(
            profileLearningStatsProvider.refreshFromService(userService).then(
              (_) {
                if (!mounted) return;
                setState(() {
                  _reviewTotalStack =
                      profileLearningStatsProvider.stats?.reviewPendingCount ??
                          _reviewTotalStack;
                });
              },
            ),
          );
        }
        if (_isIntroducing) {
          isFinished.value = true;
          duration.value = 0;
          return;
        }

        duration.value = 4;
        timeBarResetNotifier.value += 1;

        return;
      }

      if (widget.reviewMode && mounted) {
        setState(() {
          _isReviewEmpty = true;
          // Bekleyen Karty yokken debug kartından açılan ekran, gerçek
          // tamamlanma sonucunu görsel olarak inceletebilsin. Üretimde bu
          // değerler yalnızca sunucunun döndürdüğü sonuçtan gelir.
          if (kDebugMode) {
            _reviewRewardTickets = 1;
          }
        });
        return;
      }

      print("Karty yüklenirken bir hata oluştu.");
    });
  }

  @override
  void dispose() {
    // Ekrandan çıkarken ses kesiliyor. Servis uygulama ömrü boyunca
    // yaşadığı için bu olmadan oynatıcı arka planda çalmaya devam ediyor ve
    // kullanıcı tekrar girdiğinde bir önceki kartın sesini duyuyordu.
    pronunciationService.stop();
    _boostTimer?.cancel();
    boostProgress.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.reviewMode || _didPrecacheReviewCompleteScene) return;

    _didPrecacheReviewCompleteScene = true;
    precacheImage(
      const AssetImage('assets/scenes/karty_review_complete.png'),
      context,
    );
  }

  void _recordCorrectBoostAnswer() {
    if (widget.reviewMode || _isBoostReady || _isBoostActive) return;

    _boostCharge = (_boostCharge + 1).clamp(0, _boostChargeGoal).toInt();
    if (_boostCharge == _boostChargeGoal) {
      _isBoostReady = true;
    }
  }

  void _recordWrongBoostAnswer() {
    if (widget.reviewMode || _isBoostReady || _isBoostActive) return;
    _boostCharge = 0;
  }

  Future<void> _activateBoost() async {
    if (!_isBoostReady ||
        _isBoostActive ||
        _isBoostActivating ||
        isPaused.value ||
        isFinished.value) {
      return;
    }

    _boostTimer?.cancel();
    setState(() {
      _isBoostReady = false;
      _isBoostActivating = true;
    });
    // Enerji darbesi oynarken cevap kartı ve süre bekler. Böylece efekt bir
    // süs değil, kullanıcının başlattığı boost olayının kendisi olur.
    isPaused.value = true;

    final completed = await _boostActivationKey.currentState?.play();
    if (!mounted || completed != true) return;

    setState(() {
      _isBoostActivating = false;
      _isBoostActive = true;
      _boostCharge = 0;
      _boostRemainingMilliseconds = _boostDurationMilliseconds;
      boostProgress.value = 1;
    });
    isPaused.value = false;

    _boostTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (isPaused.value || isFinished.value) return;

      _boostRemainingMilliseconds -= 100;
      boostProgress.value =
          (_boostRemainingMilliseconds / _boostDurationMilliseconds)
              .clamp(0.0, 1.0);

      if (_boostRemainingMilliseconds > 0) return;

      timer.cancel();
      if (!mounted) return;
      setState(() {
        _isBoostActive = false;
        boostProgress.value = 0;
      });
    });
  }

  /// Ekrandaki kartın telaffuzunu çalar.
  ///
  /// **Yazım sorusu sırasında çağrılmaz** ve bu bilinçli: kart yanlış
  /// yazılmış bir kelime gösterirken doğru telaffuzu duyurmak cevabı
  /// sızdırır. Ses yalnız iki anda duyuluyor — kelimeyle **tanışırken** ve
  /// cevaptan **sonra**; ikisi de öğrenmenin gerçekleştiği anlar.
  void _speakCurrentKarty() {
    final cards = kartyProvider.cards;
    if (cards.isEmpty) return;
    pronunciationService.play(cards.first.audioUrl);
  }

  /// Tanışma kartı ekrana geldiğinde sesi bir kez çalar.
  ///
  /// Otomatik çalıyor çünkü ilk temasın **duyulması** gerekiyor; kullanıcı
  /// butonu keşfetmeyebilir ve kelimeyi yanlış telaffuzla ezberleyebilir.
  /// Destedeki sıradaki kartların görsellerini önden çözer.
  ///
  /// `Image.file` çözümlemeyi ilk çizimde yapıyor; kart değiştiğinde yeni
  /// görsel birkaç kare geç geliyordu. Önbellek yinelenen istekleri kendisi
  /// eliyor, bu yüzden her `build`'de çağrılması güvenli.
  void _precacheUpcomingCards(KartyProvider cardProvider) {
    for (final card in cardProvider.cards.skip(1)) {
      precacheImage(FileImage(File(card.kartyUrl)), context);
    }
  }

  void _autoPlayIntroductionIfNeeded() {
    if (!_deckReady) return;
    if (!_isIntroducing) return;
    final cards = kartyProvider.cards;
    if (cards.isEmpty) return;

    final kartyId = cards.first.kartyId;
    if (_autoPlayedKartyId == kartyId) return;
    _autoPlayedKartyId = kartyId;

    // Kart yerleşmeden çalmaya başlamak sesi geçişin altında bırakıyor.
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrentKarty());
  }

  /// Ekrandaki kart bir **tanışma** kartı mı.
  ///
  /// Kararı sunucu veriyor (`KartyPresentationPolicy`); istemci yalnız
  /// okuyor. Üç davranış buna bağlı ve hepsi bu tek kaynağa bakıyor:
  /// cevap butonları, kaydırma ve zamanlayıcı.
  bool get _isIntroducing {
    final cards = kartyProvider.cards;
    if (cards.isEmpty) return false;
    return cards.first.mode == KartyCardMode.introduce;
  }

  /// Tanışma kartındaki "Anladım". Kelime kaydedilir ve sıradaki karta
  /// geçilir — **soru hemen sorulmaz**: ekranda duran bir kelimeyi sormak
  /// hafızayı değil kısa süreli belleği ölçer. Kelime sonraki turlarda
  /// yazım sorusu olarak geri gelir.
  Future<void> _acknowledgeIntroduction(BuildContext context) async {
    final cards = kartyProvider.cards;
    if (cards.isEmpty) return;

    isFinished.value = true;
    await kartyService.recordKartyIntroduction(cards.first.kartyId);
    if (!mounted) return;

    // Desteyi ilerletmenin **tek yolu** bu: önyükleme, görsel kayma ve
    // sonraki kart hep birlikte yürüyor. Ayrı bir ilerletme yazmak ikinci
    // bir akış doğururdu ve biri diğerinden sapardı.
    await _finishAnsweredCard(context);
  }

  Future<void> _answerQuestion(BuildContext context, bool pressedRight) async {
    isFinished.value = true; // TimeBar'ı durdurduk
    final currentKarty = kartyProvider.cards[0];
    final isCorrectAnswer = currentKarty.isCorrect && pressedRight ||
        !currentKarty.isCorrect && !pressedRight;

    if (widget.reviewMode) {
      final reviewResult = await kartyService.resolveWrongKartyReview(
        currentKarty.kartyId,
        isCorrectAnswer,
      );
      if (!mounted) return;
      unawaited(
        profileLearningStatsProvider.refreshFromService(userService),
      );

      if (isCorrectAnswer) {
        setState(() {
          streak += 1;
          if (_reviewTotalStack > 0) {
            _reviewCompletedStack =
                (_reviewCompletedStack + 1).clamp(0, _reviewTotalStack).toInt();
          }
          _reviewRewardTickets += reviewResult?.rewardTickets ?? 0;
          duration.value = 0;
        });

        _successCelebrationKey.currentState?.play(
          streak: streak,
          awardedPoints: 0,
          isReviewMode: true,
        );
        isTrueAnswerBlurActive.value = true;
        // Geri bildirim anı: doğru kelime duyuluyor. Hatanın düzeltilmesi
        // en çok burada işe yarıyor.
        _speakCurrentKarty();
        await Future.delayed(Duration(seconds: 1));
        if (!mounted) return;

        isTrueAnswerBlurActive.value = false;
        await Future.delayed(Duration(milliseconds: 600));
        if (!mounted) return;

        timeBarResetNotifier.value += 1;

        return;
      }

      setState(() {
        streak = 0;
        duration.value = 0;
      });

      isFalseAnswerBlurActive.value = true;
      await Future.delayed(Duration(milliseconds: 2000));
      if (!mounted) return;

      isFalseAnswerBlurActive.value = false;
      await Future.delayed(Duration(milliseconds: 600));
      if (!mounted) return;

      timeBarResetNotifier.value += 1;

      return;
    }

    // Kupa arttı
    if (isCorrectAnswer) {
      // Kutlamada gösterilen **ödül**. Sunucuya gönderilen sayı bu değil:
      // yön ve çarpan ayrı gidiyor, çünkü boost ödülü (görünen puan, lig
      // puanı) çarparken gizli zorluk termostatına dokunmuyor. Tek sayı
      // gönderildiği dönemde boost zorluğu da üçe katlıyordu.
      final awardedPoints = _isBoostActive ? 3 : 1;
      var apiResponse = await userService.updateScoreById(
        1,
        kartyId: currentKarty.kartyId,
        boostActive: _isBoostActive,
      );
      if (!mounted) return;
      if (apiResponse.errorCode == null) {
        setState(() {
          streak += 1;
          _recordCorrectBoostAnswer();
          duration.value = 0; // Süreyi tekrar ayarla
        });

        // Tek bir geri bildirim zinciri: kartın yeşil kalınlık bandı,
        // kelimenin yeşile dönüşü ve boost şeridinin dolumu aynı karede
        // başlar. Sunucudan yenilenmiş lig sayısını beklerken kullanıcıyı
        // cevapsız bırakmıyoruz.
        isTrueAnswerBlurActive.value = true;
        _speakCurrentKarty();
        final minimumFeedbackTime =
            Future.delayed(const Duration(milliseconds: 850));

        await userService.scoreWithLivesById(context);
        if (!mounted) return;
        profileLearningStatsProvider.prefetchForHome(userService);

        _successCelebrationKey.currentState?.play(
          streak: streak,
          awardedPoints: awardedPoints,
        );
        await Future.wait([
          minimumFeedbackTime,
          Future.delayed(const Duration(milliseconds: 260)),
        ]);
        if (!mounted) return;

        isTrueAnswerBlurActive.value = false;
        await Future.delayed(const Duration(milliseconds: 520));
        if (!mounted) return;

        timeBarResetNotifier.value += 1; // ProgressBar'ı sıfırla
      }

      return;
    }

    // Kupa düştü
    var apiResponse =
        await userService.updateScoreById(-1, kartyId: currentKarty.kartyId);
    if (!mounted) return;
    if (apiResponse.errorCode == null) {
      setState(() {
        streak = 0;
        _recordWrongBoostAnswer();
        duration.value = 0; // Süreyi tekrar ayarla
      });

      // Yanlış cevap da ağ yenilemesini beklemeden yerel olarak okunur.
      isFalseAnswerBlurActive.value = true;
      final minimumFeedbackTime =
          Future.delayed(const Duration(milliseconds: 1400));

      await userService.scoreWithLivesById(context);
      if (!mounted) return;
      profileLearningStatsProvider.prefetchForHome(userService);

      await minimumFeedbackTime;
      if (!mounted) return;

      isFalseAnswerBlurActive.value = false;
      await Future.delayed(const Duration(milliseconds: 520));
      if (!mounted) return;

      timeBarResetNotifier.value += 1; // ProgressBar'ı sıfırla
    }
  }

  Future<void> _nextKarty(BuildContext context) async {
    bool isLoaded = await kartyProvider.loadKarty(
      context,
      reviewMode: widget.reviewMode,
    );
    if (isLoaded) {
      // Tanışma kartında **süre işlemez**. Okumak için gelen bir kartta geri
      // sayım öğrenmeyi aceleye getirir; kullanıcı kelimeye bakmak yerine
      // butona yetişmeye çalışır.
      if (_isIntroducing) {
        isFinished.value = true;
        duration.value = 0;
        return;
      }

      duration.value = 10; // Süreyi tekrar ayarla

      await Future.delayed(Duration(milliseconds: 20));
      timeBarResetNotifier.value += 1;
      isFinished.value = false; // TimeBar'ı başlattık

      return;
    }

    if (widget.reviewMode && mounted) {
      setState(() {
        if (_reviewTotalStack > 0) {
          _reviewCompletedStack = _reviewTotalStack;
        }
        _isReviewEmpty = true;
      });
      isFinished.value = true;
      return;
    }

    AppNotifier.showMessage("Karty yüklenirken bir hata oluştu.");
  }

  void _restartCurrentKarty() {
    _boostTimer?.cancel();
    _boostActivationKey.currentState?.stop();
    _boostCharge = 0;
    _isBoostReady = false;
    _isBoostActive = false;
    _isBoostActivating = false;
    _boostRemainingMilliseconds = 0;
    boostProgress.value = 0;

    _resetCard();
    isPaused.value = false;
    isFinished.value = false;
    duration.value = 10;
    timeBarResetNotifier.value += 1;
  }

  Future<void> _closeKartyScreen() async {
    _successCelebrationKey.currentState?.stop();
    _boostActivationKey.currentState?.stop();
    if (isPaused.value) {
      isPaused.value = false;
      await Future.delayed(const Duration(milliseconds: 16));
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _resetCard() {
    setState(() {
      _position = Offset.zero;
      _rotation = 0;
      _regionAccepted = false; // Bölge kontrolünü sıfırla
      _isDeckAdvancing = false;
    });
  }

  bool _isInRegion(Offset position, double screenWidth, bool isLeft) {
    if (isLeft) {
      return position.dx < -screenWidth / 2.5; // Sol bölge kontrolü
    }

    return position.dx > screenWidth / 2.5; // Sağ bölge kontrolü
  }

  Future<void> _animateCardOut(bool toRight, double screenWidth) async {
    final startPosition = _position;
    final startRotation = _rotation;
    final endPosition = Offset(
      toRight ? screenWidth * 1.45 : -screenWidth * 1.45,
      _position.dy,
    );
    final endRotation = toRight ? 0.65 : -0.65;

    for (var step = 1; step <= 10; step++) {
      if (!mounted) return;

      final t = Curves.easeIn.transform(step / 10);
      setState(() {
        _position = Offset.lerp(startPosition, endPosition, t)!;
        _rotation = lerpDouble(startRotation, endRotation, t)!;
      });
      await Future.delayed(const Duration(milliseconds: 16));
    }
  }

  Future<void> _advanceDeckVisual() async {
    if (!mounted) return;

    setState(() {
      _isDeckAdvancing = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _finishAnsweredCard(BuildContext context) async {
    if (!mounted) return;
    kartyProvider.prefetchNextKarty(
      context,
      reviewMode: widget.reviewMode,
    );
    await _advanceDeckVisual();
    if (!mounted) return;
    await _nextKarty(context);
    if (!mounted) return;

    _resetCard();
  }

  Future<void> _completeAnswerFlow(
    double screenWidth,
    bool pressedRight, {
    required bool animateSwipeOut,
  }) async {
    try {
      if (animateSwipeOut) {
        await _animateCardOut(pressedRight, screenWidth);
      }

      await _answerQuestion(context, pressedRight);
      await _finishAnsweredCard(context);
    } catch (_) {
      if (!mounted) return;

      _resetCard();
      isFinished.value = false;
      AppNotifier.showMessage("Bir hata oluştu. Tekrar deneyin.");
    }
  }

  /// Test kolaylığı: gerçek kartın doğru yönünü normal cevap akışına verir.
  /// Puan ve boost doğrudan artırılmaz; sunucu ve animasyonlar aynen çalışır.
  Future<void> _debugAnswerCorrectly() async {
    if (!kDebugMode ||
        isFinished.value ||
        isPaused.value ||
        _regionAccepted ||
        _isDeckAdvancing ||
        _isIntroducing ||
        duration.value <= 0 ||
        kartyProvider.cards.isEmpty) {
      return;
    }
    await _checkRegion(
      MediaQuery.sizeOf(context).width,
      kartyProvider,
      kartyProvider.cards.first.isCorrect,
      isButton: true,
    );
  }

  Future<void> _checkRegion(
      double screenWidth, KartyProvider cardProvider, bool? pressedRight,
      {bool isButton = false, bool animateSwipeOut = false}) async {
    if (!_regionAccepted) {
      if (isButton && pressedRight != null) {
        if (pressedRight) {
          print("Sağ Buttona Basıldı");

          duration.value = 0;
          _regionAccepted = true; // Bölgeyi kabul et

          await _completeAnswerFlow(
            screenWidth,
            true,
            animateSwipeOut: true,
          );
        } else {
          print("Sol Buttona Basıldı");

          duration.value = 0;
          _regionAccepted = true; // Bölgeyi kabul et

          await _completeAnswerFlow(
            screenWidth,
            false,
            animateSwipeOut: true,
          );
        }
      }

      if (_isInRegion(_position, screenWidth, false)) {
        print("Sağ Bölgeye Bırakıldı");

        duration.value = 0;
        _regionAccepted = true; // Bölgeyi kabul et

        await _completeAnswerFlow(
          screenWidth,
          true,
          animateSwipeOut: animateSwipeOut,
        );
      } else if (_isInRegion(_position, screenWidth, true)) {
        print("Sol Bölgeye Bırakıldı");

        duration.value = 0;
        _regionAccepted = true; // Bölgeyi kabul et

        await _completeAnswerFlow(
          screenWidth,
          false,
          animateSwipeOut: animateSwipeOut,
        );
      }
    }
  }

  void _togglePauseMenu() {
    if (_isBoostActivating || _isDeckAdvancing || _regionAccepted) return;
    final opening = !_pauseMenuOpen;
    if (opening) {
      pronunciationService.stop();
      _successCelebrationKey.currentState?.stop();
    }
    setState(() => _pauseMenuOpen = opening);
    isPaused.value = opening;
  }

  @override
  Widget build(BuildContext context) {
    final cardProvider = Provider.of<KartyProvider>(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = screenWidth / 750;
    _autoPlayIntroductionIfNeeded();
    _precacheUpcomingCards(cardProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: _backgroundColor,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            reverseDuration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              fit: StackFit.expand,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild
              ],
            ),
            transitionBuilder: (child, animation) {
              final fade = FadeTransition(opacity: animation, child: child);
              if (child.key != const ValueKey('review-complete-surface')) {
                return fade;
              }
              return SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, .025), end: Offset.zero)
                    .animate(animation),
                child: fade,
              );
            },
            child: _isReviewEmpty
                ? KeyedSubtree(
                    key: const ValueKey('review-complete-surface'),
                    child: KartyReviewCompleteState(
                      scale: scale,
                      rewardTickets: _reviewRewardTickets,
                      onClose: _closeKartyScreen,
                    ),
                  )
                : KeyedSubtree(
                    key: const ValueKey('quiz-active-surface'),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: isFinished,
                      builder: (context, finished, _) =>
                          ValueListenableBuilder<bool>(
                        valueListenable: isPaused,
                        builder: (context, paused, _) {
                          final loaded = cardProvider.isLoaded &&
                              cardProvider.cards.isNotEmpty;
                          final introducing = loaded && _isIntroducing;
                          final timedOut = loaded &&
                              finished &&
                              !introducing &&
                              !_isDeckAdvancing &&
                              !_regionAccepted;
                          final busy = _isDeckAdvancing ||
                              _regionAccepted ||
                              _isBoostActivating;
                          final canAnswer = loaded &&
                              !finished &&
                              !paused &&
                              !busy &&
                              duration.value > 0;
                          return KartyPlaySurface(
                            isIntroducing: introducing,
                            header: ValueListenableBuilder<bool>(
                              valueListenable: pronunciationService.isMuted,
                              builder: (context, muted, _) => KartyTopBar(
                                scale: scale,
                                duration: duration,
                                timeBarResetNotifier: timeBarResetNotifier,
                                isFinished: isFinished,
                                isPaused: isPaused,
                                isBoostActive: _isBoostActive,
                                isIntroducing: introducing,
                                reviewMode: widget.reviewMode,
                                reviewTotalStack: _reviewTotalStack,
                                reviewCompletedStack: _reviewCompletedStack,
                                leaguePointsAnchorKey: _boostLeagueTargetKey,
                                muted: muted,
                                onToggleSound: () =>
                                    pronunciationService.setMuted(!muted),
                                pauseEnabled: !busy,
                                onPause: _togglePauseMenu,
                              ),
                            ),
                            cardBuilder: (layout) {
                              if (!loaded) {
                                return const Center(
                                    child: CircularProgressIndicator(
                                        color: _progressColor));
                              }
                              return SwipableCard(
                                karty: cardProvider.cards.first,
                                layout: layout,
                                showInlineRestartAction: false,
                                // Yazım sorusunda telaffuz doğru cevabı sızdırır.
                                onPronounce: introducing &&
                                        cardProvider.cards.first.audioUrl
                                                ?.isNotEmpty ==
                                            true
                                    ? _speakCurrentKarty
                                    : null,
                                position: _position,
                                rotation: _rotation,
                                showRestartState: timedOut,
                                isAdvancingDeck: _isDeckAdvancing,
                                boostEnabled:
                                    !widget.reviewMode && !introducing,
                                boostCharge: _boostCharge,
                                boostChargeGoal: _boostChargeGoal,
                                isBoostReady: _isBoostReady,
                                isBoostActive: _isBoostActive && !timedOut,
                                isBoostActivating: _isBoostActivating,
                                topLeftBoostAnchorKey: _boostTopLeftAnchorKey,
                                bottomRightBoostAnchorKey:
                                    _boostBottomRightAnchorKey,
                                boostProgress: boostProgress,
                                onRestart: _restartCurrentKarty,
                                onBoostTap: _activateBoost,
                                isTrueAnswerBlurActive: isTrueAnswerBlurActive,
                                isFalseAnswerBlurActive:
                                    isFalseAnswerBlurActive,
                                onPanUpdate: canAnswer && !introducing
                                    ? (details) => setState(() {
                                          _position += details.delta;
                                          _rotation = _position.dx / 300;
                                        })
                                    : (_) {},
                                onPanEnd: (details) async {
                                  if (introducing) return;
                                  if (canAnswer) {
                                    await _checkRegion(
                                        screenWidth, cardProvider, null,
                                        animateSwipeOut: true);
                                  }
                                  if (!_regionAccepted && mounted) {
                                    setState(() {
                                      _position = Offset.zero;
                                      _rotation = 0;
                                    });
                                  }
                                },
                              );
                            },
                            actions: !loaded
                                ? const SizedBox.shrink()
                                : KartyAnswerActions(
                                    scale: scale,
                                    isIntroducing: introducing,
                                    isTimedOut: timedOut,
                                    enabled: !paused &&
                                        !busy &&
                                        (introducing || timedOut || canAnswer),
                                    onWrong: () => _checkRegion(
                                        screenWidth, cardProvider, false,
                                        isButton: true),
                                    onCorrect: () => _checkRegion(
                                        screenWidth, cardProvider, true,
                                        isButton: true),
                                    onContinue: () {
                                      if (introducing) {
                                        _acknowledgeIntroduction(context);
                                      } else {
                                        _restartCurrentKarty();
                                      }
                                    },
                                  ),
                            // Sadece debug sürümünde; ana cevaplarla aynı ağırlıkta değil.
                            debugAction: kDebugMode &&
                                    loaded &&
                                    !introducing &&
                                    !timedOut
                                ? TextButton(
                                    onPressed: canAnswer
                                        ? _debugAnswerCorrectly
                                        : null,
                                    style: TextButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF8FA0B5)),
                                    child: KartyDebugAnswerLabel(scale: scale),
                                  )
                                : null,
                            overlays: [
                              if (loaded)
                                KartySuccessCelebration(
                                  key: _successCelebrationKey,
                                  scale: scale,
                                  sourceKey: _boostBottomRightAnchorKey,
                                  targetKey: _boostLeagueTargetKey,
                                ),
                              KartyBoostActivationEffect(
                                key: _boostActivationKey,
                                scale: scale,
                                topLeftSourceKey: _boostTopLeftAnchorKey,
                                bottomRightSourceKey:
                                    _boostBottomRightAnchorKey,
                                targetKey: _boostLeagueTargetKey,
                              ),
                              // Efekt de süreyi durdurur; menü yalnız kullanıcının
                              // duraklatma eylemiyle açılır.
                              if (_pauseMenuOpen)
                                Consumer<ScoreWithLivesProvider>(
                                  builder: (context, scores, _) =>
                                      KartyPauseOverlay(
                                    scale: scale,
                                    level: scores.scoreWithLives?.level ?? 1,
                                    streak: streak,
                                    onResume: _togglePauseMenu,
                                    onExit: _closeKartyScreen,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ));
  }
}
