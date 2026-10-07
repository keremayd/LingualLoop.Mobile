import 'package:flutter/material.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/widgets/ProfileCard.dart';
import 'package:lingualloop/ui/widgets/profile_learning_stats_card.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileLearningStatsProvider profileLearningStatsProvider;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    profileLearningStatsProvider =
        Provider.of<ProfileLearningStatsProvider>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    Future.microtask(() async {
      try {
        final response = await userService.recordDailyActivity();
        final activity = response?.data;
        if (activity != null) {
          profileLearningStatsProvider.applyDailyActivity(activity);
        }
      } catch (_) {
        // Streak kaydı profil ekranının açılmasını engellemesin.
      }
      if (!mounted) return;
      await userService.scoreWithLivesById(context);
      if (!mounted) return;
      await profileLearningStatsProvider.load(context);

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const ColoredBox(
        color: Color(0xFF041227),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final scale = MediaQuery.sizeOf(context).width / 750;

    return Scaffold(
      backgroundColor: const Color(0xFF041227),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          38 * scale,
          40 * scale,
          40 * scale,
          52 * scale,
        ),
        // Yerleşim: kimlik → hedefler → bugün → toplam.
        //
        // Eskiden "Genel Bakış" ve "İstatistikler" diye iki bölüm vardı ve
        // ikisi de aynı şeyi yapıyordu: güncel sayı göstermek. Ekran veri
        // döküyor ama hiçbir yere yönlendirmiyordu.
        //
        // Yeni sıra bir soruya cevap veriyor: **neye yakınsın** (hedefler),
        // **bugün ne var** (seri + rövanş), **toplamda neredesin** (sayılar).
        // Referans bilgisi en sona iniyor çünkü bakılan şey, yapılan şey
        // değil.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProfileCard(color: Color(0xFF0C2244)),
            SizedBox(height: 34 * scale),
            Consumer2<ScoreWithLivesProvider, ProfileLearningStatsProvider>(
              builder: (context, scoreProvider, statsProvider, child) {
                final data = scoreProvider.scoreWithLives;
                final league = data?.league;
                final stats = statsProvider.stats;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileSectionTitle(
                      text: 'SIRADAKİ HEDEFLERİN',
                      scale: scale,
                    ),
                    SizedBox(height: 15 * scale),
                    ProfileGoalsCard(
                      level: data?.level ?? 1,
                      levelProgress: data?.levelProgress ?? 0,
                      levelBandSize: data?.levelBandSize ?? 50,
                      leagueKey: league?.leagueKey ?? 'merkur',
                      pointsToNextLeague: league?.pointsToNextLeague,
                      leagueProgressRatio: league?.progressRatio ?? 0,
                      currentStreak: stats?.currentStreak ?? 0,
                    ),
                    SizedBox(height: 34 * scale),
                    ProfileSectionTitle(text: 'BUGÜN', scale: scale),
                    SizedBox(height: 15 * scale),
                    const ProfileLearningStatsCard(),
                    SizedBox(height: 34 * scale),
                    ProfileSectionTitle(text: 'TOPLAM', scale: scale),
                    SizedBox(height: 15 * scale),
                    ProfileTotalsRow(
                      // Ham skor değil XP; skor zorluk termostatı olduğu için
                      // kullanıcıya gösterilmez.
                      experience: data?.experience ?? 0,
                      learnedWords: stats?.learnedWordCount ?? 0,
                      learnedArticles: stats?.learnedArticleCount ?? 0,
                      leaderboardRank: league?.leaderboardRank,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
