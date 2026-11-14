import 'package:json_annotation/json_annotation.dart';

part 'DailyQuestsResponse.g.dart';

@JsonSerializable()
class DailyQuestsResponse {
  final int dayKey;
  final DateTime resetAtUtc;
  @JsonKey(defaultValue: [])
  final List<DailyQuest> quests;

  /// Bütün görevler bitince toplanan seri koruması; eski sunucuda yok.
  final QuestFreezeBonus? freezeBonus;

  DailyQuestsResponse({
    required this.dayKey,
    required this.resetAtUtc,
    this.quests = const [],
    this.freezeBonus,
  });

  factory DailyQuestsResponse.fromJson(Map<String, dynamic> json) =>
      _$DailyQuestsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DailyQuestsResponseToJson(this);
}

@JsonSerializable()
class DailyQuest {
  final String questKey;
  final String title;
  final int target;
  int progress;
  final int rewardTickets;
  bool isCompleted;
  bool isClaimed;

  DailyQuest({
    required this.questKey,
    required this.title,
    required this.target,
    required this.progress,
    required this.rewardTickets,
    required this.isCompleted,
    required this.isClaimed,
  });

  factory DailyQuest.fromJson(Map<String, dynamic> json) =>
      _$DailyQuestFromJson(json);

  Map<String, dynamic> toJson() => _$DailyQuestToJson(this);
}

/// Günün bütün görevleri bitince görevler ekranında toplanan seri koruması.
/// Tavan ücretsiz 1, premium 2 (sunucu `PremiumRules.FreezeCap`).
@JsonSerializable()
class QuestFreezeBonus {
  @JsonKey(defaultValue: 0)
  final int completed;
  @JsonKey(defaultValue: 0)
  final int total;
  @JsonKey(defaultValue: false)
  bool claimed;
  @JsonKey(defaultValue: 0)
  int freezeCount;
  @JsonKey(defaultValue: 1)
  final int freezeCap;

  QuestFreezeBonus({
    required this.completed,
    required this.total,
    required this.claimed,
    required this.freezeCount,
    required this.freezeCap,
  });

  /// Günün bütün görevleri bitti: koruma toplanabilir.
  bool get unlocked => total > 0 && completed >= total;

  factory QuestFreezeBonus.fromJson(Map<String, dynamic> json) =>
      _$QuestFreezeBonusFromJson(json);

  Map<String, dynamic> toJson() => _$QuestFreezeBonusToJson(this);
}

@JsonSerializable()
class ClaimFreezeResponse {
  final bool claimed;
  @JsonKey(defaultValue: 0)
  final int freezeCount;
  @JsonKey(defaultValue: 1)
  final int freezeCap;

  /// Koruma tavanda, verilemedi; talep tüketilmedi.
  @JsonKey(defaultValue: false)
  final bool blockedByCap;

  ClaimFreezeResponse({
    required this.claimed,
    required this.freezeCount,
    required this.freezeCap,
    this.blockedByCap = false,
  });

  factory ClaimFreezeResponse.fromJson(Map<String, dynamic> json) =>
      _$ClaimFreezeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ClaimFreezeResponseToJson(this);
}

@JsonSerializable()
class ClaimQuestResponse {
  final String questKey;
  final bool claimed;
  final int rewardTickets;
  final int lives;

  /// Bakiye tavanda olduğu için ödül verilemedi ve **talep tüketilmedi**:
  /// görev alınabilir kalır, kullanıcı yer açınca alır.
  @JsonKey(defaultValue: false)
  final bool blockedByCap;

  ClaimQuestResponse({
    required this.questKey,
    required this.claimed,
    required this.rewardTickets,
    required this.lives,
    this.blockedByCap = false,
  });

  factory ClaimQuestResponse.fromJson(Map<String, dynamic> json) =>
      _$ClaimQuestResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ClaimQuestResponseToJson(this);
}
