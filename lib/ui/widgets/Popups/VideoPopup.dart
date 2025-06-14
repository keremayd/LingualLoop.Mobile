import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/providers/BadgeProvider.dart';
import 'package:lingualloop/providers/VideoProvider.dart';
import 'package:provider/provider.dart';

import '../CustomIconButton.dart';

void showVideoPopup(BuildContext context, int badgeIndex) {
  final videoProvider = Provider.of<VideoProvider>(context, listen: false);
  final savedVideo = videoProvider.savedVideos[badgeIndex];

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(0),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomIconButton(
                        img: 'cancel',
                        backgroundColor: Color(0xFFF7F9FD),
                        iconColor: Color(0xFF5F5CF0),
                        buttonSize: 18,
                        padding: 9,
                        ontap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Text(
                    savedVideo.video.videoTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5F5CF0),
                    ),
                  ),
                  SizedBox(height: 16),

                  Text(
                    savedVideo.video.videoDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Color(0xFF5F5CF0), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
