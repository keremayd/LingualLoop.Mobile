// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ScoreWithLivesResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScoreWithLivesResponse _$ScoreWithLivesResponseFromJson(
        Map<String, dynamic> json) =>
    ScoreWithLivesResponse(
      score: (json['score'] as num).toInt(),
      lives: (json['lives'] as num).toInt(),
    );

Map<String, dynamic> _$ScoreWithLivesResponseToJson(
        ScoreWithLivesResponse instance) =>
    <String, dynamic>{
      'score': instance.score,
      'lives': instance.lives,
    };
