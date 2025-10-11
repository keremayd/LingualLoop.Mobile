// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'GetKartyByScoreResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetKartyByScoreResponse _$GetKartyByScoreResponseFromJson(
        Map<String, dynamic> json) =>
    GetKartyByScoreResponse(
      (json['kartyId'] as num).toInt(),
      json['questionText'] as String,
      json['correctText'] as String,
      json['kartyUrl'] as String,
      json['isCorrect'] as bool,
      (json['minScore'] as num).toInt(),
      (json['maxScore'] as num).toInt(),
    );

Map<String, dynamic> _$GetKartyByScoreResponseToJson(
        GetKartyByScoreResponse instance) =>
    <String, dynamic>{
      'kartyId': instance.kartyId,
      'questionText': instance.questionText,
      'correctText': instance.questionText,
      'kartyUrl': instance.kartyUrl,
      'isCorrect': instance.isCorrect,
      'minScore': instance.minScore,
      'maxScore': instance.maxScore,
    };
