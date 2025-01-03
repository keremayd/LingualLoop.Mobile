import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/User.dart';
import 'package:lingualloop/models/responses/ScoreWithLivesResponse.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/providers/UserProvider.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/services/auth_service.dart';
import 'package:lingualloop/services/question_service.dart';
import 'package:lingualloop/ui/widgets/CurvedDesign.dart';
import 'package:lingualloop/ui/widgets/CustomIconButton.dart';
import 'package:lingualloop/ui/widgets/ProgressBar.dart';
import 'package:provider/provider.dart';

import '../../models/responses/GetQuestionByScoreResponse.dart';
import '../widgets/AnswerButton.dart';
import '../widgets/CustomAppBar.dart';

class VideoQuizScreen extends StatefulWidget {
  @override
  _VideoQuizScreenState createState() => _VideoQuizScreenState();
}

class _VideoQuizScreenState extends State<VideoQuizScreen> {
  int streak = 0;
  late int duration;
  String aButton = "";
  String bButton = "";
  bool isLoading = true;
  bool isAnswered = false;
  var userNickname = "";
  User? user;
  ScoreWithLivesResponse? scoreWithLives;
  final ValueNotifier<int> progressBarResetNotifier = ValueNotifier<int>(1);
  final ValueNotifier<int> durationNotifier = ValueNotifier<int>(3);
  final ValueNotifier<bool> isCountdownFinished = ValueNotifier(false);
  ApiResponse<GetQuestionByScoreResponse>? question;
  Map<String, Color> buttonsColor = {};
  late Color textColors;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
    });
    await _getQuestion(context);
    await _getUser(context);
    await _getScoreWithLives(context);
    setState(() {
      duration = 4;
      isLoading = false;
    });
  }

  Future<void> _getUser(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    user = userProvider.user!;
  }

  Future<void> _getScoreWithLives(BuildContext context) async {
    final userService = Provider.of<UserService>(context, listen: false);
    final scoreWithLivesProvider = Provider.of<ScoreWithLivesProvider>(context, listen: false);

    await userService.scoreWithLivesById(context);
    scoreWithLives = scoreWithLivesProvider.scoreWithLives;
  }

  Future<void> _getQuestion(BuildContext context) async {
    final questionService = Provider.of<QuestionService>(context, listen: false);
    question = await questionService.random();

    setState(() {
      aButton = question!.data!.answers[0].answerText;
      bButton = question!.data!.answers[1].answerText;
      textColors = Color(0xFF5F5CEF);
      buttonsColor = {
        aButton: Colors.transparent,
        bButton: Colors.transparent,
      };
    });
  }

  Future<void> _answerQuestion(BuildContext context, String pressedButton) async {
    final questionService = Provider.of<QuestionService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    final scoreWithLivesProvider = Provider.of<ScoreWithLivesProvider>(context, listen: false);

    var correctAnswerText = question!.data!.answers
        .where((x) => x.isCorrect == true)
        .map((x) => x.answerText)
        .firstOrNull;

    isCountdownFinished.value = true;

    if (correctAnswerText != pressedButton) {
      // Kupa düştü
      var apiResponse = await userService.updateScoreById(-1);
      if (apiResponse.errorCode == null) {
        setState(() {
          streak = 0;
          scoreWithLives!.score += -1;
          scoreWithLivesProvider.setScoreWithLives(scoreWithLives);
          duration = 0; // Süreyi tekrar ayarla
        });
        await Future.delayed(Duration(milliseconds: 20));
        progressBarResetNotifier.value+= 1; // ProgressBar'ı sıfırla

      }
      return;
    }

    // Kupa arttı
    var apiResponse = await userService.updateScoreById(1);
    if (apiResponse.errorCode == null) {
      setState(() {
        streak += 1;
        scoreWithLives!.score += 1;
        scoreWithLivesProvider.setScoreWithLives(scoreWithLives);
        duration = 0; // Süreyi tekrar ayarla
      });
      await Future.delayed(Duration(milliseconds: 20));
      progressBarResetNotifier.value+= 1; // ProgressBar'ı sıfırla
    }

  }

  void _updateButtonBorder() {
    var correctAnswerText = question!.data!.answers
        .where((x) => x.isCorrect == true)
        .map((x) => x.answerText)
        .firstOrNull;

    buttonsColor = {
      aButton: (aButton == correctAnswerText) ? Color(0xFF67D445) : Color(0xFFFF6536),
      bButton: (bButton == correctAnswerText) ? Color(0xFF67D445) : Color(0xFFFF6536),
    };
    textColors = Colors.white;
  }

  Future<void> _test(BuildContext context) async {
    await _getQuestion(context);
    isCountdownFinished.value = false;

    print("yeni videoya geçildi");

    duration = 5; // Süreyi tekrar ayarla

    await Future.delayed(Duration(milliseconds: 20));
    progressBarResetNotifier.value+= 1;

  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        color: Color(0xFF5F5CEF),
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF5F5CEF),
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(93),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(
                  top: 50, // 50
                ),
                child: CustomAppBar(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            GestureDetector(
                              onTap:(){
                                Navigator.pop(context);
                              },
                              child:Icon(Icons.close_rounded, color: Colors.white, size: 29)
                            ),

                          ],
                        ),

                        Column(
                          children: [
                            Row(
                              children: [
                                if (duration != 0)
                                  ProgressBar(
                                    duration: duration, // 10 saniye geri sayım
                                    isCountdownFinished: isCountdownFinished,
                                    onReset: progressBarResetNotifier,
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
                            Text(
                              "${scoreWithLives?.score}",
                              style: TextStyle(
                                  fontSize: 17,
                                  color: Color(0xFFF99300),
                                  fontWeight: FontWeight.w600),
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
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 300,
            margin: EdgeInsets.only(left: 16, right: 16),
            decoration: BoxDecoration(
              color: Color(0xFF7875FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    ValueListenableBuilder<bool>(
              valueListenable: isCountdownFinished,
              builder: (context, value, child) {
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: duration == 0 || value
                        ? Align(
                      alignment: Alignment.centerRight, // Sağ ortada
                      child: CustomIconButton(
                        img: 'next',
                        clickedImg: 'next',
                        backgroundColor: Colors.white,
                        iconColor: Colors.grey,
                        ontap: () => _test(context),
                      ),
                    )
                        : null,
                  ),
                );
              },
            ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconButton(
                                img: 'info',
                                clickedImg: 'info',
                                backgroundColor: Colors.white,
                                iconColor: Colors.grey,
                              ),
                              SizedBox(width: 10),
                              CustomIconButton(
                                img: 'subtitleopen',
                                clickedImg: 'subtitleclose',
                                backgroundColor: Colors.white,
                                iconColor: Colors.grey,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconButton(
                                img: 'bookmark',
                                clickedImg: 'bookmark',
                                backgroundColor: Colors.white,
                                iconColor: Colors.grey,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          CustomDesignWidget(),
          Expanded(
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF7875FC),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 32),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "Süre tükenmeden yanıtını seç!",
                            style: TextStyle(
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Spacer(),
                      ValueListenableBuilder<bool>(
                        valueListenable: isCountdownFinished,
                        builder: (context, value, child) {
                          if (value) {
                            _updateButtonBorder();
                          }
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnswerButton(
                                    text: aButton,
                                    onPressed: value ? null : () => _answerQuestion(context, aButton),
                                    buttonDisabledColor: buttonsColor[aButton]!,
                                    textColor: textColors,
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),
                              Text(
                                "veya",
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Color(0xFF5F5CEF),
                                    fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnswerButton(
                                    text: bButton,
                                    onPressed: value ? null : () => _answerQuestion(context, bButton),
                                    buttonDisabledColor: buttonsColor[bButton]!,
                                    textColor: textColors,
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
