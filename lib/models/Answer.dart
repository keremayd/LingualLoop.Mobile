import 'package:json_annotation/json_annotation.dart';
import 'package:lingualloop/models/Question.dart';

part 'Answer.g.dart';

@JsonSerializable()
class Answer {
  final int? answerId;
  final String answerText;
  final bool? isCorrect;
  final int? questionId;
  final Question? question;

  Answer(this.answerId, this.answerText, this.isCorrect, this.questionId, this.question);

  factory Answer.fromJson(Map<String, dynamic> json) => _$AnswerFromJson(json);
  Map<String, dynamic> toJson() => _$AnswerToJson(this);
}