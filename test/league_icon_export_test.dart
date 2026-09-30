import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/league_badge_mark.dart';

const _exportDir =
    '/Users/kerem.aydin/Desktop/Repos/Lingualloop/tmp/league_icons';
const _assetPath =
    '/Users/kerem.aydin/Desktop/Repos/Lingualloop/LingualLoop.Mobile/assets/icons/league.png';

const _leagueKeys = [
  'merkur',
  'aytasi',
  'yildiz',
  'kuyruklu',
  'mars',
  'uranus',
  'saturn',
  'nebula',
  'kosmoz',
  'supernova',
  'pulsar',
];

Future<void> _writePng(ui.Image image, String path) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(path).writeAsBytes(bytes!.buffer.asUint8List());
}

/// Loop şimşeği; [box] içine oturur (rozetlerdeki bolt ile aynı oranlar).
Path _boltPath(Rect box) {
  final w = box.width;
  final h = box.height;
  final l = box.left;
  final t = box.top;

  return Path()
    ..moveTo(l + w * 0.64, t)
    ..lineTo(l + w * 0.14, t + h * 0.56)
    ..lineTo(l + w * 0.46, t + h * 0.56)
    ..lineTo(l + w * 0.36, t + h)
    ..lineTo(l + w * 0.86, t + h * 0.44)
    ..lineTo(l + w * 0.54, t + h * 0.44)
    ..close();
}

Path _union(Iterable<Path> paths) {
  return paths.reduce(
    (a, b) => Path.combine(PathOperation.union, a, b),
  );
}

/// Çerçeveyi dolduran kupa: mürekkep alanı 96'lık tuvalin tamamına yayılır
/// ki navbar'daki ev/profil ikonlarıyla aynı optik büyüklükte dursun.
Path boldTrophyGlyph() {
  final bowl = Path()
    ..moveTo(14, 6)
    ..lineTo(82, 6)
    ..cubicTo(82, 34, 72, 52, 48, 56)
    ..cubicTo(24, 52, 14, 34, 14, 6)
    ..close();

  final earLeft = Path()..addOval(const Rect.fromLTRB(0, 15, 22, 39));
  final earRight = Path()..addOval(const Rect.fromLTRB(74, 15, 96, 39));

  final stem = Path()
    ..addRRect(RRect.fromLTRBR(38, 54, 58, 68, const Radius.circular(4)));
  final flare = Path()
    ..moveTo(34, 65)
    ..lineTo(62, 65)
    ..lineTo(67, 77)
    ..lineTo(29, 77)
    ..close();
  final base = Path()
    ..addRRect(RRect.fromLTRBR(18, 75, 78, 92, const Radius.circular(8)));

  return _union([bowl, earLeft, earRight, stem, flare, base]);
}

/// Tombul kupa: küçük boyut okunabilirliği için tek kütleli, kalın formlar.
/// [ears] kulp çıkıntıları, [bolt] gövdeye şimşek oyuğu ekler.
Path fatTrophyGlyph({bool ears = true, bool bolt = false}) {
  final rim = Path()
    ..addRRect(RRect.fromLTRBR(18, 10, 78, 21, const Radius.circular(5.5)));

  final bowl = Path()
    ..moveTo(22, 18)
    ..lineTo(74, 18)
    ..cubicTo(74, 42, 64, 55, 48, 57)
    ..cubicTo(32, 55, 22, 42, 22, 18)
    ..close();

  final parts = <Path>[rim, bowl];

  if (ears) {
    parts.add(Path()..addOval(const Rect.fromLTRB(9, 23, 27, 41)));
    parts.add(Path()..addOval(const Rect.fromLTRB(69, 23, 87, 41)));
  }

  parts.add(
    Path()..addRRect(RRect.fromLTRBR(41, 54, 55, 67, const Radius.circular(3))),
  );
  parts.add(
    Path()
      ..moveTo(37, 64)
      ..lineTo(59, 64)
      ..lineTo(63, 73)
      ..lineTo(33, 73)
      ..close(),
  );
  parts.add(
    Path()..addRRect(RRect.fromLTRBR(26, 71, 70, 84, const Radius.circular(6))),
  );

  final cup = _union(parts);
  if (!bolt) return cup;

  return Path.combine(
    PathOperation.difference,
    cup,
    _boltPath(const Rect.fromLTWH(38, 23, 20, 26)),
  );
}

/// Kupa: gövdesine loop şimşeği işlenmiş klasik lig kupası.
Path trophyGlyph() {
  final bowl = Path()
    ..moveTo(26, 15)
    ..lineTo(70, 15)
    ..cubicTo(70, 38, 62, 52, 48, 55)
    ..cubicTo(34, 52, 26, 38, 26, 15)
    ..close();

  final rim = Path()
    ..addRRect(RRect.fromLTRBR(20, 11, 76, 21, const Radius.circular(5)));

  Path handleRing(Offset center) {
    return Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: center, radius: 12.5)),
      Path()..addOval(Rect.fromCircle(center: center, radius: 6.5)),
    );
  }

  final stem = Path()
    ..addRRect(RRect.fromLTRBR(42, 52, 54, 68, const Radius.circular(3)));
  final flare = Path()
    ..moveTo(40, 65)
    ..lineTo(56, 65)
    ..lineTo(61, 75)
    ..lineTo(35, 75)
    ..close();
  final base = Path()
    ..addRRect(RRect.fromLTRBR(28, 73, 68, 84, const Radius.circular(5.5)));

  final cup = _union([
    bowl,
    rim,
    handleRing(const Offset(24, 31)),
    handleRing(const Offset(72, 31)),
    stem,
    flare,
    base,
  ]);

  return Path.combine(
    PathOperation.difference,
    cup,
    _boltPath(const Rect.fromLTWH(39.5, 21, 17, 25)),
  );
}

/// Podyum: 2-1-3 kürsüsü, birincilik basamağının üzerinde loop şimşeği.
Path podiumGlyph() {
  RRect step(double l, double t, double r) {
    return RRect.fromLTRBAndCorners(
      l,
      t,
      r,
      82,
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
    );
  }

  final steps = Path()
    ..addRRect(step(8, 46, 33))
    ..addRRect(step(36, 28, 60))
    ..addRRect(step(63, 54, 88));

  final baseBar = Path()
    ..addRRect(RRect.fromLTRBR(4, 82, 92, 90, const Radius.circular(4)));

  return _union([
    steps,
    baseBar,
    _boltPath(const Rect.fromLTWH(39, 4, 18, 20)),
  ]);
}

/// Madalya: kurdeleli disk, içinde loop şimşeği.
Path medalGlyph() {
  final ribbonLeft = Path()
    ..moveTo(31, 6)
    ..lineTo(47, 6)
    ..lineTo(41, 34)
    ..lineTo(23, 30)
    ..close();
  final ribbonRight = Path()
    ..moveTo(49, 6)
    ..lineTo(65, 6)
    ..lineTo(73, 30)
    ..lineTo(55, 34)
    ..close();

  final disc = Path()
    ..addOval(Rect.fromCircle(center: const Offset(48, 58), radius: 24));

  final medal = _union([ribbonLeft, ribbonRight, disc]);

  return Path.combine(
    PathOperation.difference,
    medal,
    _boltPath(const Rect.fromLTWH(38, 43, 20, 30)),
  );
}

/// Görevler sekmesi ikonu: direk + dalgalanan bayrak. Navbar'daki ev/profil
/// ikonlarıyla aynı optik ağırlıkta, çerçeveyi dolduran tek kütleli silüet.
Path questFlagGlyph() {
  final pole = Path()
    ..addRRect(RRect.fromLTRBR(12, 4, 28, 92, const Radius.circular(7)));

  final banner = Path()
    ..moveTo(28, 12)
    ..cubicTo(48, 2, 66, 24, 90, 12)
    ..lineTo(90, 56)
    ..cubicTo(66, 68, 48, 46, 28, 56)
    ..close();

  return _union([pole, banner]);
}

void main() {
  testWidgets('export league badges as transparent PNGs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 640));
    tester.view.physicalSize = const Size(640, 640);
    tester.view.devicePixelRatio = 1.0;

    await tester.runAsync(() async {
      Directory(_exportDir).createSync(recursive: true);

      Future<void> export(String fileName, Widget badge) async {
        await tester.pumpWidget(
          Center(
            child: RepaintBoundary(
              child: SizedBox(
                width: 600,
                height: 600,
                child: Center(child: badge),
              ),
            ),
          ),
        );

        final boundary = tester
            .renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary));
        final image = await boundary.toImage();
        await _writePng(image, '$_exportDir/$fileName');
      }

      for (final key in _leagueKeys) {
        await export(
          'lig_$key.png',
          LeagueBadgeMark(leagueKey: key, size: 512),
        );
      }
      await export(
        'lig_kilitli.png',
        const LeagueBadgeMark(leagueKey: 'mars', size: 512, locked: true),
      );
    });
  });

  test('export navbar quest glyph', () async {
    final glyph = questFlagGlyph();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawPath(glyph, Paint()..color = Colors.white);
    final asset = await recorder.endRecording().toImage(96, 96);
    await _writePng(
      asset,
      '/Users/kerem.aydin/Desktop/Repos/Lingualloop/LingualLoop.Mobile/assets/icons/quest.png',
    );

    final previewRecorder = ui.PictureRecorder();
    final preview = Canvas(previewRecorder);
    preview.drawRect(
      const Rect.fromLTWH(0, 0, 300, 120),
      Paint()..color = const Color(0xFF041227),
    );
    for (final (i, color) in [
      (0, const Color(0xFFD1D1D1)),
      (1, const Color(0xFF00B4FB)),
    ]) {
      preview.save();
      preview.translate(24.0 + i * 110, 12);
      preview.drawPath(glyph, Paint()..color = color);
      preview.restore();
    }
    preview.save();
    preview.translate(252, 44);
    preview.scale(28 / 96);
    preview.drawPath(glyph, Paint()..color = const Color(0xFFD1D1D1));
    preview.restore();

    final sheet = await previewRecorder.endRecording().toImage(300, 120);
    await _writePng(sheet, '$_exportDir/quest_glyph_preview.png');
  });

  test('export navbar league glyph and navbar comparison preview', () async {
    final selected = boldTrophyGlyph();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawPath(selected, Paint()..color = Colors.white);
    final asset = await recorder.endRecording().toImage(96, 96);
    await _writePng(asset, _assetPath);

    Future<ui.Image> loadAsset(String name) async {
      final bytes = File(
        '/Users/kerem.aydin/Desktop/Repos/Lingualloop/LingualLoop.Mobile/assets/icons/$name',
      ).readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes);
      return (await codec.getNextFrame()).image;
    }

    final home = await loadAsset('home.png');
    final profile = await loadAsset('profile.png');

    // Gerçek navbar simülasyonu: ev / kupa / profil yan yana, 24 px,
    // pasif gri ve seçili mor tint ile.
    final previewRecorder = ui.PictureRecorder();
    final preview = Canvas(previewRecorder);
    preview.drawRect(
      const Rect.fromLTWH(0, 0, 360, 220),
      Paint()..color = const Color(0xFF041227),
    );

    void drawTinted(ui.Image image, Rect dst, Color color) {
      preview.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        dst,
        Paint()..colorFilter = ColorFilter.mode(color, BlendMode.srcIn),
      );
    }

    void drawGlyphAt(double x, double y, double size, Color color) {
      preview.save();
      preview.translate(x, y);
      preview.scale(size / 96);
      preview.drawPath(selected, Paint()..color = color);
      preview.restore();
    }

    const gray = Color(0xFFD1D1D1);
    const purple = Color(0xFF5F5CF0);

    for (final (row, color) in [(48.0, gray), (96.0, purple)]) {
      drawTinted(home, Rect.fromLTWH(60, row, 24, 24), color);
      drawGlyphAt(140, row, 24, color);
      drawTinted(profile, Rect.fromLTWH(220, row, 24, 24), color);
    }

    drawGlyphAt(40, 140, 20, gray);
    drawGlyphAt(90, 136, 28, gray);
    drawGlyphAt(150, 132, 64, gray);
    drawGlyphAt(240, 132, 64, purple);

    final sheet =
        await previewRecorder.endRecording().toImage(360, 220);
    await _writePng(sheet, '$_exportDir/navbar_glyph_preview.png');
  });
}
