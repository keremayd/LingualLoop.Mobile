import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/models/responses/KartyPathResponse.dart';
import 'package:lingualloop/services/cached_signed_image.dart';

/// Ünite resmi imzalı adresle gelir ve imza her yanıtta değişir. Önbellek
/// anahtarı imzaya bağlı olsaydı ana ekran her tazelendiğinde resim silinip
/// yeniden inerdi.
const _bucket = 'https://kova.s3.eu-central-1.amazonaws.com';

String _signed(String key, String signature) =>
    '$_bucket/$key?X-Amz-Date=20261112T1000Z&X-Amz-Signature=$signature';

KartyPathResponse _path(String emblemUrl) => KartyPathResponse.fromJson({
      'deckSize': 8,
      'units': [
        {
          'sequence': 1,
          'title': 'Evde',
          'state': 'current',
          'wordCount': 16,
          'consolidatedCount': 3,
          'unlockGoal': 0.8,
          'emblemUrl': emblemUrl,
          'steps': <dynamic>[],
        },
      ],
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('aynı nesne yeni imzayla gelince anahtar değişmez', () {
    final first = CachedSignedImage(_signed('assets/42/karty_42.png', 'aaa'));
    final second = CachedSignedImage(_signed('assets/42/karty_42.png', 'bbb'));
    final other = CachedSignedImage(_signed('assets/43/karty_43.png', 'aaa'));

    expect(second, first);
    expect(second.hashCode, first.hashCode);
    expect(other, isNot(first));
  });

  test('yenilenen patikanın ünite resmi bellekteki kopyayı bulur', () {
    final before = KartyPathData.fromResponse(
      _path(_signed('assets/42/karty_42.png', 'aaa')),
    ).units.single.emblem!;
    final after = KartyPathData.fromResponse(
      _path(_signed('assets/42/karty_42.png', 'bbb')),
    ).units.single.emblem!;

    final cache = PaintingBinding.instance.imageCache;
    addTearDown(cache.clear);
    cache.putIfAbsent(
      before,
      () => OneFrameImageStreamCompleter(Completer<ImageInfo>().future),
    );

    expect(cache.containsKey(after), isTrue);
  });
}
