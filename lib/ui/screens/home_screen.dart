import 'package:flutter/material.dart';
import 'package:lingualloop/services/auth_service.dart';
import 'package:lingualloop/services/question_service.dart';
import 'package:lingualloop/ui/screens/video_quiz_screen.dart';
import 'package:lingualloop/ui/widgets/LessonCard.dart';
import 'package:provider/provider.dart';

import '../../models/User.dart';
import '../../providers/UserProvider.dart'; // Provider'ı ekliyoruz

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenScreenState createState() => _HomeScreenScreenState();
}

class _HomeScreenScreenState extends State<HomeScreen> {
  User? user;

  @override
  void initState() {
    super.initState();
    _getUser(context);
  }

  Future<void> _sendRequest(BuildContext context) async {
    final questionService = Provider.of<QuestionService>(context, listen: false);
    await questionService.random();
  }

  Future<void> _getUser(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    user = userProvider.user!;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Sol hizalama
          mainAxisSize: MainAxisSize.min, // AppBar'da fazla alan kaplamaması için
          children: [
             Text('Merhaba, ${user!.userNickname}', // İlk satır
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),
            ),
            Text('Almanca\'ya devam et!', // Alt satır
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ],
        ),
      ),


      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.35, // Ekranın %90'ını kapla
          child: Row(
            children: [
              Expanded(
                flex: 1, // Büyük kart için daha fazla alan
                child: LessonCard(
                  icon: Icons.style_outlined,
                  title: "Oyun Kartları",
                  progress: "300'den fazla oyun kartı",
                  color: Color(0xFFF66955),
                  onTap: () {
                    Navigator.pushNamed(context, '/videoquiz');
                  },
                ),
              ),
              SizedBox(width: 14), // Üst ve alt kartlar arası boşluk
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Kartları genişlet

                  children: [

                    // Üstteki küçük kart
                    Expanded(
                      child:  LessonCard(
                        icon: Icons.video_library_outlined,
                        title: "Video",
                        progress: "500'den fazla video",
                        color: Color(0xFFF4CE53),
                        onTap: () {
                          Navigator.pushNamed(context, '/videoquiz');
                        },
                      ),
                    ),
                    SizedBox(height: 14), // Üst ve alt kartlar arası boşluk
                    // Alttaki küçük kart
                    Expanded(
                      child:  LessonCard(
                        icon: Icons.description_outlined,
                        title: "Test",
                        progress: "Seviyeni belirle",
                        color: const Color(0xFF70c9c3),
                        onTap: () {
                          Navigator.pushNamed(context, '/videoquiz');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      ),
    );
  }
}