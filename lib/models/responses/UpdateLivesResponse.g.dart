// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UpdateLivesResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateLivesResponse _$UpdateLivesResponseFromJson(Map<String, dynamic> json) =>
    UpdateLivesResponse(
      userId: json['userId'] as String,
      lives: (json['lives'] as num).toInt(),
    );

Map<String, dynamic> _$UpdateLivesResponseToJson(
        UpdateLivesResponse instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'lives': instance.lives,
    };
