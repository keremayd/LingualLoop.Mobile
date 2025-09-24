import 'package:json_annotation/json_annotation.dart';

part 'User.g.dart';

@JsonSerializable()
class User {
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  String? profilePhotoUrl;
  final String userNickname;
  final String userName;
  final int userRank;

  User({required this.userId, required this.firstName, required this.lastName, required this.displayName, required this.profilePhotoUrl, required this.userNickname,  required this.userName, required this.userRank});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
