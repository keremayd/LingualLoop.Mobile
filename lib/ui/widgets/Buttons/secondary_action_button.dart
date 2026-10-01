import 'package:flutter/material.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';

/// Hoş geldin ekranındaki ikincil eylemin ortak yüzü ve basılma davranışı.
class SecondaryActionButton extends StatelessWidget {
  const SecondaryActionButton({
    super.key,
    required this.text,
    required this.scale,
    required this.width,
    required this.onPressed,
  });

  final String text;
  final double scale;
  final double width;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DepthPressableButton(
        width: width,
        height: 96 * scale,
        radius: 26 * scale,
        shadowOffset: 10 * scale,
        backgroundColor: const Color(0xFF0C2244),
        shadowColor: const Color(0xFF07182F),
        fontSize: 28 * scale,
        fontWeight: AppTypography.action,
        onPressed: onPressed,
        child: Text(text,
            style: TextStyle(
                color: const Color(0xFFE9EEF5),
                fontFamily: AppTypography.family,
                fontSize: 28 * scale,
                fontWeight: AppTypography.action)),
      );
}
