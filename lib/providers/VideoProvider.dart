import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lingualloop/models/responses/GetQuestionByScoreResponse.dart';
import 'package:lingualloop/services/VideoService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/models/ApiResponse.dart';

import '../models/responses/GetSavedVideosByIdResponse.dart';

class VideoProvider with ChangeNotifier {
  GetQuestionByScoreResponse? question;
  final List<GetSavedVideosByIdResponse> _savedVideos = [];
  List<GetSavedVideosByIdResponse> get savedVideos => List.unmodifiable(_savedVideos); // Dışarıdan değiştirilemez liste

  String aButton = "";
  String bButton = "";
  Map<String, Color> buttonsColor = {};
  Color textColor = const Color(0xFF5F5CEF);

  int streak = 0;
  bool isLoading = true;

  // TimeBar ile bağlantı için ValueNotifier'ları dışarı açıyoruz,
  // böylece UI doğrudan bunlara bağlanabilir (eski ekrana maksimum uyumluluk).
  final ValueNotifier<int> timeBarResetNotifier = ValueNotifier<int>(1);
  final ValueNotifier<int> duration = ValueNotifier<int>(4);
  final ValueNotifier<bool> isFinished = ValueNotifier<bool>(false);

  VideoProvider() {
    // isFinished'ın değişimlerini dinle, true olunca buton renklerini güncelle
    isFinished.addListener(() {
      if (isFinished.value) {
        updateButtonBorder();
      }
    });
  }

  Future<bool> getSavedVideos(BuildContext context) async {
    final videoService = Provider.of<VideoService>(context, listen: false);

    _savedVideos.clear();
    var apiResponse = await videoService.savedVideos();
    if (apiResponse.errorCode == null) {
      isLoading = true;
      notifyListeners();

      for (var savedVideo in apiResponse.data!) {
        _savedVideos.add(
          GetSavedVideosByIdResponse(
            userVideoId: savedVideo.userVideoId,
            userId: savedVideo.userId,
            video: savedVideo.video,
            savedDate: savedVideo.savedDate,
          ),
        );
      }

      isLoading = false;
      notifyListeners();
      return true;
    }

    return false;
  }

  /// Başlangıç mantığını çalıştır (screen initState içinde çağrılacak)
  Future<void> init(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    // Soru çek + scoreWithLives bilgisi güncelle
    await getQuestion(context);

    final userService = Provider.of<UserService>(context, listen: false);
    await userService.scoreWithLivesById(context);

    isLoading = false;
    notifyListeners();
  }

  Future<void> getQuestion(BuildContext context) async {
    final videoService = Provider.of<VideoService>(context, listen: false);
    final ApiResponse<GetQuestionByScoreResponse> apiResponse = await videoService.random();

    if (apiResponse.errorCode == null) {
      question = apiResponse.data;
      _setButtonsFromQuestion();

      // reset timebar
      duration.value = 4;
      isFinished.value = false;
      await Future.delayed(Duration(milliseconds: 20));
      timeBarResetNotifier.value += 1;

      notifyListeners();
    } else {
      // hata durumunda istenirse işlemler eklenebilir
      // örn: toast/alert göstermek vs.
    }
  }

  void _setButtonsFromQuestion() {
    if (question == null || (question!.answers?.length ?? 0) < 2) {
      aButton = "";
      bButton = "";
      buttonsColor = { aButton: Colors.transparent, bButton: Colors.transparent };
      textColor = const Color(0xFF5F5CEF);
      return;
    }

    // ilk iki cevabı alıyoruz (mevcut ekran mantığına göre)
    aButton = question!.answers[0].answerText;
    bButton = question!.answers[1].answerText;
    textColor = const Color(0xFF5F5CEF);
    buttonsColor = {
      aButton: Colors.transparent,
      bButton: Colors.transparent,
    };
  }

  /// Cevabı kontrol et ve score'u güncelle
  Future<void> answerQuestion(BuildContext context, String pressedButton) async {
    if (question == null) return;

    final userService = Provider.of<UserService>(context, listen: false);

    // doğru cevabı bul
    String correctAnswerText = "";
    try {
      correctAnswerText = question!.answers!
          .firstWhere((x) => x.isCorrect == true)
          .answerText!;
    } catch (ex) {
      // fallback (hata durumunda çık)
      return;
    }

    isFinished.value = true;

    if (correctAnswerText != pressedButton) {
      // yanlış
      var apiResponse = await userService.updateScoreById(-1);
      if (apiResponse.errorCode == null) {
        streak = 0;
        duration.value = 0;
        await userService.scoreWithLivesById(context);

        await Future.delayed(Duration(milliseconds: 20));
        timeBarResetNotifier.value += 1;

        notifyListeners();
      }
      return;
    }

    // doğru
    var apiResponse = await userService.updateScoreById(1);
    if (apiResponse.errorCode == null) {
      streak += 1;
      duration.value = 0;
      await userService.scoreWithLivesById(context);

      await Future.delayed(Duration(milliseconds: 20));
      timeBarResetNotifier.value += 1;

      notifyListeners();
    }
  }

  /// isFinished true olduğunda buton border'larını güncelle
  void updateButtonBorder() {
    if (question == null) return;

    String correctAnswerText = "";
    try {
      correctAnswerText = question!.answers!
          .firstWhere((x) => x.isCorrect == true)
          .answerText!;
    } catch (e) {
      return;
    }

    buttonsColor = {
      aButton: (aButton == correctAnswerText) ? const Color(0xFF67D445) : const Color(0xFFFF6536),
      bButton: (bButton == correctAnswerText) ? const Color(0xFF67D445) : const Color(0xFFFF6536),
    };
    textColor = Colors.white;
  }

  Future<void> nextVideo(BuildContext context) async {
    await getQuestion(context);
    isFinished.value = false;

    // yeni videoya geçtiğinde süreyi ayarla
    duration.value = 5;
    await Future.delayed(Duration(milliseconds: 20));
    timeBarResetNotifier.value += 1;

    notifyListeners();
  }
}
