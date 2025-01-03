import 'package:flutter/material.dart';

class SwipableCard extends StatefulWidget {
  @override
  _SwipableCardState createState() => _SwipableCardState();
}

class _SwipableCardState extends State<SwipableCard> {
  Offset _position = Offset(0, 0);
  double _rotation = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Center(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _position += details.delta;
                  _rotation = _position.dx / 300; // Kartın döndürme miktarı
                });
              },
              onPanEnd: (details) {
                if (_position.dx > 100) {
                  // Sağa kaydırma
                  print("Swiped Right");
                } else if (_position.dx < -100) {
                  // Sola kaydırma
                  print("Swiped Left");
                }
                setState(() {
                  // Kartı başlangıç pozisyonuna sıfırla
                  _position = Offset(0, 0);
                  _rotation = 0;
                });
              },
              child: Transform.translate(
                offset: _position,
                child: Transform.rotate(
                  angle: _rotation,
                  child: Container(
                    width: 200, // Kart genişliği
                    height: 300, // Kart yüksekliği
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF7ED957), // Yeşil ton
                          Color(0xFF4DB4E7), // Mavi ton
                          Colors.purpleAccent,
                          Color(0xFFFFD94C), // Sarı ton
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomCenter,
                      ),
                      border: Border.all(
                        color: Colors.white, // Beyaz çerçeve
                        width: 4, // Çerçeve kalınlığı
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Swipe Me",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
