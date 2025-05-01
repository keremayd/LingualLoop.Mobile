import 'package:json_annotation/json_annotation.dart';

part 'Badge.g.dart';

@JsonSerializable()
class Badge {
  final String badgeUrl;
  final String badgeTitle;
  final String badgeDescription;
  final DateTime createdDate;

  Badge({required this.badgeUrl, required this.badgeTitle, required this.badgeDescription, required this.createdDate});

  factory Badge.fromJson(Map<String, dynamic> json) => _$BadgeFromJson(json);
  Map<String, dynamic> toJson() => _$BadgeToJson(this);
}