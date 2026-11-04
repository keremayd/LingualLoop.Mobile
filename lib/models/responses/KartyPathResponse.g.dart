// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'KartyPathResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KartyPathResponse _$KartyPathResponseFromJson(Map<String, dynamic> json) =>
    KartyPathResponse(
      units: (json['units'] as List<dynamic>?)
              ?.map((e) => KartyPathUnitDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dailyNewWordLimit: (json['dailyNewWordLimit'] as num).toInt(),
      tomorrowStartsAtUtc:
          DateTime.parse(json['tomorrowStartsAtUtc'] as String),
    );

Map<String, dynamic> _$KartyPathResponseToJson(KartyPathResponse instance) =>
    <String, dynamic>{
      'units': instance.units,
      'dailyNewWordLimit': instance.dailyNewWordLimit,
      'tomorrowStartsAtUtc': instance.tomorrowStartsAtUtc.toIso8601String(),
    };

KartyPathUnitDto _$KartyPathUnitDtoFromJson(Map<String, dynamic> json) =>
    KartyPathUnitDto(
      sequence: (json['sequence'] as num).toInt(),
      title: json['title'] as String,
      state: json['state'] as String,
      wordCount: (json['wordCount'] as num).toInt(),
      consolidatedCount: (json['consolidatedCount'] as num).toInt(),
      unlockGoal: (json['unlockGoal'] as num).toDouble(),
      emblemUrl: json['emblemUrl'] as String?,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => KartyPathStepDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$KartyPathUnitDtoToJson(KartyPathUnitDto instance) =>
    <String, dynamic>{
      'sequence': instance.sequence,
      'title': instance.title,
      'state': instance.state,
      'wordCount': instance.wordCount,
      'consolidatedCount': instance.consolidatedCount,
      'unlockGoal': instance.unlockGoal,
      'emblemUrl': instance.emblemUrl,
      'steps': instance.steps,
    };

KartyPathStepDto _$KartyPathStepDtoFromJson(Map<String, dynamic> json) =>
    KartyPathStepDto(
      state: json['state'] as String,
      day: json['day'] as String?,
      newCount: (json['newCount'] as num).toInt(),
      newGoal: (json['newGoal'] as num).toInt(),
      reviewCount: (json['reviewCount'] as num).toInt(),
      dueCount: (json['dueCount'] as num).toInt(),
      words: (json['words'] as List<dynamic>?)
              ?.map((e) => KartyPathWordDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      upcomingImageUrls: (json['upcomingImageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$KartyPathStepDtoToJson(KartyPathStepDto instance) =>
    <String, dynamic>{
      'state': instance.state,
      'day': instance.day,
      'newCount': instance.newCount,
      'newGoal': instance.newGoal,
      'reviewCount': instance.reviewCount,
      'dueCount': instance.dueCount,
      'words': instance.words,
      'upcomingImageUrls': instance.upcomingImageUrls,
    };

KartyPathWordDto _$KartyPathWordDtoFromJson(Map<String, dynamic> json) =>
    KartyPathWordDto(
      kartyId: (json['kartyId'] as num).toInt(),
      nounText: json['nounText'] as String,
      article: json['article'] as String,
      kartyUrl: json['kartyUrl'] as String,
      box: (json['box'] as num).toInt(),
      isDue: json['isDue'] as bool,
    );

Map<String, dynamic> _$KartyPathWordDtoToJson(KartyPathWordDto instance) =>
    <String, dynamic>{
      'kartyId': instance.kartyId,
      'nounText': instance.nounText,
      'article': instance.article,
      'kartyUrl': instance.kartyUrl,
      'box': instance.box,
      'isDue': instance.isDue,
    };
