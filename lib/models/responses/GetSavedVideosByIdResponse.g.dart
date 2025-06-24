// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'GetSavedVideosByIdResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetSavedVideosByIdResponse _$GetSavedVideosByIdResponseFromJson(
        Map<String, dynamic> json) =>
    GetSavedVideosByIdResponse(
      userVideoId: (json['userVideoId'] as num).toInt(),
      userId: json['userId'] as String,
      video: Video.fromJson(json['video'] as Map<String, dynamic>),
      savedDate: DateTime.parse(json['savedDate'] as String),
    );

Map<String, dynamic> _$GetSavedVideosByIdResponseToJson(
        GetSavedVideosByIdResponse instance) =>
    <String, dynamic>{
      'userVideoId': instance.userVideoId,
      'userId': instance.userId,
      'video': instance.video,
      'savedDate': instance.savedDate.toIso8601String(),
    };
