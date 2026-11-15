import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_button_style.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/nav_marks.dart';
import 'package:lingualloop/ui/widgets/premium_ticket_mark.dart';
import 'package:lingualloop/ui/widgets/quest_flag_mark.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

/// Beş ana ekranın ortak alt menüsü; önizlemede de uygulamada da aynı yüzey.
///
/// Premium profilin solunda, Duolingo'da Super'in durduğu gibi sona yakın.
/// Sekme değil: dokununca premium ekranı tam ekran açılır, seçili hâle
/// geçmez. İkonu premium bilet (∞): 3B premium maskot bu boyda seçilmiyor.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _backgroundColor = Color(0xFF041227);
  static const _curveColor = Color(0xFF0B2143);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 750;
    final horizontalRadius = 60 * scale;
    final verticalRadius = 39 * scale;
    final strokeWidth = 8 * scale;
    // Alt boşluk, alt güvenli alanın (iPhone'da 34 pt) 20 pt eksiği: 14 pt.
    // Karonun altı böylece ana ekran çizgisinin (alttan 8–13 pt) ve ekranın
    // yuvarlak köşesinin üstünde kalır. Sabit 12 birimde (6 pt) seçili
    // karo köşede kesiliyordu ("alt menü çok aşağı sıkışmış gibi"); alanın
    // tamamı (34 pt) ise menüyü 28 pt uzatıp kocaman yaptı (ikisi de
    // kullanıcı, 16 Kas 2026). Güvenli alanı olmayan cihazda 12 birim.
    final bottom =
        math.max(12 * scale, MediaQuery.paddingOf(context).bottom - 20);

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.elliptical(horizontalRadius, verticalRadius),
        topRight: Radius.elliptical(horizontalRadius, verticalRadius),
      ),
      child: CustomPaint(
        foregroundPainter: _NavTopCurvePainter(
          color: _curveColor,
          horizontalRadius: horizontalRadius,
          verticalRadius: verticalRadius,
          strokeWidth: strokeWidth,
        ),
        child: ColoredBox(
          color: _backgroundColor,
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(18 * scale, 16 * scale, 18 * scale, bottom),
            child: Row(
              children: [
                _item((size) => NavMark(kind: NavMarkKind.home, size: size), 0,
                    'Ana sayfa', scale),
                _item((size) => TrophyIcon(size: size), 2, 'Ligler', scale),
                _item(
                    (size) => QuestFlagMark(size: size), 1, 'Görevler', scale),
                // Bilet kare değil (en/boy 1,56): kare ikonlarla aynı ağırlıkta
                // dursun diye biraz geniş.
                _item((size) => PremiumTicketMark(width: size * 1.2), 4,
                    'Premium', scale),
                _item((size) => NavMark(kind: NavMarkKind.profile, size: size),
                    3, 'Profil', scale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(Widget Function(double size) iconBuilder, int index,
      String label, double scale) {
    final selected = selectedIndex == index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: ExcludeSemantics(
          child: SizedBox(
            height: 112 * scale,
            child: Center(
              child: DepthPressableButton(
                width: 96 * scale,
                height: 96 * scale,
                radius: 26 * scale,
                shadowOffset: 7 * scale,
                roundedDepthOverride: AppButtonStyle.tileDepth(8 * scale),
                backgroundColor:
                    selected ? const Color(0xFF163258) : _backgroundColor,
                shadowColor: selected ? _curveColor : _backgroundColor,
                fontSize: 21 * scale,
                onPressed: () => onTap(index),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: selected ? 1 : 0.72,
                  child: iconBuilder(64 * scale),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTopCurvePainter extends CustomPainter {
  const _NavTopCurvePainter({
    required this.color,
    required this.horizontalRadius,
    required this.verticalRadius,
    required this.strokeWidth,
  });

  final Color color;
  final double horizontalRadius;
  final double verticalRadius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final top = strokeWidth / 2;
    final path = Path()
      ..moveTo(0, verticalRadius + top)
      ..quadraticBezierTo(0, top, horizontalRadius, top)
      ..lineTo(size.width - horizontalRadius, top)
      ..quadraticBezierTo(size.width, top, size.width, verticalRadius + top);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _NavTopCurvePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.horizontalRadius != horizontalRadius ||
      oldDelegate.verticalRadius != verticalRadius ||
      oldDelegate.strokeWidth != strokeWidth;
}
