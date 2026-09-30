import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/quest_flag_mark.dart';

void main() {
  test('flag icon sheet', () async {
    final boltBytes = File(
      '/Users/kerem.aydin/Desktop/Repos/Lingualloop/LingualLoop.Mobile/assets/icons/boost-bolt.png',
    ).readAsBytesSync();
    final bolt =
        (await (await ui.instantiateImageCodec(boltBytes)).getNextFrame()).image;

    const w = 720.0, h = 300.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(const Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFF041227));

    final ratio = bolt.width / bolt.height;
    c.drawImageRect(
      bolt,
      Rect.fromLTWH(0, 0, bolt.width.toDouble(), bolt.height.toDouble()),
      Rect.fromLTWH(40, 60, 160 * ratio, 160),
      Paint(),
    );

    void tile(double x, double y, double tileSize) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, tileSize, tileSize),
        Radius.circular(tileSize * 0.235),
      );
      c.drawRRect(r, Paint()..color = const Color(0xFF0C2244));
      c.save();
      final icon = tileSize * 0.62;
      c.translate(x + (tileSize - icon) / 2, y + (tileSize - icon) / 2);
      QuestFlagPainter().paint(c, Size(icon, icon));
      c.restore();
    }

    tile(220, 60, 180);
    tile(440, 95, 110);
    tile(590, 120, 68);

    final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('/private/tmp/claude-503/-Users-kerem-aydin-Desktop-Repos-Lingualloop/c4cc6928-4c1c-4312-ae13-9e579aa02cdb/scratchpad/flag_v3.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
