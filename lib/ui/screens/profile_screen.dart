import 'package:flutter/material.dart';
import 'package:lingualloop/providers/BadgeProvider.dart';
import 'package:lingualloop/providers/UserProvider.dart';
import 'package:lingualloop/ui/widgets/BadgesCard.dart';
import 'package:lingualloop/ui/widgets/ProfileCard.dart';
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


  Future<void> _logout(BuildContext context) async {
    userProvider.clearUser();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()),);

    print('The user is logout');
  }

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    badgeProvider = Provider.of<BadgeProvider>(context, listen: false);

    Future.microtask(() async {

      final isLoaded = await badgeProvider.loadBadges(context);
      if (!isLoaded)
        print("Rozetler yüklenirken bir hata oluştu.");

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
          top: 50,  // 13
          left: 16, // 16
          right: 16, // 16
        ),
        child: Column(
            children: [
              SizedBox(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Başlığı sola hizalamak için
                    children: [
                      SizedBox(
                        //height: MediaQuery.of(context).size.height * 0.28, // 219
                        height: 248.7, // 218.7
                        child: ProfileCard(
                          title: "Solo Pratik!",
                          description: "Kendi hızınızda videolarla öğrenin ve pratik yapın.",
                          color: Color(0xFF7875FC),
                          onTap: () async {
                          },
                        ),
                      ),
                    ]
                ),
              ),


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
                                    badgeNames: badgeProvider.badges.map((b) => b.badgeUrl).toList(),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0), // Oval kenarlar
                    ),
                    backgroundColor:  Color(0xFF7875FC),
                    minimumSize: Size(double.infinity, 58), // Yüksekliği input alanlarına eşitle
                  ),
                  onPressed: () => _logout(context),
                  child: Text('Çıkış Yap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white)),
                ),
              ),
            ]
        ),
      )
    );
  }
}
