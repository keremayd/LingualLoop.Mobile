import 'package:json_annotation/json_annotation.dart';
import 'package:lingualloop/models/User.dart';

part 'SignUpResponse.g.dart';

@JsonSerializable()
class SignUpResponse {
  final User user;
  final String signedUrl;

  SignUpResponse({required this.user, required this.signedUrl});

  factory SignUpResponse.fromJson(Map<String, dynamic> json) => _$SignUpResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SignUpResponseToJson(this);
}