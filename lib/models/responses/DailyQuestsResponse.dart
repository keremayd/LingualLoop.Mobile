import 'package:json_annotation/json_annotation.dart';

part 'DailyQuestsResponse.g.dart';

@JsonSerializable()
class DailyQuestsResponse {
  final int dayKey;
  final DateTime resetAtUtc;
  @JsonKey(defaultValue: [])
  final List<DailyQuest> quests;

  DailyQuestsResponse({
    required this.dayKey,
    required this.resetAtUtc,
    this.quests = const [],
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
