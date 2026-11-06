import 'package:json_annotation/json_annotation.dart';

part 'GetKartyByScoreResponse.g.dart';

/// Bir Karty kartının **nasıl sunulacağı**.
///
/// Sunucudan metin olarak geliyor; sayı gelseydi enum'a yeni bir mod eklemek
/// sıra değişikliğiyle burada sessizce yanlış moda dönüşebilirdi.
enum KartyCardMode {
  /// Kelimeyle ilk tanışma — soru yok, kelime doğru yazımıyla gösterilir.
  @JsonValue('Introduce')
  introduce,

  /// Yazım sorusu — kelime doğru ya da bozuk yazılmış olabilir.
  @JsonValue('Spelling')
  spelling,
}

/// Kartın hangi aşamadan geldiği (sunucuda `KartyScheduler`). İstemci oyunda
/// verilen tekrarları buradan sayar; sunucu tekrarı oyunun payı kadar,
/// yeni kelimelerle karışık verir.
enum KartyCardStage {
  @JsonValue('review')
  review,
  @JsonValue('test')
  test,

  /// Yeni kelime (sunucuda `new`).
  @JsonValue('new')
  newWord,
  @JsonValue('practice')
  practice,
}

@JsonSerializable()
class GetKartyByScoreResponse {
  final int kartyId;
  final String questionText;
  final String correctText;
  final String article;
  final String kartyUrl;
  final bool isCorrect;
  final int minScore;
  final int maxScore;

  /// Kelimenin Almanca telaffuzu (imzalı URL). Ses henüz üretilmemişse
  /// `null` gelir ve telaffuz butonu gösterilmez.
  final String? audioUrl;

  /// Eski sunucu sürümleri bu alanı göndermiyor; o durumda kart yazım
  /// sorusu olarak davranır — yani bugünkü davranış.
  @JsonKey(defaultValue: KartyCardMode.spelling, unknownEnumValue: KartyCardMode.spelling)
  final KartyCardMode mode;

  /// Eski sunucu sürümleri göndermiyor; o durumda kart tekrar sayılmaz.
  @JsonKey(defaultValue: KartyCardStage.practice, unknownEnumValue: KartyCardStage.practice)
  final KartyCardStage stage;

  GetKartyByScoreResponse(
    this.kartyId,
    this.questionText,
    this.correctText,
    this.article,
    this.kartyUrl,
    this.isCorrect,
    this.minScore,
    this.maxScore, {
    this.audioUrl,
    this.mode = KartyCardMode.spelling,
    this.stage = KartyCardStage.practice,
  });

  factory GetKartyByScoreResponse.fromJson(Map<String, dynamic> json) =>
      _$GetKartyByScoreResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GetKartyByScoreResponseToJson(this);
}
