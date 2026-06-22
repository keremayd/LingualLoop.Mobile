import 'package:flutter/material.dart';

import 'Popups/VideoPopup.dart';

class SavedVideosCard extends StatelessWidget {
  const SavedVideosCard({
    super.key,
    required this.color,
    required this.videoTitle,
    required this.onTap,
  });

  final Color color;
  final List<String> videoTitle;
  final VoidCallback onTap;

  static const _shadowColor = Color(0xFF07182F);
  static const _secondaryTextColor = Color(0xFFB7B7B7);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 750;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 281 * scale,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(38 * scale),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 66 * scale,
              padding: EdgeInsets.symmetric(horizontal: 27 * scale),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _shadowColor,
                    width: 3 * scale,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kaydedilenler',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontSize: 36 * scale,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Tümünü Gör',
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontFamily: 'Inter',
                      fontSize: 30 * scale,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: videoTitle.length,
                padding: EdgeInsets.symmetric(horizontal: 46 * scale),
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => showVideoPopup(context, index),
                  child: SizedBox(
                    width: 204 * scale,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.translate(
                            offset: Offset(0, 12 * scale),
                            child: Container(
                              width: 170 * scale,
                              height: 170 * scale,
                              decoration: BoxDecoration(
                                color: _shadowColor,
                                borderRadius: BorderRadius.circular(35 * scale),
                              ),
                            ),
                          ),
                          Container(
                            width: 170 * scale,
                            height: 170 * scale,
                            alignment: Alignment.center,
                            padding:
                                EdgeInsets.symmetric(horizontal: 10 * scale),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F9FD),
                              borderRadius: BorderRadius.circular(35 * scale),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                videoTitle[index],
                                maxLines: 1,
                                style: TextStyle(
                                  color: const Color(0xFF5F5CF0),
                                  fontFamily: 'Inter',
                                  fontSize: 40 * scale,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
