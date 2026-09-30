class DailyActivityResponse {
  const DailyActivityResponse({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActiveDate,
    required this.freezeCount,
    required this.streakAtRisk,
    required this.missedDays,
    required this.week,
    required this.checkedInToday,
  });

  final int currentStreak;
  final int longestStreak;
  final String lastActiveDate;

  /// Elde kalan seri koruma sayısı.
  final int freezeCount;

  /// Seri kırılmak üzere ve kullanıcının bunu önleyecek koruması var.
  ///
  /// Koruma otomatik harcanmaz — karar penceresi bununla açılır. Karar
  /// verilene kadar backend seriyi ne artırır ne sıfırlar, yani her açılışta
  /// yeniden sorulur.
  final bool streakAtRisk;

  /// Risk durumunda kaç gün kaçırıldığı; o kadar koruma harcanacak.
  final int missedDays;

  /// Son yedi gün, eskiden yeniye.
  final List<DailyActivityDay> week;

  final bool checkedInToday;

  factory DailyActivityResponse.fromJson(Map<String, dynamic> json) {
    return DailyActivityResponse(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastActiveDate: json['lastActiveDate'] as String? ?? '',
      freezeCount: json['freezeCount'] as int? ?? 0,
      streakAtRisk: json['streakAtRisk'] as bool? ?? false,
      missedDays: json['missedDays'] as int? ?? 0,
      week: (json['week'] as List<dynamic>? ?? const [])
          .map((day) => DailyActivityDay.fromJson(day as Map<String, dynamic>))
          .toList(),
      checkedInToday: json['checkedInToday'] as bool? ?? false,
    );
  }
}

/// Seri şeridindeki tek gün.
class DailyActivityDay {
  const DailyActivityDay({
    required this.date,
    required this.active,
    required this.frozen,
  });

  final DateTime date;
  final bool active;
  final bool frozen;

  factory DailyActivityDay.fromJson(Map<String, dynamic> json) {
    return DailyActivityDay(
      date: DateTime.parse(json['date'] as String),
      active: json['active'] as bool? ?? false,
      frozen: json['frozen'] as bool? ?? false,
    );
  }

  /// `ScoreWithLivesResponse` bu tipi `json_serializable` ile üretilen kodda
  /// kullanıyor; üreteç `toJson` olmadan alanı işleyemiyor.
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'active': active,
        'frozen': frozen,
      };
}
