// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Question _$QuestionFromJson(Map<String, dynamic> json) => Question(
      (json['questionId'] as num).toInt(),
      json['questionText'] as String,
      (json['minScore'] as num).toInt(),
      (json['maxScore'] as num).toInt(),
      Video.fromJson(json['video'] as Map<String, dynamic>),
      (json['answers'] as List<dynamic>)
          .map((e) => Answer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$QuestionToJson(Question instance) => <String, dynamic>{
      'questionId': instance.questionId,
      'questionText': instance.questionText,
      'minScore': instance.minScore,
      'maxScore': instance.maxScore,
      'video': instance.video,
      'answers': instance.answers,
    };
