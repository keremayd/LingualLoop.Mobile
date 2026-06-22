import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lingualloop/Utils/AppNotifier.dart';
import 'package:lingualloop/providers/KartyProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:lingualloop/ui/widgets/SwipableCard.dart';
import 'package:lingualloop/ui/widgets/karty_boost_multiplier_badge.dart';
import 'package:lingualloop/ui/widgets/karty_review_complete_state.dart';
import 'package:lingualloop/ui/widgets/karty_success_celebration.dart';
import 'package:lingualloop/ui/widgets/karty_time_bar.dart';
import 'package:provider/provider.dart';

import '../../services/UserService.dart';

class KartyQuizScreen extends StatefulWidget {
  final bool reviewMode;

  const KartyQuizScreen({super.key, this.reviewMode = false});

  @override
  _KartyQuizScreenState createState() => _KartyQuizScreenState();
}

class _KartyQuizScreenState extends State<KartyQuizScreen> {
  static const _backgroundColor = Color(0xFF041227);
  static const _panelColor = Color(0xFF0B2143);
  static const _progressColor = Color(0xFF93D334);
  static const _scoreColor = Color(0xFFFF9300);
  static const _streakColor = Color(0xFFFF6536);
  static const _wrongButtonColor = Color(0xFF9B2524);
  static const _rightButtonColor = Color(0xFF659D22);
  static const _boostChargeGoal = 5;
  static const _boostDurationMilliseconds = 20000;

  Offset _position = Offset.zero;
  double _rotation = 0;
  bool _regionAccepted = false; // Bölge kontrolü için flag
  bool _isDeckAdvancing = false;
  bool _isBoostEnergyTransferring = false;
  bool _isReviewEmpty = false;
  bool _didCompleteReviewSession = false;
  int _boostCharge = 0;
  int _boostRemainingMilliseconds = 0;
  bool _isBoostReady = false;
  bool _isBoostActive = false;
  Future<void>? _boostEnergyTransferFuture;
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
  final GlobalKey<KartySuccessCelebrationState> _successCelebrationKey =
      GlobalKey();

  @override
  void initState() {
    super.initState();
    kartyProvider = Provider.of<KartyProvider>(context, listen: false);
    kartyService = Provider.of<KartyService>(context, listen: false);
    userService = Provider.of<UserService>(context, listen: false);

    Future.microtask(() async {
      kartyProvider.reset();
      final isLoaded = await kartyProvider.loadKarty(
        context,
        reviewMode: widget.reviewMode,
      );
      if (isLoaded) {
        duration.value = 4;
        timeBarResetNotifier.value += 1;

        return;
      }

      if (widget.reviewMode && mounted) {
        setState(() {
          _isReviewEmpty = true;
        });
        return;
      }

      print("Karty yüklenirken bir hata oluştu.");
    });
  }

  @override
  void dispose() {
    _boostTimer?.cancel();
    boostProgress.dispose();
    super.dispose();
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

  void _activateBoost() {
    if (!_isBoostReady ||
        _isBoostActive ||
        isPaused.value ||
        isFinished.value) {
      return;
    }

    _boostTimer?.cancel();
    setState(() {
      _isBoostReady = false;
      _isBoostActive = true;
      _boostCharge = 0;
      _boostRemainingMilliseconds = _boostDurationMilliseconds;
      boostProgress.value = 1;
    });

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

  void _beginBoostEnergyTransfer() {
    if (!_isBoostActive || _isBoostEnergyTransferring) return;

    setState(() {
      _isBoostEnergyTransferring = true;
    });
    _boostEnergyTransferFuture =
        Future.delayed(const Duration(milliseconds: 430));
  }

  Future<void> _waitForBoostEnergyTransfer() async {
    final transferFuture = _boostEnergyTransferFuture;
    if (transferFuture != null) {
      await transferFuture;
    }
  }

  Future<void> _answerQuestion(BuildContext context, bool pressedRight) async {
    isFinished.value = true; // TimeBar'ı durdurduk
    _beginBoostEnergyTransfer();
    final currentKarty = kartyProvider.cards[0];
    final isCorrectAnswer = currentKarty.isCorrect && pressedRight ||
        !currentKarty.isCorrect && !pressedRight;

    if (widget.reviewMode) {
      await kartyService.resolveWrongKartyReview(
        currentKarty.kartyId,
        isCorrectAnswer,
      );
      if (!mounted) return;

      if (isCorrectAnswer) {
        setState(() {
          streak += 1;
          duration.value = 0;
        });

        _successCelebrationKey.currentState?.play(
          streak: streak,
          awardedPoints: 0,
          isReviewMode: true,
        );
        isTrueAnswerBlurActive.value = true;
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
      final awardedPoints = _isBoostActive ? 3 : 1;
      var apiResponse = await userService.updateScoreById(awardedPoints);
      if (!mounted) return;
      if (apiResponse.errorCode == null) {
        setState(() {
          streak += 1;
          _recordCorrectBoostAnswer();
          duration.value = 0; // Süreyi tekrar ayarla
        });
        await userService.scoreWithLivesById(context);
        if (!mounted) return;

        await _waitForBoostEnergyTransfer();
        if (!mounted) return;

        _successCelebrationKey.currentState?.play(
          streak: streak,
          awardedPoints: awardedPoints,
        );
        isTrueAnswerBlurActive.value = true;
        await Future.delayed(Duration(seconds: 1));
        if (!mounted) return;

        isTrueAnswerBlurActive.value = false;
        await Future.delayed(Duration(seconds: 1));
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
      await userService.scoreWithLivesById(context);
      if (!mounted) return;

      await _waitForBoostEnergyTransfer();
      if (!mounted) return;

      isFalseAnswerBlurActive.value = true;
      await Future.delayed(Duration(milliseconds: 2000));
      if (!mounted) return;

      isFalseAnswerBlurActive.value = false;
      await Future.delayed(Duration(milliseconds: 600));
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
      print("yeni karty'e geçildi");

      duration.value = 10; // Süreyi tekrar ayarla

      await Future.delayed(Duration(milliseconds: 20));
      timeBarResetNotifier.value += 1;
      isFinished.value = false; // TimeBar'ı başlattık

      return;
    }

    if (widget.reviewMode && mounted) {
      setState(() {
        _didCompleteReviewSession = true;
        _isReviewEmpty = true;
      });
      isFinished.value = true;
      return;
    }

    AppNotifier.showMessage("Karty yüklenirken bir hata oluştu.");
  }

  void _restartCurrentKarty() {
    _boostTimer?.cancel();
    _boostCharge = 0;
    _isBoostReady = false;
    _isBoostActive = false;
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
      _isBoostEnergyTransferring = false;
      _boostEnergyTransferFuture = null;
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

    final transferFuture = _boostEnergyTransferFuture;
    if (transferFuture != null) {
      await transferFuture;
      if (!mounted) return;
    }

    setState(() {
      _isBoostEnergyTransferring = false;
      _boostEnergyTransferFuture = null;
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

  @override
  Widget build(BuildContext context) {
    final cardProvider = Provider.of<KartyProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / 750;
          final canvasHeight = 1624 * scale;
          final height = canvasHeight > constraints.maxHeight
              ? canvasHeight
              : constraints.maxHeight;

          return SizedBox(
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: _isReviewEmpty
                      ? KartyReviewCompleteState(
                          scale: scale,
                          didCompleteSession: _didCompleteReviewSession,
                          onClose: _closeKartyScreen,
                        )
                      : cardProvider.isLoaded && cardProvider.cards.isNotEmpty
                          ? ValueListenableBuilder<bool>(
                              valueListenable: isFinished,
                              builder: (context, isFinishedValue, child) {
                                return ValueListenableBuilder<bool>(
                                  valueListenable: isPaused,
                                  builder: (context, isPausedValue, child) {
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          top: 309 * scale,
                                          child: SwipableCard(
                                            karty: cardProvider.cards.first,
                                            position: _position,
                                            rotation: _rotation,
                                            showRestartState: isFinishedValue,
                                            isAdvancingDeck: _isDeckAdvancing,
                                            isBoostEnergyTransferring:
                                                _isBoostEnergyTransferring,
                                            boostEnabled: !widget.reviewMode,
                                            boostCharge: _boostCharge,
                                            boostChargeGoal: _boostChargeGoal,
                                            isBoostReady: _isBoostReady,
                                            isBoostActive: _isBoostActive,
                                            boostProgress: boostProgress,
                                            onRestart: _restartCurrentKarty,
                                            onBoostTap: _activateBoost,
                                            isTrueAnswerBlurActive:
                                                isTrueAnswerBlurActive,
                                            isFalseAnswerBlurActive:
                                                isFalseAnswerBlurActive,
                                            onPanUpdate: (isFinishedValue ||
                                                    isPausedValue ||
                                                    duration.value == 0 ||
                                                    _isDeckAdvancing)
                                                ? (_) {}
                                                : (details) {
                                                    setState(() {
                                                      _position +=
                                                          details.delta;
                                                      _rotation =
                                                          _position.dx / 300;
                                                    });
                                                  },
                                            onPanEnd: (details) async {
                                              if (!isFinishedValue &&
                                                  !isPausedValue &&
                                                  !_isDeckAdvancing) {
                                                await _checkRegion(
                                                  screenWidth,
                                                  cardProvider,
                                                  null,
                                                  animateSwipeOut: true,
                                                );
                                              }

                                              if (!_regionAccepted) {
                                                _resetCard();
                                              }
                                            },
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: KartySuccessCelebration(
                                            key: _successCelebrationKey,
                                            scale: scale,
                                          ),
                                        ),
                                        Positioned(
                                          left: 232 * scale,
                                          top: 1348 * scale,
                                          child: _KartyAnswerButton(
                                            scale: scale,
                                            iconPath: 'assets/icons/cancel.png',
                                            iconSize: 64,
                                            backgroundColor: _wrongButtonColor,
                                            isVisuallyDisabled: isFinishedValue,
                                            isDisabled: isFinishedValue ||
                                                isPausedValue,
                                            onTap: () async {
                                              await _checkRegion(screenWidth,
                                                  cardProvider, false,
                                                  isButton: true);
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          left: 388 * scale,
                                          top: 1348 * scale,
                                          child: _KartyAnswerButton(
                                            scale: scale,
                                            iconPath:
                                                'assets/icons/correct.png',
                                            iconSize: 66,
                                            backgroundColor: _rightButtonColor,
                                            isVisuallyDisabled: isFinishedValue,
                                            isDisabled: isFinishedValue ||
                                                isPausedValue,
                                            onTap: () async {
                                              await _checkRegion(screenWidth,
                                                  cardProvider, true,
                                                  isButton: true);
                                            },
                                          ),
                                        ),
                                        if (isPausedValue)
                                          Positioned.fill(
                                            child: IgnorePointer(
                                              child: BackdropFilter(
                                                filter: ImageFilter.blur(
                                                    sigmaX: 5, sigmaY: 5),
                                                child: Container(
                                                  color: Colors.black
                                                      .withOpacity(0),
                                                ),
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          left: 342 * scale,
                                          top: 1495 * scale,
                                          child: _KartyPauseButton(
                                            scale: scale,
                                            isPaused: isPausedValue,
                                            isFinished: isFinishedValue,
                                            isVisuallyDisabled: isFinishedValue,
                                            isDisabled: isFinishedValue,
                                            onTap: () async {
                                              isPaused.value = !isPaused.value;
                                              if (isPausedValue) {
                                                _successCelebrationKey
                                                    .currentState
                                                    ?.stop();
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            )
                          : const Center(
                              child: CircularProgressIndicator(
                                color: _progressColor,
                              ),
                            ),
                ),
                if (!_isReviewEmpty)
                  Positioned(
                    left: 40 * scale,
                    right: 40 * scale,
                    top: 155 * scale,
                    child: _KartyTopBar(
                      scale: scale,
                      duration: duration,
                      timeBarResetNotifier: timeBarResetNotifier,
                      isFinished: isFinished,
                      isPaused: isPaused,
                      isBoostActive: _isBoostActive,
                      streak: streak,
                      onClose: _closeKartyScreen,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KartyTopBar extends StatelessWidget {
  const _KartyTopBar({
    required this.scale,
    required this.duration,
    required this.timeBarResetNotifier,
    required this.isFinished,
    required this.isPaused,
    required this.isBoostActive,
    required this.streak,
    required this.onClose,
  });

  final double scale;
  final ValueNotifier<int> duration;
  final ValueNotifier<int> timeBarResetNotifier;
  final ValueNotifier<bool> isFinished;
  final ValueNotifier<bool> isPaused;
  final bool isBoostActive;
  final int streak;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final topBarHeight = 64 * scale;
    final timeBarHeight = 28.16 * scale;
    final timeBarTop = (topBarHeight - timeBarHeight) / 2;

    return SizedBox(
      height: topBarHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 56 * scale,
              height: 56 * scale,
              decoration: BoxDecoration(
                color: _KartyQuizScreenState._panelColor,
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 48 * scale,
              ),
            ),
          ),
          SizedBox(width: 12 * scale),
          SizedBox(
            width: 388 * scale,
            height: topBarHeight,
            child: ValueListenableBuilder<int>(
              valueListenable: duration,
              builder: (context, durationValue, child) {
                if (durationValue == 0) return const SizedBox.shrink();

                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: timeBarTop,
                      child: KartyTimeBar(
                        width: 388 * scale,
                        height: timeBarHeight,
                        duration: duration,
                        onReset: timeBarResetNotifier,
                        isFinished: isFinished,
                        isPaused: isPaused,
                        isBoostActive: isBoostActive,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 44 * scale,
            height: 44 * scale,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/icons/score.png',
                    fit: BoxFit.contain,
                  ),
                ),
                if (isBoostActive)
                  Positioned(
                    top: -12 * scale,
                    right: -12 * scale,
                    child: KartyBoostMultiplierBadge(scale: scale),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8 * scale),
          Consumer<ScoreWithLivesProvider>(
            builder: (context, provider, child) {
              return Text(
                "${provider.scoreWithLives?.score ?? 0}",
                style: TextStyle(
                  color: _KartyQuizScreenState._scoreColor,
                  fontSize: 26 * scale,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                ),
              );
            },
          ),
          SizedBox(width: 25 * scale),
          Image.asset(
            'assets/icons/fire.png',
            width: 44 * scale,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 8 * scale),
          Text(
            "$streak",
            style: TextStyle(
              color: _KartyQuizScreenState._streakColor,
              fontSize: 26 * scale,
              fontWeight: FontWeight.w900,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _KartyAnswerButton extends StatelessWidget {
  const _KartyAnswerButton({
    required this.scale,
    required this.iconPath,
    required this.iconSize,
    required this.backgroundColor,
    required this.isVisuallyDisabled,
    required this.isDisabled,
    required this.onTap,
  });

  final double scale;
  final String iconPath;
  final double iconSize;
  final Color backgroundColor;
  final bool isVisuallyDisabled;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: 130 * scale,
      height: 130 * scale,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28 * scale),
      ),
      child: Center(
        child: Image.asset(
          iconPath,
          width: iconSize * scale,
          height: iconSize * scale,
          color: Colors.white,
          fit: BoxFit.contain,
        ),
      ),
    );

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isVisuallyDisabled ? 0.55 : 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28 * scale),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: isVisuallyDisabled ? 2.4 : 0,
              sigmaY: isVisuallyDisabled ? 2.4 : 0,
            ),
            child: button,
          ),
        ),
      ),
    );
  }
}

class _KartyPauseButton extends StatelessWidget {
  const _KartyPauseButton({
    required this.scale,
    required this.isPaused,
    required this.isFinished,
    required this.isVisuallyDisabled,
    required this.isDisabled,
    required this.onTap,
  });

  final double scale;
  final bool isPaused;
  final bool isFinished;
  final bool isVisuallyDisabled;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: 67 * scale,
      height: 67 * scale,
      decoration: BoxDecoration(
        color: _KartyQuizScreenState._panelColor,
        borderRadius: BorderRadius.circular(30 * scale),
      ),
      child: Center(
        child: Image.asset(
          isPaused ? 'assets/icons/play.png' : 'assets/icons/pause.png',
          width: 32 * scale,
          height: 32 * scale,
          color: Colors.white,
          fit: BoxFit.contain,
        ),
      ),
    );

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isVisuallyDisabled ? 0.55 : 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30 * scale),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: isVisuallyDisabled ? 2.4 : 0,
              sigmaY: isVisuallyDisabled ? 2.4 : 0,
            ),
            child: button,
          ),
        ),
      ),
    );
  }
}
