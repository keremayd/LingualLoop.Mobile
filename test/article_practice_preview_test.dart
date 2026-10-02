import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lingualloop/models/ArticlePractice.dart';
import 'package:lingualloop/providers/ArticlePracticeProvider.dart';
import 'package:lingualloop/services/ArticlePracticeService.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/screens/article_practice_screen.dart';
import 'package:lingualloop/ui/widgets/article_practice_card.dart';
import 'helpers/preview_fonts.dart';

const _capture = bool.fromEnvironment('ARTICLE_CAPTURE');
const _image = String.fromEnvironment('ARTICLE_PREVIEW_IMAGE',
    defaultValue: 'assets/icons/mascot_hello.png');

class _Service extends Fake implements ArticlePracticeService {}

class _Practice extends ArticlePracticeProvider {
  _Practice() : super(_Service()) {
    status = ArticlePracticeStatus.playing;
    task = const ArticlePracticeTask(
      kartyId: 1,
      nounText: 'Koffer',
      kartyUrl: '',
      localImagePath: _image,
      articleAttemptCount: 2,
      articleCorrectCount: 2,
      learningStack: 2,
      learningGoal: 5,
    );
    nextTask = task;
  }

  @override
  Future<void> loadNext({int completedTaskRetries = 0}) async {}
}

void main() {
  setUpAll(loadPreviewFonts);

  for (final width in [375.0, 430.0]) {
    testWidgets('Artikel kartları ve sürükleme önizlemesi: $width',
        (tester) async {
      tester.view.physicalSize = Size(width, width / 430 * 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.runAsync(() async {
        await precacheImage(FileImage(File(_image)),
                tester.element(find.byType(SizedBox).first))
            .timeout(const Duration(seconds: 10));
      });
      await tester.pumpWidget(ChangeNotifierProvider<ArticlePracticeProvider>(
        create: (_) => _Practice(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: AppTypography.family,
            textTheme: AppTypography.textTheme,
          ),
          home: const ArticlePracticeScreen(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      if (_capture && width == 430) {
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('goldens/article_practice_gradient.png'));
      }

      // Yeni yüzeyin kartın sürükleme hedefini engellemediğini doğrula.
      final card = find.byType(ArticlePracticeCard).last;
      final before = tester.getRect(card);
      final gesture = await tester.startGesture(before.center);
      await gesture.moveBy(Offset(120 * width / 750, 0));
      await gesture.moveBy(Offset(20 * width / 750, 0));
      await tester.pump(const Duration(milliseconds: 160));
      expect(
          tester.widget<ArticlePracticeCard>(card).highlightedArticle, 'der');
      expect(tester.getRect(card).center.dx, greaterThan(before.center.dx));
      expect(tester.takeException(), isNull);
      if (_capture && width == 430) {
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('goldens/article_practice_gradient_drag.png'));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
