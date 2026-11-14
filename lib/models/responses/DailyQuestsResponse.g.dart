// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'DailyQuestsResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyQuestsResponse _$DailyQuestsResponseFromJson(Map<String, dynamic> json) =>
    DailyQuestsResponse(
      dayKey: (json['dayKey'] as num).toInt(),
      resetAtUtc: DateTime.parse(json['resetAtUtc'] as String),
      quests: (json['quests'] as List<dynamic>?)
              ?.map((e) => DailyQuest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      freezeBonus: json['freezeBonus'] == null
          ? null
          : QuestFreezeBonus.fromJson(
              json['freezeBonus'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DailyQuestsResponseToJson(
        DailyQuestsResponse instance) =>
    <String, dynamic>{
      'dayKey': instance.dayKey,
      'resetAtUtc': instance.resetAtUtc.toIso8601String(),
      'quests': instance.quests,
      'freezeBonus': instance.freezeBonus,
    };

DailyQuest _$DailyQuestFromJson(Map<String, dynamic> json) => DailyQuest(
      questKey: json['questKey'] as String,
      title: json['title'] as String,
      target: (json['target'] as num).toInt(),
      progress: (json['progress'] as num).toInt(),
      rewardTickets: (json['rewardTickets'] as num).toInt(),
      isCompleted: json['isCompleted'] as bool,
      isClaimed: json['isClaimed'] as bool,
    );

Map<String, dynamic> _$DailyQuestToJson(DailyQuest instance) =>
    <String, dynamic>{
      'questKey': instance.questKey,
      'title': instance.title,
      'target': instance.target,
      'progress': instance.progress,
      'rewardTickets': instance.rewardTickets,
      'isCompleted': instance.isCompleted,
      'isClaimed': instance.isClaimed,
    };

QuestFreezeBonus _$QuestFreezeBonusFromJson(Map<String, dynamic> json) =>
    QuestFreezeBonus(
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      claimed: json['claimed'] as bool? ?? false,
      freezeCount: (json['freezeCount'] as num?)?.toInt() ?? 0,
      freezeCap: (json['freezeCap'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$QuestFreezeBonusToJson(QuestFreezeBonus instance) =>
    <String, dynamic>{
      'completed': instance.completed,
      'total': instance.total,
      'claimed': instance.claimed,
      'freezeCount': instance.freezeCount,
      'freezeCap': instance.freezeCap,
    };

ClaimFreezeResponse _$ClaimFreezeResponseFromJson(Map<String, dynamic> json) =>
    ClaimFreezeResponse(
      claimed: json['claimed'] as bool,
      freezeCount: (json['freezeCount'] as num?)?.toInt() ?? 0,
      freezeCap: (json['freezeCap'] as num?)?.toInt() ?? 1,
      blockedByCap: json['blockedByCap'] as bool? ?? false,
    );

Map<String, dynamic> _$ClaimFreezeResponseToJson(
        ClaimFreezeResponse instance) =>
    <String, dynamic>{
      'claimed': instance.claimed,
      'freezeCount': instance.freezeCount,
      'freezeCap': instance.freezeCap,
      'blockedByCap': instance.blockedByCap,
    };

ClaimQuestResponse _$ClaimQuestResponseFromJson(Map<String, dynamic> json) =>
    ClaimQuestResponse(
      questKey: json['questKey'] as String,
      claimed: json['claimed'] as bool,
      rewardTickets: (json['rewardTickets'] as num).toInt(),
      lives: (json['lives'] as num).toInt(),
      blockedByCap: json['blockedByCap'] as bool? ?? false,
    );

Map<String, dynamic> _$ClaimQuestResponseToJson(ClaimQuestResponse instance) =>
    <String, dynamic>{
      'questKey': instance.questKey,
      'claimed': instance.claimed,
      'rewardTickets': instance.rewardTickets,
      'lives': instance.lives,
      'blockedByCap': instance.blockedByCap,
    };
