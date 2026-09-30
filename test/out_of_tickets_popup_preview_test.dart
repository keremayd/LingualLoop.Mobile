import 'helpers/preview_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/Popups/out_of_tickets_popup.dart';

/// Bilet bitti penceresi: uzun ve kisa geri sayimla iki durum.
void main() {
  setUpAll(loadPreviewFonts);
  Future<void> shot(WidgetTester tester, Duration left, String file) async {
    const size = Size(430, 932);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) => Material(
            color: const Color(0xFF041227),
            child: Center(
              child: OutOfTicketsCard(
                nextTicketAt: DateTime.now().toUtc().add(left),
                onRefreshTickets: () async => false,
                onTicketsReady: () {},
                questTickets: 7,
                onGoToReview: () {},
                onGoToQuests: () {},
                onGoPremium: () {},
              ),
            ),
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
      matchesGoldenFile('goldens/$file'),
    );
  }

  testWidgets('out of tickets - uzun sure', (tester) async {
    await shot(tester, const Duration(hours: 1, minutes: 24),
        'out_of_tickets_normal.png');
  });

  testWidgets('out of tickets - yakin sure', (tester) async {
    await shot(tester, const Duration(minutes: 8), 'out_of_tickets_urgent.png');
  });

  testWidgets('bekleyen rovanş yoksa yol pasif kalir', (tester) async {
    var openedReview = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OutOfTicketsCard(
          nextTicketAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          onRefreshTickets: () async => false,
          onTicketsReady: () {},
          reviewAvailable: false,
          onGoToReview: () => openedReview = true,
          onGoToQuests: () {},
          onGoPremium: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Bekleyen rövanş kartın yok'), findsOneWidget);
    await tester.tap(find.text('Rövanş oyna'));
    expect(openedReview, isFalse);
  });

  testWidgets('sure dolunca sunucudan bilet yeniler ve popup akisini bitirir',
      (tester) async {
    var refreshCount = 0;
    var readyHandled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OutOfTicketsCard(
          nextTicketAt:
              DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
          onRefreshTickets: () async {
            refreshCount += 1;
            return true;
          },
          onTicketsReady: () => readyHandled = true,
          onGoToReview: () {},
          onGoToQuests: () {},
          onGoPremium: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(refreshCount, 1);
    expect(readyHandled, isTrue);
    expect(find.text('Yeni biletin hazır'), findsNothing);
    expect(find.text('sonra yeni bilet'), findsNothing);
  });

  testWidgets('bilet yenileme istegini sunucunun verdigi andan once atmaz',
      (tester) async {
    var refreshCount = 0;
    var readyHandled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OutOfTicketsCard(
          nextTicketAt: DateTime.now().toUtc().add(const Duration(seconds: 10)),
          onRefreshTickets: () async {
            refreshCount += 1;
            return true;
          },
          onTicketsReady: () => readyHandled = true,
          onGoToReview: () {},
          onGoToQuests: () {},
          onGoPremium: () {},
        ),
      ),
    );
    await tester.pump();

    await tester.pump(const Duration(seconds: 9));
    expect(refreshCount, 0);
    expect(readyHandled, isFalse);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(refreshCount, 1);
    expect(readyHandled, isTrue);
  });
}
