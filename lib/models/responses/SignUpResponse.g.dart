// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SignUpResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignUpResponse _$SignUpResponseFromJson(Map<String, dynamic> json) =>
    SignUpResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      signedUrl: json['signedUrl'] as String,
    );

Map<String, dynamic> _$SignUpResponseToJson(SignUpResponse instance) =>
    <String, dynamic>{
      'user': instance.user,
      'signedUrl': instance.signedUrl,
    };
