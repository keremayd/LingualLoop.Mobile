import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/practice_station_marks.dart';

/// Yan durak simgeleri: Artikel Pusulası ve Rövanş, durak karosu
/// boyutunda ve büyük.
///
///   flutter test --update-goldens test/practice_station_marks_preview_test.dart
void main() {
  testWidgets('yan durak simgeleri', (tester) async {
    const size = Size(720, 360);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2.0;

    Widget tile(Widget child, double side) => Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            color: const Color(0xFF0C2244),
            borderRadius: BorderRadius.circular(side * 0.29),
          ),
          alignment: Alignment.center,
          child: child,
        );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          color: const Color(0xFF041227),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Row(
              children: [
                tile(const ArticleDragMark(size: 180), 260),
                const SizedBox(width: 24),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    tile(const ArticleDragMark(size: 52), 78),
                    const SizedBox(height: 16),
                    tile(const RevengeCardMark(size: 52), 78),
                  ],
                ),
                const SizedBox(width: 24),
                tile(const RevengeCardMark(size: 180), 260),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/practice_station_marks.png'),
    );
  });
}
