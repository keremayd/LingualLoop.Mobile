import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/AuthenticationService.dart';
import 'package:lingualloop/ui/widgets/ProfilePhoto.dart';
import 'package:provider/provider.dart';

import '../../providers/UserProvider.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.color});

  final Color color;

  static const _backgroundColor = Color(0xFF041227);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final scale = MediaQuery.sizeOf(context).width / 750;

    return Container(
      height: 660 * scale,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(40 * scale),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 44 * scale,
            right: 45 * scale,
            child: GestureDetector(
              onTap: () => AuthService(Dio()).signOut(context),
              child: Container(
                width: 76 * scale,
                height: 75 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFF041227),
                  borderRadius: BorderRadius.circular(20 * scale),
                ),
                child: Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 47 * scale,
                ),
              ),
            ),
          ),
          Positioned(
            top: 120 * scale,
            child: ProfilePhotoWidget(
              width: 157 * scale,
              height: 162 * scale,
              borderRadius: 28 * scale,
              editable: false,
            ),
          ),
          Positioned(
            top: 311 * scale,
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
                    fontFamily: 'Inter',
                    fontSize: 25 * scale,
                    fontWeight: FontWeight.w600,
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
                    fontFamily: 'Inter',
                    fontSize: 38 * scale,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 48 * scale,
            right: 48 * scale,
            bottom: 32 * scale,
            height: 174 * scale,
            child: Row(
              children: [
                Expanded(
                  child: Consumer<ScoreWithLivesProvider>(
                    builder: (context, provider, child) => _StatCard(
                      scale: scale,
                      imagePath: 'assets/icons/score.png',
                      imageHeight: 66,
                      label: 'Toplam Puan',
                      value: '${provider.scoreWithLives?.score ?? 0}',
                    ),
                  ),
                ),
                SizedBox(width: 7 * scale),
                Expanded(
                  child: Consumer<UserProvider>(
                    builder: (context, provider, child) => _StatCard(
                      scale: scale,
                      imagePath: 'assets/icons/league.png',
                      imageHeight: 64,
                      label: 'Lig',
                      value: '#${provider.user?.userRank ?? 0}',
                    ),
                  ),
                ),
                SizedBox(width: 7 * scale),
                Expanded(
                  child: Consumer<ScoreWithLivesProvider>(
                    builder: (context, provider, child) => _StatCard(
                      scale: scale,
                      imagePath: 'assets/icons/ticket.png',
                      imageHeight: 48,
                      label: 'Bilet',
                      value: '${provider.scoreWithLives?.lives ?? 0}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.scale,
    required this.imagePath,
    required this.imageHeight,
    required this.label,
    required this.value,
  });

  final double scale;
  final String imagePath;
  final double imageHeight;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ProfileCard._backgroundColor,
        borderRadius: BorderRadius.circular(28 * scale),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 66 * scale,
            child: Center(
              child: Image.asset(
                imagePath,
                height: imageHeight * scale,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontSize: 24 * scale,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontSize: 38 * scale,
              fontWeight: FontWeight.w600,
              height: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}
