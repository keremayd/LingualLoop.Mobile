import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Popups/VideoPopup.dart';


class SavedVideosCard extends StatelessWidget {
  final Color color;
  final List<String> videoTitle;
  final VoidCallback onTap;

  SavedVideosCard({
    required this.color,
    required this.videoTitle,
    required this.onTap,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            // Öğeleri hizalayın
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF7875FC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFF5F5CF0),
                        width: 4,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(right: 17, top: 7, left: 17, bottom: 7), // 10, 10, 12
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      // Elemanları sağa ve sola hizala
                      children: [
                        Text(
                          "Kaydedilenler",
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w700, height: 0),
                        ),
                        SizedBox(
                          child:
                          Text(
                            "Tümünü Gör",
                            style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: Align(
                      alignment: Alignment.center,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: BouncingScrollPhysics(),
                        itemCount: videoTitle.length,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              showVideoPopup(context, index);
                            },
                            child: Padding(
                              padding: EdgeInsets.only(right: 21),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.translate(
                                      offset: Offset(0, 4),
                                      child: Container(
                                        width: 74,
                                        height: 74,
                                        decoration: BoxDecoration(
                                          color: Color(0xFF5F5CF0).withOpacity(0.8), //Colors.black.withOpacity(0.3) hangisi karar ver
                                          borderRadius: BorderRadius.circular(18), // ← oval köşeler buradan geliyor
                                        ),
                                      )
                                  ),

                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF9FBFF),
                                      borderRadius: BorderRadius.circular(18), // ← oval köşeler buradan geliyor
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      videoTitle[index],
                                      style: TextStyle(
                                        color: Color(0xFF7875FC),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      )

                  ),
                ),
              ]
          ),
        ),
      );
    });
  }
}