import 'package:flutter/material.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/widgets/LessonCard.dart';
import 'package:lingualloop/ui/widgets/MainLessonCard.dart';
import 'package:lingualloop/ui/widgets/ProfilePhoto.dart';
import 'package:provider/provider.dart';

import '../../providers/ScoreWithLivesProvider.dart';
import '../../providers/UserProvider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenScreenState createState() => _HomeScreenScreenState();
}

class _HomeScreenScreenState extends State<HomeScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
    });
    await _getScoreWithLives(context);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getScoreWithLives(BuildContext context) async {
    final userService = Provider.of<UserService>(context, listen: false);
    await userService.scoreWithLivesById(context);
  }

  Future<void> _updateLivesAndRouter(BuildContext context, String routeUrl) async {
    final userService = Provider.of<UserService>(context, listen: false);

    var apiResponse = await userService.updateLivesById();
    if (apiResponse.errorCode == null) {
      Navigator.pushNamed(context, '/${routeUrl}');
      await userService.scoreWithLivesById(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double screenHeight = constraints.maxHeight; // 706.09
        double screenWidth = constraints.maxWidth; // 392.72

        return Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(130), // 93
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(
                      top: 65, // 40
                      left: screenHeight * 0.0226, // 16
                      right: screenHeight * 0.0226, // 16
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF0B2143), // Mor arkaplan
                      borderRadius: BorderRadius.circular(14), // Köşeleri yuvarla
                    ),
                    child: Column(
                      children: [
                        // Üst Koyu Mavi Alan
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4, right: 4, bottom: 4), 
                          child: Container(
                          padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.0226), // 16
                          decoration: BoxDecoration(
                            color: Color(0xFF041227),
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(14),
                                topRight: Radius.circular(14),
                                bottomLeft: Radius.circular(14),
                                bottomRight: Radius.circular(14)
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: 10, // 17
                              bottom: 10, // 17
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    ProfilePhotoWidget(width: 49, height: 49, borderRadius: 13, editable: false),
                                    SizedBox(width: screenWidth * 0.0254),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Consumer<UserProvider>(
                                          builder: (context, provider, child) {
                                            return Text(
                                              'Merhaba, ${provider.user?.firstName}',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        ),
                                        Text(
                                          'Almanca\'ya devam et!',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  width: screenWidth * 0.1247, // 49
                                  height: screenHeight * 0.0693, // 49
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF7F9FD), // Arka plan rengi mor
                                    borderRadius: BorderRadius.circular(14), // Köşeleri 14 px oval yap
                                  ),
                                  child: Center(
                                    child:  Image.asset(
                                      'assets/icons/diamond.png',
                                      height: screenHeight * 0.0410, // 29
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ),
                        )
                        ),
                        // Alt Mor Şerit
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.0226), // 16
                          decoration: BoxDecoration(
                            color: Color(0xFF0B2143), // Mor arkaplan
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(14),
                              bottomRight: Radius.circular(14),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(left: screenWidth * 0.005, top: screenHeight * 0.0028, bottom: screenHeight * 0.0028), // 2, 2, 2
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/icons/cup.png', // Coin simgesi
                                      height: screenHeight * 0.0311, // 22
                                      width: screenWidth * 0.0560, // 22
                                    ),
                                    SizedBox(width: screenWidth * 0.0127), // 5
                                    Consumer<ScoreWithLivesProvider>(
                                      builder: (context, provider, child) {
                                        return Text(
                                          "${provider.scoreWithLives?.score ?? ""}",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(width: screenWidth * 0.0381), // 15
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/icons/ticket.png', // Ticket simgesi
                                      height: screenHeight * 0.0269, // 19
                                      width: screenWidth * 0.0789, // 31
                                    ),
                                    SizedBox(width: screenWidth * 0.0127), // 5
                                    Consumer<ScoreWithLivesProvider>(
                                      builder: (context, provider, child) {
                                        return Text(
                                          "${provider.scoreWithLives?.lives}",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                    ),

                                  ],
                                ),
                              ],
                            ),),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            body: Padding(
              padding: EdgeInsets.only(
                top: screenHeight * 0.0226,  // 13
                left: screenWidth * 0.0407, // 16
                right: screenWidth * 0.0407, // 16
              ),
              child: Column(
                  children: [
                    SizedBox(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // Başlığı sola hizalamak için
                          children: [
                            // Başlık
                            Text(
                              "Yolculuğunu Sürdür",
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 0.0084), // 6
                            SizedBox(
                              //height: MediaQuery.of(context).size.height * 0.28, // 219
                              height: screenHeight * 0.30973, // 218.7
                              child: MainLessonCard(
                                title: "Solo Pratik!",
                                description: "Kendi hızınızda videolarla öğrenin ve pratik yapın.",
                                color: Color(0xFF1CB1F5),
                                onTap: () async {
                                  await _updateLivesAndRouter(context, 'videoquiz');
                                },
                              ),
                            ),
                          ]
                      ),
                    ),


                    SizedBox(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // Başlığı sola hizalamak için
                          children: [
                            SizedBox(height: screenHeight * 0.0283), // 20
                            Text(
                              "Diğer modlar",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.0056), // 4
                            SizedBox(
                              height: screenHeight * 0.30973, // 218.7
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1, // Eşit alan kaplaması için
                                    child: LessonCard(
                                      title: "Karty",
                                      description: "Kartları kaydır, yeni kelimeler öğren!",
                                      color: Color(0xFF93D334),
                                      borderColor: Color(0xFF628C22),
                                      imageName: "karty",
                                      onTap: () async {
                                        await _updateLivesAndRouter(context, 'kartyquiz');
                                      },
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.0509), // 20
                                  Expanded(
                                    flex: 1, // Eşit alan kaplaması için
                                    child: LessonCard(
                                      title: "Battle",
                                      description: "Rakiplerinle 10 soruda kapış!",
                                      color: Color(0xFFF52A2A),
                                      borderColor: Color(0xFFAA1C1C),
                                      imageName: "catsbattle",
                                      onTap: () async {
                                        await _updateLivesAndRouter(context, 'videoquiz');
                                      },
                                      childTitle: "1v1",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                    )
                  ]
              ),
            )
        );
      },
    );
  }
}