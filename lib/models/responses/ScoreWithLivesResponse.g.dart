// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ScoreWithLivesResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScoreWithLivesResponse _$ScoreWithLivesResponseFromJson(
        Map<String, dynamic> json) =>
    ScoreWithLivesResponse(
      score: (json['score'] as num).toInt(),
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      levelProgress: (json['levelProgress'] as num?)?.toInt() ?? 0,
      levelBandSize: (json['levelBandSize'] as num?)?.toInt() ?? 50,
      lives: (json['lives'] as num).toInt(),
      maxLives: (json['maxLives'] as num?)?.toInt() ?? 15,
      nextTicketAt: json['nextTicketAt'] == null
          ? null
          : DateTime.parse(json['nextTicketAt'] as String),
      league: json['league'] == null
          ? null
          : LeagueProgressResponse.fromJson(
              json['league'] as Map<String, dynamic>),
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      freezeCount: (json['freezeCount'] as num?)?.toInt() ?? 0,
      playedToday: json['playedToday'] as bool? ?? false,
      streakWeek: (json['streakWeek'] as List<dynamic>?)
              ?.map((e) => DailyActivityDay.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ScoreWithLivesResponseToJson(
        ScoreWithLivesResponse instance) =>
    <String, dynamic>{
      'score': instance.score,
      'experience': instance.experience,
      'level': instance.level,
      'levelProgress': instance.levelProgress,
      'levelBandSize': instance.levelBandSize,
      'lives': instance.lives,
      'maxLives': instance.maxLives,
      'nextTicketAt': instance.nextTicketAt?.toIso8601String(),
      'league': instance.league,
      'streak': instance.streak,
      'freezeCount': instance.freezeCount,
      'playedToday': instance.playedToday,
      'streakWeek': instance.streakWeek,
    };
