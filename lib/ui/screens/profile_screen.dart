import 'package:flutter/material.dart';
import 'package:lingualloop/providers/BadgeProvider.dart';
import 'package:lingualloop/providers/UserProvider.dart';
import 'package:lingualloop/providers/VideoProvider.dart';
import 'package:lingualloop/ui/widgets/BadgesCard.dart';
import 'package:lingualloop/ui/widgets/ProfileCard.dart';
import 'package:lingualloop/ui/widgets/SavedVideosCard.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProvider userProvider;
  late BadgeProvider badgeProvider;
  late VideoProvider videoProvider;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    badgeProvider = Provider.of<BadgeProvider>(context, listen: false);
    videoProvider = Provider.of<VideoProvider>(context, listen: false);

    Future.microtask(() async {
      final isLoaded = await badgeProvider.loadBadges(context);
      if (!isLoaded) {
        print("Rozetler yüklenirken bir hata oluştu.");
      }

      await videoProvider.getSavedVideos(context);

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
          24 * scale,
          40 * scale,
          52 * scale,
        ),
        child: Column(
          children: [
            const ProfileCard(color: Color(0xFF0C2244)),
            SizedBox(height: 54 * scale),
            Consumer<BadgeProvider>(
              builder: (context, badgeProvider, child) => BadgesCard(
                color: const Color(0xFF0C2244),
                onTap: () async {},
              ),
            ),
            SizedBox(height: 58 * scale),
            Consumer<VideoProvider>(
              builder: (context, videoProvider, child) => SavedVideosCard(
                color: const Color(0xFF0C2244),
                videoTitle: videoProvider.savedVideos
                    .map((v) => v.video.videoTitle.substring(0, 7))
                    .toList(),
                onTap: () async {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
