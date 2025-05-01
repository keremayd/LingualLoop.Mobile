import 'package:json_annotation/json_annotation.dart';
import 'package:lingualloop/models/Badge.dart';

part 'GetBadgesByIdResponse.g.dart';

@JsonSerializable()
class GetBadgesByIdResponse {
  final int userBadgeId;
  final String userId;
  final DateTime earnedDate;
  final Badge badge;

  GetBadgesByIdResponse(this.userBadgeId, this.userId, this.earnedDate, this.badge);

  factory GetBadgesByIdResponse.fromJson(Map<String, dynamic> json) => _$GetBadgesByIdResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GetBadgesByIdResponseToJson(this);
}