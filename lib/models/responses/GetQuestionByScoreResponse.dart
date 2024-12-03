import 'package:json_annotation/json_annotation.dart';
import 'package:lingualloop/models/Answer.dart';
import 'package:lingualloop/models/Video.dart';

part 'GetQuestionByScoreResponse.g.dart';

@JsonSerializable()
class GetQuestionByScoreResponse {
  final int? questionId;
  final String questionText;
  final int? minScore;
  final int? maxScore;
  final int? videoId;
  final Video video;
  final List<Answer> answers;
  final String? userVideoHistories;

  GetQuestionByScoreResponse(this.questionId, this.questionText, this.minScore, this.maxScore, this.videoId, this.video, this.answers, this.userVideoHistories);

  factory GetQuestionByScoreResponse.fromJson(Map<String, dynamic> json) => _$GetQuestionByScoreResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GetQuestionByScoreResponseToJson(this);
}