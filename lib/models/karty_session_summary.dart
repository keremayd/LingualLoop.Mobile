import 'package:lingualloop/models/karty_path.dart';

/// Oyun (bir deste) bittiğinde Karty'nin "tamam" ekranında gösterilenler.
///
/// Sayılar oturum boyunca istemcide toplanır; destenin kelimeleri ve
/// ünitenin son hâli `karty/session` yanıtından, pekişen kelime sayısı
/// ünitenin oturum başındaki ve sonundaki hâlinden çıkar.
class KartySessionSummary {
  const KartySessionSummary({
    required this.unit,
    this.deck,
    this.practice = false,
    required this.words,
    required this.newCount,
    required this.reviewCount,
    required this.consolidatedBefore,
    required this.points,
    required this.correct,
    required this.answered,
    required this.revenge,
    this.league,
  });

  /// Oturumun ilerlettiği ünite; sayıları oturum sonundaki hâliyle.
  final KartyUnit unit;

  /// Oynanan deste; yalnız tekrar oyununda ve pratikte null.
  final int? deck;

  /// Pratik turu: vakti gelmiş tekrar yokken ya da özetten sonra oynanan
  /// on soru. Puan kazandırır, kelime pekiştirmez.
  final bool practice;

  /// Karolarda gösterilen kelimeler: destenin kelimeleri; yalnız tekrar
  /// oyununda ve pratikte cevaplananlar.
  final List<KartyWord> words;
  final int newCount;
  final int reviewCount;

  /// Oturum başında pekişmiş kelime sayısı; çubuk buradan ünitenin
  /// sayısına dolar.
  final int consolidatedBefore;

  /// Kazanılan puan. Karty'de XP ile lig puanı aynı miktarda artar
  /// (`UpdateScoreCommandHandler`), bu yüzden tek sayı gösterilir.
  final int points;
  final int correct;
  final int answered;

  /// Yanlış bilinip rövanşa kalan kelime sayısı.
  final int revenge;

  /// Lig sonucu; yalnız bir sonraki lige yaklaşıldığında gösterilir.
  final KartyLeagueNote? league;

  int get consolidatedToday =>
      (unit.consolidatedCount - consolidatedBefore).clamp(0, unit.wordCount);
}

/// "Supernova Ligi'ne 2 puan kaldı" — lig ekranındaki cümlenin aynısı.
class KartyLeagueNote {
  const KartyLeagueNote({
    required this.nextLeagueKey,
    required this.nextLeagueName,
    required this.pointsLeft,
  });

  final String nextLeagueKey;
  final String nextLeagueName;
  final int pointsLeft;
}
