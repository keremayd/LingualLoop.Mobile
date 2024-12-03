// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'GetQuestionByScoreResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetQuestionByScoreResponse _$GetQuestionByScoreResponseFromJson(
        Map<String, dynamic> json) =>
    GetQuestionByScoreResponse(
      (json['questionId'] as num?)?.toInt(),
      json['questionText'] as String,
      (json['minScore'] as num?)?.toInt(),
      (json['maxScore'] as num?)?.toInt(),
      (json['videoId'] as num?)?.toInt(),
      Video.fromJson(json['video'] as Map<String, dynamic>),
      (json['answers'] as List<dynamic>)
          .map((e) => Answer.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['userVideoHistories'] as String?,
    );

Map<String, dynamic> _$GetQuestionByScoreResponseToJson(
        GetQuestionByScoreResponse instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'questionText': instance.questionText,
      'minScore': instance.minScore,
      'maxScore': instance.maxScore,
      'videoId': instance.videoId,
      'video': instance.video,
      'answers': instance.answers,
      'userVideoHistories': instance.userVideoHistories,
    };
