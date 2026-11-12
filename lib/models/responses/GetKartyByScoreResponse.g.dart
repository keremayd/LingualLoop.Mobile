// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'GetKartyByScoreResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KartyOptionResponse _$KartyOptionResponseFromJson(Map<String, dynamic> json) =>
    KartyOptionResponse(
      (json['kartyId'] as num).toInt(),
      json['kartyUrl'] as String,
    );

Map<String, dynamic> _$KartyOptionResponseToJson(
        KartyOptionResponse instance) =>
    <String, dynamic>{
      'kartyId': instance.kartyId,
      'kartyUrl': instance.kartyUrl,
    };

GetKartyByScoreResponse _$GetKartyByScoreResponseFromJson(
        Map<String, dynamic> json) =>
    GetKartyByScoreResponse(
      (json['kartyId'] as num).toInt(),
      json['correctText'] as String,
      json['article'] as String,
      json['kartyUrl'] as String,
      (json['minScore'] as num).toInt(),
      (json['maxScore'] as num).toInt(),
      audioUrl: json['audioUrl'] as String?,
      mode: $enumDecodeNullable(_$KartyCardModeEnumMap, json['mode'],
              unknownValue: KartyCardMode.pickArticle) ??
          KartyCardMode.pickArticle,
      stage: $enumDecodeNullable(_$KartyCardStageEnumMap, json['stage'],
              unknownValue: KartyCardStage.practice) ??
          KartyCardStage.practice,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) =>
                  KartyOptionResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$GetKartyByScoreResponseToJson(
        GetKartyByScoreResponse instance) =>
    <String, dynamic>{
      'kartyId': instance.kartyId,
      'correctText': instance.correctText,
      'article': instance.article,
      'kartyUrl': instance.kartyUrl,
      'minScore': instance.minScore,
      'maxScore': instance.maxScore,
      'audioUrl': instance.audioUrl,
      'mode': _$KartyCardModeEnumMap[instance.mode]!,
      'stage': _$KartyCardStageEnumMap[instance.stage]!,
      'options': instance.options,
    };

const _$KartyCardModeEnumMap = {
  KartyCardMode.introduce: 'Introduce',
  KartyCardMode.pickImage: 'PickImage',
  KartyCardMode.pickArticle: 'PickArticle',
  KartyCardMode.arrangeLetters: 'ArrangeLetters',
  KartyCardMode.listen: 'Listen',
};

const _$KartyCardStageEnumMap = {
  KartyCardStage.review: 'review',
  KartyCardStage.test: 'test',
  KartyCardStage.newWord: 'new',
  KartyCardStage.practice: 'practice',
};
