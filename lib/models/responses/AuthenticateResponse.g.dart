// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'AuthenticateResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthenticateResponse _$AuthenticateResponseFromJson(
        Map<String, dynamic> json) =>
    AuthenticateResponse(
      userId: json['userId'] as String,
      userNickname: json['userNickname'] as String,
      userName: json['userName'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );

Map<String, dynamic> _$AuthenticateResponseToJson(
        AuthenticateResponse instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'userNickname': instance.userNickname,
      'userName': instance.userName,
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
    };
