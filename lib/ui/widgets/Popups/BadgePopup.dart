import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/providers/BadgeProvider.dart';
import 'package:provider/provider.dart';

import '../CustomIconButton.dart';

void showBadgePopup(BuildContext context, int badgeIndex) {
  final badgeProvider = Provider.of<BadgeProvider>(context, listen: false);
  final badge = badgeProvider.badges[badgeIndex];

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
                        clickedImg: 'cancel',
                        backgroundColor: Color(0xFFF7F9FD),
                        iconColor: Color(0xFF5F5CF0),
                        buttonSize: 18,
                        padding: 9,
                        ontap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Text(
                    badge.badgeTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5F5CF0),
                    ),
                  ),
                  SizedBox(height: 16),

                  Stack(
                    children: [
                      Transform.translate(
                        offset: Offset(0, 3),
                        child: Image.asset(
                          'assets/badges/${badge.badgeUrl}.png',
                          height: 103,
                          color: Color(0xFF5F5CF0).withOpacity(0.8),
                        ),
                      ),
                      Image.asset(
                        'assets/badges/${badge.badgeUrl}.png',
                        height: 100,
                      ),
                    ],
                  ),

                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF7875FC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${badge.createdDate.day.toString().padLeft(2, '0')}.${badge.createdDate.month.toString().padLeft(2, '0')}.${badge.createdDate.year}",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),

                  SizedBox(height: 16),
                  Text(
                    badge.badgeDescription,
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
