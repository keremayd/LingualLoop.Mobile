import 'package:json_annotation/json_annotation.dart';

part 'UploadUserFileResponse.g.dart';

@JsonSerializable()
class UploadUserFileResponse {
  final String id;
  final String signedUrl;

  UploadUserFileResponse({required this.id, required this.signedUrl});

  factory UploadUserFileResponse.fromJson(Map<String, dynamic> json) => _$UploadUserFileResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UploadUserFileResponseToJson(this);
}