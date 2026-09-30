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
  });

  factory GetKartyByScoreResponse.fromJson(Map<String, dynamic> json) =>
      _$GetKartyByScoreResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GetKartyByScoreResponseToJson(this);
}
