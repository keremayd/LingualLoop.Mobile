import 'package:json_annotation/json_annotation.dart';

part 'AuthenticateResponse.g.dart';

@JsonSerializable()
class AuthenticateResponse {
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String userNickname;
  final String userName;
  final String accessToken;
  final String refreshToken;

  AuthenticateResponse({required this.userId, required this.firstName, required this.lastName, required this.displayName, required this.userNickname, required this.userName, required this.accessToken, required this.refreshToken});

  factory AuthenticateResponse.fromJson(Map<String, dynamic> json) => _$AuthenticateResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthenticateResponseToJson(this);
}