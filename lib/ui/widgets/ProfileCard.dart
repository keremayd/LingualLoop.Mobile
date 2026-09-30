import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_button_style.dart';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/services/AuthenticationService.dart';
import 'package:lingualloop/ui/widgets/ProfilePhoto.dart';
import 'package:provider/provider.dart';

import '../../providers/UserProvider.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.color});

  final Color color;

  static const _backgroundColor = Color(0xFF041227);
  static const _borderColor = Color(0xFF0B2143);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final scale = MediaQuery.sizeOf(context).width / 750;

    // Kart 440'tan **366** birime indi.
    //
    // Kısalma ayar düğmesini küçültmekten değil, fotoğrafı yukarı
    // çekmekten geliyor: düğme sağ üst **köşede** duruyor ve fotoğrafın
    // yanında kaldığı için artık onun üstünde ayrı bir satır işgal
    // etmiyor. Fotoğraf 120 → 46'ya çıktı, altındaki her şey onunla
    // birlikte yukarı geldi.
    //
    // Düğme bir ara fotoğrafın dikey merkezine hizalanmıştı; kartın
    // ortasında asılı duruyordu ve fotoğrafı sağa kaymış gösteriyordu.
    // Köşe doğru yer.
    return SizedBox(
      height: 366 * scale,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: AppShapeStyle.cardDepth(9 * scale),
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF0B2143),
                borderRadius:
                    BorderRadius.circular(AppShapeStyle.cardRadius(38 * scale)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: AppShapeStyle.cardDepth(9 * scale),
            child: Container(
              decoration: BoxDecoration(
                color: ProfileCard._backgroundColor,
                borderRadius:
                    BorderRadius.circular(AppShapeStyle.cardRadius(38 * scale)),
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 30 * scale,
                    right: 38 * scale,
                    child: GestureDetector(
                      onTap: () => AuthService(Dio()).signOut(context),
                      child: _SettingsButton(scale: scale),
                    ),
                  ),
                  Positioned(
                    top: 46 * scale,
                    child: ProfilePhotoWidget(
                      width: 157 * scale,
                      height: 162 * scale,
                      borderRadius: 28 * scale,
                      editable: false,
                    ),
                  ),
                  Positioned(
                    top: 237 * scale,
                    left: 20 * scale,
                    right: 20 * scale,
                    child: Column(
                      children: [
                        Text(
                          '@${user?.userNickname ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: AppTypography.family,
                            fontSize: 25 * scale,
                            fontWeight: AppTypography.caption,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 18 * scale),
                        Text(
                          user?.displayName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 38 * scale,
                            fontWeight: AppTypography.heading,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _NoTopBorderPainter(
                          color: ProfileCard._borderColor,
                          strokeWidth: AppShapeStyle.outline(2 * scale),
                          radius: AppShapeStyle.cardRadius(38 * scale),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final geometry = AppButtonStyle.resolve(
      width: 76 * scale,
      totalHeight: 82 * scale,
      legacyRadius: 20 * scale,
      legacyDepth: 7 * scale,
    );
    final radius = BorderRadius.circular(geometry.radius);

    return SizedBox(
      width: 76 * scale,
      height: 82 * scale,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: geometry.depth,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF0B2143),
                borderRadius: radius,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: geometry.depth,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF041227),
                borderRadius: radius,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 47 * scale,
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _NoTopBorderPainter(
                          color: const Color(0xFF0B2143),
                          strokeWidth: AppShapeStyle.outline(2 * scale),
                          radius: geometry.radius,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoTopBorderPainter extends CustomPainter {
  const _NoTopBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final usableRadius = radius.clamp(0, size.shortestSide / 2).toDouble();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(inset, usableRadius)
      ..lineTo(inset, size.height - usableRadius)
      ..quadraticBezierTo(
        inset,
        size.height - inset,
        usableRadius,
        size.height - inset,
      )
      ..lineTo(size.width - usableRadius, size.height - inset)
      ..quadraticBezierTo(
        size.width - inset,
        size.height - inset,
        size.width - inset,
        size.height - usableRadius,
      )
      ..lineTo(size.width - inset, usableRadius);

    canvas.drawPath(path, paint);

    final leftCorner = Path()
      ..moveTo(usableRadius, inset)
      ..quadraticBezierTo(inset, inset, inset, usableRadius);
    final rightCorner = Path()
      ..moveTo(size.width - usableRadius, inset)
      ..quadraticBezierTo(
        size.width - inset,
        inset,
        size.width - inset,
        usableRadius,
      );

    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      leftCorner,
      cornerPaint
        ..shader = ui.Gradient.linear(
          Offset(usableRadius, inset),
          Offset(inset, usableRadius),
          [color.withValues(alpha: 0), color],
        ),
    );
    canvas.drawPath(
      rightCorner,
      cornerPaint
        ..shader = ui.Gradient.linear(
          Offset(size.width - usableRadius, inset),
          Offset(size.width - inset, usableRadius),
          [color.withValues(alpha: 0), color],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _NoTopBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}
