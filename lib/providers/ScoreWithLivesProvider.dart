import 'package:flutter/material.dart';
import 'package:lingualloop/models/User.dart';
import 'package:lingualloop/models/responses/ScoreWithLivesResponse.dart';

class ScoreWithLivesProvider with ChangeNotifier {
  ScoreWithLivesResponse? _scoreWithLives;

  ScoreWithLivesResponse? get scoreWithLives => _scoreWithLives;

  void setScoreWithLives(ScoreWithLivesResponse? scoreWithLives) {
    if (_scoreWithLives == null || _scoreWithLives != scoreWithLives) {
      _scoreWithLives = scoreWithLives;
      notifyListeners();
    }
  }

  void clearScoreWithLives() {
    _scoreWithLives = null;
    notifyListeners();
  }
}
