import 'package:json_annotation/json_annotation.dart';
import 'package:lingualloop/models/responses/KartyPathResponse.dart';

part 'KartySessionStatusResponse.g.dart';

/// `GET karty/session/{userId}` — oyunun "bitti mi" sorusunun cevabı ve
/// özet ekranının sunucudan gelen kısmı.
@JsonSerializable()
class KartySessionStatusResponse {
  /// Deste bitti (her kelimesi en az bir kez doğru) ve vadesi gelmiş tekrar yok.
  final bool complete;
  final int dueReviews;
  final int deckSize;
  final int deckIntroduced;
  final int deckTested;

  /// Destenin bütün kelimeleri, deste sırasıyla; görsel adresleri imzalı.
  @JsonKey(defaultValue: [])
  final List<KartyPathWordDto> words;

  /// Ünitenin şimdiki pekişen kelime sayısı.
  final int unitConsolidated;
  final int unitWordCount;

  KartySessionStatusResponse({
    required this.complete,
    required this.dueReviews,
    required this.deckSize,
    required this.deckIntroduced,
    required this.deckTested,
    required this.words,
    required this.unitConsolidated,
    required this.unitWordCount,
  });

  factory KartySessionStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$KartySessionStatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$KartySessionStatusResponseToJson(this);
}
