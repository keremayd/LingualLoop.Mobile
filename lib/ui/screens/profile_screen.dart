import 'package:flutter/material.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/ProfileCard.dart';
import 'package:lingualloop/ui/widgets/loading_skeleton.dart';
import 'package:lingualloop/ui/widgets/profile_learning_stats_card.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileLearningStatsProvider profileLearningStatsProvider;

  late bool isLoading;

  void _openWordCollection() {
    Navigator.of(context).pushNamed('/wordcollection');
  }

  @override
  void initState() {
    super.initState();
    profileLearningStatsProvider =
        Provider.of<ProfileLearningStatsProvider>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    // Sekmeler her geçişte yeniden kurulur. Bu verinin ikisini de ana ekran
    // yüklüyor: eldeyse ekran beklemeden gelir, arkada tazelenir.
    isLoading = context.read<ScoreWithLivesProvider>().scoreWithLives == null ||
        profileLearningStatsProvider.stats == null;

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
      await Future.wait([
        userService.scoreWithLivesById(context),
        profileLearningStatsProvider.refreshSilently(context),
      ]);

      if (!mounted || !isLoading) return;
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _ProfileSkeleton();
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
                    Row(
                      children: [
                        Expanded(
                          child: ProfileSectionTitle(
                            text: 'TOPLAM',
                            scale: scale,
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Kelimelerim ekranını aç',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _openWordCollection,
                            child: Text(
                              'KELİMELERİM  ›',
                              style: TextStyle(
                                color: const Color(0xFF1CB1F5),
                                fontFamily: AppTypography.family,
                                fontSize: 20 * scale,
                                fontWeight: AppTypography.label,
                                letterSpacing: 0.3 * scale,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15 * scale),
                    ProfileTotalsRow(
                      // Ham skor değil XP; skor zorluk termostatı olduğu için
                      // kullanıcıya gösterilmez.
                      experience: data?.experience ?? 0,
                      encounteredWords: stats?.encounteredWordCount ?? 0,
                      learnedArticles: stats?.learnedArticleCount ?? 0,
                      leaderboardRank: league?.leaderboardRank,
                      onWordsTap: _openWordCollection,
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

/// Profil verisi ilk kez inerken: kimlik kartı (kullanıcı zaten belli) ve
/// diğer kartların yeri, içleri boş. Veriyi ana ekran yüklediği için
/// çoğunlukla hiç görünmez.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 750;

    Widget goalRow() => Padding(
          padding: EdgeInsets.fromLTRB(24 * s, 22 * s, 24 * s, 22 * s),
          child: Row(
            children: [
              SkeletonBlock(width: 52 * s, height: 52 * s, radius: 14 * s),
              SizedBox(width: 20 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(
                        width: 220 * s, height: 26 * s, radius: 8 * s),
                    SizedBox(height: 16 * s),
                    SkeletonBlock(height: 14 * s, radius: 7 * s),
                  ],
                ),
              ),
            ],
          ),
        );

    Widget total() => Column(
          children: [
            SkeletonBlock(width: 52 * s, height: 52 * s, radius: 14 * s),
            SizedBox(height: 14 * s),
            SkeletonBlock(width: 70 * s, height: 34 * s, radius: 9 * s),
            SizedBox(height: 10 * s),
            SkeletonBlock(width: 90 * s, height: 18 * s, radius: 6 * s),
          ],
        );

    return Scaffold(
      backgroundColor: const Color(0xFF041227),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(38 * s, 40 * s, 40 * s, 52 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProfileCard(color: Color(0xFF0C2244)),
            SizedBox(height: 34 * s),
            SkeletonReveal(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileSectionTitle(text: 'SIRADAKİ HEDEFLERİN', scale: s),
                  SizedBox(height: 15 * s),
                  ProfileSkeletonSurface(
                    child: Column(children: [goalRow(), goalRow()]),
                  ),
                  SizedBox(height: 34 * s),
                  ProfileSectionTitle(text: 'BUGÜN', scale: s),
                  SizedBox(height: 15 * s),
                  ProfileSkeletonSurface(
                    radius: 28,
                    depth: 7,
                    child: Padding(
                      padding:
                          EdgeInsets.fromLTRB(32 * s, 30 * s, 32 * s, 30 * s),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SkeletonBlock(
                                  width: 60 * s,
                                  height: 64 * s,
                                  radius: 18 * s),
                              SizedBox(width: 18 * s),
                              SkeletonBlock(
                                  width: 240 * s,
                                  height: 40 * s,
                                  radius: 10 * s),
                              const Spacer(),
                              SkeletonBlock(
                                  width: 190 * s,
                                  height: 64 * s,
                                  radius: 20 * s),
                            ],
                          ),
                          SizedBox(height: 34 * s),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (var i = 0; i < 7; i++)
                                Column(
                                  children: [
                                    SkeletonBlock(
                                        width: 44 * s,
                                        height: 20 * s,
                                        radius: 6 * s),
                                    SizedBox(height: 14 * s),
                                    SkeletonBlock(
                                        width: 52 * s,
                                        height: 52 * s,
                                        radius: 26 * s),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 34 * s),
                  ProfileSectionTitle(text: 'TOPLAM', scale: s),
                  SizedBox(height: 15 * s),
                  ProfileSkeletonSurface(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 28 * s),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [total(), total(), total(), total()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
