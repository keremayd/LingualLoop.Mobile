import 'package:json_annotation/json_annotation.dart';

part 'LeagueProgressResponse.g.dart';

@JsonSerializable()
class LeagueProgressResponse {
  final String leagueKey;
  final String leagueName;
  final int rank;
  final int points;
  final int minPoints;
  final int? maxPoints;
  final int? pointsToNextLeague;
  final double progressRatio;
  final int seasonKey;
  final DateTime seasonStartsAtUtc;
  final DateTime seasonEndsAtUtc;
  final int? leaderboardRank;
  final int? leagueUserCount;
  @JsonKey(defaultValue: [])
  final List<LeagueLeaderboardEntry> leaderboard;
  final LeaguePromotionResponse? pendingPromotion;

  LeagueProgressResponse({
    required this.leagueKey,
    required this.leagueName,
    required this.rank,
    required this.points,
    required this.minPoints,
    required this.maxPoints,
    required this.pointsToNextLeague,
    required this.progressRatio,
    required this.seasonKey,
    required this.seasonStartsAtUtc,
    required this.seasonEndsAtUtc,
    required this.leaderboardRank,
    required this.leagueUserCount,
    this.leaderboard = const [],
    this.pendingPromotion,
  });

  factory LeagueProgressResponse.fromJson(Map<String, dynamic> json) =>
      _$LeagueProgressResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LeagueProgressResponseToJson(this);
}

@JsonSerializable()
class LeaguePromotionResponse {
  final int fromRank;
  final String fromLeagueKey;
  final String fromLeagueName;
  final int toRank;
  final String toLeagueKey;
  final String toLeagueName;

  const LeaguePromotionResponse({
    required this.fromRank,
    required this.fromLeagueKey,
    required this.fromLeagueName,
    required this.toRank,
    required this.toLeagueKey,
    required this.toLeagueName,
  });

  factory LeaguePromotionResponse.fromJson(Map<String, dynamic> json) =>
      _$LeaguePromotionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LeaguePromotionResponseToJson(this);
}

@JsonSerializable()
class LeagueLeaderboardEntry {
  final int rank;
  final String userId;
  final String displayName;
  final int points;
  final bool isCurrentUser;
  final String? profilePhotoUrl;

  LeagueLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.points,
    required this.isCurrentUser,
    this.profilePhotoUrl,
  });

  factory LeagueLeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeagueLeaderboardEntryFromJson(json);

  Map<String, dynamic> toJson() => _$LeagueLeaderboardEntryToJson(this);
}
