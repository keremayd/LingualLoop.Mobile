import 'package:json_annotation/json_annotation.dart';

part 'UpdateScoreResponse.g.dart';

@JsonSerializable()
class UpdateScoreResponse {
  final String userId;
  final int score;

  UpdateScoreResponse({required this.userId, required this.score});

  factory UpdateScoreResponse.fromJson(Map<String, dynamic> json) => _$UpdateScoreResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateScoreResponseToJson(this);
}