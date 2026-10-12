class WordCollectionResponse {
  const WordCollectionResponse({
    required this.totalCount,
    required this.newCount,
    required this.dueCount,
    required this.articleCount,
    required this.filteredCount,
    required this.page,
    required this.hasMore,
    required this.items,
  });

  final int totalCount;
  final int newCount;
  final int dueCount;
  final int articleCount;
  final int filteredCount;
  final int page;
  final bool hasMore;
  final List<WordCollectionItem> items;

  factory WordCollectionResponse.fromJson(Map<String, dynamic> json) {
    return WordCollectionResponse(
      totalCount: json['totalCount'] as int? ?? 0,
      newCount: json['newCount'] as int? ?? 0,
      dueCount: json['dueCount'] as int? ?? 0,
      articleCount: json['articleCount'] as int? ?? 0,
      filteredCount: json['filteredCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      hasMore: json['hasMore'] as bool? ?? false,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) =>
              WordCollectionItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WordCollectionItem {
  const WordCollectionItem({
    required this.kartyId,
    required this.nounText,
    required this.article,
    required this.kartyUrl,
    required this.audioUrl,
    required this.isNew,
    required this.isDue,
    required this.needsArticlePractice,
  });

  final int kartyId;
  final String nounText;
  final String article;
  final String kartyUrl;
  final String? audioUrl;
  final bool isNew;
  final bool isDue;
  final bool needsArticlePractice;

  factory WordCollectionItem.fromJson(Map<String, dynamic> json) {
    return WordCollectionItem(
      kartyId: json['kartyId'] as int,
      nounText: json['nounText'] as String? ?? '',
      article: json['article'] as String? ?? '',
      kartyUrl: json['kartyUrl'] as String? ?? '',
      audioUrl: json['audioUrl'] as String?,
      isNew: json['isNew'] as bool? ?? false,
      isDue: json['isDue'] as bool? ?? false,
      needsArticlePractice: json['needsArticlePractice'] as bool? ?? false,
    );
  }
}
