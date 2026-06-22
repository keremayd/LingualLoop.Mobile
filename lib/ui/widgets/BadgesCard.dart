import 'package:flutter/material.dart';
import 'package:lingualloop/models/Badge.dart' as model;
import 'package:provider/provider.dart';

import '../../providers/BadgeProvider.dart';
import 'Popups/BadgePopup.dart';

class BadgesCard extends StatelessWidget {
  const BadgesCard({
    super.key,
    required this.color,
    required this.onTap,
  });

  final Color color;
  final VoidCallback onTap;

  static const _shadowColor = Color(0xFF07182F);
  static const _secondaryTextColor = Color(0xFFB7B7B7);

  @override
  Widget build(BuildContext context) {
    final badges = Provider.of<BadgeProvider>(context, listen: false).badges;
    final scale = MediaQuery.sizeOf(context).width / 750;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 282 * scale,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(38 * scale),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _SectionHeader(
              scale: scale,
              title: 'Başarılar',
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: badges.length,
                padding: EdgeInsets.symmetric(horizontal: 28 * scale),
                itemBuilder: (context, index) => _BadgeItem(
                  scale: scale,
                  badge: badges[index],
                  index: index,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.scale, required this.title});

  final double scale;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66 * scale,
      padding: EdgeInsets.symmetric(horizontal: 27 * scale),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: BadgesCard._shadowColor,
            width: 3 * scale,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
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
              color: BadgesCard._secondaryTextColor,
              fontFamily: 'Inter',
              fontSize: 30 * scale,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({
    required this.scale,
    required this.badge,
    required this.index,
  });

  final double scale;
  final model.Badge badge;
  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showBadgePopup(context, index),
      child: SizedBox(
        width: 204 * scale,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, 9 * scale),
              child: Image.asset(
                'assets/badges/${badge.badgeUrl}.png',
                height: 177 * scale,
                color: BadgesCard._shadowColor.withOpacity(0.75),
              ),
            ),
            Image.asset(
              'assets/badges/${badge.badgeUrl}.png',
              height: 170 * scale,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
