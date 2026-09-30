import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/premium_ticket_mark.dart';

/// Silueti dogrulama: ust siradaki yan yana, alt siradaki **ust uste**.
/// Ust uste binen durumda kenarda altin gorunuyorsa siluet tutmuyor demektir.
void main() {
  testWidgets('premium ticket silhouette check', (tester) async {
    const size = Size(760, 620);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: const Color(0xFF041227),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Image.asset('assets/icons/ticket.png', width: 300),
                  const PremiumTicketMark(width: 300),
                ],
              ),
              // Ust uste: altin altta, premium ustte. Kenarda altin cizgi
              // gorunurse siluetler ayni degil demektir.
              SizedBox(
                width: 300,
                height: 300 / PremiumTicketMark.aspectRatio,
                child: Stack(
                  children: [
                    Image.asset('assets/icons/ticket.png', width: 300),
                    const PremiumTicketMark(width: 300),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Image.asset('assets/icons/ticket.png', width: 110),
                  const PremiumTicketMark(width: 110),
                  Image.asset('assets/icons/ticket.png', width: 58),
                  const PremiumTicketMark(width: 58),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/premium_ticket.png'),
    );
  });
}
