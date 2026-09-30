import 'package:lingualloop/models/responses/GetKartyByScoreResponse.dart';

class Karty {
  final int kartyId;
  final String kartyUrl;
  final String questionText;
  final String correctText;
  final String article;
  final bool isCorrect;

  /// Telaffuz sesinin adresi. Ses üretilmemişse `null` — buton gizlenir.
  final String? audioUrl;

  /// Kartın nasıl sunulacağı — kararı sunucu veriyor
  /// (`KartyPresentationPolicy`), istemci yalnız uyguluyor.
  ///
  /// Varsayılan `spelling`: eski sunucu sürümü alanı göndermezse kart
  /// bugünkü gibi yazım sorusu olarak davranır.
  final KartyCardMode mode;

  Karty({
    required this.kartyId,
    required this.kartyUrl,
    required this.questionText,
    required this.correctText,
    required this.article,
    required this.isCorrect,
    this.audioUrl,
    this.mode = KartyCardMode.spelling,
  });
}
