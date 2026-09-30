import 'package:json_annotation/json_annotation.dart';

part 'AcknowledgeLeaguePromotionResponse.g.dart';

@JsonSerializable()
class AcknowledgeLeaguePromotionResponse {
  final int acknowledgedRank;

  const AcknowledgeLeaguePromotionResponse({
    required this.acknowledgedRank,
  });

  factory AcknowledgeLeaguePromotionResponse.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$AcknowledgeLeaguePromotionResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AcknowledgeLeaguePromotionResponseToJson(this);
}
