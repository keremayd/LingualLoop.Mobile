import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

/// İmzalı S3 görsellerinin disk önbelleği; patika, oyun ve Artikel aynı
/// dosyayı kullanır. Anahtar adresin imzasız hâli, yani S3 nesnesi: imza her
/// yanıtta değişse de görsel bir kez iner.
///
/// Kart görselleri sabit adla yeniden yüklenebiliyor
/// (`assets/42/karty_42.png`). Diskteki kopya bu yüzden her oturumda bir kez
/// arkada sunucuya sorulur (ETag): değiştiyse yenisi iner ve sonraki
/// açılışta görünür. Ekrandaki görsel oturum içinde değişmez.
abstract final class SignedImageCache {
  /// Bu oturumda sunucuya sorulmuş görseller.
  static final Set<String> _revalidated = {};

  /// Aynı görsel aynı anda iki kez inmesin.
  static final Map<String, Future<File>> _downloads = {};

  static final Set<Future<void>> _refreshes = {};

  /// İndirme istemcisi. Uygulamanın Dio'su değil: oturum anahtarını ekleyen
  /// interceptor imzalı S3 adresini bozar.
  @visibleForTesting
  static Dio http = Dio();

  /// Testte geçici klasör; uygulamada sistemin önbellek klasörü.
  @visibleForTesting
  static Directory? directory;

  /// Yeni bir oturumu taklit eder: görseller yeniden sunucuya sorulur.
  @visibleForTesting
  static void resetSession() {
    _revalidated.clear();
    _downloads.clear();
  }

  /// Arkadaki sorgular bitene kadar bekler.
  @visibleForTesting
  static Future<void> whenRefreshed() => Future.wait(_refreshes.toList());

  static String objectKeyOf(String url) {
    final uri = Uri.tryParse(url);
    return uri == null || uri.host.isEmpty ? url : '${uri.host}${uri.path}';
  }

  /// Görselin diskteki dosyası. Yoksa iner; varsa hemen döner ve oturumda
  /// bir kez arkada sunucuya sorulur.
  static Future<File> fileFor(String url) async {
    final key = objectKeyOf(url);
    final file = await _fileOf(key);
    if (await file.exists()) {
      if (_revalidated.add(key)) {
        final refresh = _refresh(url, key, file);
        _refreshes.add(refresh);
        unawaited(refresh.whenComplete(() => _refreshes.remove(refresh)));
      }
      return file;
    }
    return _downloads[key] ??= () async {
      try {
        await _download(url, file);
        _revalidated.add(key);
        return file;
      } finally {
        _downloads.remove(key);
      }
    }();
  }

  static Future<File> _fileOf(String key) async {
    final root = directory ?? await getApplicationCacheDirectory();
    final name = key.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return File('${root.path}/signed_images/$name');
  }

  /// Görseli indirip diske yazar. [etag] verildiyse ve görsel değişmediyse
  /// (304) hiçbir şey yazmaz.
  static Future<void> _download(String url, File file, {String? etag}) async {
    final response = await http.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {if (etag != null) 'If-None-Match': etag},
        validateStatus: (status) => status == 200 || status == 304,
      ),
    );
    if (response.statusCode == 304) return;

    await file.parent.create(recursive: true);
    // Yarım kalan yazım bozuk bir dosya bırakmasın; aynı anda yazan iki
    // indirme birbirinin geçici dosyasına karışmasın.
    final temp = File(
      '${file.path}.${DateTime.now().microsecondsSinceEpoch}'
      '${math.Random().nextInt(1 << 20)}.tmp',
    );
    await temp.writeAsBytes(response.data!, flush: true);
    await temp.rename(file.path);
    final tag = File('${file.path}.etag');
    final value = response.headers.value('etag');
    if (value != null) {
      await tag.writeAsString(value);
    } else if (await tag.exists()) {
      await tag.delete();
    }
  }

  static Future<void> _refresh(String url, String key, File file) async {
    try {
      final tag = File('${file.path}.etag');
      await _download(
        url,
        file,
        etag: await tag.exists() ? await tag.readAsString() : null,
      );
    } catch (_) {
      // Sunucuya ulaşılamadı: diskteki kopya geçerli, sonra yine sorulur.
      _revalidated.remove(key);
    }
  }
}

/// İmzalı S3 adresinden gelen görsel; bellekte ve diskte önbellekli
/// ([SignedImageCache]).
///
/// Adresin imzası her yanıtta değişiyor. `NetworkImage` adresi anahtar
/// aldığı için ana ekran her tazelendiğinde ünite resmi silinip yeniden
/// iniyordu (kullanıcı, 12 Kas 2026). Burada anahtar S3 nesnesi: aynı görsel
/// yeni imzayla gelse de bellekteki kopya kullanılır.
@immutable
class CachedSignedImage extends ImageProvider<CachedSignedImage> {
  CachedSignedImage(this.url) : objectKey = SignedImageCache.objectKeyOf(url);

  final String url;

  /// Adresin imzasız hâli; önbellek anahtarı.
  final String objectKey;

  @override
  Future<CachedSignedImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<CachedSignedImage>(this);

  @override
  ImageStreamCompleter loadImage(
    CachedSignedImage key,
    ImageDecoderCallback decode,
  ) =>
      MultiFrameImageStreamCompleter(
        codec: key._load(decode),
        scale: 1,
        debugLabel: key.objectKey,
      );

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final file = await SignedImageCache.fileFor(url);
    final bytes = await file.readAsBytes();
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is CachedSignedImage && other.objectKey == objectKey;

  @override
  int get hashCode => objectKey.hashCode;

  @override
  String toString() => 'CachedSignedImage($objectKey)';
}
