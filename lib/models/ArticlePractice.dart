class ArticlePracticeTask {
  const ArticlePracticeTask({
    required this.kartyId,
    required this.nounText,
    required this.kartyUrl,
    required this.articleAttemptCount,
    required this.articleCorrectCount,
    required this.learningStack,
    required this.learningGoal,
    this.localImagePath = '',
  });

  final int kartyId;
  final String nounText;
  final String kartyUrl;
  final int articleAttemptCount;
  final int articleCorrectCount;
  final int learningStack;
  final int learningGoal;
  final String localImagePath;

  bool get isArticleComplete => learningStack >= learningGoal;

  factory ArticlePracticeTask.fromJson(Map<String, dynamic> json) {
    return ArticlePracticeTask(
      kartyId: json['kartyId'] as int,
      nounText: json['nounText'] as String? ?? '',
      kartyUrl: json['kartyUrl'] as String? ?? '',
      articleAttemptCount: json['articleAttemptCount'] as int? ?? 0,
      articleCorrectCount: json['articleCorrectCount'] as int? ?? 0,
      learningStack: json['learningStack'] as int? ?? 0,
      learningGoal: json['learningGoal'] as int? ?? 5,
    );
  }

  ArticlePracticeTask withLocalImage(String path) {
    return ArticlePracticeTask(
      kartyId: kartyId,
      nounText: nounText,
      kartyUrl: kartyUrl,
      articleAttemptCount: articleAttemptCount,
      articleCorrectCount: articleCorrectCount,
      learningStack: learningStack,
      learningGoal: learningGoal,
      localImagePath: path,
    );
  }
}

class ArticlePracticeLoadResult {
  const ArticlePracticeLoadResult({
    required this.isUnlocked,
    required this.learnedWordCount,
    required this.requiredWordCount,
    this.task,
    this.nextTask,
  });

  final bool isUnlocked;
  final int learnedWordCount;
  final int requiredWordCount;
  final ArticlePracticeTask? task;
  final ArticlePracticeTask? nextTask;

  factory ArticlePracticeLoadResult.fromJson(Map<String, dynamic> json) {
    final taskJson = json['task'];
    return ArticlePracticeLoadResult(
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      learnedWordCount: json['learnedWordCount'] as int? ?? 0,
      requiredWordCount: json['requiredWordCount'] as int? ?? 2,
      task: taskJson is Map<String, dynamic>
          ? ArticlePracticeTask.fromJson(taskJson)
          : null,
      nextTask: json['nextTask'] is Map<String, dynamic>
          ? ArticlePracticeTask.fromJson(
              json['nextTask'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  ArticlePracticeLoadResult withTasks({
    required ArticlePracticeTask? task,
    required ArticlePracticeTask? nextTask,
  }) {
    return ArticlePracticeLoadResult(
      isUnlocked: isUnlocked,
      learnedWordCount: learnedWordCount,
      requiredWordCount: requiredWordCount,
      task: task,
      nextTask: nextTask,
    );
  }
}

class ArticlePracticeAnswer {
  const ArticlePracticeAnswer({
    required this.isAccepted,
    required this.isCorrect,
    required this.correctArticle,
    required this.earnedPoints,
    required this.articleAttemptCount,
    required this.articleCorrectCount,
  });

  final bool isAccepted;
  final bool isCorrect;
  final String correctArticle;
  final int earnedPoints;
  final int articleAttemptCount;
  final int articleCorrectCount;

  factory ArticlePracticeAnswer.fromJson(Map<String, dynamic> json) {
    return ArticlePracticeAnswer(
      isAccepted: json['isAccepted'] as bool? ?? false,
      isCorrect: json['isCorrect'] as bool? ?? false,
      correctArticle: json['correctArticle'] as String? ?? '',
      earnedPoints: json['earnedPoints'] as int? ?? 0,
      articleAttemptCount: json['articleAttemptCount'] as int? ?? 0,
      articleCorrectCount: json['articleCorrectCount'] as int? ?? 0,
    );
  }
}
