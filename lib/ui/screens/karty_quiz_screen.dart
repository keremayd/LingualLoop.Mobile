import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lingualloop/Utils/ErrorHandler.dart';
import 'package:lingualloop/models/Karty.dart';
import 'package:lingualloop/providers/KartyProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:lingualloop/ui/widgets/CustomAppBar.dart';
import 'package:lingualloop/ui/widgets/SwipableCard.dart';
import 'package:lingualloop/ui/widgets/TimeBar.dart';
import 'package:provider/provider.dart';

import '../../services/FileService.dart';
import '../../services/UserService.dart';
import '../widgets/CorrectAnimation.dart';
import '../widgets/CustomIconButton.dart';

class KartyQuizScreen extends StatefulWidget {
  @override
  _KartyQuizScreenState createState() => _KartyQuizScreenState();
}

class _KartyQuizScreenState extends State<KartyQuizScreen> {
  Offset _position = Offset.zero;
  double _rotation = 0;
  bool _regionAccepted = false; // Bölge kontrolü için flag
  int streak = 0;
  final ValueNotifier<int> timeBarResetNotifier = ValueNotifier<int>(1);
  late ValueNotifier<int> duration = ValueNotifier<int>(0);
  final ValueNotifier<bool> isFinished = ValueNotifier(false);
  final ValueNotifier<bool> isPaused = ValueNotifier(false);
  final ValueNotifier<bool> isTrueAnswerBlurActive = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isFalseAnswerBlurActive = ValueNotifier<bool>(false);

  late KartyProvider kartyProvider;
  late KartyService kartyService;
  late UserService userService;
  final GlobalKey<CorrectAnimationState> _confettiKey = GlobalKey(); // Confetti Key


  @override
  void initState() {
    super.initState();
    kartyProvider = Provider.of<KartyProvider>(context, listen: false);
    kartyService = Provider.of<KartyService>(context, listen: false);
    userService = Provider.of<UserService>(context, listen: false);

    Future.microtask(() async {

      kartyProvider.removeTopCard();
      final isLoaded = await kartyProvider.loadCard(context);
      if (isLoaded) {
        duration.value = 2;
        timeBarResetNotifier.value += 1;

        return;
      }

      print("Karty yüklenirken bir hata oluştu.");
    });
  }

  Future<void> _answerQuestion(BuildContext context, bool pressedRight) async {
    isFinished.value = true; // TimeBar'ı durdurduk

    // Kupa arttı
    if (kartyProvider.cards[0].isCorrect && pressedRight || !kartyProvider.cards[0].isCorrect && !pressedRight) {
      var apiResponse = await userService.updateScoreById(1);
      if (apiResponse.errorCode == null) {
        setState(() {
          streak += 1;
          duration.value = 0; // Süreyi tekrar ayarla
        });
        await userService.scoreWithLivesById(context);

        _confettiKey.currentState?.play();
        isTrueAnswerBlurActive.value = true;
        await Future.delayed(Duration(seconds: 1));
        isTrueAnswerBlurActive.value = false;

        await Future.delayed(Duration(milliseconds: 20));
        timeBarResetNotifier.value+= 1; // ProgressBar'ı sıfırla
      }

      return;
    }

    // Kupa düştü
    var apiResponse = await userService.updateScoreById(-1);
    if (apiResponse.errorCode == null) {
      setState(() {
        streak = 0;
        duration.value = 0; // Süreyi tekrar ayarla
      });
      await userService.scoreWithLivesById(context);

      isFalseAnswerBlurActive.value = true;
      await Future.delayed(Duration(seconds: 1));
      isFalseAnswerBlurActive.value = false;

      await Future.delayed(Duration(milliseconds: 20));
      timeBarResetNotifier.value+= 1; // ProgressBar'ı sıfırla
    }
  }

  Future<Karty?> _getQuestion(BuildContext context) async {
    final localFileService = Provider.of<LocalFileService>(context, listen: false);

    var apiResponse = await kartyService.random();
    if (apiResponse.errorCode == null) {
      var cacheUrl = await localFileService.cacheKartyImage(apiResponse.data!.kartyUrl, apiResponse.data!.kartyId);

      // Cache'teki kaydettiğimiz adres üzerinden ilerletiyoruz
      return Karty(kartyUrl: cacheUrl, questionText: apiResponse.data!.questionText, isCorrect: apiResponse.data!.isCorrect);
    }

    return null;
  }

  Future<void> _nextKarty(BuildContext context) async {
    var karty = await _getQuestion(context);
    if (karty != null) {
      print("yeni karty'e geçildi");

      kartyProvider.removeTopCard();
      kartyProvider.addNewCard(karty);
      duration.value = 5; // Süreyi tekrar ayarla

      await Future.delayed(Duration(milliseconds: 20));
      timeBarResetNotifier.value+= 1;
      isFinished.value = false; // TimeBar'ı başlattık

      return;
    }

    ErrorHandler.showError("Karty yüklenirken bir hata oluştu.");
  }

  void _resetCard() {
    setState(() {
      _position = Offset.zero;
      _rotation = 0;
      _regionAccepted = false; // Bölge kontrolünü sıfırla
    });
  }

  bool _isInRegion(Offset position, double screenWidth, bool isLeft) {
    if (isLeft) {
      return position.dx < -screenWidth / 2.5; // Sol bölge kontrolü
    }

    return position.dx > screenWidth / 2.5; // Sağ bölge kontrolü
  }

  Future<void> _checkRegion(double screenWidth, KartyProvider cardProvider, bool? pressedRight, {bool isButton = false}) async {
    if (!_regionAccepted) {
      if (isButton && pressedRight != null) {
        if (pressedRight) {
          print("Sağ Buttona Basıldı");

          duration.value = 0;
          _regionAccepted = true; // Bölgeyi kabul et

          await _answerQuestion(context, true);
          await _nextKarty(context);

          _resetCard();
        } else {
          print("Sol Buttona Basıldı");

          duration.value = 0;
          _regionAccepted = true; // Bölgeyi kabul et

          await _answerQuestion(context, false);
          await _nextKarty(context);

          _resetCard();
        }

      }

      if (_isInRegion(_position, screenWidth, false)) {
        print("Sağ Bölgeye Bırakıldı");

        duration.value = 0;
        _regionAccepted = true; // Bölgeyi kabul et

        await _answerQuestion(context, true);
        await _nextKarty(context);

        _resetCard();
      }
      else if (_isInRegion(_position, screenWidth, true)) {
        print("Sol Bölgeye Bırakıldı");

        duration.value = 0;
        _regionAccepted = true; // Bölgeyi kabul et

        await _answerQuestion(context, false);
        await _nextKarty(context);

        _resetCard();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardProvider = Provider.of<KartyProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFF5F5CEF),
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(93),
          child: Column(children: [
            Container(
                margin: EdgeInsets.only(top: 50),
                child: CustomAppBar(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 29,
                          ),
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                if (duration.value != 0)
                                  TimeBar(
                                    duration: duration,
                                    onReset: timeBarResetNotifier,
                                    isFinished: isFinished,
                                    isPaused: isPaused,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/icons/cup.png',
                                  height: 22,
                                  width: 22,
                                ),
                                SizedBox(width: 4),
                                Consumer<ScoreWithLivesProvider>(
                                  builder: (context, provider, child) {
                                    return Text(
                                      "${provider.scoreWithLives?.score}",
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: Color(0xFFF99300),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(width: 20),
                                Image.asset(
                                  'assets/icons/fire.png',
                                  height: 22,
                                  width: 22,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "${streak}",
                                  style: TextStyle(
                                      fontSize: 17,
                                      color: Color(0xFFFF6536),
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    )
                )
            )
          ])),

      body: Center(
        child: cardProvider.isLoaded
            ? ValueListenableBuilder<bool>(
                valueListenable: isFinished,
                builder: (context, isFinishedValue, child) {
                  return ValueListenableBuilder<bool>(
                      valueListenable: isPaused,
                      builder: (context, isPausedValue, child) {
                        return Stack(
                          children: [


                            Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CorrectAnimation(
                                      key: _confettiKey,
                                      numberOfParticles: (streak + 1) * 5,
                                      duration: 1,
                                    ),

                                    ...cardProvider.cards.asMap().entries.map((entry) {
                                      int index = entry.key;
                                      final card = entry.value;

                                      if ((index == 0 && duration.value != 0) && isFinishedValue == false && isPausedValue == false) {
                                        return SwipableCard(
                                          card: card,
                                          position: _position,
                                          rotation: _rotation,
                                          isTrueAnswerBlurActive: isTrueAnswerBlurActive,
                                          isFalseAnswerBlurActive: isFalseAnswerBlurActive,
                                          onPanUpdate: (details) {
                                            setState(() {
                                              _position += details.delta;
                                              _rotation = _position.dx / 300;
                                              _checkRegion(screenWidth, cardProvider, null);
                                            });
                                          },
                                          onPanEnd: (details) {
                                            if (!_regionAccepted) {
                                              _resetCard();
                                            }
                                          },
                                        );
                                      } else {
                                        return Transform.translate(
                                          offset: Offset(0, index * 10.0),
                                          child: SwipableCard(
                                            card: card,
                                            position: Offset.zero,
                                            rotation: 0,
                                            isTrueAnswerBlurActive: isTrueAnswerBlurActive,
                                            isFalseAnswerBlurActive: isFalseAnswerBlurActive,
                                            onPanUpdate: (_) {},
                                            onPanEnd: (_) {},
                                          ),
                                        );
                                      }
                                    }).toList(),
                                  ],
                                ),
                                Spacer(),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 70),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CustomIconButton(
                                            img: 'cancel',
                                            backgroundColor: Color(0xFFDE4343),
                                            iconColor: Colors.white,
                                            buttonSize: 25,
                                            padding: 15,
                                            ontap: isFinishedValue || isPausedValue ? null : () async {
                                              await _checkRegion(screenWidth, cardProvider, false, isButton: true);
                                            },
                                          ),



                                          SizedBox(width: 10),
                                          CustomIconButton(
                                            img: 'correct',
                                            backgroundColor: Color(0xFF4EA42B),
                                            iconColor: Colors.white,
                                            buttonSize: 25,
                                            padding: 15,
                                            ontap: isFinishedValue || isPausedValue ? null : () async {
                                              await _checkRegion(screenWidth, cardProvider, true, isButton: true);
                                            },
                                          ),

                                          if (isPausedValue)
                                            Positioned.fill(
                                              child: BackdropFilter(
                                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Bulanıklık şiddeti
                                                child: Container(
                                                  color: Colors.black.withOpacity(0), // Arka plandaki içerikleri maskeler
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(top: 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            CustomIconButton(
                                              img: 'pause',
                                              clickedImg: 'play',
                                              backgroundColor: Color(0xFF7875FC),
                                              iconColor: Colors.white,
                                              buttonSize: 15,
                                              ontap: isFinishedValue ? null : () async {
                                                isPaused.value = !isPaused.value;
                                                if (isPausedValue) {
                                                  _confettiKey.currentState?.stop();
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                  );
                  },
            )
            : CircularProgressIndicator(),
      ),
    );
  }
}