import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stelinda/models/karty_path.dart';
import 'package:stelinda/ui/app_typography.dart';
import 'package:stelinda/ui/screens/karty_path_screen.dart';
import 'package:stelinda/ui/widgets/app_bottom_nav_bar.dart';

import 'helpers/karty_path_preview.dart';
import 'helpers/preview_fonts.dart';

/// "Bulunduğun desteye dön" düğmesi, gerçek cihaz boyutunda: patika
/// kaydırılıp şu anki deste ekrandan çıkınca sağ altta belirir, ok destenin
/// kaldığı yöne bakar. Üç kare: geçmişe kaydırınca (ok aşağı), ileriye
/// kaydırınca (ok yukarı) ve dokununca varılan yer (düğme yok).
///
///   flutter test --update-goldens test/karty_path_back_to_current_preview_test.dart
void main() {
  setUpAll(loadPreviewFonts);

  ImageProvider img(String name) => MemoryImage(
        File('test/fixtures/karty_words/$name.png').readAsBytesSync(),
      );

  KartyUnit doneUnit(int number, String title, String emblem) => KartyUnit(
        number: number,
        title: title,
        state: KartyUnitState.done,
        wordCount: 24,
        consolidatedCount: 22,
        emblem: img(emblem),
        steps: [
          for (var deck = 1; deck <= 3; deck++)
            KartyStep(
              state: KartyStepState.done,
              deck: deck,
              label: 'Deste $deck',
            ),
        ],
      );

  final data = KartyPathData(
    units: [
      doneUnit(1, 'Evde', 'haus'),
      doneUnit(2, 'Sofrada', 'brot'),
      KartyUnit(
        number: 3,
        title: 'İnsanlar',
        state: KartyUnitState.current,
        wordCount: 24,
        consolidatedCount: 6,
        emblem: img('tasche'),
        steps: const [
          KartyStep(state: KartyStepState.done, deck: 1, label: 'Deste 1'),
          KartyStep(
            state: KartyStepState.current,
            deck: 2,
            label: 'Deste 2',
            newCount: 3,
            learnedCount: 3,
            reviewCount: 4,
          ),
          KartyStep(state: KartyStepState.upcoming, deck: 3, label: 'Deste 3'),
        ],
      ),
      KartyUnit(
        number: 4,
        title: 'Okulda',
        state: KartyUnitState.locked,
        wordCount: 24,
        emblem: img('buch'),
        unlockHint: "İnsanlar'ın %80'i pekişince açılır",
        steps: const [
          KartyStep(state: KartyStepState.locked, deck: 1),
          KartyStep(state: KartyStepState.locked, deck: 2),
          KartyStep(state: KartyStepState.locked, deck: 3),
        ],
      ),
    ],
  );

  Widget phone(ScrollController controller) => ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: SizedBox(
          width: 430,
          height: 932,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(430, 932),
              padding: EdgeInsets.only(top: 47, bottom: 34),
              devicePixelRatio: 2,
              disableAnimations: true,
            ),
            child: Scaffold(
              backgroundColor: const Color(0xFF041227),
              body: SafeArea(
                bottom: false,
                child: KartyPathScreen(
                  data: data,
                  controller: controller,
                  onContinue: () {},
                  stations: previewStations(),
                  header: previewPathHeader,
                ),
              ),
              bottomNavigationBar:
                  AppBottomNavBar(selectedIndex: 0, onTap: (_) {}),
            ),
          ),
        ),
      );

  Widget board(List<(String, String, Widget)> frames) => Material(
        color: const Color(0xFF020A18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 34, 40, 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, (title, subtitle, frame)) in frames.indexed) ...[
                if (i > 0) const SizedBox(width: 40),
                Column(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: AppTypography.heading,
                        fontFamily: AppTypography.displayFamily,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8FA0B5),
                        fontSize: 16,
                        fontWeight: AppTypography.body,
                        fontFamily: AppTypography.family,
                      ),
                    ),
                    const SizedBox(height: 22),
                    frame,
                  ],
                ),
              ],
            ],
          ),
        ),
      );

  testWidgets('desteye dön düğmesi — üç kare', (tester) async {
    const size = Size(40 + 3 * 430 + 2 * 40 + 40, 34 + 90 + 932 + 40);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final past = ScrollController();
    final ahead = ScrollController();
    final home = ScrollController();
    addTearDown(past.dispose);
    addTearDown(ahead.dispose);
    addTearDown(home.dispose);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: board([
          (
            'Geçmişe kaydırınca',
            'Deste aşağıda kaldı, ok aşağı bakar',
            phone(past),
          ),
          (
            'İleriye kaydırınca',
            'Deste yukarıda kaldı, ok yukarı bakar',
            phone(ahead),
          ),
          (
            'Dokununca',
            'Kamera desteye kayar, düğme söner',
            phone(home),
          ),
        ]),
      ),
    );
    // İlk kare şu anki desteyi ortalar; iki telefon sonra kaydırılır.
    await tester.pump();
    // Ünite 2'nin başlığı tepede: geçmişte bir ünite.
    past.jumpTo(past.position.maxScrollExtent * 0.3);
    ahead.jumpTo(ahead.position.maxScrollExtent);
    await tester.pump();
    await precachePreviewImages(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/karty_path_back_to_current.png'),
    );
  });
}
