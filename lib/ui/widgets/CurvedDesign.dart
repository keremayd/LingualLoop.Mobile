import 'package:flutter/material.dart';

class CustomDesignWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60, // Görsele göre bir yükseklik
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF5F5CEF), // Sol tarafın rengi
            Color(0xFF7875FC), // Sağ tarafın rengi
          ],
          stops: [0.5, 0.5], // Eşit şekilde bölmek için
        ),
      ),
      child: Stack(
        children: [
          // Üst bölüm
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              height: 30, // Üst kısmın yüksekliği
              decoration: BoxDecoration(
                color: Color(0xFF5F5CEF), // Üst kısım sabit renk (mor)
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(25), // Oval köşe
                ),
              ),
            ),
          ),
          // Alt bölüm
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              height: 30, // Alt kısmın yüksekliği
              decoration: BoxDecoration(
                color: Color(0xFF7875FC), // Alt kısım sabit renk (mavi)
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50), // Oval köşe
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
