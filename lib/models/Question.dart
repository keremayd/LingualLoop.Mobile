import 'package:json_annotation/json_annotation.dart';
import 'package:lingualloop/models/Answer.dart';
import 'package:lingualloop/models/Video.dart';

part 'Question.g.dart';

@JsonSerializable()
class Question {
  final int questionId;
  final String questionText;
  final int minScore;
  final int maxScore;
  final Video video;
  final List<Answer> answers;

//  Video({required this.accessToken, required this.refreshToken});
  Question(this.questionId, this.questionText, this.minScore, this.maxScore, this.video, this.answers);

  factory Question.fromJson(Map<String, dynamic> json) => _$QuestionFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionToJson(this);
}