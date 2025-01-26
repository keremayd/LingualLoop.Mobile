import 'package:flutter/material.dart';
import 'package:lingualloop/models/Karty.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:provider/provider.dart';

class KartyProvider with ChangeNotifier {
  final List<Karty> _cards = [];
  bool _isLoaded = false;

  List<Karty> get cards => List.unmodifiable(_cards); // Dışarıdan değiştirilemez liste
  bool get isLoaded => _isLoaded;

  Future<bool> loadCard(BuildContext context) async {
    final kartyService = Provider.of<KartyService>(context, listen: false);

    var apiResponse = await kartyService.random();
    if (apiResponse.errorCode == null) {
      _isLoaded = false;
      notifyListeners();
      _cards.clear();
      _cards.add(
        Karty(kartyUrl: apiResponse.data!.kartyUrl, questionText: apiResponse.data!.questionText, isCorrect: apiResponse.data!.isCorrect),
      );

      _isLoaded = true;
      notifyListeners();
      return true;
    }

    return false;
  }

  void removeTopCard() {
    if (_cards.isNotEmpty) {
      _cards.removeAt(0);
      _isLoaded = false;
      notifyListeners();
    }
  }

  void addNewCard(Karty card) {
    _cards.add(card);
    _isLoaded = true;
    notifyListeners();
  }
}
