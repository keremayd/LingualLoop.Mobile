import 'package:lingualloop/models/responses/GetKartyByScoreResponse.dart';

/// Görsel seçilen soruda bir seçenek; görsel önbellekteki dosyadır.
class KartyOption {
  const KartyOption({required this.kartyId, required this.imagePath});

  final int kartyId;
  final String imagePath;
}

class Karty {
  final int kartyId;
  final String kartyUrl;
  final String correctText;
  final String article;

  /// Telaffuz sesinin adresi. Ses üretilmemişse `null` — buton gizlenir.
  final String? audioUrl;

  /// Kartın nasıl sunulacağı — kararı sunucu veriyor
  /// (`KartyPresentationPolicy`), istemci yalnız uyguluyor.
  ///
  final KartyCardMode mode;

  /// Kartın hangi aşamadan geldiği; oyunun tekrar sayısı buradan tutulur.
  final KartyCardStage stage;

  /// Görsel seçilen soruların seçenekleri, doğrusu dahil.
  final List<KartyOption> options;

  Karty({
    required this.kartyId,
    required this.kartyUrl,
    required this.correctText,
    required this.article,
    this.audioUrl,
    this.mode = KartyCardMode.pickArticle,
    this.stage = KartyCardStage.practice,
    this.options = const [],
  });
}
