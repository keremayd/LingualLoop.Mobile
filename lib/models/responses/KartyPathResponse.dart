import 'package:json_annotation/json_annotation.dart';

part 'KartyPathResponse.g.dart';

/// `GET karty/path/{userId}` — Karty Yolu: üniteler ve desteleri.
/// Görsel adresleri imzalı S3 adresleridir.
@JsonSerializable()
class KartyPathResponse {
  @JsonKey(defaultValue: [])
  final List<KartyPathUnitDto> units;

  /// Bir destedeki kelime sayısı.
  final int deckSize;

  /// Açılıp kutlaması henüz gösterilmemiş ünitenin sırası; yoksa null.
  final int? pendingUnlockSequence;

  KartyPathResponse({
    required this.units,
    required this.deckSize,
    this.pendingUnlockSequence,
  });

  factory KartyPathResponse.fromJson(Map<String, dynamic> json) =>
      _$KartyPathResponseFromJson(json);

  Map<String, dynamic> toJson() => _$KartyPathResponseToJson(this);
}

@JsonSerializable()
class KartyPathUnitDto {
  final int sequence;
  final String title;

  /// `done` · `current` · `open` · `locked`.
  final String state;
  final int wordCount;
  final int consolidatedCount;
  final double unlockGoal;
  final String? emblemUrl;
  @JsonKey(defaultValue: [])
  final List<KartyPathStepDto> steps;

  KartyPathUnitDto({
    required this.sequence,
    required this.title,
    required this.state,
    required this.wordCount,
    required this.consolidatedCount,
    required this.unlockGoal,
    this.emblemUrl,
    required this.steps,
  });

  factory KartyPathUnitDto.fromJson(Map<String, dynamic> json) =>
      _$KartyPathUnitDtoFromJson(json);

  Map<String, dynamic> toJson() => _$KartyPathUnitDtoToJson(this);
}

@JsonSerializable()
class KartyPathStepDto {
  /// `done` · `current` · `upcoming` · `locked`.
  final String state;

  /// Ünite içindeki deste numarası (1'den); yalnız tekrar adımında null.
  final int? deck;
  final int newCount;
  final int newGoal;
  final int reviewCount;
  final int dueCount;
  @JsonKey(defaultValue: [])
  final List<KartyPathWordDto> words;
  @JsonKey(defaultValue: [])
  final List<String> upcomingImageUrls;

  KartyPathStepDto({
    required this.state,
    this.deck,
    required this.newCount,
    required this.newGoal,
    required this.reviewCount,
    required this.dueCount,
    required this.words,
    required this.upcomingImageUrls,
  });

  factory KartyPathStepDto.fromJson(Map<String, dynamic> json) =>
      _$KartyPathStepDtoFromJson(json);

  Map<String, dynamic> toJson() => _$KartyPathStepDtoToJson(this);
}

@JsonSerializable()
class KartyPathWordDto {
  final int kartyId;
  final String nounText;
  final String article;
  final String kartyUrl;
  final int box;
  final bool isDue;

  KartyPathWordDto({
    required this.kartyId,
    required this.nounText,
    required this.article,
    required this.kartyUrl,
    required this.box,
    required this.isDue,
  });

  factory KartyPathWordDto.fromJson(Map<String, dynamic> json) =>
      _$KartyPathWordDtoFromJson(json);

  Map<String, dynamic> toJson() => _$KartyPathWordDtoToJson(this);
}
