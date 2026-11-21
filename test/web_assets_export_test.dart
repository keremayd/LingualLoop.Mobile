import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stelinda/ui/widgets/practice_station_marks.dart';
import 'package:stelinda/ui/widgets/premium_ticket_mark.dart';
import 'package:stelinda/ui/widgets/quest_icons.dart';

/// stelinda.com için uygulamanın simgelerini saydam PNG olarak dışa aktarır;
/// sitedeki simgeler elle çizilmez, uygulamadakinin aynısıdır.
///
///   WEB_EXPORT_DIR=<klasör> flutter test test/web_assets_export_test.dart
///
/// Normal koşuda atlanır.
final _dir = Platform.environment['WEB_EXPORT_DIR'];

/// Üst şeritteki ve Görevler başlığındaki bilet: kalınlık bandıyla
/// (`TicketBalance` ile aynı çizim, sayısız).
Widget _bandedTicket(double width) {
  final depth = width * 6 / 84;
  return SizedBox(
    width: width,
    height: width * 110 / 172 + depth,
    child: Stack(
      children: [
        Positioned(
          left: 0,
          top: depth,
          child: Image.asset(
            'assets/icons/ticket.png',
            width: width,
            fit: BoxFit.contain,
            color: const Color(0xFFB87E00),
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          child: Image.asset('assets/icons/ticket.png', width: width),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('site simgeleri dışa aktarılır', (tester) async {
    final out = Directory(_dir!)..createSync(recursive: true);
    // Yalnız sitede kullanılanlar; site yeni bir simge isterse buraya eklenir.
    final icons = <String, Widget>{
      'bilet': _bandedTicket(84),
      'premium-bilet': const PremiumTicketMark(width: 84),
      'artikel': const ArticleDragMark(size: 96),
      'alev': const QuestIcon(questKey: 'streak_three', size: 72),
      'simsek': const QuestIcon(questKey: 'correct_five', size: 72),
      'tekrar': const QuestIcon(questKey: 'review_two', size: 72),
    };

    for (final MapEntry(key: name, value: icon) in icons.entries) {
      final boundary = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          type: MaterialType.transparency,
          child: Center(
            child: RepaintBoundary(key: boundary, child: icon),
          ),
        ),
      ));
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          await precacheImage((element.widget as Image).image, element);
        }
      });
      await tester.pump();
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 3);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      File('${out.path}/$name.png').writeAsBytesSync(bytes!);
    }
    expect(out.listSync().whereType<File>().length, greaterThanOrEqualTo(6));
  }, skip: _dir == null);
}
