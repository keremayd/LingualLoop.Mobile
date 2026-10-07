import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';

/// Karty ve form başlıklarında kullanılan aynı ölçüde derinlikli ikon kontrolü.
class AppIconControlButton extends StatelessWidget {
  const AppIconControlButton({
    super.key,
    required this.scale,
    required this.label,
    required this.onPressed,
    required this.child,
    this.enabled = true,
  });

  final double scale;
  final String label;
  final VoidCallback onPressed;
  final Widget child;
  final bool enabled;

  static double sizeForScale(double scale) => math.max(44.0, 84.75 * scale);

  /// Alt derinlik de dahil olmak üzere yerleşimde ayrılması gereken yükseklik.
  static double outerHeightForScale(double scale) =>
      sizeForScale(scale) + 4.875 * scale;

  @override
  Widget build(BuildContext context) {
    final size = sizeForScale(scale);

    return Semantics(
      label: label,
      child: DepthPressableButton(
        width: size,
        height: size - 3.125 * scale,
        radius: 24 * scale,
        shadowOffset: 8 * scale,
        backgroundColor: const Color(0xFF163258),
        shadowColor: const Color(0xFF0B2143),
        fontSize: 24 * scale,
        enabled: enabled,
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
