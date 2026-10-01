import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/karty_sound_button.dart';
import 'package:lingualloop/ui/widgets/karty_answer_actions.dart';
import 'package:lingualloop/ui/widgets/speaker_mark.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';

void main() {
  testWidgets('Ses dalgaları çalarken hareket eder, bitince ve sessizde durur',
      (tester) async {
    Future<void> show({
      bool speaking = false,
      bool muted = false,
      bool reduceMotion = false,
    }) =>
        tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: Center(
              child: KartySoundButton(
                  scale: 0.6,
                  muted: muted,
                  speaking: speaking,
                  onToggle: () {}),
            ),
          ),
        ));
    double wave() => tester.widget<SpeakerMark>(find.byType(SpeakerMark)).wave;

    await show();
    final bounds = tester.getRect(find.byType(KartySoundButton));
    expect(wave(), 0);
    await show(speaking: true);
    await tester.pump(const Duration(milliseconds: 160));
    final first = wave();
    expect(first, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 160));
    expect(wave(), isNot(first));
    expect(tester.getRect(find.byType(KartySoundButton)), bounds);

    await show(speaking: true, muted: true);
    await tester.pump(const Duration(milliseconds: 200));
    expect(wave(), 0);
    await show(speaking: true);
    await tester.pump(const Duration(milliseconds: 160));
    expect(wave(), greaterThan(0));
    await show();
    await tester.pump(const Duration(milliseconds: 200));
    expect(wave(), 0);

    await show(speaking: true, reduceMotion: true);
    final still = wave();
    await tester.pump(const Duration(milliseconds: 200));
    expect(wave(), still);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ses kontrolü 44 px dokunma alanında açılır ve kapanır',
      (tester) async {
    var muted = false;
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child: StatefulBuilder(
      builder: (context, setState) => KartySoundButton(
        scale: 320 / 750,
        muted: muted,
        onToggle: () => setState(() {
          muted = !muted;
          taps++;
        }),
      ),
    ))));
    final button = find.byType(KartySoundButton);
    expect(tester.getSize(button).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<SpeakerMark>(find.byType(SpeakerMark)).muted, isTrue);
    expect(find.byTooltip('Sesi aç'), findsOneWidget);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 100));
    expect(taps, 2);
    expect(tester.widget<SpeakerMark>(find.byType(SpeakerMark)).muted, isFalse);
    expect(find.byTooltip('Sesi kapat'), findsOneWidget);
  });

  testWidgets('Dar ekranda ses kontrolü tanışma eylemini örtmez',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const s = 320 / 750;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Stack(children: [
      Positioned(
          top: 1348 * s,
          left: 0,
          right: 0,
          child: KartyAnswerActions(
              scale: s,
              isIntroducing: true,
              onWrong: () {},
              onCorrect: () {},
              onContinue: () {})),
      Positioned(
          top: 100 * s,
          left: 40 * s,
          child: KartySoundButton(scale: s, muted: true, onToggle: () {})),
    ]))));
    final sound = tester.getRect(find.byType(KartySoundButton));
    final action = tester.getRect(find.ancestor(
        of: find.text('ANLADIM'), matching: find.byType(DepthPressableButton)));
    expect(sound.overlaps(action), isFalse);
    expect(sound.bottom, lessThan(700));
    expect(tester.takeException(), isNull);
  });
}
