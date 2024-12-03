import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/User.dart';
import 'package:lingualloop/providers/UserProvider.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/services/auth_service.dart';
import 'package:lingualloop/services/question_service.dart';
import 'package:provider/provider.dart';

import '../../models/responses/GetQuestionByScoreResponse.dart';
import '../widgets/AnswerButton.dart';

class VideoQuizScreen extends StatefulWidget {
  @override
  _VideoQuizScreenState createState() => _VideoQuizScreenState();
}

class _VideoQuizScreenState extends State<VideoQuizScreen> {
  bool isAnswered = false;
  String aButton = "";
  String bButton = "";
  var userNickname = "";
  User? user;

  ApiResponse<GetQuestionByScoreResponse>? question;

  @override
  void initState() {
    super.initState();
    _getQuestion(context);
    _getUser(context);
  }

  Future<void> _getUser(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    user = userProvider.user!;
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
      var correctAnswerText = question!.data!.answers
          .where((x) => x.isCorrect == true)
          .map((x) => x.answerText)
          .firstOrNull;

      if (correctAnswerText != pressedButton) {
        print("Puan düştü!");
        var apiResponse = await userService.updateScoreById(-1);
        return;
      }

      print("Puan arttı!");
      var apiResponse = await userService.updateScoreById(1);
      if(apiResponse.errorCode == null){
        await _getQuestion(context);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Video Quiz")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Butonları yatay olarak ortalar
              children: [
                  AnswerButton(
                    text: aButton,
                    onPressed: () => _answerQuestion(context, aButton),
                  ),
                SizedBox(width: 20), // Butonlar arasında boşluk bırakır
                AnswerButton(
                    text: bButton,
                    onPressed: () => _answerQuestion(context, bButton),
                  ),
              ],
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _getQuestion(context),
                  child: Text('Get Question'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
