import 'package:flutter/material.dart';
import 'package:lingualloop/models/Karty.dart';

class SwipableCard extends StatelessWidget {
  final Karty card;
  final Offset position;
  final double rotation;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;

  const SwipableCard({
    Key? key,
    required this.card,
    required this.position,
    required this.rotation,
    required this.onPanUpdate,
    required this.onPanEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Column(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Text(
              card.questionText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 35,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 10),
          Transform.translate(
            offset: position,
            child: Transform.rotate(
                angle: rotation,
                child: Container(
                  width: 230,
                  height: 350,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF7ED957),
                        Color(0xFF4DB4E7),
                        Colors.purpleAccent,
                        Color(0xFFFFD94C),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border.all(
                      color: Colors.white,
                      width: 8,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          card.kartyUrl,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ),
          ),
        ],
      )
    );
  }
}