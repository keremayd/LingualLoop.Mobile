import 'package:lingualloop/models/responses/DailyActivityResponse.dart';

class ProfileLearningStatsResponse {
  const ProfileLearningStatsResponse({
    required this.learnedWordCount,
    required this.learnedArticleCount,
    required this.articleInProgressCount,
    required this.reviewPendingCount,
    required this.reviewMistakeCount,
    required this.totalCorrectAnswers,
    required this.totalArticleCorrectAnswers,
    required this.currentStreak,
    required this.longestStreak,
    required this.freezeCount,
    required this.week,
  });

  final int learnedWordCount;
  final int learnedArticleCount;
  final int articleInProgressCount;
  final int reviewPendingCount;
  final int reviewMistakeCount;
  final int totalCorrectAnswers;
  final int totalArticleCorrectAnswers;
  final int currentStreak;
  final int longestStreak;

  /// Elde kalan seri koruma sayısı.
  final int freezeCount;

  /// Son yedi gün, eskiden yeniye. Profildeki seri şeridi bunu çizer.
  final List<DailyActivityDay> week;

  ProfileLearningStatsResponse copyWith({
    int? learnedWordCount,
    int? learnedArticleCount,
    int? articleInProgressCount,
    int? reviewPendingCount,
    int? reviewMistakeCount,
    int? totalCorrectAnswers,
    int? totalArticleCorrectAnswers,
    int? currentStreak,
    int? longestStreak,
    int? freezeCount,
    List<DailyActivityDay>? week,
  }) {
    return ProfileLearningStatsResponse(
      learnedWordCount: learnedWordCount ?? this.learnedWordCount,
      learnedArticleCount: learnedArticleCount ?? this.learnedArticleCount,
      articleInProgressCount:
          articleInProgressCount ?? this.articleInProgressCount,
      reviewPendingCount: reviewPendingCount ?? this.reviewPendingCount,
      reviewMistakeCount: reviewMistakeCount ?? this.reviewMistakeCount,
      totalCorrectAnswers: totalCorrectAnswers ?? this.totalCorrectAnswers,
      totalArticleCorrectAnswers:
          totalArticleCorrectAnswers ?? this.totalArticleCorrectAnswers,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      freezeCount: freezeCount ?? this.freezeCount,
      week: week ?? this.week,
    );
  }

  factory ProfileLearningStatsResponse.fromJson(Map<String, dynamic> json) {
    return ProfileLearningStatsResponse(
      learnedWordCount: json['learnedWordCount'] as int? ?? 0,
      learnedArticleCount: json['learnedArticleCount'] as int? ?? 0,
      articleInProgressCount: json['articleInProgressCount'] as int? ?? 0,
      reviewPendingCount: json['reviewPendingCount'] as int? ?? 0,
      reviewMistakeCount: json['reviewMistakeCount'] as int? ?? 0,
      totalCorrectAnswers: json['totalCorrectAnswers'] as int? ?? 0,
      totalArticleCorrectAnswers:
          json['totalArticleCorrectAnswers'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      freezeCount: json['freezeCount'] as int? ?? 0,
      week: (json['week'] as List<dynamic>? ?? const [])
          .map((day) => DailyActivityDay.fromJson(day as Map<String, dynamic>))
          .toList(),
    );
  }
}
