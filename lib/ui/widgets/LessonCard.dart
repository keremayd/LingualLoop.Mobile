import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LessonCard extends StatelessWidget {
  final String title;
  final String? childTitle;
  final String description;
  final Color color;
  final String imageName;
  final VoidCallback onTap;

  LessonCard({
    required this.title,
    required this.description,
    required this.color,
    required this.imageName,
    required this.onTap,
    this.childTitle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
        double screenHeight = constraints.maxHeight; // 218.697
        double screenWidth = constraints.maxWidth; // 170.384

        return GestureDetector(
          onTap: onTap, // Tıklama işlemi burada işleniyor
          child: Card(
              color: color,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: EdgeInsets.only(right: screenWidth * 0.0586, top: screenHeight * 0.0457, left: screenWidth * 0.0704), // 10, 10, 12
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // Öğeleri hizalayın
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      // Elemanları sağa ve sola hizala
                      children: [
                        Text(
                          title,
                          style: TextStyle(fontSize: 25,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 0,),
                        ),
                        Image.asset(
                          'assets/icons/ticket-one.png',
                          height: screenHeight * 0.1026, // 22.45
                        ),
                      ],
                    ),
                    SizedBox(height: 0), // Ekstra boşlukları kontrol et
                    Row(
                      children: [
                        Text(
                          childTitle ?? "",
                          style: TextStyle(fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 0,),
                        ),
                      ],
                    ),
                    SizedBox(
                      child:
                      Text(
                        description,
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // Satır içi dikey hizalamayı başa al
                      children: [
                        Flexible(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.center, // Resmi sola hizala
                            child: Image.asset(
                                'assets/images/$imageName.png', height: screenHeight * 0.4572), // 100
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
          ),
        );
      },
    );
  }
}
