import 'package:json_annotation/json_annotation.dart';

part 'ScoreWithLivesResponse.g.dart';

@JsonSerializable()
class ScoreWithLivesResponse {
  int score;
  int lives;

  ScoreWithLivesResponse({required this.score, required this.lives});

  factory ScoreWithLivesResponse.fromJson(Map<String, dynamic> json) => _$ScoreWithLivesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ScoreWithLivesResponseToJson(this);
}