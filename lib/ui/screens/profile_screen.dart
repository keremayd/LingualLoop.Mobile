import 'package:flutter/material.dart';
import 'package:lingualloop/providers/BadgeProvider.dart';
import 'package:lingualloop/providers/UserProvider.dart';
import 'package:lingualloop/providers/VideoProvider.dart';
import 'package:lingualloop/ui/widgets/BadgesCard.dart';
import 'package:lingualloop/ui/widgets/ProfileCard.dart';
import 'package:lingualloop/ui/widgets/SavedVideosCard.dart';
import '../../services/AuthenticationService.dart';
import 'package:provider/provider.dart';

import '../widgets/LessonCard.dart';
import '../widgets/MainLessonCard.dart';
import 'login_screen.dart';


class ProfileScreen extends StatefulWidget {
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
      if (!isLoaded)
        print("Rozetler yüklenirken bir hata oluştu.");

      final resp = await videoProvider.getSavedVideos(context);


      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
          top: 65,  // 13
          left: 16, // 16
          right: 16, // 16
        ),
        child: Column(
            children: [
              SizedBox(
                child: ProfileCard(
                  color: Color(0xFF7875FC),
                ),
              ),
              SizedBox(height: 10),

              SizedBox(
                child: Column(
                    children: [
                      SizedBox(
                        height: 150, // 218.7
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1, // Eşit alan kaplaması için
                              child: Consumer<BadgeProvider>(
                                builder: (context, badgeProvider, child) {
                                  return BadgesCard(
                                    color: Color(0xFF7875FC),
                                    onTap: () async {},
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                ),
              ),
              SizedBox(height: 10),

              SizedBox(
                child: Column(
                    children: [
                      SizedBox(
                        height: 150, // 218.7
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1, // Eşit alan kaplaması için
                              child: Consumer<VideoProvider>(
                                builder: (context, videoProvider, child) {
                                  return SavedVideosCard(
                                    color: Color(0xFF7875FC),
                                    videoTitle: videoProvider.savedVideos.map((v) => v.video.videoTitle.substring(0, 7)).toList(),
                                    onTap: () async {},
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                ),
              ),


            ]
        ),
      )
    );
  }
}
