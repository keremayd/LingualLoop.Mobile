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

  /// Kelime yazılı, dört görsel arasından doğrusu bulunur.
  @JsonValue('PickImage')
  pickImage,

  /// Görsel ve kelime görünür, artikel sorulur.
  @JsonValue('PickArticle')
  pickArticle,

  /// Görselden kelimenin harfleri sırayla dizilir.
  @JsonValue('ArrangeLetters')
  arrangeLetters,

  /// Kelime yalnız duyulur, dört görsel arasından doğrusu bulunur.
  @JsonValue('Listen')
  listen,
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
class KartyOptionResponse {
  final int kartyId;
  final String kartyUrl;

  KartyOptionResponse(this.kartyId, this.kartyUrl);

  factory KartyOptionResponse.fromJson(Map<String, dynamic> json) =>
      _$KartyOptionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$KartyOptionResponseToJson(this);
}

@JsonSerializable()
class GetKartyByScoreResponse {
  final int kartyId;
  final String correctText;
  final String article;
  final String kartyUrl;
  final int minScore;
  final int maxScore;

  /// Kelimenin Almanca telaffuzu (imzalı URL). Ses henüz üretilmemişse
  /// `null` gelir ve telaffuz butonu gösterilmez.
  final String? audioUrl;

  /// Bilinmeyen mod artikel sorusuna düşer: seçenek ya da ses istemeyen tek soru.
  @JsonKey(defaultValue: KartyCardMode.pickArticle, unknownEnumValue: KartyCardMode.pickArticle)
  final KartyCardMode mode;

  /// Eski sunucu sürümleri göndermiyor; o durumda kart tekrar sayılmaz.
  @JsonKey(defaultValue: KartyCardStage.practice, unknownEnumValue: KartyCardStage.practice)
  final KartyCardStage stage;

  /// Görsel seçilen sorularda seçenekler, doğrusu dahil karışık sırayla.
  @JsonKey(defaultValue: [])
  final List<KartyOptionResponse> options;

  GetKartyByScoreResponse(
    this.kartyId,
    this.correctText,
    this.article,
    this.kartyUrl,
    this.minScore,
    this.maxScore, {
    this.audioUrl,
    this.mode = KartyCardMode.pickArticle,
    this.stage = KartyCardStage.practice,
    this.options = const [],
  });

  factory GetKartyByScoreResponse.fromJson(Map<String, dynamic> json) =>
      _$GetKartyByScoreResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GetKartyByScoreResponseToJson(this);
}
