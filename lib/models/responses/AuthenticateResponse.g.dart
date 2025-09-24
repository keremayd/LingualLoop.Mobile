// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'AuthenticateResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthenticateResponse _$AuthenticateResponseFromJson(
        Map<String, dynamic> json) =>
    AuthenticateResponse(
      userId: json['userId'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      displayName: json['displayName'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String,
      userNickname: json['userNickname'] as String,
      userName: json['userName'] as String,
      userRank: json['userRank'] as int,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );

Map<String, dynamic> _$AuthenticateResponseToJson(
        AuthenticateResponse instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'displayName': instance.displayName,
      'profilePhotoUrl': instance.profilePhotoUrl,
      'userNickname': instance.userNickname,
      'userName': instance.userName,
      'userRank': instance.userRank,
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
    };
