// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Answer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Answer _$AnswerFromJson(Map<String, dynamic> json) => Answer(
      (json['answerId'] as num?)?.toInt(),
      json['answerText'] as String,
      json['isCorrect'] as bool?,
      (json['questionId'] as num?)?.toInt(),
      json['question'] == null
          ? null
          : Question.fromJson(json['question'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AnswerToJson(Answer instance) => <String, dynamic>{
      'answerId': instance.answerId,
      'answerText': instance.answerText,
      'isCorrect': instance.isCorrect,
      'questionId': instance.questionId,
      'question': instance.question,
    };
