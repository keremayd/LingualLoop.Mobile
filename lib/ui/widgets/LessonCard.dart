import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LessonCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String progress;
  final Color color;
  final VoidCallback onTap; // Tıklama özelliği eklendi

  LessonCard({
    required this.icon,
    required this.title,
    required this.progress,
    required this.color,
    required this.onTap, // Tıklama işlevini zorunlu kılıyoruz
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Tıklama işlemi burada işleniyor
      child: Card(
        color: color,
        elevation: 5, // Gölgenin yüksekliği (1-24 arasında değerler alabilir)
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 45, color: Colors.white),
              SizedBox(height: 5),
              Text(
                title,
                style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                progress,
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
        ),
    );
  }
}
