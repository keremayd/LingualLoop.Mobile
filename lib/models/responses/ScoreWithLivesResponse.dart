import 'package:json_annotation/json_annotation.dart';
import 'package:lingualloop/models/responses/DailyActivityResponse.dart';
import 'package:lingualloop/models/responses/LeagueProgressResponse.dart';

part 'ScoreWithLivesResponse.g.dart';

@JsonSerializable()
class ScoreWithLivesResponse {
  /// Eski zorluk termostatı. 4 Kas 2026'dan beri sunucuda oynatılmıyor ve
  /// hiçbir şeyi belirlemiyor; içerik Karty Yolu'nda ünitelerle açılıyor.
  /// Yanıtta durduğu için modelde; kullanıcıya gösterilmez.
  int score;

  /// İlerleme sayacı: yalnızca doğru cevapta artar. Ekranda gösterilen sayı.
  @JsonKey(defaultValue: 0)
  int experience;

  int lives;

  /// Bilet tavanı.
  @JsonKey(defaultValue: 15)
  int maxLives;

  /// Sıradaki biletin geleceği an; tavandayken null.
  DateTime? nextTicketAt;

  LeagueProgressResponse? league;

  /// Ana ekranın üst şeridi için: günlük seri ve elde kalan koruma.
  ///
  /// Profil istatistikleri ucundan da geliyor ama ana ekran o ucu çağırmıyor;
  /// üst şerit veriyi zaten çektiği bu yanıttan okuyor.
  @JsonKey(defaultValue: 0)
  int streak;

  /// Geçmişte ulaşılan en uzun seri; ana ekrandaki sahneleri seçer.
  @JsonKey(defaultValue: 0)
  int longestStreak;

  @JsonKey(defaultValue: 0)
  int freezeCount;

  /// Bugün gerçekten oynandı mı. Seri sayısı bunu söylemiyor: "2" yazması
  /// bugünün kurtarıldığı anlamına gelmez.
  @JsonKey(defaultValue: false)
  bool playedToday;

  /// Son yedi gün; ana ekrandaki seri şeridi için. Profildeki şeritle aynı
  /// modeli kullanır (`toStrip()` ile çevrilir).
  @JsonKey(defaultValue: <DailyActivityDay>[])
  List<DailyActivityDay> streakWeek;

  ScoreWithLivesResponse({
    required this.score,
    required this.experience,
    required this.lives,
    required this.maxLives,
    this.nextTicketAt,
    this.league,
    this.streak = 0,
    this.longestStreak = 0,
    this.freezeCount = 0,
    this.playedToday = false,
    this.streakWeek = const <DailyActivityDay>[],
  });

  factory ScoreWithLivesResponse.fromJson(Map<String, dynamic> json) =>
      _$ScoreWithLivesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ScoreWithLivesResponseToJson(this);
}
