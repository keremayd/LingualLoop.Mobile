import 'package:provider/provider.dart';
import 'package:lingualloop/services/PronunciationService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/karty_answer_feedback_effect.dart';
import 'helpers/preview_fonts.dart';

class _SilentAudio extends Fake implements PronunciationService {
  @override
  final isSpeaking = ValueNotifier(false);
  @override
  final isMuted = ValueNotifier(false);
}

void main() {
  setUpAll(loadPreviewFonts);

  testWidgets('Rubik uzun Almanca kelimeyi kesmeden yuvaya sığdırır',
      (tester) async {
    final audio = _SilentAudio();
    addTearDown(audio.isSpeaking.dispose);
    addTearDown(audio.isMuted.dispose);
    final correct = ValueNotifier(false);
    final wrong = ValueNotifier(false);
    addTearDown(correct.dispose);
    addTearDown(wrong.dispose);
    addTearDown(tester.view.reset);
    for (final width in [320.0, 430.0]) {
      tester.view.physicalSize = Size(width, 932);
      tester.view.devicePixelRatio = 1;
      for (final text in ['Tresor', 'Schlüssel', 'Sehenswürdigkeit']) {
        await tester.pumpWidget(Provider<PronunciationService>.value(
            value: audio,
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: width - 32,
                    child: KartyFeedbackWord(
                      article: text == 'Sehenswürdigkeit' ? 'die' : 'der',
                      text: text,
                      scale: width / 750,
                      isCorrectActive: correct,
                      isWrongActive: wrong,
                      onPronounce: () {},
                    ),
                  ),
                ),
              ),
            )));
        final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
        expect(paragraph.didExceedMaxLines, isFalse);
        final start = paragraph.localToGlobal(Offset.zero);
        final end =
            paragraph.localToGlobal(paragraph.size.bottomRight(Offset.zero));
        final article = tester
            .getRect(find.text(text == 'Sehenswürdigkeit' ? 'die' : 'der'));
        expect(start.dx, greaterThan(article.right));
        expect(end.dx, lessThanOrEqualTo(width - 16));
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
