class ResolveWrongKartyReviewResponse {
  const ResolveWrongKartyReviewResponse({
    required this.userId,
    required this.kartyId,
    required this.isMastered,
    required this.wrongCount,
    required this.rewardTickets,
    this.reviewedDate,
  });

  final String userId;
  final int kartyId;
  final bool isMastered;
  final int wrongCount;
  final DateTime? reviewedDate;

  /// Bekleyen son Rövanş kartı da kapatıldıysa verilen gerçek bilet sayısı.
  /// Tekrarlanan çözüm isteğinde veya tavan doluyken sıfırdır.
  final int rewardTickets;

  factory ResolveWrongKartyReviewResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ResolveWrongKartyReviewResponse(
      userId: json['userId'] as String? ?? '',
      kartyId: json['kartyId'] as int? ?? 0,
      isMastered: json['isMastered'] as bool? ?? false,
      wrongCount: json['wrongCount'] as int? ?? 0,
      reviewedDate: json['reviewedDate'] == null
          ? null
          : DateTime.parse(json['reviewedDate'] as String),
      rewardTickets: json['rewardTickets'] as int? ?? 0,
    );
  }
}
