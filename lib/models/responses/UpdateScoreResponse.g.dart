// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UpdateScoreResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateScoreResponse _$UpdateScoreResponseFromJson(Map<String, dynamic> json) =>
    UpdateScoreResponse(
      userId: json['userId'] as String,
      score: (json['score'] as num).toInt(),
    );

Map<String, dynamic> _$UpdateScoreResponseToJson(
        UpdateScoreResponse instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'score': instance.score,
    };
