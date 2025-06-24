// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UploadUserFileResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadUserFileResponse _$UploadUserFileResponseFromJson(
        Map<String, dynamic> json) =>
    UploadUserFileResponse(
      id: json['id'] as String,
      signedUrl: json['signedUrl'] as String,
    );

Map<String, dynamic> _$UploadUserFileResponseToJson(
        UploadUserFileResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'signedUrl': instance.signedUrl,
    };
