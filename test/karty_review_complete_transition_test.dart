import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/karty_review_complete_state.dart';

void main() {
  testWidgets('rövanş sonucu katmanlı girer ve butonu sona kadar kilitler',
      (tester) async {
    tester.view.physicalSize = const Size(750, 1624);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF041227),
          body: KartyReviewCompleteState(
            scale: 1,
            rewardTickets: 1,
            onClose: () {},
          ),
        ),
      ),
    );

    final title = find.text('Rövanşı tamamladın!');
    final titleFadeFinder = find.ancestor(
      of: title,
      matching: find.byType(FadeTransition),
    );
    double titleOpacity() =>
        tester.widgetList<FadeTransition>(titleFadeFinder).fold<double>(
              1,
              (lowest, widget) =>
                  widget.opacity.value < lowest ? widget.opacity.value : lowest,
            );
    expect(titleOpacity(), 0);

    final button = find.text('ANA MENÜYE DÖN');
    bool buttonIsBlocked() => tester
        .widgetList<IgnorePointer>(
          find.ancestor(of: button, matching: find.byType(IgnorePointer)),
        )
        .any((widget) => widget.ignoring);

    expect(buttonIsBlocked(), isTrue);

    await tester.pump(const Duration(milliseconds: 500));
    final midwayOpacity = titleOpacity();
    expect(midwayOpacity, greaterThan(0));
    expect(midwayOpacity, lessThan(1));
    expect(buttonIsBlocked(), isTrue);

    await tester.pump(const Duration(milliseconds: 600));
    expect(titleOpacity(), closeTo(1, 0.001));
    expect(buttonIsBlocked(), isFalse);
  });
}
