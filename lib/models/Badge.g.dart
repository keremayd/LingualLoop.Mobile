// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Badge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Badge _$BadgeFromJson(Map<String, dynamic> json) => Badge(
      badgeUrl: json['badgeUrl'] as String,
      badgeTitle: json['badgeTitle'] as String,
      badgeDescription: json['badgeDescription'] as String,
      createdDate: DateTime.parse(json['createdDate'] as String),
    );

Map<String, dynamic> _$BadgeToJson(Badge instance) => <String, dynamic>{
      'badgeUrl': instance.badgeUrl,
      'badgeTitle': instance.badgeTitle,
      'badgeDescription': instance.badgeDescription,
      'createdDate': instance.createdDate.toIso8601String(),
    };
