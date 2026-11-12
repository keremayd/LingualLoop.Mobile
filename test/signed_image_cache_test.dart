import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/services/cached_signed_image.dart';

/// S3 gibi davranır: görselin içeriği ve ETag'i var; `If-None-Match` aynıysa
/// 304 döner.
class _Bucket implements HttpClientAdapter {
  List<int> bytes = [1, 2, 3];
  String etag = '"v1"';
  int downloads = 0;
  int notModified = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future? cancelFuture) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    if (options.headers['If-None-Match'] == etag) {
      notModified += 1;
      return ResponseBody.fromBytes(const [], 304);
    }
    downloads += 1;
    return ResponseBody.fromBytes(bytes, 200, headers: {
      'etag': [etag],
    });
  }

  @override
  void close({bool force = false}) {}
}

const _object =
    'https://kova.s3.eu-north-1.amazonaws.com/assets/42/karty_42.png';

String _signed(String signature) => '$_object?X-Amz-Signature=$signature';

void main() {
  late Directory root;
  late _Bucket bucket;

  setUp(() {
    root = Directory.systemTemp.createTempSync('signed_images_');
    bucket = _Bucket();
    SignedImageCache.directory = root;
    SignedImageCache.http = Dio()..httpClientAdapter = bucket;
    SignedImageCache.resetSession();
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('ilk istekte iner; yeni imzayla gelen aynı görsel yeniden inmez',
      () async {
    final first = await SignedImageCache.fileFor(_signed('aaa'));
    final second = await SignedImageCache.fileFor(_signed('bbb'));
    await SignedImageCache.whenRefreshed();

    expect(second.path, first.path);
    expect(first.readAsBytesSync(), [1, 2, 3]);
    expect(bucket.downloads, 1);
    expect(bucket.notModified, 0);
  });

  test('yeni oturumda görsel değişmediyse diskteki kopya kalır', () async {
    final file = await SignedImageCache.fileFor(_signed('aaa'));
    final written = file.lastModifiedSync();

    SignedImageCache.resetSession();
    await SignedImageCache.fileFor(_signed('bbb'));
    await SignedImageCache.whenRefreshed();

    expect(bucket.notModified, 1);
    expect(bucket.downloads, 1);
    expect(file.lastModifiedSync(), written);
  });

  test('sunucuda değişen görsel sonraki oturumda yenisiyle gelir', () async {
    final file = await SignedImageCache.fileFor(_signed('aaa'));
    bucket
      ..bytes = [9, 9]
      ..etag = '"v2"';

    // Aynı oturumda ekrandaki görsel değişmez: sunucuya sorulmaz.
    await SignedImageCache.fileFor(_signed('bbb'));
    await SignedImageCache.whenRefreshed();
    expect(file.readAsBytesSync(), [1, 2, 3]);

    SignedImageCache.resetSession();
    await SignedImageCache.fileFor(_signed('ccc'));
    await SignedImageCache.whenRefreshed();
    expect(file.readAsBytesSync(), [9, 9]);
    expect(File('${file.path}.etag').readAsStringSync(), '"v2"');
  });

  test('aynı görsel aynı anda bir kez iner', () async {
    await Future.wait([
      SignedImageCache.fileFor(_signed('aaa')),
      SignedImageCache.fileFor(_signed('bbb')),
    ]);

    expect(bucket.downloads, 1);
  });
}
