import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/User.dart';
import '../../providers/UserProvider.dart';
import 'CustomIconButton.dart'; // CustomIconButton widget'ının bulunduğu dosya

class ProfileCard extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  ProfileCard({
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    User? user = Provider.of<UserProvider>(context).user;

    return GestureDetector(
      onTap: onTap,
      child: Card(
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
                        clickedImg: 'settings',
                        backgroundColor: Color(0xFFF7F9FD),
                        iconColor: Colors.black,
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
                      '${user?.userName}',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(),
                    Column(),
                    Column()
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}