import 'package:json_annotation/json_annotation.dart';

part 'UpdateLivesResponse.g.dart';

@JsonSerializable()
class UpdateLivesResponse {
  final String userId;
  final int lives;

  UpdateLivesResponse({required this.userId, required this.lives});

  factory UpdateLivesResponse.fromJson(Map<String, dynamic> json) => _$UpdateLivesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateLivesResponseToJson(this);
}