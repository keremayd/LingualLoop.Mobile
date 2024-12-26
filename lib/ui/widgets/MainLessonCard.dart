import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MainLessonCard extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  MainLessonCard({
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: LayoutBuilder( // Card'ın boyutlarını ölçmek için
          builder: (context, constraints) {
            double cardHeight = constraints.maxHeight; // Card'ın toplam yüksekliği
            double ticketHeight = cardHeight * 0.106; // ticket-one.png'nin yüksekliği
            double ottaHeight = cardHeight - ticketHeight - 10; // Kalan yükseklik

            return Padding(
              padding: const EdgeInsets.only(right: 10.0, top: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Öğeleri hizalayın
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Image.asset(
                        'assets/icons/ticket-one.png',
                        height: ticketHeight,
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Satır içi dikey hizalamayı başa al
                    children: [
                      Flexible(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.topLeft, // Resmi sola hizala
                          child: Image.asset('assets/images/otta.png', height: ottaHeight),
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(height: 5),
                            Text(
                              textAlign: TextAlign.right,
                              title,
                              style: TextStyle(
                                  fontSize: 30,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              textAlign: TextAlign.right,
                              description,
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )],
              ),
            );
          },
        ),
      ),
    );
  }
}
