// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Video _$VideoFromJson(Map<String, dynamic> json) => Video(
      (json['videoId'] as num?)?.toInt(),
      json['videoUrl'] as String,
      json['videoTitle'] as String,
      json['videoDescription'] as String,
      (json['questions'] as List<dynamic>?)
          ?.map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$VideoToJson(Video instance) => <String, dynamic>{
      'videoId': instance.videoId,
      'videoUrl': instance.videoUrl,
      'videoTitle': instance.videoTitle,
      'videoDescription': instance.videoDescription,
      'questions': instance.questions,
    };
