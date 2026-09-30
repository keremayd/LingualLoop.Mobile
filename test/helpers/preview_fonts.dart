import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/app_typography.dart';

Future<void> loadPreviewFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final rubik = FontLoader(AppTypography.family);
  for (final weight in ['SemiBold', 'Bold', 'ExtraBold']) {
    rubik.addFont(rootBundle.load('assets/fonts/Rubik-$weight.ttf'));
  }
  final baloo = FontLoader(AppTypography.displayFamily)
    ..addFont(rootBundle.load('assets/fonts/Baloo2-ExtraBold.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([rubik.load(), baloo.load(), icons.load()]);
}

Future<void> precachePreviewImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pump();
}
