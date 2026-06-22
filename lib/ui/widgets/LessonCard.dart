import 'package:flutter/material.dart';

class LessonCard extends StatefulWidget {
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;
  final String title;
  final String? childTitle;
  final String description;
  final String imageName;

  const LessonCard({
    Key? key,
    this.onTap,
    required this.color,
    required this.borderColor,
    required this.title,
    this.childTitle,
    required this.description,
    required this.imageName,
  }) : super(key: key);

  @override
  State<LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<LessonCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
        double screenHeight = constraints.maxHeight; // 218.697
        double screenWidth = constraints.maxWidth; // 170.384
        String imageName = widget.imageName;

        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap?.call();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 40), // Butonun aşağı çökme süresi
            transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0),
            decoration: BoxDecoration(
              boxShadow: _isPressed
                  ? [ BoxShadow(color: widget.borderColor, offset: const Offset(0, 2)) ]
                  : [ BoxShadow(color: widget.borderColor, offset: const Offset(0, 6)) ],
              borderRadius: BorderRadius.circular(14),
              
            ),
            child: Card(
              color: widget.color,
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
                          widget.title,
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
                          widget.childTitle ?? "",
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
                        widget.description,
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
              ),
            ),
          ),
        );
      },
    );
  }
}
