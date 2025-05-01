// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'GetBadgesByIdResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetBadgesByIdResponse _$GetBadgesByIdResponseFromJson(
        Map<String, dynamic> json) =>
    GetBadgesByIdResponse(
      (json['userBadgeId'] as num).toInt(),
      json['userId'] as String,
      DateTime.parse(json['earnedDate'] as String),
      Badge.fromJson(json['badge'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetBadgesByIdResponseToJson(
        GetBadgesByIdResponse instance) =>
    <String, dynamic>{
      'userBadgeId': instance.userBadgeId,
      'userId': instance.userId,
      'earnedDate': instance.earnedDate.toIso8601String(),
      'badge': instance.badge,
    };
