// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'KartySessionStatusResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KartySessionStatusResponse _$KartySessionStatusResponseFromJson(
        Map<String, dynamic> json) =>
    KartySessionStatusResponse(
      complete: json['complete'] as bool,
      dueReviews: (json['dueReviews'] as num).toInt(),
      deckSize: (json['deckSize'] as num).toInt(),
      deckIntroduced: (json['deckIntroduced'] as num).toInt(),
      deckTested: (json['deckTested'] as num).toInt(),
      words: (json['words'] as List<dynamic>?)
              ?.map((e) => KartyPathWordDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      unitConsolidated: (json['unitConsolidated'] as num).toInt(),
      unitWordCount: (json['unitWordCount'] as num).toInt(),
    );

Map<String, dynamic> _$KartySessionStatusResponseToJson(
        KartySessionStatusResponse instance) =>
    <String, dynamic>{
      'complete': instance.complete,
      'dueReviews': instance.dueReviews,
      'deckSize': instance.deckSize,
      'deckIntroduced': instance.deckIntroduced,
      'deckTested': instance.deckTested,
      'words': instance.words,
      'unitConsolidated': instance.unitConsolidated,
      'unitWordCount': instance.unitWordCount,
    };
