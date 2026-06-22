class Karty {
  final int kartyId;
  final String kartyUrl;
  final String questionText;
  final String correctText;
  final bool isCorrect;

  Karty({
    required this.kartyId,
    required this.kartyUrl,
    required this.questionText,
    required this.correctText,
    required this.isCorrect,
  });
}
