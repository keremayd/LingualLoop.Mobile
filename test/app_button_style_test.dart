import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';

void main() {
  testWidgets('Global style keeps layout stable while pressing and disabling',
      (tester) async {
    var taps = 0;
    var enabled = true;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(
      child: StatefulBuilder(builder: (context, setState) {
        update = setState;
        return DepthPressableButton(
          width: 180,
          height: 48,
          radius: 13,
          shadowOffset: 5,
          backgroundColor: Colors.blue,
          shadowColor: Colors.indigo,
          fontSize: 16,
          enabled: enabled,
          onPressed: () => taps++,
          child: const Text('Devam', key: ValueKey('label')),
        );
      }),
    ))));
    final button = find.byType(DepthPressableButton);
    final rect = tester.getRect(button);
    final labelTop = tester.getTopLeft(find.byKey(const ValueKey('label'))).dy;
    final gesture = await tester.startGesture(rect.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    expect(tester.getRect(button), rect);
    expect(tester.getTopLeft(find.byKey(const ValueKey('label'))).dy,
        greaterThan(labelTop));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.getRect(button), rect);
    update(() => enabled = false);
    await tester.pumpAndSettle();
    expect(tester.getRect(button), rect);
    await tester.tap(button);
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
