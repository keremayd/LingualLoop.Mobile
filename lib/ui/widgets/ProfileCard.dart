import 'package:flutter/material.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:provider/provider.dart';
import '../../models/User.dart';
import '../../providers/UserProvider.dart';
import 'CustomIconButton.dart'; // CustomIconButton widget'ının bulunduğu dosya

class ProfileCard extends StatelessWidget {
  final Color color;

  ProfileCard({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    User? user = Provider.of<UserProvider>(context).user;

    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: LayoutBuilder( // Card'ın boyutlarını ölçmek için
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Öğeleri hizalayın
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 20.0, top: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomIconButton(
                      img: 'settings',
                      backgroundColor: Color(0xFFF7F9FD),
                      iconColor: Color(0xFF5F5CF0),
                      buttonSize: 18,
                      padding: 9,
                      ontap: () async {},
                    ),
                  ],
                ),

              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.center, // Resmi sola hizala
                    child: Image.asset('assets/icons/profilephoto.png', height: 75),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 5),
                  Text(
                    textAlign: TextAlign.center,
                    '@${user?.userNickname}',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  Text(
                    textAlign: TextAlign.center,
                    '${user?.displayName}',
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 25, top: 15, bottom: 25, left: 25),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // Arka plan rengini beyaz yapıyoruz
                    borderRadius: BorderRadius.circular(18), // Ovallık için köşe yuvarlama
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFF5F5CF0),
                        width: 4,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10, top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center, // Öğeleri dikeyde hizalamak için
                      children: [
                        // Kupa bölümü
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center, // Yatayda ortalama
                          crossAxisAlignment: CrossAxisAlignment.center, // Dikeyde ortalama
                          children: [
                            Image.asset(
                              'assets/icons/cup.png',
                              height: 26,
                            ),
                            Text(
                              'Kupa',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF7875FC),
                                  fontWeight: FontWeight.bold),
                            ),
                            Consumer<ScoreWithLivesProvider>(
                              builder: (context, scoreWithLivesProvider, child) {
                                return Text(
                                  '${scoreWithLivesProvider.scoreWithLives?.score ?? 0}',
                                  style: TextStyle(
                                      fontSize: 19,
                                      color: Color(0xFF5F5CF0),
                                      fontWeight: FontWeight.w800),
                                );
                              },
                            ),
                          ],
                        ),
                        Container(
                          height: 60, // Çizginin yüksekliği
                          width: 1, // Çizginin kalınlığı
                          color: Color(0xFF7875FC), // Çizginin mor rengi
                        ),
                        // Liderlik bölümü
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center, // Yatayda ortalama
                          crossAxisAlignment: CrossAxisAlignment.center, // Dikeyde ortalama
                          children: [
                            Image.asset(
                              'assets/icons/leader.png',
                              height: 26,
                            ),
                            Text(
                              'Liderlik',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF7875FC),
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '#5', // Liderlik numarasını ekledim
                              style: TextStyle(
                                  fontSize: 19,
                                  color: Color(0xFF5F5CF0),
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        Container(
                          height: 60, // Çizginin yüksekliği
                          width: 1, // Çizginin kalınlığı
                          color: Color(0xFF7875FC), // Çizginin mor rengi
                        ),
                        // Bilet bölümü
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center, // Yatayda ortalama
                          crossAxisAlignment: CrossAxisAlignment.center, // Dikeyde ortalama
                          children: [
                            Image.asset(
                              'assets/icons/ticket.png',
                              height: 19,
                            ),
                            Text(
                              'Bilet',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF7875FC),
                                  fontWeight: FontWeight.bold),
                            ),
                            Consumer<ScoreWithLivesProvider>(
                              builder: (context, scoreWithLivesProvider, child) {
                                return Text(
                                  '${scoreWithLivesProvider.scoreWithLives?.lives ?? 0}',
                                  style: TextStyle(
                                      fontSize: 19,
                                      color: Color(0xFF5F5CF0),
                                      fontWeight: FontWeight.w800),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )

            ],
          );
        },
      ),
    );
  }
}