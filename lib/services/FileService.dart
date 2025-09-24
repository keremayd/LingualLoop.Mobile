import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/User.dart';
import '../providers/UserProvider.dart';

class LocalFileService {
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

  Future<void> updateCachedProfilePhoto(String imageUrl, String userId, BuildContext context) async {
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

  Future<String> cacheKartyImage(String imageUrl, int kartyId) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$kartyId.png';
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
}
