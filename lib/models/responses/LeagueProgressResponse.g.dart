// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'LeagueProgressResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeagueProgressResponse _$LeagueProgressResponseFromJson(
        Map<String, dynamic> json) =>
    LeagueProgressResponse(
      leagueKey: json['leagueKey'] as String,
      leagueName: json['leagueName'] as String,
      rank: (json['rank'] as num).toInt(),
      points: (json['points'] as num).toInt(),
      minPoints: (json['minPoints'] as num).toInt(),
      maxPoints: (json['maxPoints'] as num?)?.toInt(),
      pointsToNextLeague: (json['pointsToNextLeague'] as num?)?.toInt(),
      progressRatio: (json['progressRatio'] as num).toDouble(),
      seasonKey: (json['seasonKey'] as num).toInt(),
      seasonStartsAtUtc: DateTime.parse(json['seasonStartsAtUtc'] as String),
      seasonEndsAtUtc: DateTime.parse(json['seasonEndsAtUtc'] as String),
      leaderboardRank: (json['leaderboardRank'] as num?)?.toInt(),
      leagueUserCount: (json['leagueUserCount'] as num?)?.toInt(),
      leaderboard: (json['leaderboard'] as List<dynamic>?)
              ?.map((e) =>
                  LeagueLeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pendingPromotion: json['pendingPromotion'] == null
          ? null
          : LeaguePromotionResponse.fromJson(
              json['pendingPromotion'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LeagueProgressResponseToJson(
        LeagueProgressResponse instance) =>
    <String, dynamic>{
      'leagueKey': instance.leagueKey,
      'leagueName': instance.leagueName,
      'rank': instance.rank,
      'points': instance.points,
      'minPoints': instance.minPoints,
      'maxPoints': instance.maxPoints,
      'pointsToNextLeague': instance.pointsToNextLeague,
      'progressRatio': instance.progressRatio,
      'seasonKey': instance.seasonKey,
      'seasonStartsAtUtc': instance.seasonStartsAtUtc.toIso8601String(),
      'seasonEndsAtUtc': instance.seasonEndsAtUtc.toIso8601String(),
      'leaderboardRank': instance.leaderboardRank,
      'leagueUserCount': instance.leagueUserCount,
      'leaderboard': instance.leaderboard,
      'pendingPromotion': instance.pendingPromotion,
    };

LeaguePromotionResponse _$LeaguePromotionResponseFromJson(
        Map<String, dynamic> json) =>
    LeaguePromotionResponse(
      fromRank: (json['fromRank'] as num).toInt(),
      fromLeagueKey: json['fromLeagueKey'] as String,
      fromLeagueName: json['fromLeagueName'] as String,
      toRank: (json['toRank'] as num).toInt(),
      toLeagueKey: json['toLeagueKey'] as String,
      toLeagueName: json['toLeagueName'] as String,
    );

Map<String, dynamic> _$LeaguePromotionResponseToJson(
        LeaguePromotionResponse instance) =>
    <String, dynamic>{
      'fromRank': instance.fromRank,
      'fromLeagueKey': instance.fromLeagueKey,
      'fromLeagueName': instance.fromLeagueName,
      'toRank': instance.toRank,
      'toLeagueKey': instance.toLeagueKey,
      'toLeagueName': instance.toLeagueName,
    };

LeagueLeaderboardEntry _$LeagueLeaderboardEntryFromJson(
        Map<String, dynamic> json) =>
    LeagueLeaderboardEntry(
      rank: (json['rank'] as num).toInt(),
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      points: (json['points'] as num).toInt(),
      isCurrentUser: json['isCurrentUser'] as bool,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
    );

Map<String, dynamic> _$LeagueLeaderboardEntryToJson(
        LeagueLeaderboardEntry instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'userId': instance.userId,
      'displayName': instance.displayName,
      'points': instance.points,
      'isCurrentUser': instance.isCurrentUser,
      'profilePhotoUrl': instance.profilePhotoUrl,
    };
