import 'package:flutter/material.dart';
import 'package:lingualloop/models/User.dart';
import 'package:provider/provider.dart';

import '../models/responses/GetSavedVideosByIdResponse.dart';
import '../services/VideoService.dart';

class VideoProvider with ChangeNotifier {
  final List<GetSavedVideosByIdResponse> _savedVideos = [];
  bool _isLoaded = false;

  List<GetSavedVideosByIdResponse> get savedVideos => List.unmodifiable(_savedVideos); // Dışarıdan değiştirilemez liste
  bool get isLoaded => _isLoaded;

  Future<bool> getSavedVideos(BuildContext context) async {
    final videoService = Provider.of<VideoService>(context, listen: false);

    _savedVideos.clear();
    var apiResponse = await videoService.savedVideos();
    if (apiResponse.errorCode == null) {
      _isLoaded = false;
      notifyListeners();

      for (var savedVideo in apiResponse.data!) {
        _savedVideos.add(
          GetSavedVideosByIdResponse(
            userVideoId: savedVideo.userVideoId,
            userId: savedVideo.userId,
            video: savedVideo.video,
            savedDate: savedVideo.savedDate,
          ),
        );
      }

      _isLoaded = true;
      notifyListeners();
      return true;
    }

    return false;
  }
}
