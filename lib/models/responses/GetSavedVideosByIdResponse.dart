import 'package:json_annotation/json_annotation.dart';
import 'package:lingualloop/models/Video.dart';

part 'GetSavedVideosByIdResponse.g.dart';

@JsonSerializable()
class GetSavedVideosByIdResponse {
  final int userVideoId;
  final String userId;
  final Video video;
  final DateTime savedDate;

  GetSavedVideosByIdResponse({required this.userVideoId, required this.userId, required this.video, required this.savedDate});

  factory GetSavedVideosByIdResponse.fromJson(Map<String, dynamic> json) => _$GetSavedVideosByIdResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GetSavedVideosByIdResponseToJson(this);
}