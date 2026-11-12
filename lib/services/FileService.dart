import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:lingualloop/services/cached_signed_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../providers/UserProvider.dart';

class LocalFileService {
  /// Önbellekteki profil fotoğrafının yolu; henüz inmemişse `null`.
  Future<String?> cachedProfilePhotoPath(String userId) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$userId-profile.jpg';
    return await File(filePath).exists() ? filePath : null;
  }

  Future<String> cacheProfilePhoto(String imageUrl, String userId) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$userId-profile.jpg';
    final file = File(filePath);

    // Eğer daha önce kaydedilmişse tekrar indirme
    if (await file.exists()) return filePath;

    final response = await Dio().get<List<int>>(
      imageUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    await file.writeAsBytes(response.data!);

    return filePath;
  }

  Future<void> updateCachedProfilePhoto(
      String imageUrl, String userId, BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$userId-profile.jpg';
    final cacheFile = File(filePath);

    if (await cacheFile.exists()) {
      // Evict old image from cache before deleting
      final oldImage = FileImage(File(filePath));
      await oldImage.evict(); // Force cache removal
      await cacheFile.delete();
    }

    final response = await Dio().get<List<int>>(
      imageUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    await cacheFile.writeAsBytes(response.data!);

    // Evict any potential cache of new file
    final newImage = FileImage(File(filePath));
    await newImage.evict();

    await userProvider.setProfilePhoto(filePath);
  }

  /// Kart görselinin diskteki yolu. Patika, oyun ve Artikel aynı önbelleği
  /// kullanır ([SignedImageCache]); sunucuda değişen görsel sonraki açılışta
  /// yenilenir.
  Future<String> cacheKartyImage(String imageUrl) async {
    unawaited(_removeLegacyKartyImages());
    return (await SignedImageCache.fileFor(imageUrl)).path;
  }

  static bool _legacyRemoved = false;

  /// Eski önbellek `Documents/<kartyId>.png` idi: sunucuya hiç sormuyordu ve
  /// yedeklenen klasörde duruyordu. Artık kullanılmıyor, bir kez silinir.
  Future<void> _removeLegacyKartyImages() async {
    if (_legacyRemoved) return;
    _legacyRemoved = true;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final legacy = RegExp(r'/\d+\.png$');
      await for (final entity in directory.list()) {
        if (entity is File && legacy.hasMatch(entity.path)) {
          await entity.delete();
        }
      }
    } catch (_) {
      // Silinemeyen dosya yalnız yer kaplar; uygulamayı durdurmaz.
    }
  }
}
