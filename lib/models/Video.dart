import 'package:json_annotation/json_annotation.dart';
import 'package:lingualloop/models/Question.dart';

part 'Video.g.dart';

@JsonSerializable()
class Video {
  final int? videoId;
  final String videoUrl;
  final String videoTitle;
  final String videoDescription;
  final List<Question>? questions;

//  Video({required this.accessToken, required this.refreshToken});
  Video(this.videoId, this.videoUrl, this.videoTitle, this.videoDescription, this.questions);

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
  Map<String, dynamic> toJson() => _$VideoToJson(this);
}