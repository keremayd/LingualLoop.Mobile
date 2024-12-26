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
  String aButton = "";
  String bButton = "";
  bool isLoading = true;
  bool isAnswered = false;
  var userNickname = "";
  User? user;
  ScoreWithLivesResponse? scoreWithLives;
  final ValueNotifier<bool> isCountdownFinished = ValueNotifier(false);
  ApiResponse<GetQuestionByScoreResponse>? question;

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

    if (correctAnswerText != pressedButton) {
      // Kupa düştü
      var apiResponse = await userService.updateScoreById(-1);
      if(apiResponse.errorCode == null){
        setState(() {
          streak = 0;
          scoreWithLives!.score += -1;
          scoreWithLivesProvider.setScoreWithLives(scoreWithLives);
        });

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
      });

      await _getQuestion(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        color: Color(0xFF5F5CEF),
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.white, // Yükleme göstergesinin renk
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
                                ProgressBar(
                                  duration: 10, // 10 saniye geri sayım
                                  isCountdownFinished: isCountdownFinished,
                                ),
                              ],
                            )
                          ],
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/icons/cup.png', // Coin simgesi
                                  height: 22, // 22
                                  width: 22, // 22
                                ),
                                SizedBox(width: 4), // İkon ile sayı arasında boşluk
                                Text(
                                  "${scoreWithLives?.score}", // Sayı
                                  style: TextStyle(
                                    fontSize: 17, // Yazı boyutu
                                    color: Color(0xFFF99300), // Yazı rengi
                                    fontWeight: FontWeight.w600
                                  ),
                                ),
                                SizedBox(width: 20),


                                Image.asset(
                                  'assets/icons/fire.png', // Coin simgesi
                                  height: 22, // 22
                                  width: 22, // 22
                                ),
                                SizedBox(width: 4), // İkon ile sayı arasında boşluk
                                Text(
                                  "${streak}", // Sayı
                                  style: TextStyle(
                                    fontSize: 17, // Yazı boyutu
                                    color: Color(0xFFFF6536), // Yazı rengi
                                    fontWeight: FontWeight.w600
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ],
                    )
                ),
              ),
            ],
          )
        ),
        
        body: Column(
          children: [
            Container(
              height: 300,
              margin: EdgeInsets.only(
                left: 16, // Kenar boşlukları
                right: 16, // Kenar boşlukları
              ),
              decoration: BoxDecoration(
                color: Color(0xFF7875FC), // Mor arka plan
                borderRadius: BorderRadius.circular(14), // Yuvarlak köşeler
              ),
              child: Column(
                children: [
                  // Üstteki Beyaz Alan
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white, // Beyaz arka plan
                        borderRadius: BorderRadius.circular(12), // İç köşeleri yuvarla
                      ),

                    ),
                  ),

                  // Alttaki İkon Butonlar
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:
                      [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center, // İkonları orta
                          children: [
                            CustomIconButton(
                              img: 'subtitleclose',
                              clickedImg: 'subtitleclose',
                              backgroundColor: Colors.white,
                              iconColor: Colors.grey,
                            ),
                            SizedBox(width: 10), // İkonlar arasında boşluk
                            CustomIconButton(
                              img: 'subtitleopen',
                              clickedImg: 'subtitleclose',
                              backgroundColor: Colors.white,
                              iconColor: Colors.grey,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center, // İkonları ortal
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
                  )
                ],
              ),
            ),

            CustomDesignWidget(),

            Expanded(
                child: Center(
                  child:  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF7875FC), // Arka plan rengi
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 32),
                      // Her taraftan 14 piksel padding
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Süre tükenmeden yanıtını seç!", // Sayı
                                style: TextStyle(
                                    fontSize: 22, // Yazı boyutu
                                    color: Colors.white, // Yazı rengi
                                    fontWeight: FontWeight.w600
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10), // Butonlar arasında boşluk bırakır
                          Spacer(),




                          ValueListenableBuilder<bool>(
                            valueListenable: isCountdownFinished,
                            builder: (context, value, child) {
                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnswerButton(
                                        text: aButton,
                                        onPressed: value ? null : () => _answerQuestion(context, aButton),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 5), // Butonlar arasında boşluk bırakır
                                  Text(
                                    "veya", // Sayı
                                    style: TextStyle(
                                        fontSize: 20, // Yazı boyutu
                                        color: Color(0xFF5F5CEF), // Yazı rengi
                                        fontWeight: FontWeight.w600
                                    ),
                                  ),
                                  SizedBox(height: 5), // Butonlar arasında boşluk bırakır

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnswerButton(
                                        text: bButton,
                                        onPressed: value ? null : () => _answerQuestion(context, bButton),
                                      )
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
                )
            )
          ],
        )
    );
  }
}
