import 'package:json_annotation/json_annotation.dart';

part 'GetKartyByScoreResponse.g.dart';

@JsonSerializable()
class GetKartyByScoreResponse {
  final int kartyId;
  final String questionText;
  final String kartyUrl;
  final bool isCorrect;
  final int minScore;
  final int maxScore;

  GetKartyByScoreResponse(this.kartyId, this.questionText, this.kartyUrl, this.isCorrect, this.minScore, this.maxScore);

  factory GetKartyByScoreResponse.fromJson(Map<String, dynamic> json) => _$GetKartyByScoreResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GetKartyByScoreResponseToJson(this);
}